-- =====================================================
-- Engify Supabase Database Setup
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- USERS TABLE
-- Stores user profile information
-- =====================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

-- =====================================================
-- USER PROGRESS TABLE
-- Stores gamification progress (XP, level, streak, etc.)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_progress (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    xp INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    streak_days INTEGER DEFAULT 0,
    hearts INTEGER DEFAULT 5,
    max_hearts INTEGER DEFAULT 5,
    lingots INTEGER DEFAULT 0,
    last_active_date TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

-- Users can read their own progress
CREATE POLICY "Users can read own progress"
    ON public.user_progress FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert/update their own progress
CREATE POLICY "Users can manage own progress"
    ON public.user_progress FOR ALL
    USING (auth.uid() = user_id);

-- =====================================================
-- SAVED WORDS TABLE
-- Stores vocabulary words saved by users
-- =====================================================
CREATE TABLE IF NOT EXISTS public.saved_words (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    word_id TEXT NOT NULL,
    word TEXT NOT NULL,
    pronunciation TEXT,
    part_of_speech TEXT,
    meaning TEXT NOT NULL,
    example TEXT,
    saved_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, word_id)
);

-- Enable Row Level Security
ALTER TABLE public.saved_words ENABLE ROW LEVEL SECURITY;

-- Users can only see their own saved words
CREATE POLICY "Users can manage own words"
    ON public.saved_words FOR ALL
    USING (auth.uid() = user_id);

-- =====================================================
-- LESSON RESULTS TABLE
-- Stores completed lesson history
-- =====================================================
CREATE TABLE IF NOT EXISTS public.lesson_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lesson_type TEXT NOT NULL,
    xp_earned INTEGER NOT NULL,
    lingots_earned INTEGER DEFAULT 0,
    completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.lesson_results ENABLE ROW LEVEL SECURITY;

-- Users can only see their own lesson results
CREATE POLICY "Users can manage own lessons"
    ON public.lesson_results FOR ALL
    USING (auth.uid() = user_id);

-- =====================================================
-- BADGES TABLE
-- Stores earned achievements
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    badge_id TEXT NOT NULL,
    badge_name TEXT NOT NULL,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

-- Enable Row Level Security
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

-- Users can only see/manage their own badges
CREATE POLICY "Users can manage own badges"
    ON public.user_badges FOR ALL
    USING (auth.uid() = user_id);

