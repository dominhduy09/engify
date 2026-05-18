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
