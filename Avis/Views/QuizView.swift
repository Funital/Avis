import SwiftUI

struct QuizView: View {
    @EnvironmentObject var quizVM: QuizViewModel
    @EnvironmentObject var wordListVM: WordListViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var inputFocused: Bool
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            switch quizVM.quizState {
            case .idle:
                Text("퀴즈를 시작하세요").onAppear { dismiss() }
            case .active, .answered:
                quizContent
            case .finished:
                if let result = quizVM.result {
                    ResultView(result: result, onRetry: {
                        quizVM.startQuiz(words: wordListVM.words, mode: quizVM.quizMode)
                    }, onRetryWrong: {
                        quizVM.startQuiz(words: wordListVM.words, mode: quizVM.quizMode, wrongOnly: true)
                    }, onDismiss: {
                        quizVM.reset()
                        dismiss()
                    })
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    quizVM.reset()
                    dismiss()
                } label: {
                    Label("종료", systemImage: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear { inputFocused = true }
    }
    
    @ViewBuilder
    private var quizContent: some View {
        if let question = quizVM.currentQuestion {
            VStack(spacing: 0) {
                // 진행 바
                progressHeader(question: question)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 문제 카드
                        questionCard(question: question)
                        
                        // 입력
                        answerInput(question: question)
                        
                        // 정오 피드백
                        if case .answered(let isCorrect) = quizVM.quizState {
                            feedbackView(isCorrect: isCorrect, question: question)
                        }
                    }
                    .padding()
                }
                
                // 하단 버튼
                bottomBar(question: question)
            }
        }
    }
    
    private func progressHeader(question: QuizQuestion) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(quizVM.currentNumber) / \(quizVM.totalCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                modeBadge(question: question)
            }
            .padding(.horizontal)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule()
                        .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * quizVM.progress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal)
            .animation(.easeInOut(duration: 0.3), value: quizVM.progress)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private func modeBadge(question: QuizQuestion) -> some View {
        Text(question.promptLabel + " → " + (question.mode == .englishToKorean ? "한글" : "영어"))
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.indigo)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.indigo.opacity(0.1))
            .clipShape(Capsule())
    }
    
    private func questionCard(question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            Text("다음 단어의 뜻은?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(question.prompt)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        )
    }
    
    private func answerInput(question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.answerLabel)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            HStack {
                TextField("정답 입력", text: $quizVM.userInput)
                    .font(.title3)
                    .focused($inputFocused)
                    .disabled(quizVM.quizState != .active)
                    .onSubmit {
                        if quizVM.canSubmit && quizVM.quizState == .active {
                            quizVM.submitAnswer(wordListVM: wordListVM)
                        }
                    }
                
                if !quizVM.userInput.isEmpty && quizVM.quizState == .active {
                    Button {
                        quizVM.userInput = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(inputBorderColor, lineWidth: 2)
                    )
            )
        }
    }
    
    private var inputBorderColor: Color {
        switch quizVM.quizState {
        case .answered(let isCorrect):
            return isCorrect ? .green : .red
        default:
            return Color(.systemGray4)
        }
    }
    
    private func feedbackView(isCorrect: Bool, question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(isCorrect ? .green : .red)
                
                Text(isCorrect ? "정답이에요!" : "틀렸어요")
                    .font(.headline)
                    .foregroundColor(isCorrect ? .green : .red)
                Spacer()
            }
            
            if !isCorrect {
                // 정답 목록 표시: 품사 제거 후 후보 전체를 보여줌
                let validAnswers = question.acceptableAnswers
                VStack(alignment: .leading, spacing: 4) {
                    Text("정답으로 인정되는 뜻:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    FlowLayout(items: validAnswers) { ans in
                        Text(ans)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCorrect ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
        )
        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
        .animation(.spring(response: 0.4), value: quizVM.quizState)
    }
    
    private func bottomBar(question: QuizQuestion) -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                if quizVM.quizState == .active {
                    Button("건너뛰기") {
                        quizVM.skipQuestion()
                        inputFocused = true
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    Button("확인") {
                        quizVM.submitAnswer(wordListVM: wordListVM)
                    }
                    .disabled(!quizVM.canSubmit)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(quizVM.canSubmit ? Color.indigo : Color(.systemGray4))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .fontWeight(.semibold)
                } else {
                    Button("다음 문제") {
                        quizVM.nextQuestion()
                        inputFocused = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .fontWeight(.semibold)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
}
