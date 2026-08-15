import SwiftUI

// MARK: - MilliTypography — Sora (display) + Inter (body)
// Falls back to SF Pro if custom fonts not registered.

enum MilliFont {
    // MARK: Display — Sora
    static func displayLarge() -> Font { .custom("Sora-Bold", size: 34, relativeTo: .largeTitle) }
    static func displayMedium() -> Font { .custom("Sora-Bold", size: 28, relativeTo: .title) }
    static func displaySmall() -> Font { .custom("Sora-SemiBold", size: 22, relativeTo: .title2) }

    // MARK: Headline — Sora
    static func headline() -> Font { .custom("Sora-SemiBold", size: 17, relativeTo: .headline) }
    static func headlineSmall() -> Font { .custom("Sora-Medium", size: 15, relativeTo: .subheadline) }

    // MARK: Body — Inter
    static func bodyLarge() -> Font { .custom("Inter-Regular", size: 17, relativeTo: .body) }
    static func bodyMedium() -> Font { .custom("Inter-Regular", size: 15, relativeTo: .subheadline) }
    static func bodySmall() -> Font { .custom("Inter-Regular", size: 13, relativeTo: .footnote) }

    // MARK: Label — Inter
    static func label() -> Font { .custom("Inter-Medium", size: 11, relativeTo: .caption2) }
    static func labelLarge() -> Font { .custom("Inter-SemiBold", size: 13, relativeTo: .caption) }

    // MARK: Numeric — Inter SemiBold for financial figures
    static func numericLarge() -> Font { .custom("Inter-Bold", size: 36, relativeTo: .largeTitle) }
    static func numericMedium() -> Font { .custom("Inter-SemiBold", size: 20, relativeTo: .title3) }
    static func numericSmall() -> Font { .custom("Inter-SemiBold", size: 15, relativeTo: .body) }

    // MARK: Wordmark — Sora Bold for MILLI header
    static func wordmark() -> Font { .custom("Sora-Bold", size: 20, relativeTo: .title3) }
}
