import Foundation

class WordStore {
    private static let wordsKey = "saved_words"
    private static let statsKey = "quiz_stats"
    
    private struct DefaultWord: Decodable {
        let english: String
        let korean: String
    }
    
    static func save(words: [Word]) {
        if let data = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(data, forKey: wordsKey)
        }
    }
    
    static func load() -> [Word] {
        guard let data = UserDefaults.standard.data(forKey: wordsKey),
              let words = try? JSONDecoder().decode([Word].self, from: data) else {
            return defaultWords()
        }
        return words
    }
    
    static func saveStats(_ stats: QuizStats) {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: statsKey)
        }
    }
    
    static func loadStats() -> QuizStats {
        guard let data = UserDefaults.standard.data(forKey: statsKey),
              let stats = try? JSONDecoder().decode(QuizStats.self, from: data) else {
            return QuizStats()
        }
        return stats
    }
    
    static func defaultWords() -> [Word] {
        guard let url = Bundle.main.url(forResource: "DefaultWords", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([DefaultWord].self, from: data) else {
            return []
        }
        return entries.map { Word(english: $0.english, korean: $0.korean) }
    }
}

struct QuizStats: Codable {
    var totalSessions: Int = 0
    var totalCorrect: Int = 0
    var totalWrong: Int = 0
    var bestScore: Double = 0
    var lastPlayedDate: Date?
    var studyDates: [String] = []
    
    var totalQuestions: Int { totalCorrect + totalWrong }
    var overallAccuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalQuestions) * 100
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalSessions = try container.decodeIfPresent(Int.self, forKey: .totalSessions) ?? 0
        totalCorrect = try container.decodeIfPresent(Int.self, forKey: .totalCorrect) ?? 0
        totalWrong = try container.decodeIfPresent(Int.self, forKey: .totalWrong) ?? 0
        bestScore = try container.decodeIfPresent(Double.self, forKey: .bestScore) ?? 0
        lastPlayedDate = try container.decodeIfPresent(Date.self, forKey: .lastPlayedDate)
        studyDates = try container.decodeIfPresent([String].self, forKey: .studyDates) ?? []
    }
}
