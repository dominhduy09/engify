import Foundation

/// All core domain models for the Engify app.
/// These types are used throughout the Views, ViewModels, Services, and Managers layers.
///
/// WHEN THEY SHOW:
/// - EngifyTab: referenced by MainTabView and FloatingTabBar to know which tab is selected.
/// - User: created by AuthenticationManager on login/signup/guest session.
/// - Word: each item cycled through in VocabularyView flashcards.
/// - DictionaryEntry: returned by DictionaryService, displayed in DictionaryView entry section.
/// - DictionarySuggestion: fetched live from Datamuse while typing in DictionaryView search bar.
/// - QuizQuestion / Question: rendered by MultipleChoiceQuestionCard in NewsReadingView and PracticeView.
/// - Article: fetched by NewsService and rendered as article cards in NewsReadingView.
enum EngifyTab: Hashable {
    case home
    case vocabulary
    case dictionary
    case news
    case practice
}

enum EngifyAvatarStyle: String, Codable, CaseIterable, Hashable, Identifiable {
    case meadow
    case sky
    case sunrise
    case twilight

    var id: String { rawValue }
}

/// User account model. Created during login, signup, or guest session.
struct User: Identifiable, Codable, Hashable {
    let id: UUID
    let email: String
    let displayName: String
    let avatarStyle: EngifyAvatarStyle

    init(
        id: UUID = UUID(),
        email: String,
        displayName: String,
        avatarStyle: EngifyAvatarStyle = .meadow
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarStyle = avatarStyle
    }
}

/// A vocabulary flashcard word with pronunciation, meaning, and example.
/// Displayed one at a time in VocabularyView with navigation between cards.
struct Word: Identifiable, Codable, Hashable {
    let id: UUID
    let word: String
    let pronunciation: String
    let partOfSpeech: String
    let meaning: String
    let example: String
    let source: WordSource

    init(
        id: UUID = UUID(),
        word: String,
        pronunciation: String,
        partOfSpeech: String,
        meaning: String,
        example: String,
        source: WordSource = .vocabulary
    ) {
        self.id = id
        self.word = word
        self.pronunciation = pronunciation
        self.partOfSpeech = partOfSpeech
        self.meaning = meaning
        self.example = example
        self.source = source
    }
}

enum WordSource: String, Codable, Hashable {
    case vocabulary
    case news
}

/// A dictionary lookup result returned by DictionaryService from dictionaryapi.dev.
/// Displayed in DictionaryView and can be saved/bookmarked via SavedWordsManager.
struct DictionaryEntry: Identifiable, Codable, Hashable {
    let id: String
    let word: String
    let phonetic: String
    let audioURL: URL?
    let partOfSpeech: String
    let definition: String
    let example: String
    let vietnameseMeaning: String
    let nounForm: String
    let adjectiveForm: String
    let verbForm: String

    init(
        word: String,
        phonetic: String,
        audioURL: URL?,
        partOfSpeech: String,
        definition: String,
        example: String,
        vietnameseMeaning: String,
        nounForm: String = "N/A",
        adjectiveForm: String = "N/A",
        verbForm: String = "N/A"
    ) {
        self.id = word.lowercased()
        self.word = word
        self.phonetic = phonetic
        self.audioURL = audioURL
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.example = example
        self.vietnameseMeaning = vietnameseMeaning
        self.nounForm = nounForm
        self.adjectiveForm = adjectiveForm
        self.verbForm = verbForm
    }

    static func placeholder(for word: String) -> DictionaryEntry {
        let normalizedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)

        return DictionaryEntry(
            word: normalizedWord.isEmpty ? "N/A" : normalizedWord,
            phonetic: "N/A",
            audioURL: nil,
            partOfSpeech: "N/A",
            definition: "N/A",
            example: "N/A",
            vietnameseMeaning: "N/A",
            nounForm: "N/A",
            adjectiveForm: "N/A",
            verbForm: "N/A"
        )
    }
}

/// A real-time spelling suggestion returned by Datamuse and shown in DictionaryView's
/// suggestion dropdown while the user is typing a search query.
struct DictionarySuggestion: Identifiable, Codable, Hashable {
    let id: String
    let word: String
    let hint: String?

    init(word: String, hint: String? = nil) {
        self.id = word.lowercased()
        self.word = word
        self.hint = hint
    }
}

