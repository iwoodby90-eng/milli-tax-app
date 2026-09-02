import SwiftUI

// MARK: - PrimaryCTA / SecondaryGlassButton / DestructiveButton
// Cyan-lit fill for primary actions; black-glass chrome for secondary;
// explicit negative styling for destructive. Covers every action surface.

struct PrimaryCTA: View {
    let title: String
    var isProcessing: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled, !isProcessing else { return }
            action()
        } label: {
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .tint(MilliColors.blackGlass)
                        .controlSize(.small)
                }
                Text(isProcessing ? "Processing…" : title)
                    .font(MilliFont.headlineMedium)
                    .foregroundStyle(enabled ? MilliColors.blackGlass : MilliColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                Capsule().fill(enabled ? MilliColors.cyanGlow : Color.white.opacity(0.06))
            )
            .overlay(
                Capsule().stroke(
                    enabled ? MilliColors.cyanGlow.opacity(0.5) : MilliColors.borderSubtle,
                    lineWidth: 0.8
                )
            )
            .shadow(color: enabled ? MilliColors.cyanGlow.opacity(0.22) : .clear, radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(enabled ? [] : [.isButton, .notEnabled])
    }
}

struct SecondaryGlassButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule().fill(Color.white.opacity(0.045))
                )
                .overlay(
                    Capsule().stroke(MilliColors.borderSubtle, lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct DestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.negative)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule().fill(MilliColors.negative.opacity(0.08))
                )
                .overlay(
                    Capsule().stroke(MilliColors.negative.opacity(0.4), lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}