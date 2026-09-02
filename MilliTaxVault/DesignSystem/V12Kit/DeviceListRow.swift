import SwiftUI

// MARK: - DeviceListRow
// Sessions/devices (30). StatusRow variant with a trailing detail value.

struct DeviceListRow: View {
    let icon: String
    let title: String
    let detail: String
    var isCurrent: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) { inner }
                    .buttonStyle(.plain)
            } else {
                inner
            }
        }
    }

    private var inner: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white.opacity(0.04)))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.textPrimary)
                    if isCurrent {
                        Text("THIS DEVICE")
                            .font(MilliFont.label)
                            .tracking(0.5)
                            .foregroundStyle(MilliColors.cyanGlow)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(MilliColors.cyanGlow.opacity(0.10)))
                    }
                }
                Text(detail)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MilliColors.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .carbonCard(cornerRadius: MilliSpacing.radiusMd)
    }
}