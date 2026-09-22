import SwiftUI

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    var size: CGFloat = 64
    var lineWidth: CGFloat = 8
    var colors: [Color] = [.indigo, .purple]
    var label: String? = nil
    var sublabel: String? = nil
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 4) {
                if let label {
                    Text(label)
                        .font(size > 100 ? .system(size: 44, weight: .bold, design: .rounded) : .caption)
                        .fontWeight(.bold)
                }
                if let sublabel {
                    Text(sublabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut, value: progress)
    }
}

// MARK: - Stat Badge (Vertical: Icon + Value + Label)

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    var showBackground: Bool = true
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(showBackground ? 16 : 0)
        .background(showBackground ? Color(.systemBackground) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}

// MARK: - Stat Row (Horizontal: Icon + Title + Value)

struct StatRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Badge (Capsule Chip)

struct BadgeView: View {
    let text: String
    var color: Color = .indigo
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}
