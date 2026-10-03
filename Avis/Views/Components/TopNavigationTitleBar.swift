import SwiftUI

struct TopNavigationTitleBar<TrailingContent: View>: View {
    let title: String
    var height: CGFloat = 44
    var titleFont: Font = .system(size: 30)
    let trailingContent: TrailingContent
    
    init(title: String, height: CGFloat = 44, titleFont: Font = .system(size: 40), @ViewBuilder trailing: () -> TrailingContent) {
        self.title = title
        self.height = height
        self.titleFont = titleFont
        self.trailingContent = trailing()
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(titleFont)
                .fontWeight(.bold)
            Spacer()
            trailingContent
        }
        .frame(height: height)
        .padding(.horizontal)
        .background(Color(.systemGroupedBackground))
    }
}

extension TopNavigationTitleBar where TrailingContent == EmptyView {
    init(title: String, height: CGFloat = 44, titleFont: Font = .system(size: 30)) {
        self.title = title
        self.height = height
        self.titleFont = titleFont
        self.trailingContent = EmptyView()
    }
}
