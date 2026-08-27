import SwiftUI

/// Visual Blueprint v2 — Aug 27, 2026 (canonical).
/// Global design tokens: palette, typography, spacing, radii, motion.
/// Visual layer only — no financial logic is modified.
enum MilliBlueprint {

    // MARK: - Palette

    enum Palette {
        static let obsidian       = Color(hex: 0x07090B) // App background, deepest recesses
        static let carbon         = Color(hex: 0x0E1114) // Card surfaces, ledger rows
        static let electricCyan   = Color(hex: 0x00E5FF) // Primary accent, progress, active
        static let deepCyan       = Color(hex: 0x00B4C2) // Secondary accent, recessed progress
        static let polishedSilver = Color(hex: 0xC0C0C0) // Secondary text, metallic detailing
        static let white          = Color.white
        static let positive       = Color(hex: 0x22DB83) // Posted / confirmed
        static let warning        = Color(hex: 0xF4B73B) // Processing / attention
        static let negative       = Color(hex: 0xFF5661) // Failed / reversed
    }

    // MARK: - Typography (Sora headings · Inter dense financial content)

    enum Type {
        static func sora(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
            .custom("Sora-\(weight.soraName)", size: size)
        }
        static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .custom("Inter-\(weight.interName)", size: size)
        }
        // Tabular numerals on every monetary figure, percentage, running balance.
        static func monetary(_ size: CGFloat, sora: Bool = false, weight: Font.Weight = .medium) -> Font {
            (sora ? sora(size, weight: weight) : inter(size, weight: weight)).monospacedDigit()
        }
    }

    // MARK: - Spacing scale (pt)

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 40
        static let giant: CGFloat = 48
        static let massive: CGFloat = 64
        static let screenH: CGFloat = 20 // horizontal screen padding (20–24)
    }

    // MARK: - Corner radii (pt)

    enum Radius {
        static let control: CGFloat = 11   // Controls 10–12
        static let standard: CGFloat = 16  // Standard 14–18
        static let card: CGFloat = 21      // Cards 18–24
        static let hero: CGFloat = 28      // Hero 24–32
    }

    // MARK: - Motion (subtle only; respects Reduce Motion)

    enum Motion {
        static let fast: TimeInterval = 0.2
        static let standard: TimeInterval = 0.25
        static let slow: TimeInterval = 0.4
        static func animation(_ duration: TimeInterval) -> Animation? {
            UIAccessibility.isReduceMotionEnabled ? nil : .easeInOut(duration: duration)
        }
    }
}

// MARK: - Font weight name mapping

private extension Font.Weight {
    var soraName: String {
        switch self {
        case .bold: return "Bold"
        case .semibold: return "SemiBold"
        case .medium: return "Medium"
        default: return "Regular"
        }
    }
    var interName: String {
        switch self {
        case .bold: return "Bold"
        case .semibold: return "SemiBold"
        case .medium: return "Medium"
        default: return "Regular"
        }
    }
}

// MARK: - Hex convenience

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
