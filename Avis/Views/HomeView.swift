import SwiftUI
import MijickCalendarView

struct HomeView: View {
    @EnvironmentObject var wordListVM: WordListViewModel
    @EnvironmentObject var quizVM: QuizViewModel
    @EnvironmentObject var statsVM: StatsViewModel
    @State private var selectedDate: Date? = nil
    @State private var displayedMonth: Date = Date()
    @State private var navigateToQuiz = false
    
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
                    
                    // 학습 캘린더
                    calendarSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("영단어 퀴즈")
            .navigationBarTitleDisplayMode(.large)
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
                    quizVM.startQuiz(words: wordListVM.words, mode: .mixed)
                    navigateToQuiz = true
                }
                
                quickStartButton(
                    title: "틀린 단어",
                    subtitle: "\(wordListVM.words.filter { $0.wrongCount > 0 }.count)개 단어",
                    icon: "arrow.counterclockwise",
                    gradient: [.orange, .red]
                ) {
                    quizVM.startQuiz(words: wordListVM.words, mode: .mixed, wrongOnly: true)
                    navigateToQuiz = true
                }
            }
            .navigationDestination(isPresented: $navigateToQuiz) {
                QuizView()
                    .environmentObject(quizVM)
                    .environmentObject(wordListVM)
            }
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: displayedMonth)
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("학습 캘린더")
                .font(.headline)
                .padding(.leading, 4)
            
            VStack(spacing: 12) {
                // 년월 헤더 + 좌우 버튼
                HStack {
                    Button {
                        withAnimation {
                            displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.indigo)
                    }
                    
                    Spacer()
                    
                    Text(monthYearString)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.indigo)
                    }
                }
                .padding(.horizontal, 4)
                
                // 캘린더
                let studyDates = Set(statsVM.stats.studyDates)
                MCalendarView(selectedDate: $selectedDate, selectedRange: nil) {
                    $0.dayView { date, isCurrentMonth, selectedDate, selectedRange in
                        StudyDayView(
                            date: date,
                            isCurrentMonth: isCurrentMonth,
                            selectedDate: selectedDate,
                            selectedRange: selectedRange,
                            studyDates: studyDates
                        )
                    }
                    .monthLabel { date in EmptyMonthLabel(month: date) }
                    .startMonth(displayedMonth)
                    .endMonth(displayedMonth)
                    .firstWeekday(.sunday)
                    .locale(Locale(identifier: "ko_KR"))
                }
                .id(displayedMonth)
                .frame(height: 300)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }
    
    private func quickStartButton(title: String, subtitle: String, icon: String, gradient: [Color], action: @escaping () -> Void) -> some View {
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

// MARK: - Custom DayView for Study Calendar
struct StudyDayView: DayView {
    let date: Date
    let isCurrentMonth: Bool
    let selectedDate: Binding<Date?>?
    let selectedRange: Binding<MDateRange?>?
    let studyDates: Set<String>
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private var hasStudied: Bool {
        studyDates.contains(dateString)
    }
    
    func createContent() -> AnyView {
        AnyView(
            VStack(spacing: 2) {
                Text(getStringFromDay(format: "d"))
                    .font(.system(size: 14, weight: isToday() ? .bold : .medium))
                    .foregroundColor(isToday() ? .indigo : (isPast() ? .primary : .secondary))
                
                if hasStudied {
                    Circle()
                        .fill(Color.indigo)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
        )
    }
    
    func onSelection() {}
}

// MARK: - Empty Month Label (hidden, replaced by custom header)
struct EmptyMonthLabel: MonthLabel {
    let month: Date
    func createContent() -> AnyView {
        AnyView(EmptyView())
    }
}
