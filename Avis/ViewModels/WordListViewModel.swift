import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class WordListViewModel: ObservableObject {
    @Published var words: [Word] = []
    @Published var isImporting = false
    @Published var importError: String?
    @Published var showImportSuccess = false
    @Published var importedCount = 0
    @Published var searchText = ""
    
    var filteredWords: [Word] {
        if searchText.isEmpty { return words }
        return words.filter {
            $0.english.localizedCaseInsensitiveContains(searchText) ||
            $0.korean.contains(searchText)
        }
    }
    
    var learnedCount: Int { words.filter { $0.isLearned }.count }
    
    init() {
        words = WordStore.load()
    }
    
    func importExcel(url: URL) {
        isImporting = true
        importError = nil
        
        Task {
            do {
                let parsed = try ExcelService.parseWords(from: url)
                if parsed.isEmpty {
                    importError = "단어를 찾을 수 없습니다. A열: 영어, B열: 한글 형식인지 확인해주세요."
                } else {
                    // 기존 단어와 병합 (중복 제거)
                    var merged = words
                    var existingEnglish = Set(words.map { $0.english.lowercased() })
                    var newCount = 0
                    for word in parsed {
                        if !existingEnglish.contains(word.english.lowercased()) {
                            merged.append(word)
                            existingEnglish.insert(word.english.lowercased())
                            newCount += 1
                        }
                    }
                    words = merged
                    importedCount = newCount
                    save()
                    showImportSuccess = true
                }
            } catch {
                importError = error.localizedDescription
            }
            isImporting = false
        }
    }
    
    func replaceAllWords(url: URL) {
        isImporting = true
        importError = nil
        
        Task {
            do {
                let parsed = try ExcelService.parseWords(from: url)
                if parsed.isEmpty {
                    importError = "단어를 찾을 수 없습니다."
                } else {
                    words = parsed
                    importedCount = parsed.count
                    save()
                    showImportSuccess = true
                }
            } catch {
                importError = error.localizedDescription
            }
            isImporting = false
        }
    }
    
    func deleteWord(_ word: Word) {
        words.removeAll { $0.id == word.id }
        save()
    }
    
    func resetProgress() {
        words = words.map {
            var w = $0
            w.isLearned = false
            w.wrongCount = 0
            w.correctCount = 0
            return w
        }
        save()
    }
    
    func markLearned(_ word: Word) {
        if let idx = words.firstIndex(of: word) {
            words[idx].isLearned = true
            save()
        }
    }
    
    func updateWordResult(wordId: UUID, isCorrect: Bool) {
        if let idx = words.firstIndex(where: { $0.id == wordId }) {
            if isCorrect {
                words[idx].correctCount += 1
                if words[idx].correctCount >= 3 {
                    words[idx].isLearned = true
                }
            } else {
                words[idx].wrongCount += 1
                words[idx].isLearned = false
            }
            save()
        }
    }
    
    private func save() {
        WordStore.save(words: words)
    }
}
