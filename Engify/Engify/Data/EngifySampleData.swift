import Foundation

struct PracticeImageLesson: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let locationLabel: String
    let systemImage: String
    let visualStyle: String
    let searchTopics: [String]
    let sceneDescription: String
    let focusVocabulary: [String]
    let guidedPrompts: [String]
    let challengePrompt: String
}

struct PracticeDialogueScenario: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let setting: String
    let goal: String
    let systemImage: String
    let partnerOpeningLine: String
    let responseIdeas: [String]
    let usefulPhrases: [String]
    let confidenceTip: String
}

/// Hardcoded sample content used as offline fallback and default vocabulary source.
///
/// WHAT IT CONTAINS:
/// - vocabularyWords: 4 Word flashcard items used by VocabularyView.
/// - dictionaryFallbackWords: 3 DictionaryEntry items shown when API returns no result.
/// - articles: 3 Article items with comprehension quizzes (used when no API key).
/// - speakingSentence: the sentence displayed in PracticeView's speaking section.
/// - grammarTopics: 2 grammar lessons (Present Simple, There is/There are).
/// - practiceQuizQuestions: 3 multiple-choice quiz questions for the Practice tab.
/// - practiceImageLessons: scene-based visual prompts for descriptive speaking.
/// - practiceDialogueScenarios: roleplay prompts for real-life conversations.
///
/// WHEN IT SHOWS:
/// - VocabularyView uses vocabularyWords as its primary word list.
/// - NewsService returns articles when apiKey == "YOUR_API_KEY_HERE".
/// - PracticeView reads grammarTopics and practiceQuizQuestions directly.
/// - DictionaryService falls back to dictionaryFallbackWords on error.
enum EngifySampleData {
    // Sample content keeps the whole app usable when the network is unavailable.
    static let vocabularyWords: [Word] = [
        Word(word: "habit", pronunciation: "/ˈhæb.ɪt/", partOfSpeech: "noun", meaning: "thói quen", example: "Reading for 10 minutes every day is a good habit."),
        Word(word: "improve", pronunciation: "/ɪmˈpruːv/", partOfSpeech: "verb", meaning: "cải thiện", example: "I want to improve my speaking skills."),
        Word(word: "daily", pronunciation: "/ˈdeɪ.li/", partOfSpeech: "adjective", meaning: "hằng ngày", example: "A daily lesson can help you learn faster."),
        Word(word: "focus", pronunciation: "/ˈfoʊ.kəs/", partOfSpeech: "verb", meaning: "tập trung", example: "Please focus on the main idea."),
        Word(word: "achieve", pronunciation: "/əˈtʃiːv/", partOfSpeech: "verb", meaning: "đạt được", example: "With hard work, you can achieve your goals."),
        Word(word: "challenge", pronunciation: "/ˈtʃæl.ɪndʒ/", partOfSpeech: "noun", meaning: "thử thách", example: "Learning a new language is a fun challenge."),
        Word(word: "confident", pronunciation: "/ˈkɑn.fɪ.dənt/", partOfSpeech: "adjective", meaning: "tự tin", example: "She felt confident before her presentation."),
        Word(word: "determine", pronunciation: "/dɪˈtɜr.mɪn/", partOfSpeech: "verb", meaning: "xác định", example: "We need to determine the best solution."),
        Word(word: "effective", pronunciation: "/ɪˈfek.tɪv/", partOfSpeech: "adjective", meaning: "hiệu quả", example: "This method is very effective for learning."),
        Word(word: "effort", pronunciation: "/ˈef.ɚt/", partOfSpeech: "noun", meaning: "nỗ lực", example: "Success requires effort and patience."),
        Word(word: "essential", pronunciation: "/ɪˈsen.ʃəl/", partOfSpeech: "adjective", meaning: "thiết yếu", example: "Water is essential for life."),
        Word(word: "evaluate", pronunciation: "/ɪˈvæl.ju.eɪt/", partOfSpeech: "verb", meaning: "đánh giá", example: "We evaluate our progress every week."),
        Word(word: "experience", pronunciation: "/ɪkˈspɪr.i.əns/", partOfSpeech: "noun", meaning: "kinh nghiệm", example: "Experience is the best teacher."),
        Word(word: "facilitate", pronunciation: "/fəˈsɪl.ə.teɪt/", partOfSpeech: "verb", meaning: "tạo điều kiện", example: "Technology facilitates learning."),
        Word(word: "flexible", pronunciation: "/ˈflek.sə.bəl/", partOfSpeech: "adjective", meaning: "linh hoạt", example: "I have a flexible schedule for studying."),
        Word(word: "flourish", pronunciation: "/ˈflɝ.ɪʃ/", partOfSpeech: "verb", meaning: "phát triển", example: "Plants flourish with proper care."),
        Word(word: "frequent", pronunciation: "/ˈfri.kwənt/", partOfSpeech: "adjective", meaning: "thường xuyên", example: "Frequent practice leads to fluency."),
        Word(word: "generate", pronunciation: "/ˈdʒen.ə.reɪt/", partOfSpeech: "verb", meaning: "tạo ra", example: "Good ideas generate solutions."),
        Word(word: "genuine", pronunciation: "/ˈdʒen.ju.wɪn/", partOfSpeech: "adjective", meaning: "chân thật", example: "She showed genuine interest in learning."),
        Word(word: "grasp", pronunciation: "/ɡræsp/", partOfSpeech: "verb", meaning: "nắm bắt", example: "It takes time to grasp new concepts."),
        Word(word: "growth", pronunciation: "/ɡroʊθ/", partOfSpeech: "noun", meaning: "sự phát triển", example: "Constant learning leads to personal growth."),
        Word(word: "guide", pronunciation: "/ɡaɪd/", partOfSpeech: "verb", meaning: "hướng dẫn", example: "A good teacher guides students to success."),
        Word(word: "harmony", pronunciation: "/ˈhɑr.mə.ni/", partOfSpeech: "noun", meaning: "hòa hợp", example: "Learning in harmony with others is rewarding."),
        Word(word: "highlight", pronunciation: "/ˈhaɪ.laɪt/", partOfSpeech: "verb", meaning: "làm nổi bật", example: "I like to highlight important vocabulary."),
        Word(word: "imitate", pronunciation: "/ˈɪm.ə.teɪt/", partOfSpeech: "verb", meaning: "bắt chước", example: "Kids often imitate native speakers."),
        Word(word: "impact", pronunciation: "/ˈɪm.pækt/", partOfSpeech: "noun", meaning: "ảnh hưởng", example: "Regular practice has a positive impact on fluency."),
        Word(word: "implement", pronunciation: "/ˈɪm.plə.ment/", partOfSpeech: "verb", meaning: "thực hiện", example: "We implement new strategies to improve learning."),
        Word(word: "inspire", pronunciation: "/ɪnˈspaɪɚ/", partOfSpeech: "verb", meaning: "truyền cảm hứng", example: "Good teachers inspire their students."),
        Word(word: "instinct", pronunciation: "/ˈɪn.stɪŋkt/", partOfSpeech: "noun", meaning: "bản năng", example: "Learning a language follows natural instinct."),
        Word(word: "integrate", pronunciation: "/ˈɪn.tə.ɡreɪt/", partOfSpeech: "verb", meaning: "kết hợp", example: "We integrate reading and listening skills."),
        Word(word: "intense", pronunciation: "/ɪnˈtens/", partOfSpeech: "adjective", meaning: "mãnh liệt", example: "I had an intense study session yesterday."),
        Word(word: "intriguing", pronunciation: "/ɪnˈtrɪɡ.ɪŋ/", partOfSpeech: "adjective", meaning: "hấp dẫn", example: "Learning about different cultures is intriguing."),
        Word(word: "journey", pronunciation: "/ˈdʒɝ.ni/", partOfSpeech: "noun", meaning: "hành trình", example: "Learning English is an exciting journey."),
        Word(word: "justify", pronunciation: "/ˈdʒʌs.tə.faɪ/", partOfSpeech: "verb", meaning: "biện minh", example: "Can you justify your answer?"),
        Word(word: "knowledge", pronunciation: "/ˈnɑl.ɪdʒ/", partOfSpeech: "noun", meaning: "kiến thức", example: "Knowledge is power in learning."),
        Word(word: "lengthen", pronunciation: "/ˈleŋ.θən/", partOfSpeech: "verb", meaning: "kéo dài", example: "Lengthening your study time improves retention."),
        Word(word: "literal", pronunciation: "/ˈlɪt.ər.əl/", partOfSpeech: "adjective", meaning: "từ chữ", example: "The literal meaning of this word is different from its figurative sense."),
        Word(word: "logical", pronunciation: "/ˈlɑdʒ.ɪ.kəl/", partOfSpeech: "adjective", meaning: "hợp lý", example: "This approach is more logical and effective."),
        Word(word: "maintain", pronunciation: "/meɪnˈteɪn/", partOfSpeech: "verb", meaning: "duy trì", example: "You must maintain consistency in your studies."),
        Word(word: "master", pronunciation: "/ˈmæs.tɚ/", partOfSpeech: "verb", meaning: "thành thạo", example: "It takes time to master a new skill."),
        Word(word: "memorable", pronunciation: "/ˈmem.ə.rə.bəl/", partOfSpeech: "adjective", meaning: "đáng nhớ", example: "That lesson was very memorable."),
        Word(word: "method", pronunciation: "/ˈmeθ.əd/", partOfSpeech: "noun", meaning: "phương pháp", example: "This method works well for language learning."),
        Word(word: "meticulous", pronunciation: "/məˈtɪk.jə.ləs/", partOfSpeech: "adjective", meaning: "tỉ mỉ", example: "She is meticulous about grammar rules."),
        Word(word: "minimize", pronunciation: "/ˈmɪn.ə.maɪz/", partOfSpeech: "verb", meaning: "giảm thiểu", example: "Minimize distractions while studying."),
        Word(word: "momentum", pronunciation: "/moʊˈmen.təm/", partOfSpeech: "noun", meaning: "động lực", example: "Don't lose momentum in your English studies."),
        Word(word: "motivate", pronunciation: "/ˈmoʊ.tə.veɪt/", partOfSpeech: "verb", meaning: "động viên", example: "Good progress motivates students to continue."),
        Word(word: "navigate", pronunciation: "/ˈnæv.ə.ɡeɪt/", partOfSpeech: "verb", meaning: "điều hướng", example: "It helps to navigate through difficult grammar."),
        Word(word: "necessary", pronunciation: "/ˈnes.ə.ser.i/", partOfSpeech: "adjective", meaning: "cần thiết", example: "Practice is necessary for fluency."),
        Word(word: "nourish", pronunciation: "/ˈnɜr.ɪʃ/", partOfSpeech: "verb", meaning: "nuôi dưỡng", example: "Reading nourishes your vocabulary."),
        Word(word: "nurture", pronunciation: "/ˈnɝ.tʃɚ/", partOfSpeech: "verb", meaning: "chăm sóc", example: "Teachers nurture their students' potential."),
        Word(word: "objective", pronunciation: "/əbˈdʒek.tɪv/", partOfSpeech: "noun", meaning: "mục tiêu", example: "My objective is to speak English fluently."),
        Word(word: "obvious", pronunciation: "/ˈɑb.vi.əs/", partOfSpeech: "adjective", meaning: "rõ ràng", example: "It's obvious that practice helps learning."),
        Word(word: "obtain", pronunciation: "/əbˈteɪn/", partOfSpeech: "verb", meaning: "đạt được", example: "You can obtain success through hard work."),
        Word(word: "optimize", pronunciation: "/ˈɑp.tə.maɪz/", partOfSpeech: "verb", meaning: "tối ưu hóa", example: "We optimize our study methods for better results."),
        Word(word: "original", pronunciation: "/əˈrɪdʒ.ə.nəl/", partOfSpeech: "adjective", meaning: "gốc", example: "Reading the original text helps comprehension."),
        Word(word: "overcome", pronunciation: "/oʊ.vɚˈkʌm/", partOfSpeech: "verb", meaning: "vượt qua", example: "You can overcome language barriers."),
        Word(word: "oversee", pronunciation: "/oʊ.vɚˈsi/", partOfSpeech: "verb", meaning: "giám sát", example: "Teachers oversee their students' progress."),
        Word(word: "pace", pronunciation: "/peɪs/", partOfSpeech: "noun", meaning: "tốc độ", example: "Learn at your own pace."),
        Word(word: "partner", pronunciation: "/ˈpɑrt.nɚ/", partOfSpeech: "noun", meaning: "đối tác", example: "Find a study partner for better learning."),
        Word(word: "passage", pronunciation: "/ˈpæs.ɪdʒ/", partOfSpeech: "noun", meaning: "đoạn văn", example: "Read this passage carefully."),
        Word(word: "patience", pronunciation: "/ˈpeɪ.ʃəns/", partOfSpeech: "noun", meaning: "kiên nhẫn", example: "Language learning requires patience and dedication."),
        Word(word: "pattern", pronunciation: "/ˈpæt.ɚn/", partOfSpeech: "noun", meaning: "mẫu", example: "English grammar has many patterns to learn."),
        Word(word: "perceive", pronunciation: "/pɚˈsiv/", partOfSpeech: "verb", meaning: "nhận thức", example: "We perceive pronunciation by listening carefully."),
        Word(word: "persist", pronunciation: "/pɚˈsɪst/", partOfSpeech: "verb", meaning: "kiên trì", example: "Persist in your learning efforts."),
        Word(word: "perspective", pronunciation: "/pɚˈspek.tɪv/", partOfSpeech: "noun", meaning: "góc nhìn", example: "Different perspectives help in understanding culture."),
        Word(word: "persuade", pronunciation: "/pɚˈsweɪd/", partOfSpeech: "verb", meaning: "thuyết phục", example: "Good teachers persuade students to learn more."),
        Word(word: "pioneer", pronunciation: "/ˌpaɪ.əˈnɪr/", partOfSpeech: "noun", meaning: "tiên phong", example: "She pioneered a new teaching method."),
        Word(word: "polish", pronunciation: "/ˈpɑl.ɪʃ/", partOfSpeech: "verb", meaning: "tinh chỉnh", example: "Polish your pronunciation with practice."),
        Word(word: "portion", pronunciation: "/ˈpɔr.ʃən/", partOfSpeech: "noun", meaning: "phần", example: "Practice a small portion each day."),
        Word(word: "positive", pronunciation: "/ˈpɑz.ə.tɪv/", partOfSpeech: "adjective", meaning: "tích cực", example: "Maintain a positive attitude while learning."),
        Word(word: "potential", pronunciation: "/pəˈten.ʃəl/", partOfSpeech: "noun", meaning: "tiềm năng", example: "Every student has great potential."),
        Word(word: "practical", pronunciation: "/ˈpræk.tɪ.kəl/", partOfSpeech: "adjective", meaning: "thực tế", example: "This is a practical approach to learning."),
        Word(word: "praise", pronunciation: "/preɪz/", partOfSpeech: "noun", meaning: "khen ngợi", example: "Teachers praise students for their hard work."),
        Word(word: "preach", pronunciation: "/pritʃ/", partOfSpeech: "verb", meaning: "thuyết giáo", example: "Good teachers preach by example."),
        Word(word: "precede", pronunciation: "/prɪˈsid/", partOfSpeech: "verb", meaning: "đi trước", example: "Practice precedes perfection."),
        Word(word: "precious", pronunciation: "/ˈpreʃ.əs/", partOfSpeech: "adjective", meaning: "quý báu", example: "Time is precious for learners."),
        Word(word: "precise", pronunciation: "/prɪˈsaɪs/", partOfSpeech: "adjective", meaning: "chính xác", example: "Be precise in your pronunciation."),
        Word(word: "predict", pronunciation: "/prɪˈdɪkt/", partOfSpeech: "verb", meaning: "dự đoán", example: "Can you predict the meaning?"),
        Word(word: "preference", pronunciation: "/ˈpref.ɚ.əns/", partOfSpeech: "noun", meaning: "sở thích", example: "Everyone has learning preferences."),
        Word(word: "prepare", pronunciation: "/prɪˈper/", partOfSpeech: "verb", meaning: "chuẩn bị", example: "Prepare for each lesson thoroughly."),
        Word(word: "present", pronunciation: "/prɪˈzent/", partOfSpeech: "verb", meaning: "trình bày", example: "Present your ideas confidently."),
        Word(word: "preserve", pronunciation: "/prɪˈzɝv/", partOfSpeech: "verb", meaning: "bảo vệ", example: "Preserve your learning momentum."),
        Word(word: "prevail", pronunciation: "/prɪˈveɪl/", partOfSpeech: "verb", meaning: "chiến thắng", example: "Determination will prevail over challenges."),
        Word(word: "previous", pronunciation: "/ˈpriv.i.əs/", partOfSpeech: "adjective", meaning: "trước đó", example: "Review previous lessons regularly."),
        Word(word: "primary", pronunciation: "/ˈpraɪ.mer.i/", partOfSpeech: "adjective", meaning: "chính", example: "The primary goal is fluency."),
        Word(word: "principle", pronunciation: "/ˈprɪn.sə.pəl/", partOfSpeech: "noun", meaning: "nguyên tắc", example: "Follow basic principles of grammar."),
        Word(word: "priority", pronunciation: "/praɪˈɑr.ə.ti/", partOfSpeech: "noun", meaning: "ưu tiên", example: "Make learning your priority."),
        Word(word: "probe", pronunciation: "/proʊb/", partOfSpeech: "verb", meaning: "thăm dò", example: "Probe deeper into vocabulary meanings."),
        Word(word: "problem", pronunciation: "/ˈprɑb.ləm/", partOfSpeech: "noun", meaning: "vấn đề", example: "Face each problem as a learning opportunity."),
        Word(word: "proceed", pronunciation: "/proʊˈsid/", partOfSpeech: "verb", meaning: "tiến hành", example: "Proceed to the next lesson when ready."),
        Word(word: "process", pronunciation: "/ˈpraʊ.ses/", partOfSpeech: "noun", meaning: "quá trình", example: "Learning is a continuous process."),
        Word(word: "produce", pronunciation: "/prəˈdus/", partOfSpeech: "verb", meaning: "tạo ra", example: "Effort produces results in learning."),
        Word(word: "productive", pronunciation: "/prəˈdʌk.tɪv/", partOfSpeech: "adjective", meaning: "hiệu quả", example: "Make your study time productive."),
        Word(word: "proficiency", pronunciation: "/prəˈfɪʃ.ən.si/", partOfSpeech: "noun", meaning: "thành thạo", example: "Proficiency comes with consistent practice."),
        Word(word: "profound", pronunciation: "/proʊˈfaʊnd/", partOfSpeech: "adjective", meaning: "sâu sắc", example: "Learning brings profound personal growth."),
        Word(word: "progress", pronunciation: "/ˈprɑɡ.res/", partOfSpeech: "noun", meaning: "tiến bộ", example: "Track your progress regularly."),
        Word(word: "prohibit", pronunciation: "/proʊˈhɪb.ɪt/", partOfSpeech: "verb", meaning: "cấm", example: "Don't prohibit yourself from trying new things."),
        Word(word: "project", pronunciation: "/ˈprɑdʒ.ekt/", partOfSpeech: "noun", meaning: "dự án", example: "Complete language projects for better learning."),
        Word(word: "proliferate", pronunciation: "/prəˈlɪf.ə.reɪt/", partOfSpeech: "verb", meaning: "nhân rộng", example: "Vocabulary proliferates with reading."),
        Word(word: "prominent", pronunciation: "/ˈprɑm.ə.nənt/", partOfSpeech: "adjective", meaning: "nổi bật", example: "Grammar is a prominent part of learning."),
        Word(word: "promise", pronunciation: "/ˈprɑm.ɪs/", partOfSpeech: "noun", meaning: "hứa hẹn", example: "Hard work promises better results."),
        Word(word: "promote", pronunciation: "/prəˈmoʊt/", partOfSpeech: "verb", meaning: "thúc đẩy", example: "We promote language learning for everyone."),
        Word(word: "prompt", pronunciation: "/prɑmpt/", partOfSpeech: "adjective", meaning: "nhanh chóng", example: "Prompt feedback helps improve learning."),
        Word(word: "pronounce", pronunciation: "/prəˈnaʊns/", partOfSpeech: "verb", meaning: "phát âm", example: "Learn to pronounce words correctly."),
        Word(word: "proof", pronunciation: "/pruf/", partOfSpeech: "noun", meaning: "bằng chứng", example: "Practice is proof of commitment."),
        Word(word: "propagate", pronunciation: "/ˈprɑp.ə.ɡeɪt/", partOfSpeech: "verb", meaning: "phát tán", example: "Good teaching propagates knowledge."),
        Word(word: "property", pronunciation: "/ˈprɑp.ɚ.ti/", partOfSpeech: "noun", meaning: "tính chất", example: "Each word has unique properties."),
        Word(word: "proportion", pronunciation: "/prəˈpɔr.ʃən/", partOfSpeech: "noun", meaning: "tỷ lệ", example: "Balance the proportion of skills you learn."),
        Word(word: "propose", pronunciation: "/prəˈpoʊz/", partOfSpeech: "verb", meaning: "đề xuất", example: "I propose we study together."),
        Word(word: "prospect", pronunciation: "/ˈprɑs.pekt/", partOfSpeech: "noun", meaning: "triển vọng", example: "Bright prospects await fluent speakers."),
        Word(word: "prosper", pronunciation: "/ˈprɑs.pɚ/", partOfSpeech: "verb", meaning: "thịnh vượng", example: "Learners prosper with dedication."),
        Word(word: "protect", pronunciation: "/prəˈtekt/", partOfSpeech: "verb", meaning: "bảo vệ", example: "Protect your learning environment from distractions."),
        Word(word: "proud", pronunciation: "/praʊd/", partOfSpeech: "adjective", meaning: "tự hào", example: "Be proud of your progress."),
        Word(word: "prove", pronunciation: "/pruv/", partOfSpeech: "verb", meaning: "chứng minh", example: "Prove your skills through conversation."),
        Word(word: "provide", pronunciation: "/prəˈvaɪd/", partOfSpeech: "verb", meaning: "cung cấp", example: "Teachers provide guidance and resources."),
        Word(word: "provoke", pronunciation: "/prəˈvoʊk/", partOfSpeech: "verb", meaning: "gây ra", example: "Interesting topics provoke discussion in class."),
        Word(word: "prowess", pronunciation: "/ˈpraʊ.əs/", partOfSpeech: "noun", meaning: "tài năng", example: "Develop your language prowess gradually."),
        Word(word: "prudent", pronunciation: "/ˈpru.dənt/", partOfSpeech: "adjective", meaning: "thận trọng", example: "It's prudent to review regularly."),
        Word(word: "public", pronunciation: "/ˈpʌb.lɪk/", partOfSpeech: "adjective", meaning: "công cộng", example: "Public speaking improves confidence."),
        Word(word: "publish", pronunciation: "/ˈpʌb.lɪʃ/", partOfSpeech: "verb", meaning: "xuất bản", example: "Share your writing by publishing online."),
        Word(word: "pull", pronunciation: "/pʊl/", partOfSpeech: "verb", meaning: "kéo", example: "Pull together as a learning community."),
        Word(word: "punish", pronunciation: "/ˈpʌn.ɪʃ/", partOfSpeech: "verb", meaning: "phạt", example: "Don't punish yourself for mistakes."),
        Word(word: "purchase", pronunciation: "/ˈpɝ.tʃəs/", partOfSpeech: "verb", meaning: "mua", example: "Purchase learning materials that interest you."),
        Word(word: "pure", pronunciation: "/pjʊr/", partOfSpeech: "adjective", meaning: "thuần", example: "Pure joy comes from learning."),
        Word(word: "pursue", pronunciation: "/pɚˈsu/", partOfSpeech: "verb", meaning: "theo đuổi", example: "Pursue your language learning goals."),
        Word(word: "push", pronunciation: "/pʊʃ/", partOfSpeech: "verb", meaning: "đẩy", example: "Push yourself beyond your comfort zone."),
        Word(word: "put", pronunciation: "/pʊt/", partOfSpeech: "verb", meaning: "đặt", example: "Put in the effort to learn.")
    ]

