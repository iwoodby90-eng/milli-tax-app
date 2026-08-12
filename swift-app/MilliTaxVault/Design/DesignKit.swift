import SwiftUI

// DesignKit — Reusable Milli UI components.
// All color tokens reference MilliPalette (defined in MilliPalette.swift).
// No duplicate enum here.

// MARK: - DKCard

struct DKCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MilliPalette.radius, style: .continuous)
                    .fill(MilliPalette.card)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MilliPalette.radius, style: .continuous)
                    .stroke(MilliPalette.cardBorder, lineWidth: 1)
            )
    }
}

// MARK: - Progress Ring

struct MilliProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var tint: Color = MilliPalette.accent
    var body: some View {
        ZStack {
            Circle().stroke(MilliPalette.cardBorder, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.5), tint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.5), radius: 8)
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
    }
}

// MARK: - Stat Tile

struct MilliStatTile: View {
    var title: String
    var value: String
    var accent: Color = MilliPalette.textPrimary
    var body: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(MilliPalette.textSecondary)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(accent)
            }
        }
    }
}

// MARK: - Segmented Picker

struct MilliSegmentedPicker<T: Hashable>: View {
    var options: [T]
    var label: (T) -> String
    @Binding var selection: T
    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { opt in
                let isOn = opt == selection
                Text(label(opt))
                    .font(.footnote.weight(.medium))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isOn ? MilliPalette.accent.opacity(0.18) : Color.clear)
                    )
                    .foregroundStyle(isOn ? MilliPalette.accent : MilliPalette.textSecondary)
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.easeInOut) { selection = opt } }
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 12).fill(MilliPalette.card))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(MilliPalette.cardBorder, lineWidth: 1))
    }
}

// MARK: - Currency Formatter

func milliCurrency(_ value: Double, fraction: Int = 0) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.maximumFractionDigits = fraction
    f.minimumFractionDigits = fraction
    return f.string(from: NSNumber(value: value)) ?? "$0"
}
