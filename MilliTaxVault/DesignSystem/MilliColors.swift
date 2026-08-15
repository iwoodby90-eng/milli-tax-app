import SwiftUI

// MARK: - MilliColors — Single source of truth for the Milli palette
// Deep navy foundation, cyan accents, chrome highlights.

enum MilliColors {
    // MARK: Backgrounds
    static let background = Color(hex: "0A0E1A")
    static let cardBackground = Color(hex: "111827")
    static let cardBackgroundElevated = Color(hex: "1A2236")
    static let heroGradientTop = Color(hex: "141E33")
    static let heroGradientBottom = Color(hex: "0D1220")

    // MARK: Accent / Cyan
    static let cyan = Color(hex: "00D4FF")
    static let cyanDim = Color(hex: "00A3CC")
    static let cyanGlow = Color(hex: "00D4FF").opacity(0.3)

    // MARK: Chrome / Metallic
    static let chromeLight = Color(hex: "E8ECF0")
    static let chromeMid = Color(hex: "9CA3AF")
    static let chromeDark = Color(hex: "4B5563")

    // MARK: Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9CA3AF")
    static let textTertiary = Color(hex: "6B7280")
    static let textLabel = Color(hex: "7B8CA8")

    // MARK: Semantic
    static let positive = Color(hex: "34D399")
    static let negative = Color(hex: "EF4444")
    static let warning = Color(hex: "FBBF24")

    // MARK: Nav Bar
    static let navBarBackground = Color(hex: "080C16")
    static let navBarBorder = Color(hex: "1F2937")
    static let navTabActive = Color.white
    static let navTabInactive = Color(hex: "6B7280")

    // MARK: Surface / Borders
    static let border = Color(hex: "1F2937")
    static let borderSubtle = Color(hex: "1A2236").opacity(0.6)

    // MARK: Legacy Aliases (backward compat)
    static let textMuted = textSecondary
    static let obsidian = background
    static let shimmer = Color.white.opacity(0.05)
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