    static let dictionaryFallbackWords: [DictionaryEntry] = [
        DictionaryEntry(
            word: "friendly",
            phonetic: "/ˈfrend.li/",
            audioURL: nil,
            partOfSpeech: "adjective",
            definition: "kind and pleasant",
            example: "The teacher is friendly and patient.",
            vietnameseMeaning: "thân thiện"
        ),
        DictionaryEntry(
            word: "practice",
            phonetic: "/ˈpræk.tɪs/",
            audioURL: nil,
            partOfSpeech: "verb",
            definition: "to repeat an activity to improve a skill",
            example: "Practice speaking English with short sentences.",
            vietnameseMeaning: "luyện tập"
        ),
        DictionaryEntry(
            word: "grammar",
            phonetic: "/ˈɡræm.ɚ/",
            audioURL: nil,
            partOfSpeech: "noun",
            definition: "the rules of language",
            example: "Grammar helps you build correct sentences.",
            vietnameseMeaning: "ngữ pháp"
        )
    ]

    static let articles: [Article] = [
        Article(
            title: "A small daily habit",
            source: "Engify News",
            category: "Learning",
            publishedDate: "May 4, 2026",
            readingTime: "2 min",
            summary: "A short article about building a daily English routine.",
            content: "Many students build a small daily habit to learn English. They read a short article, learn one word, and speak one sentence. This simple routine helps them stay consistent and focus on progress.",
            difficultWords: ["habit", "routine", "consistent", "focus"],
            questions: [
                QuizQuestion(
                    prompt: "What do students do every day?",
                    options: ["Read a short article", "Watch a long movie", "Skip practice", "Write a poem"],
                    answerIndex: 0,
                    explanation: "The article says students read a short article, learn one word, and speak one sentence."
                ),
                QuizQuestion(
                    prompt: "Why is the routine helpful?",
                    options: ["It is very hard", "It helps them stay consistent", "It has no plan", "It is only for teachers"],
                    answerIndex: 1,
                    explanation: "A consistent routine makes it easier to keep learning every day."
                ),
                QuizQuestion(
                    prompt: "What should learners focus on?",
                    options: ["Progress", "Noise", "Speed only", "Memorizing nothing"],
                    answerIndex: 0,
                    explanation: "The article says the routine helps them focus on progress."
                )
            ],
            url: URL(string: "https://example.com/article-1")
        ),
        Article(
            title: "New reading corner at school",
            source: "City School Times",
            category: "Education",
            publishedDate: "May 2, 2026",
            readingTime: "3 min",
            summary: "A school opened a quiet reading space for students.",
            content: "A school opened a new reading corner for students. The room has easy books, soft chairs, and a quiet space. Teachers say reading every day can improve vocabulary and confidence.",
            difficultWords: ["corner", "quiet", "vocabulary", "confidence"],
            questions: [
                QuizQuestion(
                    prompt: "What did the school open?",
                    options: ["A reading corner", "A sports hall", "A cafe", "A bus stop"],
                    answerIndex: 0,
                    explanation: "The article clearly says the school opened a new reading corner."
                ),
                QuizQuestion(
                    prompt: "What can reading improve?",
                    options: ["Vocabulary and confidence", "Only sleep", "The weather", "Homework length"],
                    answerIndex: 0,
                    explanation: "Reading every day can improve vocabulary and confidence."
                ),
                QuizQuestion(
                    prompt: "What is the room like?",
                    options: ["Busy and noisy", "Quiet and easy", "Dark and cold", "Empty and closed"],
                    answerIndex: 1,
                    explanation: "The room has easy books, soft chairs, and a quiet space."
                )
            ],
            url: URL(string: "https://example.com/article-2")
        ),
        Article(
            title: "Healthy walking practice",
            source: "Wellness Daily",
            category: "Health",
            publishedDate: "May 1, 2026",
            readingTime: "2 min",
            summary: "Short walks can improve your body, mind, and energy.",
            content: "Doctors recommend a short walk every day. Walking can help your body, mind, and energy. Many learners also listen to English audio while they walk.",
            difficultWords: ["recommend", "energy", "audio"],
            questions: [
                QuizQuestion(
                    prompt: "What do doctors recommend?",
                    options: ["A short walk", "No movement", "Only sleep", "Only reading"],
                    answerIndex: 0,
                    explanation: "The article says doctors recommend a short walk every day."
                ),
                QuizQuestion(
                    prompt: "What can walking help?",
                    options: ["Body, mind, and energy", "Only memory", "Only writing", "Only pronunciation"],
                    answerIndex: 0,
                    explanation: "The text says walking can help your body, mind, and energy."
                ),
                QuizQuestion(
                    prompt: "What do many learners listen to while walking?",
                    options: ["English audio", "No sound", "Only music", "A dictionary page"],
                    answerIndex: 0,
                    explanation: "The article says many learners listen to English audio while they walk."
                )
            ],
            url: URL(string: "https://example.com/article-3")
        )
    ]