-- =====================================================
-- FUNCTION: Create user profile automatically
-- Triggered when a new user signs up
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email)
    );
    INSERT INTO public.user_progress (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call function on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- FUNCTION: Update last active date
-- Called when user completes a lesson
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_last_active()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.user_progress
    SET last_active_date = NOW(),
        updated_at = NOW()
    WHERE user_id = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- REALTIME (optional - for live sync across devices)
-- =====================================================
-- Enable realtime for progress updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_progress;
ALTER PUBLICATION supabase_realtime ADD TABLE public.saved_words;

-- =====================================================
-- FUNCTION: Delete the currently authenticated account
-- Lets the signed-in user permanently remove their own
-- auth account and all related rows with ON DELETE CASCADE.
-- =====================================================
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    current_user_id UUID := auth.uid();
BEGIN
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    DELETE FROM auth.users
    WHERE id = current_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account not found';
    END IF;
END;
$$;

ALTER FUNCTION public.delete_my_account() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;

-- =====================================================
-- VOCABULARY WORD DATABASE
-- Shared word catalog for Vocabulary lessons and Lookup
-- =====================================================
CREATE TABLE IF NOT EXISTS public.vocabulary_words (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    word TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL,
    word_level TEXT NOT NULL,
    pronunciation TEXT NOT NULL,
    audio_url TEXT,
    part_of_speech TEXT NOT NULL,
    definition TEXT NOT NULL,
    vietnamese_meaning TEXT NOT NULL,
    example TEXT NOT NULL,
    noun_form TEXT DEFAULT 'N/A',
    adjective_form TEXT DEFAULT 'N/A',
    verb_form TEXT DEFAULT 'N/A',
    idiom TEXT DEFAULT 'N/A',
    phrasal_verbs TEXT[] DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vocabulary_words_word
    ON public.vocabulary_words (lower(word));

CREATE INDEX IF NOT EXISTS idx_vocabulary_words_category
    ON public.vocabulary_words (category);

CREATE INDEX IF NOT EXISTS idx_vocabulary_words_level
    ON public.vocabulary_words (word_level);

ALTER TABLE public.vocabulary_words ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Vocabulary words are readable by everyone" ON public.vocabulary_words;
CREATE POLICY "Vocabulary words are readable by everyone"
    ON public.vocabulary_words FOR SELECT
    USING (true);

INSERT INTO public.vocabulary_words (
    word,
    category,
    word_level,
    pronunciation,
    audio_url,
    part_of_speech,
    definition,
    vietnamese_meaning,
    example,
    noun_form,
    adjective_form,
    verb_form,
    idiom,
    phrasal_verbs,
    tags,
    is_featured
)
VALUES
    (
        'habit',
        'Daily Life',
        'A1',
        '/ˈhæb.ɪt/',
        NULL,
        'noun',
        'something you do regularly, often without thinking about it',
        'thói quen',
        'Reading before bed became a healthy habit for her.',
        'habit',
        'habitual',
        'habituate',
        'old habits die hard',
        ARRAY[]::TEXT[],
        ARRAY['routine', 'daily-life', 'beginner'],
        true
    ),
    (
        'improve',
        'Learning',
        'A2',
        '/ɪmˈpruːv/',
        NULL,
        'verb',
        'to become better or to make something better',
        'cải thiện',
        'You will improve your listening if you practice every day.',
        'improvement',
        'improved',
        'improve',
        'improve on something',
        ARRAY['improve on'],
        ARRAY['study', 'progress', 'core'],
        true
    ),
    (
        'focus',
        'Study Skills',
        'A2',
        '/ˈfoʊ.kəs/',
        NULL,
        'verb',
        'to give your attention to one thing and think about it carefully',
        'tập trung',
        'Try to focus on the key sentence before checking the translation.',
        'focus',
        'focused',
        'focus',
        'focus on the task at hand',
        ARRAY['focus on'],
        ARRAY['attention', 'study-skills'],
        true
    ),
    (
        'confidence',
        'Speaking',
        'B1',
        '/ˈkɑn.fə.dəns/',
        NULL,
        'noun',
        'the feeling that you can do something successfully',
        'sự tự tin',
        'Short daily speaking practice builds confidence over time.',
        'confidence',
        'confident',
        'confide',
        'with confidence',
        ARRAY[]::TEXT[],
        ARRAY['speaking', 'mindset'],
        true
    ),
    (
        'break down',
        'Phrasal Verbs',
        'B1',
        '/breɪk daʊn/',
        NULL,
        'phrasal verb',
        'to divide something into smaller parts to make it easier to understand',
        'chia nhỏ; phân tích',
        'Let''s break down this sentence word by word.',
        'breakdown',
        'N/A',
        'break down',
        'break it down',
        ARRAY['break down', 'break it down'],
        ARRAY['phrasal-verb', 'analysis'],
        true
    ),
    (
        'piece of cake',
        'Idioms',
        'B1',
        '/ˌpiːs əv ˈkeɪk/',
        NULL,
        'idiom',
        'something that is very easy to do',
        'dễ như ăn bánh',
        'The vocabulary quiz was a piece of cake after all that review.',
        'N/A',
        'N/A',
        'N/A',
        'a piece of cake',
        ARRAY[]::TEXT[],
        ARRAY['idiom', 'conversation'],
        false
    ),
    (
        'analyze',
        'Academic',
        'B2',
        '/ˈæn.əl.aɪz/',
        NULL,
        'verb',
        'to study something carefully in order to understand it',
        'phân tích',
        'Readers should analyze the example sentence before memorizing the word.',
        'analysis',
        'analytical',
        'analyze',
        'analyze something in depth',
        ARRAY[]::TEXT[],
        ARRAY['academic', 'reading'],
        false
    ),
    (
        'carry out',
        'Work',
        'B2',
        '/ˈkær.i aʊt/',
        NULL,
        'phrasal verb',
        'to do and complete something that has been planned',
        'thực hiện',
        'The team carried out the new learning plan successfully.',
        'N/A',
        'N/A',
        'carry out',
        'carry out a plan',
        ARRAY['carry out', 'carry out a plan'],
        ARRAY['phrasal-verb', 'work'],
        false
    ),
    (
        'resilient',
        'Motivation',
        'C1',
        '/rɪˈzɪl.jənt/',
        NULL,
        'adjective',
        'able to recover quickly after difficulties',
        'kiên cường',
        'A resilient learner keeps going even after making mistakes.',
        'resilience',
        'resilient',
        'N/A',
        'stay resilient under pressure',
        ARRAY[]::TEXT[],
        ARRAY['motivation', 'advanced'],
        false
    )
ON CONFLICT (word) DO UPDATE SET
    category = EXCLUDED.category,
    word_level = EXCLUDED.word_level,
    pronunciation = EXCLUDED.pronunciation,
    audio_url = EXCLUDED.audio_url,
    part_of_speech = EXCLUDED.part_of_speech,
    definition = EXCLUDED.definition,
    vietnamese_meaning = EXCLUDED.vietnamese_meaning,
    example = EXCLUDED.example,
    noun_form = EXCLUDED.noun_form,
    adjective_form = EXCLUDED.adjective_form,
    verb_form = EXCLUDED.verb_form,
    idiom = EXCLUDED.idiom,
    phrasal_verbs = EXCLUDED.phrasal_verbs,
    tags = EXCLUDED.tags,
    is_featured = EXCLUDED.is_featured,
    updated_at = NOW();
