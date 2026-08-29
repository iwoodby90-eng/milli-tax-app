import SwiftUI

// MARK: - MILLI AI Nav Ambient Character
// Implements the "MILLI AI — Nav Ambient Character Behavior Spec" (Aug 28, 2026).
//
// Spec compliance map:
// §2 Default State      -> character is nil between events; no idle loop, no breathing timer.
// §3 Ambient Walk-By    -> 3–5 s crossing of the upper chrome deck, optional glance.
// §4 Center M Moments   -> momentary stop near center with one subtle action, then continue.
// §5 Mini Dance         -> rare (~6% of appearances), 1–2 s, physically grounded micro-motion.
// §6 Financial Trust    -> no public API tied to balances/payouts; success-style behavior is
//                          never triggered by financial events (no such trigger exists here).
// §7 Interaction Priority -> allowsHitTesting(false) on the whole layer; nav always wins.
// §8 Scale & Depth      -> miniature scale, soft deck shadow, cyan rim reflection from center M.
// §9 Reduce Motion      -> walking/dancing disabled; static fade-in + small head turn only.
// §10 Performance       -> discrete scheduled events; no continuous timer; Task cancelled on exit.
// §11 Final Principle   -> the character is a guest; the nav is untouched.

struct MilliAINavAmbientCharacter: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Character presentation
    private let characterSize: CGFloat = 34
    private let deckYOffset: CGFloat = -46 // stands on the upper chrome deck of the nav bar

    // Event scheduling (§3: minutes-scale cooldown, low probability, serendipitous)
    private let minCooldown: TimeInterval = 180 // 3 minutes
    private let maxCooldown: TimeInterval = 480 // 8 minutes
    private let appearanceProbability: Double = 0.35 // per scheduled tick
    private let miniDanceProbability: Double = 0.06 // §5: rare

    // Walk phases
    private enum Phase {
        case idle
        case walking(direction: WalkDirection, stopAtCenter: Bool)
        case centerMoment(direction: WalkDirection)
        case miniDance(direction: WalkDirection)
        case exiting(direction: WalkDirection)
    }

    private enum WalkDirection {
        case leftToRight, rightToLeft

        var start: CGFloat { self == .leftToRight ? -1.0 : 1.0 } // fraction of width
        var end: CGFloat { self == .leftToRight ? 1.0 : -1.0 }
        var facing: CGFloat { self == .leftToRight ? 1.0 : -1.0 }
    }

    @State private var phase: Phase = .idle
    @State private var progress: CGFloat = 0 // 0...1 across the deck
    @State private var visible = false
    @State private var headTurn = false
    @State private var danceWiggle = false
    @State private var task: Task<Void, Never>?

    /// QA hook: fire one appearance ~1 s after appear (then normal schedule).
    var debugImmediate: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if visible {
                    characterView
                        .position(
                            x: characterX(in: geo.size.width),
                            y: geo.size.height + deckYOffset
                        )
                        .allowsHitTesting(false) // §7: nav always wins
                }
            }
            .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
        .onAppear {
            if debugImmediate {
                task = Task {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                    await runAppearance()
                    scheduleNextEvent()
                }
            } else {
                scheduleNextEvent()
            }
        }
        .onDisappear { task?.cancel() }
    }

    // MARK: - Character

    private var characterView: some View {
        ZStack {
            // §8: deck contact shadow — reads as standing on the chrome, not a sticker
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.black.opacity(0.55), Color.clear],
                        center: .center,
                        startRadius: 1,
                        endRadius: 18
                    )
                )
                .frame(width: 30, height: 7)
                .offset(y: characterSize / 2 + 2)

            // §8: cyan reflection cast from the center M illumination
            Circle()
                .fill(
                    RadialGradient(
                        colors: [MilliColors.cyanGlow.opacity(0.22), Color.clear],
                        center: .center,
                        startRadius: 2,
                        endRadius: 26
                    )
                )
                .frame(width: 52, height: 52)
                .offset(y: -4)

            Image("milli-ai-robot")
                .resizable()
                .scaledToFit()
                .frame(width: characterSize, height: characterSize)
                .scaleEffect(x: walkFacing, y: 1) // face travel direction
                .rotationEffect(.degrees(headTurn ? -8 : 0), anchor: .center)
                .offset(x: danceWiggle ? 2.5 : 0)
                .shadow(color: Color.black.opacity(0.6), radius: 4, y: 2)
        }
        .opacity(visible ? 1 : 0)
    }

    private var walkFacing: CGFloat {
        switch phase {
        case .walking(let dir, _), .centerMoment(let dir), .miniDance(let dir), .exiting(let dir):
            return dir.facing
        case .idle:
            return 1
        }
    }

    private func characterX(in width: CGFloat) -> CGFloat {
        let margin: CGFloat = characterSize
        let startX = margin
        let endX = width - margin
        return startX + (endX - startX) * (progress + 1) / 2 // progress -1...1
    }

    // MARK: - Event scheduling (§10: discrete events, no continuous timer)

    private func scheduleNextEvent() {
        task?.cancel()
        task = Task { [minCooldown, maxCooldown, appearanceProbability] in
            while !Task.isCancelled {
                let cooldown = TimeInterval.random(in: minCooldown...maxCooldown)
                try? await Task.sleep(for: .seconds(cooldown))
                guard !Task.isCancelled else { return }
                if Double.random(in: 0...1) < appearanceProbability {
                    await runAppearance()
                }
            }
        }
    }

    // MARK: - Appearance sequence

    private func runAppearance() async {
        let direction: WalkDirection = Bool.random() ? .leftToRight : .rightToLeft
        let stopsAtCenter = Bool.random() && !reduceMotion // §4: optional momentary stop
        let dances = !reduceMotion && Double.random(in: 0...1) < miniDanceProbability // §5: rare

        await MainActor.run {
            phase = .walking(direction: direction, stopAtCenter: stopsAtCenter)
            progress = direction.start
            visible = true
        }

        if reduceMotion {
            // §9: no translation-heavy animation. Brief static appearance + small head turn.
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.4)) { visible = true }
                withAnimation(.easeInOut(duration: 0.6)) { headTurn = true }
            }
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) { headTurn = false }
                withAnimation(.easeOut(duration: 0.5)) { visible = false }
            }
            await reset()
            return
        }

        // Walk toward the center (or straight across if not stopping)
        let centerStop = stopsAtCenter ? 0.0 : direction.end
        await walk(from: direction.start, to: centerStop, duration: stopsAtCenter ? 1.8 : 3.2)

        if stopsAtCenter {
            await MainActor.run { phase = .centerMoment(direction: direction) }
            // §4: one subtle action — a glance toward the M (head turn), momentary
            await MainActor.run { withAnimation(.easeInOut(duration: 0.5)) { headTurn = true } }
            try? await Task.sleep(for: .seconds(0.9))
            await MainActor.run { withAnimation(.easeInOut(duration: 0.4)) { headTurn = false } }
            try? await Task.sleep(for: .seconds(0.3))

            if dances {
                // §5: mini dance — 1–2 s, physically grounded micro-motion
                await MainActor.run { phase = .miniDance(direction: direction) }
                for _ in 0..<3 {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.22)) { danceWiggle.toggle() }
                    }
                    try? await Task.sleep(for: .seconds(0.24))
                }
                await MainActor.run { danceWiggle = false }
            }

            await MainActor.run { phase = .exiting(direction: direction) }
            await walk(from: 0.0, to: direction.end, duration: 1.6)
        }

        await MainActor.run {
            withAnimation(.easeOut(duration: 0.3)) { visible = false }
        }
        await reset()
    }

    private func walk(from: CGFloat, to: CGFloat, duration: TimeInterval) async {
        await MainActor.run {
            withAnimation(.linear(duration: duration)) {
                progress = to
            }
        }
        try? await Task.sleep(for: .seconds(duration + 0.05))
    }

    private func reset() async {
        await MainActor.run {
            phase = .idle
            progress = 0
            headTurn = false
            danceWiggle = false
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        MilliColors.obsidian.ignoresSafeArea()
        VStack {
            Spacer()
            MilliNavBar(selectedTab: .constant(.home))
        }
        MilliAINavAmbientCharacter()
    }
}
