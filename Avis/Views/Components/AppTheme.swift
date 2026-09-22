import SwiftUI

// MARK: - App Theme

enum AppTheme {
    static let accentGradient = LinearGradient(
        colors: [.indigo, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cornerRadius: CGFloat = 14
}

// MARK: - Card Modifier

struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cornerRadius
    var hasShadow: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: hasShadow ? .black.opacity(0.05) : .clear,
                radius: 8, y: 2
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = AppTheme.cornerRadius, hasShadow: Bool = true) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius, hasShadow: hasShadow))
    }
}
