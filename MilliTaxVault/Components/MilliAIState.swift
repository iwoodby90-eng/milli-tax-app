import SwiftUI
import UIKit

// MARK: - MilliAIState
// Canonical MILLI AI character state family (PR #66).
// Each case maps to a production image set in Assets.xcassets
// (milli-ai-front, milli-ai-three-quarter-left, milli-ai-three-quarter-right,
// milli-ai-listening, milli-ai-thinking, milli-ai-speaking, milli-ai-success,
// milli-ai-alert). All renders are derived from the single canonical robot
// so the character, face, proportions, materials and cyan M stay identical.
//
// Until the state image sets are committed to the asset catalog, views fall
// back to the existing canonical milli-ai-robot render, so the UI never shows
// a blank or a placeholder.

enum MilliAIState: String, CaseIterable {
    case front = "milli-ai-front"
    case threeQuarterLeft = "milli-ai-three-quarter-left"
    case threeQuarterRight = "milli-ai-three-quarter-right"
    case listening = "milli-ai-listening"
    case thinking = "milli-ai-thinking"
    case speaking = "milli-ai-speaking"
    case success = "milli-ai-success"
    case alert = "milli-ai-alert"

    var accessibilityDescription: String {
        switch self {
        case .front, .threeQuarterLeft, .threeQuarterRight:
            return "Milli AI assistant"
        case .listening:
            return "Milli AI listening"
        case .thinking:
            return "Milli AI processing your request"
        case .speaking:
            return "Milli AI responding"
        case .success:
            return "Milli AI action completed"
        case .alert:
            return "Milli AI alert"
        }
    }

    /// Resolves the render for a state, falling back to the canonical robot
    /// asset when a state image set is not present in the bundle.
    static func resolvedImage(for state: MilliAIState?) -> UIImage {
        if let state, let image = UIImage(named: state.rawValue) {
            return image
        }
        return UIImage(named: "milli-ai-robot") ?? UIImage()
    }
}

/// Renders a specific MILLI AI character state at the requested size.
struct MilliAIStateCharacterView: View {
    var state: MilliAIState
    var size: CGFloat

    var body: some View {
        Image(uiImage: MilliAIState.resolvedImage(for: state))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(state.accessibilityDescription)
    }
}