    static let speakingSentence = "I practice English every day to improve my confidence."

    static let grammarTopics: [(title: String, explanation: String, examples: [String])] = [
        (title: "Present Simple", explanation: "Use the present simple for habits, facts, and routines.", examples: ["I study English every morning.", "She reads books after dinner.", "They learn new words on Monday."]),
        (title: "There is / There are", explanation: "Use these forms to talk about existence or location.", examples: ["There is a book on the table.", "There are two students in the room."]),
        (title: "Past Simple", explanation: "Use the past simple for completed actions in the past.", examples: ["I visited Paris last summer.", "She studied hard for the exam.", "They went to the beach yesterday."]),
        (title: "Present Continuous", explanation: "Use present continuous for actions happening right now.", examples: ["I am studying English.", "She is reading a book.", "They are playing football."]),
        (title: "Articles (a, an, the)", explanation: "Use 'a/an' for indefinite nouns and 'the' for specific/definite nouns.", examples: ["I have a book.", "She is an engineer.", "The cat is sleeping."]),
        (title: "Plurals", explanation: "Add -s or -es to nouns to make them plural. Some plurals are irregular.", examples: ["One cat, many cats.", "One box, many boxes.", "One child, many children."]),
        (title: "Comparative & Superlative", explanation: "Compare things using -er/-est or more/most with adjectives.", examples: ["John is taller than Mary.", "The Nile is the longest river.", "This book is more interesting than that one."]),
        (title: "Question Forms", explanation: "Use do/does/did and question words to form questions.", examples: ["Do you like English?", "Does she study here?", "What did they do yesterday?"]),
        (title: "Conditional (If...)", explanation: "Use if clauses to talk about conditions and results.", examples: ["If you study, you will pass.", "If I had money, I would travel.", "If he comes, I'll be happy."]),
        (title: "Future Simple (will)", explanation: "Use 'will' to talk about future plans and predictions.", examples: ["I will visit London next year.", "She will become a teacher.", "They will finish the project tomorrow."])
    ]

