import Foundation

/// A daily learning tip shown on the Home screen.
///
/// WHAT IT DOES:
/// - Provides a curated pool of English learning tips across categories like
///   Vocabulary, Grammar, Speaking, Reading, Study Habits, and Motivation.
/// - Selects one tip per day using a date-based seed so it's consistent
///   throughout the day but changes the next day.
/// - Tracks previously shown tips to avoid short-term repetition.
struct LearningTip: Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let icon: String
    let category: String

    /// Returns a deterministic tip for today based on the calendar date.
    static func tipOfTheDay() -> LearningTip {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % allTips.count
        return allTips[index]
    }

    // MARK: - Curated Tips Pool

    static let allTips: [LearningTip] = [
        // Vocabulary
        LearningTip(
            id: "vocab-1",
            title: "Learn words in context",
            body: "Don't memorize isolated words. Read them in sentences so you remember how they're actually used in conversation.",
            icon: "text.book.closed.fill",
            category: "Vocabulary"
        ),
        LearningTip(
            id: "vocab-2",
            title: "Use the 5-word rule",
            body: "Pick 5 new words each day and use each one in a sentence you write yourself. Quality beats quantity for retention.",
            icon: "text.book.closed.fill",
            category: "Vocabulary"
        ),
        LearningTip(
            id: "vocab-3",
            title: "Group words by theme",
            body: "Learn related words together — food, travel, emotions. Your brain stores them in clusters, making recall faster.",
            icon: "text.book.closed.fill",
            category: "Vocabulary"
        ),
        LearningTip(
            id: "vocab-4",
            title: "Learn collocations, not just words",
            body: "Instead of just \"make\", learn \"make a decision\", \"make progress\", \"make sense\". Natural English is about word pairs.",
            icon: "text.book.closed.fill",
            category: "Vocabulary"
        ),

        // Grammar
        LearningTip(
            id: "grammar-1",
            title: "Master one tense at a time",
            body: "Focus on present simple until it's automatic, then move to past. Trying to learn all tenses at once leads to confusion.",
            icon: "pencil.and.ruler.fill",
            category: "Grammar"
        ),
        LearningTip(
            id: "grammar-2",
            title: "Notice patterns, not rules",
            body: "Instead of memorizing grammar rules, notice how native speakers structure sentences. Patterns stick better than abstract rules.",
            icon: "pencil.and.ruler.fill",
            category: "Grammar"
        ),
        LearningTip(
            id: "grammar-3",
            title: "Prepositions need practice",
            body: "\"On Monday\", \"at night\", \"in the morning\" — prepositions don't translate directly. Learn them as fixed phrases, not logic.",
            icon: "pencil.and.ruler.fill",
            category: "Grammar"
        ),

        // Speaking
        LearningTip(
            id: "speaking-1",
            title: "Shadow native speakers",
            body: "Listen to a short audio clip, then repeat it immediately, copying the rhythm and intonation. This builds natural flow.",
            icon: "waveform.and.mic",
            category: "Speaking"
        ),
        LearningTip(
            id: "speaking-2",
            title: "Talk to yourself in English",
            body: "Narrate what you're doing: \"I'm making coffee, then I'll check my email.\" It builds fluency without pressure.",
            icon: "waveform.and.mic",
            category: "Speaking"
        ),
        LearningTip(
            id: "speaking-3",
            title: "Record and listen back",
            body: "Record yourself speaking English for 1 minute, then listen. You'll catch pronunciation issues you didn't notice while speaking.",
            icon: "waveform.and.mic",
            category: "Speaking"
        ),

        // Reading
        LearningTip(
            id: "reading-1",
            title: "Read slightly above your level",
            body: "If you understand 80% of a text, it's perfect for learning. Too easy means no growth; too hard means frustration.",
            icon: "newspaper.fill",
            category: "Reading"
        ),
        LearningTip(
            id: "reading-2",
            title: "Don't look up every word",
            body: "Try to guess meaning from context first. Only look up words that appear repeatedly or block understanding completely.",
            icon: "newspaper.fill",
            category: "Reading"
        ),
        LearningTip(
            id: "reading-3",
            title: "Read the same article twice",
            body: "First read for main idea, second for details. You'll be surprised how much more you catch on the second pass.",
            icon: "newspaper.fill",
            category: "Reading"
        ),

        // Study Habits
        LearningTip(
            id: "habits-1",
            title: "10 minutes beats 0 minutes",
            body: "Short daily sessions are more effective than long weekend cramming. Consistency builds neural pathways that stick.",
            icon: "clock.fill",
            category: "Habits"
        ),
        LearningTip(
            id: "habits-2",
            title: "Review before you sleep",
            body: "Your brain consolidates memories during sleep. A quick 5-minute review before bed significantly boosts retention.",
            icon: "clock.fill",
            category: "Habits"
        ),
        LearningTip(
            id: "habits-3",
            title: "Mix up your practice",
            body: "Alternate between reading, listening, speaking, and writing in each session. Variety keeps your brain engaged and learning efficient.",
            icon: "clock.fill",
            category: "Habits"
        ),

        // Motivation
        LearningTip(
            id: "motivation-1",
            title: "Celebrate small wins",
            body: "Understood a meme in English? Read a headline without translating? That's real progress. Notice it and feel good about it.",
            icon: "star.fill",
            category: "Motivation"
        ),
        LearningTip(
            id: "motivation-2",
            title: "Mistakes are data, not failure",
            body: "Every error shows you exactly what to practice next. The learners who improve fastest are the ones who make the most mistakes.",
            icon: "star.fill",
            category: "Motivation"
        ),
        LearningTip(
            id: "motivation-3",
            title: "Compare yourself to your past self",
            body: "Don't measure your English against native speakers. Compare it to where you were 3 months ago. That's your real progress.",
            icon: "star.fill",
            category: "Motivation"
        ),
    ]
}
