import SwiftUI

struct ContentView: View {
    @StateObject private var wordListVM = WordListViewModel()
    @StateObject private var quizVM = QuizViewModel()
    @StateObject private var statsVM = StatsViewModel()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }
                .environmentObject(wordListVM)
                .environmentObject(quizVM)
                .environmentObject(statsVM)
            
            WordListView()
                .tabItem {
                    Label("단어장", systemImage: "book.fill")
                }
                .environmentObject(wordListVM)
            
            QuizSetupView()
                .tabItem {
                    Label("퀴즈", systemImage: "pencil.and.list.clipboard")
                }
                .environmentObject(wordListVM)
                .environmentObject(quizVM)
            
            StatsView()
                .tabItem {
                    Label("통계", systemImage: "chart.bar.fill")
                }
                .environmentObject(wordListVM)
                .environmentObject(statsVM)
        }
        .accentColor(.indigo)
    }
}