    static let practiceQuizQuestions: [QuizQuestion] = [
        QuizQuestion(prompt: "Choose the correct sentence.", options: ["He go to school every day.", "He goes to school every day.", "He going to school every day.", "He gone to school every day."], answerIndex: 1, explanation: "We add -s to the verb with he, she, and it in the present simple."),
        QuizQuestion(prompt: "Which word means 'luyện tập'?", options: ["Practice", "Holiday", "Answer", "Need"], answerIndex: 0, explanation: "Practice means luyện tập."),
        QuizQuestion(prompt: "When do we often use present simple?", options: ["For habits", "For the future only", "For prices only", "For songs only"], answerIndex: 0, explanation: "Present simple is used for habits and routines."),
        QuizQuestion(prompt: "Complete: 'There ___ a book on the table.'", options: ["are", "is", "have", "has"], answerIndex: 1, explanation: "Use 'is' with singular nouns in 'there is/are' construction."),
        QuizQuestion(prompt: "Which is correct?", options: ["She don't like coffee.", "She doesn't like coffee.", "She not like coffee.", "She no like coffee."], answerIndex: 1, explanation: "Use 'doesn't' for negation with 'she' in present simple."),
        QuizQuestion(prompt: "What does 'fluent' mean?", options: ["Slow", "Able to speak smoothly", "Difficult", "Common"], answerIndex: 1, explanation: "Fluent means able to speak a language smoothly and easily."),
        QuizQuestion(prompt: "Choose the correct form.", options: ["I am studying", "I studying", "I am study", "I be studying"], answerIndex: 0, explanation: "Use 'am + verb-ing' for present continuous."),
        QuizQuestion(prompt: "Which word is a noun?", options: ["Beautiful", "Run", "Learn", "Student"], answerIndex: 3, explanation: "Student is a noun. Beautiful is an adjective, run and learn are verbs."),
        QuizQuestion(prompt: "What is the past tense of 'go'?", options: ["Going", "Goed", "Went", "Gone"], answerIndex: 2, explanation: "The past tense of 'go' is 'went'. Go, went, gone are the forms."),
        QuizQuestion(prompt: "Complete: 'If I ___ more time, I would study.'", options: ["have", "had", "has", "having"], answerIndex: 1, explanation: "Use past tense 'had' in conditional sentences (If I had... I would)."),
        QuizQuestion(prompt: "What does 'vocabulary' mean?", options: ["Grammar", "All the words someone knows", "Speaking", "Listening"], answerIndex: 1, explanation: "Vocabulary is the collection of all the words someone knows."),
        QuizQuestion(prompt: "Choose the correct plural.", options: ["Child", "Childs", "Children", "Childes"], answerIndex: 2, explanation: "The plural of 'child' is 'children' (irregular plural)."),
        QuizQuestion(prompt: "Which sentence is correct?", options: ["She have gone.", "She has gone.", "She do gone.", "She is gone."], answerIndex: 1, explanation: "Use 'has' with 'she' in present perfect tense."),
        QuizQuestion(prompt: "What is the opposite of 'difficult'?", options: ["Impossible", "Easy", "Hard", "Complex"], answerIndex: 1, explanation: "Easy is the opposite of difficult."),
        QuizQuestion(prompt: "Complete: 'They ___ playing football now.'", options: ["is", "are", "am", "be"], answerIndex: 1, explanation: "Use 'are' with 'they' for present continuous."),
        QuizQuestion(prompt: "Which is a question word?", options: ["The", "And", "What", "Is"], answerIndex: 2, explanation: "What is a question word. The and And are not question words."),
        QuizQuestion(prompt: "What does 'pronounce' mean?", options: ["Write", "Say", "Think", "Feel"], answerIndex: 1, explanation: "Pronounce means to say a word correctly."),
        QuizQuestion(prompt: "Choose the correct form.", options: ["I have been studying for 2 hours.", "I am studying for 2 hours.", "I study for 2 hours.", "I have study for 2 hours."], answerIndex: 0, explanation: "Use present perfect continuous for actions that started in the past and continue."),
        QuizQuestion(prompt: "Which word means 'cải thiện'?", options: ["Improve", "Perfect", "Easy", "Simple"], answerIndex: 0, explanation: "Improve means cải thiện (to make better)."),
        QuizQuestion(prompt: "Complete: 'He ___ to the gym yesterday.'", options: ["Goes", "Going", "Went", "Go"], answerIndex: 2, explanation: "Use past tense 'went' because 'yesterday' shows past time."),
        QuizQuestion(prompt: "What is an adverb?", options: ["A word describing a noun", "A word describing a verb", "A word replacing a noun", "A connecting word"], answerIndex: 1, explanation: "An adverb describes how an action is done (verb)."),
        QuizQuestion(prompt: "Choose correctly.", options: ["She will go tomorrow.", "She go will tomorrow.", "She tomorrow will go.", "She going will tomorrow."], answerIndex: 0, explanation: "Use 'will + verb' for future simple. Correct word order: Subject + will + verb."),
        QuizQuestion(prompt: "What does 'habit' mean?", options: ["A holiday", "Something done regularly", "A difficult thing", "A type of food"], answerIndex: 1, explanation: "A habit is something done regularly (thói quen)."),
        QuizQuestion(prompt: "Complete: 'If you study hard, you ___ pass.'", options: ["won't", "will", "would", "are"], answerIndex: 1, explanation: "Use 'will' for the result in first conditional (If... then will)."),
        QuizQuestion(prompt: "Which is correct?", options: ["She said me that.", "She said to me that.", "She told to me that.", "She told me."], answerIndex: 3, explanation: "Use 'told' + object directly. 'Said' needs 'to' before the person."),
        QuizQuestion(prompt: "What does 'patient' mean?", options: ["Someone waiting", "Someone complaining", "Someone happy", "Someone tired"], answerIndex: 0, explanation: "Patient means able to wait calmly without complaining."),
        QuizQuestion(prompt: "Choose the correct sentence.", options: ["I goes there every day.", "I go there every day.", "I going there every day.", "I am go there every day."], answerIndex: 1, explanation: "With 'I', use the base form 'go' in present simple."),
        QuizQuestion(prompt: "Complete: 'By next year, I ___ English for 5 years.'", options: ["will study", "will have studied", "have studied", "studying"], answerIndex: 1, explanation: "Use future perfect 'will have studied' for something completed by a future time."),
        QuizQuestion(prompt: "What is the difference?", options: ["Speak and speaking", "Speak and spoke", "Speaking and said", "Speak and heard"], answerIndex: 1, explanation: "Speak is present/base form, spoke is past tense."),
        QuizQuestion(prompt: "Which word is a verb?", options: ["Beautiful", "Book", "Walk", "Sky"], answerIndex: 2, explanation: "Walk is a verb. Beautiful is adjective, Book and Sky are nouns."),
        QuizQuestion(prompt: "Choose the correct form.", options: ["She doesn't goes to work.", "She doesn't go to work.", "She don't go to work.", "She not go to work."], answerIndex: 1, explanation: "Use 'doesn't + base verb' for negation in present simple."),
        QuizQuestion(prompt: "What is the superlative of 'good'?", options: ["Better", "Best", "Gooder", "More good"], answerIndex: 1, explanation: "The superlative of 'good' is 'best'. Good, better, best."),
        QuizQuestion(prompt: "Complete: '___ are you going?'", options: ["Where", "What", "When", "Which"], answerIndex: 0, explanation: "Use 'where' when asking about a place."),
        QuizQuestion(prompt: "Which is correct?", options: ["The book is on the table.", "The book are on the table.", "The books is on the table.", "Book is on table."], answerIndex: 0, explanation: "Singular subject 'book' needs singular verb 'is'."),
        QuizQuestion(prompt: "What does 'achievement' mean?", options: ["Failure", "Effort", "Success in doing something", "Practice"], answerIndex: 2, explanation: "Achievement means success in accomplishing something."),
        QuizQuestion(prompt: "Choose the correct question.", options: ["Does he like coffee?", "Do he like coffee?", "He like coffee?", "Does he likes coffee?"], answerIndex: 0, explanation: "Use 'does' for questions with 'he' in present simple."),
        QuizQuestion(prompt: "Complete: 'I ___ watching TV when he arrived.'", options: ["was", "were", "am", "is"], answerIndex: 0, explanation: "Use 'was' with 'I' for past continuous."),
        QuizQuestion(prompt: "What is a preposition?", options: ["A type of verb", "A word showing position or time", "A word for a noun", "A connecting sound"], answerIndex: 1, explanation: "A preposition shows position (in, on, at) or time (before, after)."),
        QuizQuestion(prompt: "Which plural is correct?", options: ["Box, boxes", "Box, boxs", "Box, boxe", "Box, boxez"], answerIndex: 0, explanation: "For words ending in -x or -s, add -es for plural."),
        QuizQuestion(prompt: "Choose correctly.", options: ["She have been here.", "She has been here.", "She is been here.", "She are been here."], answerIndex: 1, explanation: "Use 'has been' with 'she' in present perfect."),
        QuizQuestion(prompt: "What does 'challenge' mean?", options: ["Obstacle", "Rest", "Celebration", "Reward"], answerIndex: 0, explanation: "Challenge means something difficult that you must work hard to do."),
        QuizQuestion(prompt: "Complete: 'If she ___ the exam, she will graduate.'", options: ["Passes", "Will pass", "Would pass", "Pass"], answerIndex: 0, explanation: "Use present simple in the 'if' clause: If she passes..."),
        QuizQuestion(prompt: "Which sentence has correct punctuation?", options: ["She said, Hello", "She said 'Hello'", "She said Hello'", "She said Hello."], answerIndex: 1, explanation: "Use quotation marks for direct speech."),
        QuizQuestion(prompt: "What is a pronoun?", options: ["A word for a noun", "A prefix", "A type of verb", "A connecting word"], answerIndex: 0, explanation: "A pronoun replaces a noun (he, she, it, they)."),
        QuizQuestion(prompt: "Choose the correct comparison.", options: ["This is more bigger than that.", "This is bigger than that.", "This bigger is than that.", "This is biggest than that."], answerIndex: 1, explanation: "Add -er to one-syllable adjectives. Don't use 'more' with -er."),
        QuizQuestion(prompt: "Complete: 'She ____ to London next week.'", options: ["Goes", "Will go", "Went", "Is going"], answerIndex: 1, explanation: "Use 'will go' or 'is going' for future plans."),
        QuizQuestion(prompt: "What does 'focus' mean?", options: ["To concentrate", "To rest", "To move", "To change"], answerIndex: 0, explanation: "Focus means to concentrate your attention on something."),
        QuizQuestion(prompt: "Which is the correct form?", options: ["I would have gone if I had known.", "I would have gone if I knew.", "I would go if I had known.", "I have gone if I knew."], answerIndex: 0, explanation: "Use 'would have + past participle' in third conditional with 'if + past perfect'."),
        QuizQuestion(prompt: "Choose the correctly spelled word.", options: ["Recieve", "Receive", "Recieve", "Reciève"], answerIndex: 1, explanation: "Receive is spelled with 'ei' not 'ie'."),
        QuizQuestion(prompt: "What is the opposite of 'lose'?", options: ["Found", "Find", "Win", "Left"], answerIndex: 2, explanation: "Win is the opposite of lose in competitions or games."),
        QuizQuestion(prompt: "Complete: 'They ___ not arrived yet.'", options: ["have", "has", "is", "are"], answerIndex: 0, explanation: "Use 'have' with plural subjects for present perfect."),
        QuizQuestion(prompt: "Which word is an adjective?", options: ["Run", "Happy", "Speak", "Walking"], answerIndex: 1, explanation: "Happy describes how something is (adjective)."),
    ]

