import SwiftUI

// Bel Air Cockpit nav bar — 4 flanking tabs + chrome "M" dial center (home).
struct BottomNavBar: View {
    @Binding var selection: MilliTab
    var onCenterTap: () -> Void

    // Tabs to the left and right of center
    private var leftTabs: [MilliTab] { [.vault, .wealth] }
    private var rightTabs: [MilliTab] { [.activity, .cockpit] }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(leftTabs, id: \.self) { navButton($0) }
            centerDial
            ForEach(rightTabs, id: \.self) { navButton($0) }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 26)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(MilliPalette.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 14)
    }

    private func navButton(_ t: MilliTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selection = t }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: t.icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(t.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selection == t ? MilliPalette.accent : MilliPalette.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }

    private var centerDial: some View {
        Button { onCenterTap() } label: {
            ZStack {
                // Chrome bezel ring
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [.white, .gray, .white, .gray, .white],
                            center: .center
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: .black.opacity(0.5), radius: 6, y: 3)

                // Dark face
                Circle()
                    .fill(MilliPalette.background)
                    .frame(width: 46, height: 46)

                // M character with cyan gradient
                Text("M")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, MilliPalette.accent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .offset(y: -10)
        .frame(maxWidth: .infinity)
    }
}
