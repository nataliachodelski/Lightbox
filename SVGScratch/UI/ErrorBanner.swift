import SwiftUI

struct ErrorBanner: View {
    enum Style {
        case error
        case notice

        var icon: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .notice: return "info.circle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .error: return .red
            case .notice: return .blue
            }
        }
    }

    let message: String
    var style: Style = .error
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: style.icon)
                .foregroundStyle(style.tint)
            Text(message)
                .font(.system(.footnote, design: .monospaced))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding(12)
    }
}