    static let practiceImageLessons: [PracticeImageLesson] = [
        PracticeImageLesson(
            title: "Morning Cafe Scene",
            locationLabel: "Everyday Life",
            systemImage: "cup.and.saucer.fill",
            visualStyle: "Warm window light and cozy coffee-shop details",
            searchTopics: ["cafe", "coffee", "morning", "street", "people"],
            sceneDescription: "A bright cafe opens onto a quiet street. One person is ordering coffee, another is typing on a laptop, and warm sunlight is hitting the window table.",
            focusVocabulary: ["barista", "counter", "laptop", "sunlight", "order", "quiet street"],
            guidedPrompts: [
                "Describe what each person is doing in the cafe.",
                "Say three things you can probably hear in this scene.",
                "Explain why this place feels calm or busy."
            ],
            challengePrompt: "Speak for 30 seconds about what you would do first if you walked into this cafe."
        ),
        PracticeImageLesson(
            title: "City Park Weekend",
            locationLabel: "Outdoor English",
            systemImage: "tree.fill",
            visualStyle: "Open-air lifestyle photo with movement and soft greens",
            searchTopics: ["park", "nature", "weekend", "children", "dog"],
            sceneDescription: "A city park is full of motion. Two children are flying a kite, a couple is walking a dog, and a food cart is parked beside a path lined with trees.",
            focusVocabulary: ["kite", "path", "food cart", "picnic", "jogger", "fresh air"],
            guidedPrompts: [
                "Name the activities happening in the park.",
                "Compare the mood of the children and the jogger.",
                "Describe the weather using at least two adjectives."
            ],
            challengePrompt: "Imagine you are sending a voice message from this park. Describe the scene naturally."
        ),
        PracticeImageLesson(
            title: "Travel Check-In Desk",
            locationLabel: "Travel Practice",
            systemImage: "airplane.departure",
            visualStyle: "Busy airport documentary shot with travel details",
            searchTopics: ["travel", "airport", "family", "flight", "luggage"],
            sceneDescription: "Inside an airport, travelers are lining up at a check-in desk. A family is checking passports, a digital screen shows departure times, and a suitcase is open beside the line.",
            focusVocabulary: ["passport", "boarding pass", "queue", "departure", "luggage", "check-in"],
            guidedPrompts: [
                "Describe what the family might be preparing for.",
                "Explain what objects you expect to see near the desk.",
                "Use sequence words to describe what happens before boarding."
            ],
            challengePrompt: "Pretend you are a travel vlogger and explain this airport scene in clear English."
        ),
        PracticeImageLesson(
            title: "Flower Market Morning",
            locationLabel: "Pexels-Style Topic",
            systemImage: "camera.macro",
            visualStyle: "Color-rich close-up scene with natural textures",
            searchTopics: ["flowers", "beautiful flowers", "nature", "wedding", "meadow", "flora", "bloom", "plant"],
            sceneDescription: "Rows of bright flowers fill a street market stall. Some bouquets are wrapped in paper, a seller is arranging fresh stems, and customers are stopping to smell the roses and take photos.",
            focusVocabulary: ["bouquet", "petals", "blossom", "stem", "floral stall", "fragrance"],
            guidedPrompts: [
                "Describe the colors, shapes, and textures you notice in the flowers.",
                "Explain what the seller and customers might be doing.",
                "Talk about which flowers you would buy and why."
            ],
            challengePrompt: "Search a topic like 'flowers' and speak for 30 seconds as if you are describing the photo to a friend."
        ),
        PracticeImageLesson(
            title: "Street Food Corner",
            locationLabel: "Food English",
            systemImage: "fork.knife",
            visualStyle: "Fast, colorful street scene with food and people",
            searchTopics: ["food", "street food", "market", "snack", "city"],
            sceneDescription: "A food stall is serving noodles and grilled snacks while customers wait beside a glowing menu board. Steam rises into the evening air, and the cook moves quickly between pans.",
            focusVocabulary: ["stall", "grill", "steam", "menu board", "queue", "vendor"],
            guidedPrompts: [
                "Describe what food you think is being prepared.",
                "Explain how the atmosphere feels during this busy moment.",
                "Compare this place with a quiet restaurant."
            ],
            challengePrompt: "Pretend you are recommending this food corner to a traveler in simple, vivid English."
        ),
        PracticeImageLesson(
            title: "Beach Afternoon Escape",
            locationLabel: "Relaxed Travel",
            systemImage: "beach.umbrella.fill",
            visualStyle: "Sunny travel photo with open sky and water",
            searchTopics: ["beach", "ocean", "summer", "travel", "nature"],
            sceneDescription: "Waves are rolling onto a wide beach while a few people walk near the shore. A striped umbrella is open in the sand, and the sunlight reflects across the water.",
            focusVocabulary: ["shore", "waves", "umbrella", "sand", "breeze", "coast"],
            guidedPrompts: [
                "Describe the weather and colors in the scene.",
                "Explain what people might be doing at the beach.",
                "Say why this place feels peaceful or exciting."
            ],
            challengePrompt: "Give a short voice-style description of this beach for someone who cannot see the photo."
        ),
        PracticeImageLesson(
            title: "Office Team Meeting",
            locationLabel: "Workplace English",
            systemImage: "person.3.fill",
            visualStyle: "Professional workspace scene with teamwork energy",
            searchTopics: ["office", "meeting", "work", "team", "business"],
            sceneDescription: "A small team is gathered around a table with laptops, notebooks, and coffee cups. One person is presenting an idea while the others look at charts on a screen.",
            focusVocabulary: ["presentation", "colleagues", "screen", "notebook", "discussion", "project"],
            guidedPrompts: [
                "Describe the roles of the people in the meeting.",
                "Explain what kind of project they might be discussing.",
                "Compare a formal meeting with a casual team chat."
            ],
            challengePrompt: "Pretend you are introducing this team scene in a business English class."
        )
    ]

