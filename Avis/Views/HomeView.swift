import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject var wordListVM: WordListViewModel
    @EnvironmentObject var quizVM: QuizViewModel
    @State private var showFilePicker = false
    @State private var showReplaceAlert = false
    @State private var pendingURL: URL?
    
    private var learnedPercent: Double {
        guard !wordListVM.words.isEmpty else { return 0 }
        return Double(wordListVM.learnedCount) / Double(wordListVM.words.count)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 헤더 카드
                    headerCard
                    
                    // 빠른 시작
                    quickStartSection
                    
                    // 엑셀 불러오기
                    importSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("영단어 퀴즈")
            .navigationBarTitleDisplayMode(.large)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "xlsx") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                if wordListVM.words.isEmpty {
                    wordListVM.importExcel(url: url)
                } else {
                    pendingURL = url
                    showReplaceAlert = true
                }
            case .failure(let error):
                wordListVM.importError = error.localizedDescription
            }
        }
        .alert("단어 가져오기", isPresented: $showReplaceAlert) {
            Button("추가하기") {
                if let url = pendingURL { wordListVM.importExcel(url: url) }
            }
            Button("교체하기", role: .destructive) {
                if let url = pendingURL { wordListVM.replaceAllWords(url: url) }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("기존 단어장에 추가할까요, 아니면 전체 교체할까요?")
        }
        .alert("가져오기 완료", isPresented: $wordListVM.showImportSuccess) {
            Button("확인") {}
        } message: {
            Text("단어 \(wordListVM.importedCount)개를 가져왔습니다!")
        }
        .alert("오류", isPresented: .init(
            get: { wordListVM.importError != nil },
            set: { if !$0 { wordListVM.importError = nil } }
        )) {
            Button("확인") { wordListVM.importError = nil }
        } message: {
            Text(wordListVM.importError ?? "")
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("학습 현황")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(wordListVM.learnedCount) / \(wordListVM.words.count) 완료")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: learnedPercent)
                        .stroke(
                            LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(learnedPercent * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .frame(width: 64, height: 64)
                .animation(.easeInOut, value: learnedPercent)
            }
            
            HStack(spacing: 12) {
                statBadge(icon: "checkmark.circle.fill", value: "\(wordListVM.learnedCount)", label: "학습 완료", color: .green)
                statBadge(icon: "xmark.circle.fill", value: "\(wordListVM.words.filter { $0.wrongCount > 0 }.count)", label: "틀린 단어", color: .red)
                statBadge(icon: "circle", value: "\(wordListVM.words.count - wordListVM.learnedCount)", label: "미학습", color: .orange)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    private func statBadge(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("빠른 시작")
                .font(.headline)
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                quickStartButton(
                    title: "전체 퀴즈",
                    subtitle: "\(wordListVM.words.count)개 단어",
                    icon: "play.fill",
                    gradient: [.indigo, .purple]
                ) {
                    quizVM.quizMode = .mixed
                    quizVM.startQuiz(words: wordListVM.words, mode: .mixed)
                }
                
                quickStartButton(
                    title: "틀린 단어",
                    subtitle: "\(wordListVM.words.filter { $0.wrongCount > 0 }.count)개 단어",
                    icon: "arrow.counterclockwise",
                    gradient: [.orange, .red]
                ) {
                    quizVM.startQuiz(words: wordListVM.words, mode: .mixed, wrongOnly: true)
                }
            }
        }
    }
    
    private func quickStartButton(title: String, subtitle: String, icon: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        NavigationLink(destination: QuizView().environmentObject(quizVM).environmentObject(wordListVM)) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                    Spacer()
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .frame(height: 110)
                .background(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var importSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("엑셀 파일 불러오기")
                .font(.headline)
                .padding(.leading, 4)
            
            Button {
                showFilePicker = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "tablecells")
                        .font(.title2)
                        .foregroundColor(.indigo)
                        .frame(width: 44, height: 44)
                        .background(Color.indigo.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Excel 파일 가져오기")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("A열: 번호, B열: 영어, C~F열: 품사/뜻 형식의 .xlsx 파일")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if wordListVM.isImporting {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            }
            .disabled(wordListVM.isImporting)
            
            Text("💡 지원 형식: ①번호/영어/품사/뜻/품사/뜻 (6열) ②영어/한글 (2열)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
    }
}
