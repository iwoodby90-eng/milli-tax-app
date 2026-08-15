import SwiftUI

// MARK: - MilliColors — Single source of truth for the Milli palette
// Brand spec: blackGlass foundation, cyanGlow accents, chrome/silver highlights.

enum MilliColors {
    // MARK: Core Brand Colors (from Image 18 brand sheet)
    static let cyanGlow = Color(hex: "00E5FF")
    static let deepCyan = Color(hex: "009CFF")
    static let silver = Color(hex: "D5D7DB")
    static let graphite = Color(hex: "080D10")
    static let blackGlass = Color(hex: "050808")

    // MARK: Backgrounds
    static let background = blackGlass
    static let cardBackground = Color(hex: "0C1014")
    static let cardBackgroundElevated = Color(hex: "121920")
    static let heroGradientTop = Color(hex: "0E1418")
    static let heroGradientBottom = Color(hex: "080D10")

    // MARK: Accent / Cyan
    static let cyan = cyanGlow
    static let cyanDim = Color(hex: "00B8D4")
    static let cyanGlowOpacity = cyanGlow.opacity(0.3)

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
    static let orange = Color(hex: "F97316")

    // MARK: Nav Bar
    static let navBarBackground = Color(hex: "050808")
    static let navBarBorder = Color(hex: "1F2937")
    static let navTabActive = cyanGlow
    static let navTabInactive = Color(hex: "6B7280")

    // MARK: Surface / Borders
    static let border = Color(hex: "1A2530")
    static let borderSubtle = Color(hex: "1A2236").opacity(0.6)
    static let cardBorderGlow = cyanGlow.opacity(0.15)

    // MARK: Legacy Aliases (backward compat)
    static let textMuted = textSecondary
    static let secondaryText = textSecondary
    static let green = positive
    static let amber = warning
    static let red = negative
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
