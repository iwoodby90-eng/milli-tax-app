import SwiftUI

// MARK: - MilliColors
// Canonical Milli visual palette. Graphite/black-glass is dominant; cyan is a precision accent.

enum MilliColors {
    // MARK: Brand foundation
    static let obsidian = Color(hex: "07090B")
    static let carbon = Color(hex: "0E1114")
    static let elevated = Color(hex: "12191F")
    static let elevatedHigh = Color(hex: "172028")

    static let cyanGlow = Color(hex: "00E5FF")
    static let deepCyan = Color(hex: "00B4C2")
    static let cyan = cyanGlow
    static let cyanDim = deepCyan

    static let silver = Color(hex: "C0C0C0")
    static let silverBright = Color(hex: "EEF2F4")
    static let graphite = carbon
    static let blackGlass = Color(hex: "050808")

    // MARK: Backgrounds and surfaces
    static let background = obsidian
    static let cardBackground = Color(hex: "0B1116")
    static let cardBackgroundElevated = elevated
    static let heroGradientTop = Color(hex: "101922")
    static let heroGradientBottom = Color(hex: "090E13")
    static let navBarBackground = Color(hex: "060A0D")

    // MARK: Chrome / metal
    static let chromeWhite = Color(hex: "F7FAFB")
    static let chromeLight = Color(hex: "E6EBEE")
    static let chromeMid = Color(hex: "969EA4")
    static let chromeDark = Color(hex: "4E555A")
    static let chromeDeep = Color(hex: "20262B")

    // MARK: Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8E9AA4")
    static let textTertiary = Color(hex: "65717A")
    static let textLabel = Color(hex: "90A2AF")
    static let textMuted = textSecondary
    static let secondaryText = textSecondary

    // MARK: Semantic states
    static let positive = Color(hex: "22DB83")
    static let warning = Color(hex: "F4B73B")
    static let negative = Color(hex: "FF5661")
    static let orange = Color(hex: "F7933D")
    static let green = positive
    static let amber = warning
    static let red = negative

    // MARK: Navigation
    static let navBarBorder = Color.white.opacity(0.09)
    static let navTabActive = cyanGlow
    static let navTabInactive = Color(hex: "7A858D")

    // MARK: Borders / highlights
    static let border = Color.white.opacity(0.08)
    static let borderSubtle = Color.white.opacity(0.045)
    static let cardBorderGlow = Color.white.opacity(0.08)
    static let focusedBorder = cyanGlow.opacity(0.24)
    static let cyanGlowOpacity = cyanGlow.opacity(0.28)
    static let shimmer = Color.white.opacity(0.045)

    static var chromeGradient: LinearGradient {
        LinearGradient(
            colors: [chromeDeep, chromeLight, chromeWhite, chromeMid, chromeDark],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var graphiteSurface: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.035), cardBackgroundElevated, cardBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - MilliGradients
// Shared material gradients for signature hardware-like controls.

enum MilliGradients {
    static var chromeRing: AngularGradient {
        AngularGradient(
            colors: [
                MilliColors.chromeDark,
                MilliColors.chromeWhite,
                MilliColors.chromeMid,
                MilliColors.chromeLight,
                MilliColors.chromeDeep,
                MilliColors.chromeWhite,
                MilliColors.chromeDark
            ],
            center: .center
        )
    }
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
