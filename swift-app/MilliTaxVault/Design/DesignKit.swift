import SwiftUI

// DesignKit — self-contained Milli design tokens + reusable components.
// Mirrors Colors.swift (#080810 bg, #00B4FF accent, #12121C cards w/ #1E1E2E
// border, 16pt radius). Namespaced (MilliPalette / DK*) to avoid clashing
// with the existing MilliCard component. Unify once integrated.

enum MilliPalette {
    static let background   = Color(red: 8/255,   green: 8/255,   blue: 16/255)
    static let accent       = Color(red: 0/255,   green: 180/255, blue: 255/255)
    static let card         = Color(red: 18/255,  green: 18/255,  blue: 28/255)
    static let cardBorder   = Color(red: 30/255,  green: 30/255,  blue: 46/255)
    static let positive     = Color(red: 48/255,  green: 209/255, blue: 88/255)
    static let negative     = Color(red: 255/255, green: 77/255,  blue: 77/255)
    static let textPrimary  = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let radius: CGFloat = 16
}

struct DKCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: MilliPalette.radius, style: .continuous).fill(MilliPalette.card))
            .overlay(RoundedRectangle(cornerRadius: MilliPalette.radius, style: .continuous).stroke(MilliPalette.cardBorder, lineWidth: 1))
    }
}

struct MilliProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var tint: Color = MilliPalette.accent
    var body: some View {
        ZStack {
            Circle().stroke(MilliPalette.cardBorder, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(AngularGradient(colors: [tint.opacity(0.5), tint], center: .center),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.5), radius: 8)
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
    }
}

struct MilliStatTile: View {
    var title: String
    var value: String
    var accent: Color = MilliPalette.textPrimary
    var body: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.caption).foregroundStyle(MilliPalette.textSecondary)
                Text(value).font(.title3.weight(.semibold)).foregroundStyle(accent)
            }
        }
    }
}

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
                    .padding(.vertical, 8).frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(isOn ? MilliPalette.accent.opacity(0.18) : Color.clear))
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

func milliCurrency(_ value: Double, fraction: Int = 0) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.maximumFractionDigits = fraction
    f.minimumFractionDigits = fraction
    return f.string(from: NSNumber(value: value)) ?? "USD 0"
}
