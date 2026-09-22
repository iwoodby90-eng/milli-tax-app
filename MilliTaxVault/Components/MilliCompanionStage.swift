import SwiftUI
import UIKit

// MARK: - MilliNavWalker
// The Milli AI character strolling along the top edge of the navigation deck.
// It walks in, paces across, and leaves; it never blocks a tab's hit target.

struct MilliNavWalker: View {
    let deckWidth: CGFloat
    let deckHeight: CGFloat
    let isWalking: Bool

    @State private var progress: CGFloat = -0.12
    @State private var bob: CGFloat = 0
    @State private var facingRight = true

    private var characterSize: CGFloat { max(deckHeight * 0.44, 28) }
    private var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    var body: some View {
        Image("milli-ai-robot")
            .resizable()
            .scaledToFit()
            .frame(width: characterSize, height: characterSize)
            .scaleEffect(x: facingRight ? 1 : -1, y: 1)
            .shadow(color: MilliColors.cyanGlow.opacity(0.3), radius: 8)
            .position(
                x: deckWidth * progress,
                y: deckHeight * 0.06 - characterSize * 0.18 + bob
            )
            .opacity(isWalking ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: isWalking) { _, walking in
                walking ? startWalk() : reset()
            }
    }

    private func startWalk() {
        progress = -0.12
        facingRight = true

        guard !reduceMotion else {
            progress = 0.5
            return
        }

        withAnimation(.easeInOut(duration: 3.4)) {
            progress = 1.10
        }
        withAnimation(.easeInOut(duration: 0.38).repeatCount(9, autoreverses: true)) {
            bob = -3
        }

        // Turn around near the end so the walk reads as a pace, not a drive-by.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            guard isWalking else { return }
            facingRight = false
            progress = 1.10
            withAnimation(.easeInOut(duration: 3.4)) {
                progress = -0.12
            }
        }
    }

    private func reset() {
        bob = 0
        progress = -0.12
    }
}

// MARK: - MilliDialCelebration
// Achievement moment: the character pops up inside the M dial, bounces while it
// "talks", and a short line appears above the deck.

struct MilliDialCelebration: View {
    let milestone: MilliMilestone
    let dialSize: CGFloat
    var onTap: () -> Void = {}

    @State private var bounce: CGFloat = 0
    @State private var talkScale: CGFloat = 1
    @State private var appeared = false

    private var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    var body: some View {
        ZStack {
            Circle()
                .fill(MilliColors.cyanGlow.opacity(0.16))
                .frame(width: dialSize * 1.12, height: dialSize * 1.12)
                .blur(radius: 10)

            Image("milli-ai-robot")
                .resizable()
                .scaledToFit()
                .frame(width: dialSize * 0.82, height: dialSize * 0.82)
                .scaleEffect(talkScale)
                .offset(y: bounce)
                .clipShape(Circle())

            speechBubble
                .offset(y: -dialSize * 0.95)
        }
        .scaleEffect(appeared ? 1 : 0.6)
        .opacity(appeared ? 1 : 0)
        .contentShape(Circle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(milestone.title). \(milestone.line)")
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { appeared = true }
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.34).repeatForever(autoreverses: true)) {
                bounce = -4
            }
            withAnimation(.easeInOut(duration: 0.22).repeatForever(autoreverses: true)) {
                talkScale = 1.05
            }
        }
    }

    private var speechBubble: some View {
        VStack(spacing: 2) {
            Text(milestone.title.uppercased())
                .font(.custom("Inter-SemiBold", size: 9, relativeTo: .caption2))
                .tracking(0.9)
                .foregroundStyle(MilliColors.cyanGlow)

            Text(milestone.line)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: 210)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(MilliColors.blackGlass.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.35), lineWidth: 0.8)
                }
                .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 12)
        )
    }
}

// MARK: - MilliConfettiView
// Confetti fired from both top corners of the screen. Purely decorative and
// skipped entirely when the user asks for reduced motion.

struct MilliConfettiView: View {
    let isActive: Bool

    private static let pieceCount = 26

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if isActive && !UIAccessibility.isReduceMotionEnabled {
                    ForEach(0..<Self.pieceCount, id: \.self) { index in
                        MilliConfettiPiece(
                            index: index,
                            fromLeft: index.isMultiple(of: 2),
                            canvas: proxy.size
                        )
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MilliConfettiPiece: View {
    let index: Int
    let fromLeft: Bool
    let canvas: CGSize

    @State private var travel: CGFloat = 0
    @State private var spin: Double = 0
    @State private var fade: Double = 1

    private static let palette: [Color] = [
        MilliColors.cyanGlow,
        MilliColors.cyan,
        MilliColors.chromeLight,
        MilliColors.chromeMid,
        MilliColors.positive
    ]

    private var seed: Double { Double(index) }
    private var color: Color { Self.palette[index % Self.palette.count] }
    private var size: CGFloat { 5 + CGFloat((index * 7) % 5) }
    private var duration: Double { 1.5 + Double((index * 3) % 7) / 6.0 }
    private var horizontalSpread: CGFloat { canvas.width * (0.28 + CGFloat((index * 11) % 60) / 100) }
    private var verticalDrop: CGFloat { canvas.height * (0.45 + CGFloat((index * 13) % 45) / 100) }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.4, style: .continuous)
            .fill(color)
            .frame(width: size, height: size * 1.7)
            .rotationEffect(.degrees(spin))
            .opacity(fade)
            .position(
                x: (fromLeft ? 14 : canvas.width - 14) + (fromLeft ? horizontalSpread : -horizontalSpread) * travel,
                y: 10 + verticalDrop * travel * travel
            )
            .onAppear {
                withAnimation(.easeOut(duration: duration).delay(seed * 0.018)) {
                    travel = 1
                }
                withAnimation(.linear(duration: duration).delay(seed * 0.018)) {
                    spin = fromLeft ? 420 : -420
                }
                withAnimation(.easeIn(duration: 0.6).delay(duration * 0.6)) {
                    fade = 0
                }
            }
    }
}
