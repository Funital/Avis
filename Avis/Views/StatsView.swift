import SwiftUI

struct StatsView: View {
    @EnvironmentObject var wordListVM: WordListViewModel
    @EnvironmentObject var statsVM: StatsViewModel
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // 전체 요약
                Section("전체 학습 통계") {
                    statRow(icon: "play.circle.fill", color: .indigo, title: "총 퀴즈 횟수", value: "\(statsVM.stats.totalSessions)회")
                    statRow(icon: "checkmark.circle.fill", color: .green, title: "누적 정답", value: "\(statsVM.stats.totalCorrect)개")
                    statRow(icon: "xmark.circle.fill", color: .red, title: "누적 오답", value: "\(statsVM.stats.totalWrong)개")
                    statRow(icon: "percent", color: .orange, title: "전체 정확도", value: String(format: "%.1f%%", statsVM.stats.overallAccuracy))
                    statRow(icon: "trophy.fill", color: .yellow, title: "최고 점수", value: String(format: "%.0f%%", statsVM.stats.bestScore))
                    statRow(icon: "clock.fill", color: .blue, title: "마지막 학습", value: statsVM.formattedLastPlayed)
                }
                
                // 단어장 통계
                Section("단어장 현황") {
                    statRow(icon: "book.fill", color: .indigo, title: "전체 단어", value: "\(wordListVM.words.count)개")
                    statRow(icon: "star.fill", color: .green, title: "학습 완료", value: "\(wordListVM.learnedCount)개")
                    statRow(icon: "exclamationmark.circle.fill", color: .red, title: "오답 단어", value: "\(wordListVM.words.filter { $0.wrongCount > 0 }.count)개")
                    
                    if !wordListVM.words.isEmpty {
                        // 상위 오답 단어
                        let topWrong = wordListVM.words.filter { $0.wrongCount > 0 }.sorted { $0.wrongCount > $1.wrongCount }.prefix(3)
                        if !topWrong.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("자주 틀리는 단어 TOP 3")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                ForEach(Array(topWrong.enumerated()), id: \.offset) { i, word in
                                    HStack {
                                        Text("\(i+1).")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text(word.english)
                                            .font(.subheadline)
                                        Text(word.korean)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("오답 \(word.wrongCount)회")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 초기화
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("통계 초기화", systemImage: "trash")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("통계")
            .onAppear { statsVM.load() }
            .alert("통계 초기화", isPresented: $showResetAlert) {
                Button("초기화", role: .destructive) {
                    statsVM.resetStats()
                    wordListVM.resetProgress()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("모든 학습 통계와 진행 기록이 삭제됩니다.")
            }
        }
    }
    
    private func statRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}
