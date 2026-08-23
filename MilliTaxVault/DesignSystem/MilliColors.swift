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
    static let blackGlass = Color(hex: "07090B")

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
    static let textSecondary = Color(hex: "98A5AE")
    static let textTertiary = Color(hex: "6D7982")
    static let textLabel = Color(hex: "9AAAB5")
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
    static let border = Color.white.opacity(0.085)
    static let borderSubtle = Color.white.opacity(0.045)
    static let cardBorderGlow = Color.white.opacity(0.105)
    static let focusedBorder = cyanGlow.opacity(0.30)
    static let cyanGlowOpacity = cyanGlow.opacity(0.28)
    static let shimmer = Color.white.opacity(0.05)
    static let glassHighlight = Color.white.opacity(0.075)
    static let glassLowlight = Color.black.opacity(0.30)

    // MARK: Shared material recipes
    static var chromeGradient: LinearGradient {
        LinearGradient(
            colors: [chromeDeep, chromeLight, chromeWhite, chromeMid, chromeDark],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var graphiteSurface: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "151D24"), location: 0.00),
                .init(color: Color(hex: "0D141A"), location: 0.42),
                .init(color: Color(hex: "080D11"), location: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var blackGlassSurface: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.white.opacity(0.035), location: 0.00),
                .init(color: cardBackgroundElevated.opacity(0.94), location: 0.18),
                .init(color: cardBackground.opacity(0.98), location: 0.66),
                .init(color: blackGlass, location: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var precisionChromeEdge: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.48),
                chromeMid.opacity(0.18),
                cyanGlow.opacity(0.20),
                chromeDeep.opacity(0.10)
            ],
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

    static var cyanAmbient: RadialGradient {
        RadialGradient(
            colors: [MilliColors.cyanGlow.opacity(0.12), Color.clear],
            center: .topTrailing,
            startRadius: 0,
            endRadius: 180
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
