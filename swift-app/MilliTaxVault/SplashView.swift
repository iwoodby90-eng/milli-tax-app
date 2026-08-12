import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void

    // MARK: - Phase State Machine

    enum Phase: Int, CaseIterable {
        case darkness = 0      // 0.0–1.2s: Pure black, then light ray
        case mDraw            // 1.2–2.8s: M stroke animation
        case shockwave        // 2.8–3.6s: Radial pulse
        case wordmark         // 3.6–4.8s: MILLI + TAX VAULT appear
        case hold             // 4.8–5.8s: Full brightness, pulsing glow
        case fadeOut           // 5.8–6.5s: Fade to black
    }

    // Phase 1 — Light ray
    @State private var rayOffset: CGFloat = -1.2
    @State private var rayOpacity: Double = 0

    // Phase 2 — M stroke
    @State private var mTrimEnd: CGFloat = 0
    @State private var mGlowIntensity: Double = 0

    // Phase 3 — Shockwave
    @State private var shockwaveScale: CGFloat = 0.1
    @State private var shockwaveOpacity: Double = 0

    // Phase 4 — Wordmark
    @State private var milliLetterOpacities: [Double] = Array(repeating: 0, count: 5)
    @State private var milliLetterOffsets: [CGFloat] = Array(repeating: 12, count: 5)
    @State private var taxVaultOpacity: Double = 0
    @State private var taxVaultOffset: CGFloat = 8

    // Phase 5 — Hold glow pulse
    @State private var holdGlowPulse: Double = 0.6

    // Phase 6 — Fade out
    @State private var screenOpacity: Double = 1

    // Constants
    private let cyan = Color(red: 0, green: 0.706, blue: 1) // #00B4FF
    private let bgColor = Color(red: 0.031, green: 0.031, blue: 0.063) // #080810

    var body: some View {
        ZStack {
            // Full black background
            bgColor.ignoresSafeArea()

            // Cinematic vignette overlay
            RadialGradient(
                colors: [Color.clear, Color.clear, bgColor.opacity(0.6), bgColor],
                center: .center,
                startRadius: 100,
                endRadius: 420
            )
            .ignoresSafeArea()

            // Phase 1: Horizontal light ray
            lightRayView

            // Phase 3: Shockwave / sonar pulse
            shockwaveView

            // Center content
            VStack(spacing: 0) {
                Spacer()

                // Phase 2: The M being laser-etched
                mLogoView
                    .frame(width: 100, height: 100)

                Spacer().frame(height: 36)

                // Phase 4: Wordmark
                wordmarkView

                Spacer().frame(height: 12)

                // Phase 4: TAX VAULT
                taxVaultLabel

                Spacer()
            }

            // Letterbox vignette — top and bottom bars
            VStack {
                LinearGradient(colors: [bgColor, bgColor.opacity(0.4), Color.clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 80)
                Spacer()
                LinearGradient(colors: [bgColor, bgColor.opacity(0.4), Color.clear],
                               startPoint: .bottom, endPoint: .top)
                    .frame(height: 80)
            }
            .ignoresSafeArea()
        }
        .opacity(screenOpacity)
        .ignoresSafeArea()
        .onAppear { runCinematicSequence() }
    }

    // MARK: - Light Ray (Phase 1)

    private var lightRayView: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, cyan.opacity(0.6), cyan, cyan.opacity(0.6), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 200, height: 1.5)
                .blur(radius: 3)
                .shadow(color: cyan.opacity(0.8), radius: 10)
                .shadow(color: cyan.opacity(0.4), radius: 20)
                .opacity(rayOpacity)
                .position(x: geo.size.width * rayOffset, y: geo.size.height * 0.5)
        }
    }

    // MARK: - M Logo (Phase 2)

    private var mLogoView: some View {
        ZStack {
            // Ambient glow behind M during hold phase
            Circle()
                .fill(
                    RadialGradient(
                        colors: [cyan.opacity(holdGlowPulse * 0.4), cyan.opacity(holdGlowPulse * 0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 140, height: 140)

            // M stroke — glow layer (wider, more blur)
            MilliMShape()
                .trim(from: 0, to: mTrimEnd)
                .stroke(
                    cyan.opacity(0.7),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                )
                .blur(radius: 4)
                .shadow(color: cyan, radius: 20)
                .frame(width: 80, height: 80)

            // M stroke — sharp core
            MilliMShape()
                .trim(from: 0, to: mTrimEnd)
                .stroke(
                    cyan,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: cyan.opacity(0.9), radius: 8)
                .shadow(color: cyan.opacity(0.5), radius: 4)
                .frame(width: 80, height: 80)

            // Bright leading-edge spark during draw
            if mTrimEnd > 0 && mTrimEnd < 1 {
                MilliMShape()
                    .trim(from: max(0, mTrimEnd - 0.02), to: mTrimEnd)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .blur(radius: 2)
                    .shadow(color: Color.white, radius: 6)
                    .frame(width: 80, height: 80)
            }
        }
        .opacity(mGlowIntensity)
    }

    // MARK: - Shockwave (Phase 3)

    private var shockwaveView: some View {
        Circle()
            .stroke(cyan.opacity(shockwaveOpacity), lineWidth: 2)
            .frame(width: 200, height: 200)
            .scaleEffect(shockwaveScale)
            .shadow(color: cyan.opacity(shockwaveOpacity * 0.5), radius: 15)
    }

    // MARK: - Wordmark (Phase 4)

    private var wordmarkView: some View {
        HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { index in
                Text(String("MILLI"[String.Index(utf16Offset: index, in: "MILLI")]))
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .tracking(2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(white: 0.95), Color(white: 0.6), Color(white: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(milliLetterOpacities[index])
                    .offset(y: milliLetterOffsets[index])
            }
        }
    }

    // MARK: - TAX VAULT Label (Phase 4)

    private var taxVaultLabel: some View {
        Text("TAX VAULT")
            .font(.system(size: 13, weight: .medium, design: .default))
            .tracking(6)
            .foregroundColor(Color(white: 0.55))
            .opacity(taxVaultOpacity)
            .offset(y: taxVaultOffset)
    }

    // MARK: - Cinematic Sequence

    private func runCinematicSequence() {

        // ─── Phase 1 (0.0–1.2s): Pure black → Light ray shoots across ───
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            rayOpacity = 1.0
            withAnimation(.easeInOut(duration: 0.5)) {
                rayOffset = 2.2
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                rayOpacity = 0
            }
        }

        // ─── Phase 2 (1.2–2.8s): M draws itself — laser-etch stroke ───
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            mGlowIntensity = 1.0
            withAnimation(.easeInOut(duration: 1.5)) {
                mTrimEnd = 1.0
            }
        }

        // ─── Phase 3 (2.8–3.6s): Radial shockwave from M ───
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            shockwaveOpacity = 1.0
            shockwaveScale = 0.1
            withAnimation(.easeOut(duration: 0.7)) {
                shockwaveScale = 2.5
                shockwaveOpacity = 0.0
            }
        }

        // ─── Phase 4 (3.6–4.8s): MILLI letters appear one by one ───
        let letters = "MILLI"
        for i in 0..<letters.count {
            let delay = 3.6 + Double(i) * 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.35)) {
                    milliLetterOpacities[i] = 1.0
                    milliLetterOffsets[i] = 0
                }
            }
        }

        // TAX VAULT appears after letters
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                taxVaultOpacity = 1.0
                taxVaultOffset = 0
            }
        }

        // ─── Phase 5 (4.8–5.8s): Hold + pulsing glow ───
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.8) {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                holdGlowPulse = 1.0
            }
        }

        // ─── Phase 6 (5.8–6.5s): Fade to black ───
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.8) {
            withAnimation(.easeInOut(duration: 0.7)) {
                screenOpacity = 0
            }
        }

        // Complete callback after full fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.6) {
            onComplete()
        }
    }
}

// MARK: - Geometric M Shape

struct MilliMShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Angular geometric M — sharp diagonals, no serifs
        // Left leg: bottom-left up to top-left
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: 0))

        // Left peak down to center valley
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.55))

        // Center valley up to right peak
        path.addLine(to: CGPoint(x: w, y: 0))

        // Right leg down to bottom-right
        path.addLine(to: CGPoint(x: w, y: h))

        return path
    }
}

// MARK: - String index helper

extension String {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}
