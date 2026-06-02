import SwiftUI

struct QuizSetupView: View {
    @EnvironmentObject var wordListVM: WordListViewModel
    @EnvironmentObject var quizVM: QuizViewModel
    @State private var selectedMode: QuizMode = .mixed
    @State private var wrongWordsOnly = false
    @State private var navigateToQuiz = false
    
    var availableWordCount: Int {
        if wrongWordsOnly {
            return wordListVM.words.filter { $0.wrongCount > 0 }.count
        }
        return wordListVM.words.count
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("퀴즈 모드") {
                    ForEach(QuizMode.allCases, id: \.self) { mode in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(modeDescription(mode))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.indigo)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedMode = mode }
                    }
                }
                
                Section("단어 범위") {
                    Toggle("틀린 단어만", isOn: $wrongWordsOnly)
                    
                    HStack {
                        Text("출제 단어 수")
                        Spacer()
                        Text("\(availableWordCount)개")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button {
                        quizVM.startQuiz(words: wordListVM.words, mode: selectedMode, wrongOnly: wrongWordsOnly)
                        navigateToQuiz = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("퀴즈 시작", systemImage: "play.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(availableWordCount == 0)
                    .listRowBackground(availableWordCount > 0 ? Color.indigo : Color.gray)
                    .foregroundColor(.white)
                }
                
                if availableWordCount == 0 {
                    Section {
                        Label(
                            wrongWordsOnly ? "틀린 단어가 없습니다" : "단어장이 비어있습니다",
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundColor(.orange)
                        .font(.subheadline)
                    }
                }
            }
            .navigationTitle("퀴즈 설정")
            .navigationDestination(isPresented: $navigateToQuiz) {
                QuizView()
                    .environmentObject(quizVM)
                    .environmentObject(wordListVM)
            }
        }
    }
    
    func modeDescription(_ mode: QuizMode) -> String {
        switch mode {
        case .englishToKorean: return "영어 단어를 보고 한글 뜻을 입력"
        case .koreanToEnglish: return "한글 뜻을 보고 영어 단어를 입력"
        case .mixed: return "두 방향 문제를 랜덤으로 혼합"
        }
    }
}
