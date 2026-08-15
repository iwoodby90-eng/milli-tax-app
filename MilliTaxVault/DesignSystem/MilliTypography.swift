import SwiftUI

// MARK: - MilliTypography — Sora font family (brand spec)
// All font tokens as static computed properties. Usage: .font(MilliFont.heroNumber)

enum MilliFont {
    // Hero / Display
    static var heroNumber: Font { .custom("Sora-ExtraBold", size: 38, relativeTo: .largeTitle) }
    static var heroBalance: Font { .custom("Sora-ExtraBold", size: 38, relativeTo: .largeTitle) }
    static var displayLarge: Font { .custom("Sora-Bold", size: 32, relativeTo: .largeTitle) }
    static var displayMedium: Font { .custom("Sora-Bold", size: 28, relativeTo: .title) }
    static var displaySmall: Font { .custom("Sora-Bold", size: 24, relativeTo: .title2) }

    // Screen / Section
    static var screenTitle: Font { .custom("Sora-Bold", size: 22, relativeTo: .title3) }
    static var headline: Font { .custom("Sora-SemiBold", size: 17, relativeTo: .headline) }
    static var headlineSmall: Font { .custom("Sora-SemiBold", size: 15, relativeTo: .subheadline) }
    static var cardTitle: Font { .custom("Sora-SemiBold", size: 17, relativeTo: .headline) }

    // Body
    static var bodyLarge: Font { .custom("Sora-Regular", size: 17, relativeTo: .body) }
    static var bodyMedium: Font { .custom("Sora-Regular", size: 15, relativeTo: .subheadline) }
    static var body: Font { .custom("Sora-Regular", size: 15, relativeTo: .subheadline) }
    static var bodySmall: Font { .custom("Sora-Regular", size: 13, relativeTo: .footnote) }

    // Labels / Captions
    static var label: Font { .custom("Sora-Medium", size: 12, relativeTo: .caption) }
    static var labelLarge: Font { .custom("Sora-Medium", size: 14, relativeTo: .caption) }
    static var sectionLabel: Font { .custom("Sora-Medium", size: 12, relativeTo: .caption) }
    static var caption: Font { .custom("Sora-Regular", size: 11, relativeTo: .caption2) }

    // Numeric
    static var numericLarge: Font { .custom("Sora-Bold", size: 28, relativeTo: .title) }
    static var numericMedium: Font { .custom("Sora-SemiBold", size: 20, relativeTo: .title3) }
    static var numericSmall: Font { .custom("Sora-Medium", size: 14, relativeTo: .caption) }
    static var subHeroNumber: Font { .custom("Sora-ExtraBold", size: 20, relativeTo: .title3) }

    // Special
    static var wordmark: Font { .custom("Sora-Bold", size: 16, relativeTo: .headline) }
}

// MARK: - Section Header Text Style

extension View {
    func sectionHeaderStyle() -> some View {
        self
            .font(MilliFont.label)
            .tracking(1.4)
            .foregroundColor(MilliColors.secondaryText)
    }
}
