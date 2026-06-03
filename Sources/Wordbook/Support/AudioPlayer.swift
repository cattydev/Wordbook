import AVFoundation
import Foundation

@MainActor
final class AudioPlayer {
    static let shared = AudioPlayer()

    private var player: AVPlayer?

    private init() {}

    func play(url: URL) {
        player = AVPlayer(url: url)
        player?.play()
    }
}
