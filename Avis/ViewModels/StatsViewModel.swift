import Foundation

@MainActor
class StatsViewModel: ObservableObject {
    @Published var stats: QuizStats = QuizStats()
    
    init() {
        load()
    }
    
    func load() {
        stats = WordStore.loadStats()
    }
    
    func resetStats() {
        WordStore.saveStats(QuizStats())
        stats = QuizStats()
    }
    
    var formattedLastPlayed: String {
        guard let date = stats.lastPlayedDate else { return "없음" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
