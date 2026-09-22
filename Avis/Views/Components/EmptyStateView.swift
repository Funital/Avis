import SwiftUI

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.indigo.opacity(0.4))
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
