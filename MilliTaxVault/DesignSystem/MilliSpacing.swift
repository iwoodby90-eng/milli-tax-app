import SwiftUI

// MARK: - MilliSpacing
// Tight 4pt rhythm derived from the approved high-density iPhone references.

enum MilliSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32

    // Screen edge insets
    static let screenHorizontal: CGFloat = 16
    static let screenVertical: CGFloat = 12

    // Card internal padding
    static let cardPadding: CGFloat = 14
    static let cardPaddingLarge: CGFloat = 16

    // Grid gap
    static let gridGap: CGFloat = 10

    // Corner radii
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 11
    static let radiusLg: CGFloat = 14
    static let radiusXl: CGFloat = 16
    static let radiusFull: CGFloat = 100

    // Fixed shell geometry
    static let bottomNavHeight: CGFloat = 92
    static let bottomContentClearance: CGFloat = 116
}

// MARK: - MilliRadius
// Compatibility facade for earlier screens while the app converges on MilliSpacing.

enum MilliRadius {
    static let small: CGFloat = MilliSpacing.radiusSm
    static let medium: CGFloat = MilliSpacing.radiusMd
    static let card: CGFloat = MilliSpacing.radiusLg
    static let large: CGFloat = MilliSpacing.radiusXl
    static let pill: CGFloat = MilliSpacing.radiusFull
}

// MARK: - MilliLayout — Legacy compatibility

enum MilliLayout {
    static let screenMargin: CGFloat = MilliSpacing.screenHorizontal
    static let cardPaddingH: CGFloat = MilliSpacing.cardPadding
    static let cardPaddingV: CGFloat = MilliSpacing.cardPadding
    static let sectionGap: CGFloat = MilliSpacing.xl
    static let cardRadius: CGFloat = MilliSpacing.radiusLg
    static let metadataGap: CGFloat = MilliSpacing.sm
}
