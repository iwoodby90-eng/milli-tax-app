import SwiftUI

// MARK: - NavSeam
// The transition zone where content meets the canonical Image 40 chassis:
// consistent bottom inset and the shadow the chrome deck casts onto content.
// Nav itself is the single stamped canonical component (fix/canonical-milli-nav-
// reconstruction, 3c4d31e) — MilliNavBar.swift on main is never bound.

struct NavSeam: View {
    /// Standard clearance so content clears the sculpted chassis.
    static let bottomClearance: CGFloat = MilliSpacing.bottomContentClearance

    var body: some View {
        // Deck contact shadow cast upward onto content.
        LinearGradient(
            stops: [
                .init(color: Color.black.opacity(0.42), location: 0),
                .init(color: Color.black.opacity(0.18), location: 0.45),
                .init(color: .clear, location: 1)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
        .frame(height: 18)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Apply the nav seam shadow above the canonical chassis.
    func navSeam() -> some View { background(NavSeam()) }
}