/// A single multiple-choice quiz question used in news article comprehension
/// and in the Practice tab's quick quiz.
struct QuizQuestion: Identifiable, Codable, Hashable {
    let id: UUID
    let prompt: String
    let options: [String]
    let answerIndex: Int
    let explanation: String

    init(id: UUID = UUID(), prompt: String, options: [String], answerIndex: Int, explanation: String) {
        self.id = id
        self.prompt = prompt
        self.options = options
        self.answerIndex = answerIndex
        self.explanation = explanation
    }
}

/// Type alias for QuizQuestion for brevity in some contexts.
typealias Question = QuizQuestion

/// A news article for language learners. Includes full content, difficult vocabulary
/// highlighting, and comprehension quiz questions. Fetched by NewsService.
struct Article: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let source: String
    let category: String
    let publishedDate: String
    let readingTime: String
    let summary: String
    let content: String
    let difficultWords: [String]
    let keyVocabulary: [NewsVocabularyItem]
    let questions: [QuizQuestion]
    let url: URL?

    init(
        id: UUID = UUID(),
        title: String,
        source: String,
        category: String,
        publishedDate: String,
        readingTime: String,
        summary: String,
        content: String,
        difficultWords: [String],
        keyVocabulary: [NewsVocabularyItem] = [],
        questions: [QuizQuestion],
        url: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.source = source
        self.category = category
        self.publishedDate = publishedDate
        self.readingTime = readingTime
        self.summary = summary
        self.content = content
        self.difficultWords = difficultWords
        self.keyVocabulary = keyVocabulary
        self.questions = questions
        self.url = url
    }
}

struct NewsVocabularyItem: Identifiable, Codable, Hashable {
    let id: String
    let word: String
    let partOfSpeech: String
    let phonetic: String
    let vietnameseMeaning: String
    let example: String

    init(
        word: String,
        partOfSpeech: String,
        phonetic: String,
        vietnameseMeaning: String,
        example: String
    ) {
        self.id = word.lowercased()
        self.word = word
        self.partOfSpeech = partOfSpeech
        self.phonetic = phonetic
        self.vietnameseMeaning = vietnameseMeaning
        self.example = example
    }

    var asWord: Word {
        Word(
            word: word,
            pronunciation: phonetic,
            partOfSpeech: partOfSpeech,
            meaning: vietnameseMeaning,
            example: example,
            source: .news
        )
    }
}

extension String {
    var capitalizedIfAvailable: String {
        self == "N/A" ? self : capitalized
    }
}

/// User's gamification progress: XP, level, streak, hearts, and lingots.
struct UserProgress: Codable {
    var xp: Int
    var level: Int
    var streakDays: Int
    var hearts: Int
    var maxHearts: Int
    var lingots: Int
    var lastActiveDate: Date?

    var xpForNextLevel: Int { level * 100 + 50 }

    var levelProgress: Double {
        let xpInCurrentLevel = xp - xpForCurrentLevelStart
        let xpNeeded = xpForNextLevel - xpForCurrentLevelStart
        return min(1.0, Double(xpInCurrentLevel) / Double(max(1, xpNeeded)))
    }

    var xpForCurrentLevelStart: Int {
        var sum = 0
        for l in 1..<level { sum += l * 100 + 50 }
        return sum
    }

    static var initial: UserProgress {
        UserProgress(xp: 0, level: 1, streakDays: 0, hearts: 5, maxHearts: 5, lingots: 0, lastActiveDate: nil)
    }

    mutating func earnXP(_ amount: Int) {
        xp += amount
        while xp >= xpForNextLevel {
            level += 1
        }
    }

    mutating func loseHeart() {
        hearts = max(0, hearts - 1)
    }

    mutating func restoreHearts() {
        hearts = maxHearts
    }

    mutating func addLingots(_ count: Int) {
        lingots += count
    }

    mutating func incrementStreak() {
        streakDays += 1
    }
}

/// Result of completing a lesson, used for XP awards and persistence.
struct LessonResult: Identifiable, Codable {
    let id: UUID
    let lessonType: LessonType
    let xpEarned: Int
    let lingotsEarned: Int
    let completedAt: Date

    init(lessonType: LessonType, xpEarned: Int, lingotsEarned: Int = 0) {
        self.id = UUID()
        self.lessonType = lessonType
        self.xpEarned = xpEarned
        self.lingotsEarned = lingotsEarned
        self.completedAt = Date()
    }
}

/// Types of lessons available in the app.
enum LessonType: String, Codable {
    case vocabulary
    case practice
    case dictionary
    case news
}
