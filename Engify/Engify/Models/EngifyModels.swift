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

struct OnboardingSurveyResponse: Codable, Equatable {
    let learningGoal: String
    let englishLevel: String
    let dailyStudyMinutes: Int
    let biggestChallenge: String
    let submittedAt: Date

    init(
        learningGoal: String,
        englishLevel: String,
        dailyStudyMinutes: Int,
        biggestChallenge: String,
        submittedAt: Date = Date()
    ) {
        self.learningGoal = learningGoal
        self.englishLevel = englishLevel
        self.dailyStudyMinutes = dailyStudyMinutes
        self.biggestChallenge = biggestChallenge
        self.submittedAt = submittedAt
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
    let category: String
    let wordLevel: String
    let phonetic: String
    let audioURL: URL?
    let partOfSpeech: String
    let definition: String
    let example: String
    let vietnameseMeaning: String
    let nounForm: String
    let adjectiveForm: String
    let verbForm: String
    let idiom: String
    let phrasalVerbs: [String]

    init(
        word: String,
        category: String = "N/A",
        wordLevel: String = "N/A",
        phonetic: String,
        audioURL: URL?,
        partOfSpeech: String,
        definition: String,
        example: String,
        vietnameseMeaning: String,
        nounForm: String = "N/A",
        adjectiveForm: String = "N/A",
        verbForm: String = "N/A",
        idiom: String = "N/A",
        phrasalVerbs: [String] = []
    ) {
        self.id = word.lowercased()
        self.word = word
        self.category = category
        self.wordLevel = wordLevel
        self.phonetic = phonetic
        self.audioURL = audioURL
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.example = example
        self.vietnameseMeaning = vietnameseMeaning
        self.nounForm = nounForm
        self.adjectiveForm = adjectiveForm
        self.verbForm = verbForm
        self.idiom = idiom
        self.phrasalVerbs = phrasalVerbs
    }

    static func placeholder(for word: String) -> DictionaryEntry {
        let normalizedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)

        return DictionaryEntry(
            word: normalizedWord.isEmpty ? "N/A" : normalizedWord,
            category: "N/A",
            wordLevel: "N/A",
            phonetic: "N/A",
            audioURL: nil,
            partOfSpeech: "N/A",
            definition: "N/A",
            example: "N/A",
            vietnameseMeaning: "N/A",
            nounForm: "N/A",
            adjectiveForm: "N/A",
            verbForm: "N/A",
            idiom: "N/A",
            phrasalVerbs: []
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
    struct XPSnapshot {
        let totalXP: Int
        let level: Int
        let xpForCurrentLevelStart: Int
        let xpNeededForLevel: Int

        var xpIntoCurrentLevel: Int {
            max(0, totalXP - xpForCurrentLevelStart)
        }

        var levelProgress: Double {
            Double(xpIntoCurrentLevel) / Double(max(1, xpNeededForLevel))
        }
    }

    var xp: Int
    var level: Int
    var streakDays: Int
    var hearts: Int
    var maxHearts: Int
    var lingots: Int
    var lastActiveDate: Date?

    var points: Int {
        get { lingots }
        set { lingots = max(0, newValue) }
    }

    var xpForNextLevel: Int { Self.xpRequired(for: level) }

    var levelProgress: Double {
        snapshot.levelProgress
    }

    var xpForCurrentLevelStart: Int {
        Self.levelStartXP(for: level)
    }

    var snapshot: XPSnapshot {
        Self.snapshot(forTotalXP: xp)
    }

    var resolvedLevel: Int {
        snapshot.level
    }

    static var initial: UserProgress {
        UserProgress(xp: 0, level: 1, streakDays: 0, hearts: 5, maxHearts: 5, lingots: 0, lastActiveDate: nil)
    }

    static func snapshot(forTotalXP totalXP: Int) -> XPSnapshot {
        let resolvedXP = max(0, totalXP)
        var level = 1
        var levelStartXP = 0
        var xpNeededForLevel = xpRequired(for: level)

        while resolvedXP >= levelStartXP + xpNeededForLevel {
            levelStartXP += xpNeededForLevel
            level += 1
            xpNeededForLevel = xpRequired(for: level)
        }

        return XPSnapshot(
            totalXP: resolvedXP,
            level: level,
            xpForCurrentLevelStart: levelStartXP,
            xpNeededForLevel: xpNeededForLevel
        )
    }

    static func levelStartXP(for level: Int) -> Int {
        guard level > 1 else { return 0 }

        var sum = 0
        for currentLevel in 1..<level {
            sum += xpRequired(for: currentLevel)
        }
        return sum
    }

    static func xpRequired(for level: Int) -> Int {
        150
    }

    mutating func earnXP(_ amount: Int) {
        xp = max(0, xp + amount)
        normalizeLevel()
    }

    mutating func loseHeart() {
        hearts = max(0, hearts - 1)
    }

    mutating func restoreHearts() {
        hearts = maxHearts
    }

    mutating func addLingots(_ count: Int) {
        addPoints(count)
    }

    mutating func addPoints(_ count: Int) {
        points += max(0, count)
    }

    mutating func spendPoints(_ count: Int) {
        points = max(0, points - max(0, count))
    }

    mutating func incrementStreak() {
        streakDays += 1
    }

    mutating func normalizeLevel() {
        level = resolvedLevel
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

enum PointsRewardEvent: Hashable {
    case savedWord(wordID: String)
    case perfectPractice(sessionID: UUID)
    case completedNewsQuiz(articleID: UUID)

    var rewardKey: String {
        switch self {
        case let .savedWord(wordID):
            return "saved-word:\(wordID)"
        case let .perfectPractice(sessionID):
            return "perfect-practice:\(sessionID.uuidString)"
        case let .completedNewsQuiz(articleID):
            return "completed-news-quiz:\(articleID.uuidString)"
        }
    }

    var pointsAwarded: Int {
        switch self {
        case .savedWord:
            return 5
        case .completedNewsQuiz:
            return 15
        case .perfectPractice:
            return 20
        }
    }
}

enum PointsRewardResult: Equatable {
    case awarded(amount: Int, totalPoints: Int)
    case alreadyAwarded(totalPoints: Int)
}
