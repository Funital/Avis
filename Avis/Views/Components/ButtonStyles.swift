import SwiftUI

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isEnabled ? Color.indigo : Color(.systemGray4))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .fontWeight(.semibold)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .fontWeight(.medium)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Destructive Button Style

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .fontWeight(.semibold)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
