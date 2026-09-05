import SwiftUI
import UIKit
import AVFoundation

// MARK: - Milli Presence

@MainActor
final class MilliPresence: ObservableObject {
    enum State: Equatable {
        case idle
        case thinking
        case insight
        case listening
        case speaking
        case navigating
        case turnLeft
        case turnRight
        case rerouting
        case arriving
        case success
        case celebration
        case warning
    }

    enum VoiceMode: String, CaseIterable {
        case fullCompanion = "Full Companion"
        case navigationOnly = "Navigation Only"
        case importantAlerts = "Important Alerts"
        case silent = "Silent"
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var message: String?
    @Published private(set) var celebrationTitle: String?
    @Published private(set) var celebrationDetail: String?
    @Published private(set) var celebrationNonce = UUID()

    @AppStorage("milliVoiceMode") private var storedVoiceMode = VoiceMode.fullCompanion.rawValue

    private let synthesizer = AVSpeechSynthesizer()
    private var resetTask: Task<Void, Never>?

    var voiceMode: VoiceMode {
        get { VoiceMode(rawValue: storedVoiceMode) ?? .fullCompanion }
        set { storedVoiceMode = newValue.rawValue }
    }

    func setState(_ newState: State, message: String? = nil, autoResetAfter seconds: Double? = nil) {
        resetTask?.cancel()
        state = newState
        self.message = message

        guard let seconds else { return }
        resetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.state = .idle
                self?.message = nil
            }
        }
    }

    func speak(_ text: String, category: VoiceCategory = .companion) {
        guard shouldSpeak(category) else { return }
        synthesizer.stopSpeaking(at: .word)

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.49
        utterance.pitchMultiplier = 1.02
        utterance.volume = 0.92
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
        setState(category == .navigation ? .navigating : .speaking, message: text, autoResetAfter: max(Double(text.count) / 14.0, 2.0))
    }

    func navigationInstruction(_ instruction: String, maneuver: Maneuver = .straight) {
        switch maneuver {
        case .left: setState(.turnLeft, message: instruction)
        case .right: setState(.turnRight, message: instruction)
        case .reroute: setState(.rerouting, message: instruction)
        case .arrival: setState(.arriving, message: instruction)
        case .straight: setState(.navigating, message: instruction)
        }
        speak(instruction, category: .navigation)
    }

    func celebrate(title: String, detail: String? = nil, major: Bool = true) {
        celebrationTitle = title
        celebrationDetail = detail
        celebrationNonce = UUID()
        setState(major ? .celebration : .success, message: detail, autoResetAfter: major ? 4.2 : 2.4)

        if major {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            speak("OH YEAH — WAY TO GO!", category: .important)
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    enum VoiceCategory { case companion, navigation, important }
    enum Maneuver { case straight, left, right, reroute, arrival }

    private func shouldSpeak(_ category: VoiceCategory) -> Bool {
        switch voiceMode {
        case .fullCompanion:
            return true
        case .navigationOnly:
            return category == .navigation
        case .importantAlerts:
            return category == .important
        case .silent:
            return false
        }
    }
}

// MARK: - Milli AI Character
// Vector-built transparent companion. No bitmap plate or opaque background is used.
// The approved MilliMLogo asset is the only M rendered on the character.

struct MilliAICharacterView: View {
    var size: CGFloat = 70
    var animated: Bool = false
    var presenceState: MilliPresence.State = .idle

    @State private var eyePulse = false
    @State private var bodyTilt: Double = -1
    @State private var dancePhase = false

    private var scale: CGFloat { size / 70 }
    private var isCelebrating: Bool { presenceState == .celebration || presenceState == .success }
    private var isSpeaking: Bool { presenceState == .speaking || presenceState == .navigating || presenceState == .turnLeft || presenceState == .turnRight }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(MilliColors.cyanGlow.opacity(isCelebrating ? 0.24 : 0.11))
                .frame(width: 54 * scale, height: 18 * scale)
                .blur(radius: 8 * scale)
                .offset(y: 29 * scale)

            VStack(spacing: -2 * scale) {
                head.zIndex(2)
                torso.zIndex(1)
            }
            .rotationEffect(.degrees(isCelebrating ? (dancePhase ? 8 : -8) : bodyTilt))
            .offset(y: isCelebrating && dancePhase ? -5 * scale : 0)
            .scaleEffect(isCelebrating && dancePhase ? 1.07 : 1.0)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli AI")
        .onAppear { startAmbientMotionIfNeeded() }
        .onChange(of: presenceState) { _, newState in
            guard !UIAccessibility.isReduceMotionEnabled else {
                dancePhase = false
                return
            }
            if newState == .celebration {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.52).repeatCount(7, autoreverses: true)) {
                    dancePhase.toggle()
                }
            }
        }
    }

    private func startAmbientMotionIfNeeded() {
        guard animated, !UIAccessibility.isReduceMotionEnabled else { return }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { eyePulse = true }
        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { bodyTilt = 1.2 }
    }

    private var head: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [MilliColors.cardBackground, MilliColors.cardBackground, Color.black], center: UnitPoint(x: 0.48, y: 0.38), startRadius: 1, endRadius: 25 * scale))
                .frame(width: 37 * scale, height: 37 * scale)
                .overlay { Circle().stroke(LinearGradient(colors: [MilliColors.chromeWhite, MilliColors.chromeMid, MilliColors.chromeDeep], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2.4 * scale) }
                .overlay { Circle().stroke(MilliColors.cyanGlow.opacity(isCelebrating ? 0.9 : 0.45), lineWidth: 0.7 * scale).padding(3 * scale) }
                .shadow(color: MilliColors.cyanGlow.opacity(isCelebrating ? 0.62 : 0.28), radius: 7 * scale)

            HStack(spacing: 7 * scale) { eye; eye }.offset(y: -1 * scale)

            Capsule(style: .continuous)
                .fill(isSpeaking ? MilliColors.cyanGlow.opacity(0.72) : Color.white.opacity(0.22))
                .frame(width: isSpeaking ? 10 * scale : 14 * scale, height: isSpeaking ? 2.2 * scale : 1.2 * scale)
                .offset(y: 9 * scale)

            earPod.offset(x: -21 * scale)
            earPod.offset(x: 21 * scale)
        }
    }

    private var eye: some View {
        Circle()
            .fill(MilliColors.cyanGlow)
            .frame(width: 4.6 * scale, height: 4.6 * scale)
            .shadow(color: MilliColors.cyanGlow.opacity(eyePulse || isCelebrating ? 0.95 : 0.55), radius: (eyePulse || isCelebrating ? 4.2 : 2.2) * scale)
    }

    private var earPod: some View {
        Capsule(style: .continuous)
            .fill(chromeGradient)
            .frame(width: 5.5 * scale, height: 14 * scale)
            .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 2.5 * scale)
    }

    private var torso: some View {
        ZStack {
            Capsule(style: .continuous).fill(chromeGradient).frame(width: 7 * scale, height: 24 * scale).rotationEffect(.degrees(isCelebrating ? (dancePhase ? 58 : 20) : 23)).offset(x: -20 * scale, y: isCelebrating ? -2 * scale : 2 * scale)
            Capsule(style: .continuous).fill(chromeGradient).frame(width: 7 * scale, height: 24 * scale).rotationEffect(.degrees(isCelebrating ? (dancePhase ? -20 : -58) : -23)).offset(x: 20 * scale, y: isCelebrating ? -2 * scale : 2 * scale)

            RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                .fill(LinearGradient(colors: [MilliColors.cardBackground, MilliColors.cardBackground, MilliColors.cardBackground], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 34 * scale, height: 28 * scale)
                .overlay { RoundedRectangle(cornerRadius: 10 * scale, style: .continuous).stroke(chromeGradient, lineWidth: 1.4 * scale) }
                .overlay(alignment: .top) { Capsule(style: .continuous).fill(MilliColors.cyanGlow.opacity(0.55)).frame(width: 17 * scale, height: 1.3 * scale).padding(.top, 4 * scale) }

            Image("MilliMLogo")
                .resizable().scaledToFit().frame(width: 15 * scale, height: 15 * scale)
                .blendMode(.screen).clipShape(Circle()).shadow(color: MilliColors.cyanGlow.opacity(0.25), radius: 2 * scale).offset(y: 1 * scale)

            HStack(spacing: 9 * scale) {
                Capsule(style: .continuous).fill(chromeGradient).frame(width: 9 * scale, height: 4 * scale)
                Capsule(style: .continuous).fill(chromeGradient).frame(width: 9 * scale, height: 4 * scale)
            }.offset(y: 17 * scale)
        }
        .frame(width: 58 * scale, height: 32 * scale)
    }

    private var chromeGradient: LinearGradient {
        LinearGradient(colors: [MilliColors.chromeWhite, MilliColors.chromeMid, MilliColors.chromeDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - MilliAIOrb

struct MilliAIOrb: View {
    @ObservedObject var presence: MilliPresence
    @State private var floatY: CGFloat = 2
    @State private var floatX: CGFloat = -1
    @State private var tilt: Double = -1.0

    var onTap: () -> Void = {}
    private let characterSize: CGFloat = 72

    var body: some View {
        Button(action: onTap) {
            MilliAICharacterView(size: characterSize, animated: true, presenceState: presence.state)
                .offset(x: floatX, y: floatY)
                .rotationEffect(.degrees(tilt))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: characterSize + 14, height: characterSize + 14)
        .accessibilityLabel("Open Milli AI")
        .onAppear {
            if !UIAccessibility.isReduceMotionEnabled {
                withAnimation(.easeInOut(duration: 2.7).repeatForever(autoreverses: true)) {
                    floatY = -4; floatX = 2; tilt = 1.1
                }
            }
        }
    }
}
