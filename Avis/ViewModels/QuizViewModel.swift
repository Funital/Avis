import Foundation
import SwiftUI

enum QuizState: Equatable {
    case idle
    case active
    case answered(isCorrect: Bool)
    case finished
}

@MainActor
class QuizViewModel: ObservableObject {
    @Published var currentQuestion: QuizQuestion?
    @Published var userInput: String = ""
    @Published var quizState: QuizState = .idle
    @Published var progress: Double = 0
    @Published var result: QuizResult?
    @Published var quizMode: QuizMode = .mixed
    @Published var wrongWordsOnly: Bool = false
    
    private var questions: [QuizQuestion] = []
    private var currentIndex: Int = 0
    private var correctCount: Int = 0
    private var wrongWords: [Word] = []
    
    var totalCount: Int { questions.count }
    var currentNumber: Int { currentIndex + 1 }
    var canSubmit: Bool { !userInput.trimmingCharacters(in: .whitespaces).isEmpty }
    
    func startQuiz(words: [Word], mode: QuizMode, wrongOnly: Bool = false) {
        let targetWords: [Word]
        if wrongOnly {
            targetWords = words.filter { $0.wrongCount > 0 }.shuffled()
        } else {
            targetWords = words.shuffled()
        }
        
        guard !targetWords.isEmpty else { return }
        
        questions = targetWords.map { word in
            let actualMode: QuizMode
            if mode == .mixed {
                actualMode = Bool.random() ? .englishToKorean : .koreanToEnglish
            } else {
                actualMode = mode
            }
            return QuizQuestion(word: word, mode: actualMode)
        }
        
        currentIndex = 0
        correctCount = 0
        wrongWords = []
        userInput = ""
        quizState = .active
        currentQuestion = questions[0]
        updateProgress()
    }
    
    func submitAnswer(wordListVM: WordListViewModel) {
        guard let question = currentQuestion else { return }
        
        let userAnswer = userInput.trimmingCharacters(in: .whitespaces)
        
        // acceptableAnswers 중 하나와 일치하면 정답
        // 한글은 완전 일치, 영어는 대소문자 무시
        let isCorrect = question.acceptableAnswers.contains { candidate in
            userAnswer.lowercased() == candidate.lowercased()
        }
        
        if isCorrect {
            correctCount += 1
        } else {
            wrongWords.append(question.word)
        }
        
        wordListVM.updateWordResult(wordId: question.word.id, isCorrect: isCorrect)
        quizState = .answered(isCorrect: isCorrect)
    }
    
    func nextQuestion() {
        currentIndex += 1
        userInput = ""
        
        if currentIndex >= questions.count {
            result = QuizResult(
                totalQuestions: questions.count,
                correctAnswers: correctCount,
                wrongWords: wrongWords
            )
            
            var stats = WordStore.loadStats()
            stats.totalSessions += 1
            stats.totalCorrect += correctCount
            stats.totalWrong += (questions.count - correctCount)
            let score = Double(correctCount) / Double(questions.count) * 100
            if score > stats.bestScore { stats.bestScore = score }
            stats.lastPlayedDate = Date()
            WordStore.saveStats(stats)
            
            quizState = .finished
        } else {
            currentQuestion = questions[currentIndex]
            quizState = .active
            updateProgress()
        }
    }
    
    func skipQuestion() {
        guard let question = currentQuestion else { return }
        wrongWords.append(question.word)
        nextQuestion()
    }
    
    func reset() {
        quizState = .idle
        currentQuestion = nil
        userInput = ""
        result = nil
        currentIndex = 0
        correctCount = 0
        wrongWords = []
    }
    
    private func updateProgress() {
        progress = Double(currentIndex) / Double(max(questions.count, 1))
    }
}