    static let practiceImageTopics: [String] = [
        "flowers",
        "beautiful flowers",
        "nature",
        "cafe",
        "park",
        "travel",
        "food",
        "city",
        "market",
        "beach",
        "office",
        "business",
        "summer",
        "meadow",
        "plant"
    ]

    static let practiceDialogueScenarios: [PracticeDialogueScenario] = [
        PracticeDialogueScenario(
            title: "Ordering at a Cafe",
            setting: "Daily Conversation",
            goal: "Ask for a drink, customize it, and pay confidently.",
            systemImage: "cup.and.saucer.fill",
            partnerOpeningLine: "Hi there. What can I get for you today?",
            responseIdeas: [
                "Order one drink and one small snack.",
                "Ask for the drink size or sugar level you want.",
                "Finish with a polite closing line."
            ],
            usefulPhrases: [
                "Could I get a medium latte, please?",
                "Can you make it less sweet?",
                "That's all for now, thank you."
            ],
            confidenceTip: "Keep your sentence short first, then add one detail like size, flavor, or price."
        ),
        PracticeDialogueScenario(
            title: "Asking for Directions",
            setting: "Travel Survival",
            goal: "Find a destination and confirm the route clearly.",
            systemImage: "map.fill",
            partnerOpeningLine: "Sure, where are you trying to go?",
            responseIdeas: [
                "Name the place you need to find.",
                "Ask how long it takes to get there.",
                "Repeat the last direction to confirm it."
            ],
            usefulPhrases: [
                "I'm looking for the train station.",
                "Is it within walking distance?",
                "So I go straight and turn left at the bank, right?"
            ],
            confidenceTip: "Repeat the key location words slowly so the other person can correct you if needed."
        ),
        PracticeDialogueScenario(
            title: "Interview Self-Introduction",
            setting: "Career English",
            goal: "Introduce yourself with confidence and clear structure.",
            systemImage: "briefcase.fill",
            partnerOpeningLine: "Thanks for joining us today. Could you tell me a little about yourself?",
            responseIdeas: [
                "State your name and current role or study focus.",
                "Mention one strength or achievement.",
                "End with why you are interested in the opportunity."
            ],
            usefulPhrases: [
                "My name is Duy, and I am currently focusing on language learning and design.",
                "One of my strengths is staying consistent with new challenges.",
                "I'm excited about this opportunity because it lets me grow."
            ],
            confidenceTip: "Use a three-part structure: present, strength, future."
        )
    ]
}
