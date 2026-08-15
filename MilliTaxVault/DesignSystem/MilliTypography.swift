import SwiftUI

// MARK: - MilliTypography
// Sora owns display/financial hierarchy; Inter owns interface copy and metadata.

enum MilliFont {
    // Hero / Display — Sora
    static var heroNumber: Font { .custom("Sora-ExtraBold", size: 34, relativeTo: .largeTitle) }
    static var heroBalance: Font { .custom("Sora-ExtraBold", size: 34, relativeTo: .largeTitle) }
    static var displayLarge: Font { .custom("Sora-Bold", size: 32, relativeTo: .largeTitle) }
    static var displayMedium: Font { .custom("Sora-Bold", size: 28, relativeTo: .title) }
    static var displaySmall: Font { .custom("Sora-Bold", size: 24, relativeTo: .title2) }

    // Screen / Section
    static var screenTitle: Font { .custom("Sora-Bold", size: 22, relativeTo: .title3) }
    static var headline: Font { .custom("Sora-SemiBold", size: 17, relativeTo: .headline) }
    static var headlineSmall: Font { .custom("Sora-SemiBold", size: 15, relativeTo: .subheadline) }
    static var cardTitle: Font { .custom("Sora-SemiBold", size: 16, relativeTo: .headline) }

    // Body — Inter
    static var bodyLarge: Font { .custom("Inter-Regular", size: 17, relativeTo: .body) }
    static var bodyMedium: Font { .custom("Inter-Regular", size: 14, relativeTo: .subheadline) }
    static var body: Font { .custom("Inter-Regular", size: 14, relativeTo: .subheadline) }
    static var bodySmall: Font { .custom("Inter-Regular", size: 12, relativeTo: .footnote) }

    // Labels / Captions — Inter
    static var label: Font { .custom("Inter-SemiBold", size: 10, relativeTo: .caption2) }
    static var labelLarge: Font { .custom("Inter-SemiBold", size: 12, relativeTo: .caption) }
    static var sectionLabel: Font { .custom("Inter-SemiBold", size: 10, relativeTo: .caption2) }
    static var caption: Font { .custom("Inter-Regular", size: 10, relativeTo: .caption2) }

    // Numeric — Sora
    static var numericLarge: Font { .custom("Sora-Bold", size: 27, relativeTo: .title) }
    static var numericMedium: Font { .custom("Sora-SemiBold", size: 19, relativeTo: .title3) }
    static var numericSmall: Font { .custom("Sora-Medium", size: 13, relativeTo: .caption) }
    static var subHeroNumber: Font { .custom("Sora-ExtraBold", size: 20, relativeTo: .title3) }

    // Brand wordmark. Intentionally large and bold: MILLI should never read as tiny micro-copy.
    static var wordmark: Font { .custom("Sora-ExtraBold", size: 28, relativeTo: .title) }
    static var navLabel: Font { .custom("Inter-Medium", size: 9, relativeTo: .caption2) }
}

extension View {
    func sectionHeaderStyle() -> some View {
        self
            .font(MilliFont.sectionLabel)
            .tracking(1.25)
            .foregroundColor(MilliColors.secondaryText)
    }
}
