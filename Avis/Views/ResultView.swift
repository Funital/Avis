import SwiftUI

struct ResultView: View {
    let result: QuizResult
    let onRetry: () -> Void
    let onRetryWrong: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 점수 원형
                    scoreCircle
                    
                    // 등급 메시지
                    Text(result.grade)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // 상세 통계
                    statsCards
                    
                    // 틀린 단어 목록
                    if !result.wrongWords.isEmpty {
                        wrongWordsList
                    }
                    
                    // 버튼들
                    actionButtons
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("퀴즈 결과")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var scoreCircle: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 16)
            Circle()
                .trim(from: 0, to: result.score / 100)
                .stroke(
                    LinearGradient(colors: scoreColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.2), value: result.score)
            
            VStack(spacing: 4) {
                Text("\(Int(result.score))%")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("정확도")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 160, height: 160)
        .padding(.top)
    }
    
    private var scoreColors: [Color] {
        switch result.score {
        case 90...100: return [.green, .mint]
        case 70..<90: return [.indigo, .purple]
        case 50..<70: return [.orange, .yellow]
        default: return [.red, .orange]
        }
    }
    
    private var statsCards: some View {
        HStack(spacing: 12) {
            statCard(value: "\(result.totalQuestions)", label: "총 문제", icon: "doc.text", color: .indigo)
            statCard(value: "\(result.correctAnswers)", label: "정답", icon: "checkmark.circle", color: .green)
            statCard(value: "\(result.totalQuestions - result.correctAnswers)", label: "오답", icon: "xmark.circle", color: .red)
        }
    }
    
    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private var wrongWordsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("틀린 단어 (\(result.wrongWords.count)개)")
                .font(.headline)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(result.wrongWords.enumerated()), id: \.offset) { index, word in
                    HStack {
                        Text(word.english)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(word.korean)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    if index < result.wrongWords.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onRetry()
            } label: {
                Label("다시 풀기", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .fontWeight(.semibold)
            }
            
            if !result.wrongWords.isEmpty {
                Button {
                    onRetryWrong()
                } label: {
                    Label("틀린 단어만 다시", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .fontWeight(.semibold)
                }
            }
            
            Button {
                onDismiss()
            } label: {
                Text("홈으로")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .fontWeight(.medium)
            }
        }
    }
}
