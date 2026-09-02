import SwiftUI

// MARK: - FormField (v1.2)
// One validated field component: Create Account (04), Tax Profile (05),
// Sign In (03), Documents search (27).

struct FormField: View {
    enum FieldState {
        case idle
        case valid
        case invalid(String)

        var tint: Color {
            switch self {
            case .idle: return MilliColors.borderSubtle
            case .valid: return MilliColors.positive
            case .invalid: return MilliColors.negative
            }
        }
    }

    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var state: FieldState = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            HStack(spacing: 8) {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                if case .valid = state {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(MilliColors.positive)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                    .fill(Color.white.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                    .stroke(state.tint, lineWidth: 0.8)
            )

            if case .invalid(let message) = state {
                Text(message)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.negative)
            }
        }
    }
}