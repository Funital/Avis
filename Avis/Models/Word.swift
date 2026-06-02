import Foundation

struct Word: Identifiable, Codable, Equatable {
    let id: UUID
    var english: String
    var korean: String
    var isLearned: Bool
    var wrongCount: Int
    var correctCount: Int
    
    init(id: UUID = UUID(), english: String, korean: String) {
        self.id = id
        self.english = english
        self.korean = korean
        self.isLearned = false
        self.wrongCount = 0
        self.correctCount = 1
    }
    
    var accuracy: Double {
        let total = wrongCount + correctCount
        guard total > 0 else { return 0 }
        return Double(correctCount) / Double(total) * 100
    }
}

enum QuizMode: String, CaseIterable {
    case englishToKorean = "영어 → 한글"
    case koreanToEnglish = "한글 → 영어"
    case mixed = "랜덤 혼합"
}

struct QuizQuestion {
    let word: Word
    let mode: QuizMode
    
    var prompt: String {
        switch mode {
        case .englishToKorean: return word.english
        case .koreanToEnglish: return word.korean
        case .mixed: return word.english
        }
    }
    
    /// 화면에 표시되는 대표 정답 (피드백용)
    var answer: String {
        switch mode {
        case .englishToKorean: return word.korean
        case .koreanToEnglish: return word.english
        case .mixed: return word.korean
        }
    }
    
    var promptLabel: String {
        switch mode {
        case .englishToKorean: return "영어"
        case .koreanToEnglish: return "한글"
        case .mixed: return "영어"
        }
    }
    
    var answerLabel: String {
        switch mode {
        case .englishToKorean: return "한글로 입력하세요"
        case .koreanToEnglish: return "영어로 입력하세요"
        case .mixed: return "한글로 입력하세요"
        }
    }
    
    /// 정답으로 인정되는 모든 후보를 반환합니다.
    ///
    /// 한글 뜻의 경우:
    ///   "(명) 경영진, 임원 / (형) 경영의, 운영의"
    ///   → 품사 태그 제거 → '/' 분리 → ',' 분리
    ///   → ["경영진", "임원", "경영의", "운영의"]
    ///   이 중 하나만 입력해도 정답 처리
    var acceptableAnswers: [String] {
        switch mode {
        case .koreanToEnglish:
            // 영어는 단순 비교 (대소문자 무시)
            return [word.english.trimmingCharacters(in: .whitespaces)]
        case .englishToKorean, .mixed:
            return Self.parseKoreanAnswers(from: word.korean)
        }
    }
    
    /// "(명) 경영진, 임원 / (형) 경영의, 운영의" 같은 문자열을
    /// ["경영진", "임원", "경영의", "운영의"] 로 파싱
    static func parseKoreanAnswers(from raw: String) -> [String] {
        // 1단계: (품사) 괄호 태그 전체 제거
        let withoutPos = raw.replacingOccurrences(
            of: "\\([^)]*\\)",
            with: "",
            options: .regularExpression
        )
        
        // 2단계: '/' 로 1차 분리
        let slashParts = withoutPos.components(separatedBy: "/")
        
        // 3단계: 각 파트를 ',' 로 2차 분리 후 공백 정리
        var answers: [String] = []
        for part in slashParts {
            let commaParts = part.components(separatedBy: ",")
            for item in commaParts {
                let cleaned = item.trimmingCharacters(in: .whitespaces)
                if !cleaned.isEmpty {
                    answers.append(cleaned)
                }
            }
        }
        return answers
    }
}

struct QuizResult {
    var totalQuestions: Int
    var correctAnswers: Int
    var wrongWords: [Word]
    
    var score: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    
    var grade: String {
        switch score {
        case 90...100: return "🏆 완벽해요!"
        case 70..<90:  return "👍 잘했어요!"
        case 50..<70:  return "📚 조금 더 노력해요"
        default:       return "💪 다시 도전해봐요"
        }
    }
}
