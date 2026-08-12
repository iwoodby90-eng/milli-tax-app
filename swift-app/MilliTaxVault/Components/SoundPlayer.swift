import AVFoundation

final class SoundPlayer {
    static let shared = SoundPlayer()
    private var player: AVAudioPlayer?

    private init() {}

    func playThunder() {
        guard let url = Bundle.main.url(forResource: "thunder", withExtension: "mp3") else {
            print("Thunder sound not found in bundle.")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.9
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Failed to play thunder: \(error)")
        }
    }
}
