import SwiftUI

struct WordListView: View {
    @EnvironmentObject var wordListVM: WordListViewModel
    @State private var sortByWrong = false
    @State private var showLearnedOnly = false
    
    var displayedWords: [Word] {
        var words = wordListVM.filteredWords
        if showLearnedOnly { words = words.filter { !$0.isLearned } }
        if sortByWrong { words = words.sorted { $0.wrongCount > $1.wrongCount } }
        return words
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if wordListVM.words.isEmpty {
                    emptyState
                } else {
                    wordList
                }
            }
            .navigationTitle("단어장")
            .searchable(text: $wordListVM.searchText, prompt: "영어 또는 한글 검색")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Toggle("틀린 단어 우선", isOn: $sortByWrong)
                        Toggle("미학습만 보기", isOn: $showLearnedOnly)
                        Divider()
                        Button(role: .destructive) {
                            wordListVM.resetProgress()
                        } label: {
                            Label("학습 기록 초기화", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.indigo.opacity(0.4))
            Text("단어장이 비어있어요")
                .font(.headline)
            Text("홈에서 엑셀 파일을 가져오세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var wordList: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Label("\(wordListVM.words.count)개", systemImage: "book.fill")
                        .font(.caption)
                        .foregroundColor(.indigo)
                    Label("\(wordListVM.learnedCount)개 완료", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Label("\(wordListVM.words.filter { $0.wrongCount > 0 }.count)개 오답", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.vertical, 4)
            }
            
            ForEach(displayedWords) { word in
                WordRowView(word: word)
            }
            .onDelete { indexSet in
                indexSet.forEach { wordListVM.deleteWord(displayedWords[$0]) }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct WordRowView: View {
    let word: Word
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.english)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(word.korean)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if word.isLearned {
                    Label("완료", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .labelStyle(.iconOnly)
                        .font(.title3)
                }
                
                if word.wrongCount > 0 || word.correctCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("\(word.correctCount)")
                            .font(.caption)
                            .foregroundColor(.green)
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("\(word.wrongCount)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
