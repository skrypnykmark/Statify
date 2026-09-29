import Foundation

struct PlaybackState: Equatable {
    var isRunning: Bool
    var isPlaying: Bool
    var trackID: String
    var name: String
    var artist: String
    var album: String
    var duration: Double
    var position: Double
    var volume: Double
    var artworkURL: URL?
    var songURI: String
    var isShuffling: Bool
    var isRepeating: Bool

    static let notRunning = PlaybackState(
        isRunning: false,
        isPlaying: false,
        trackID: "",
        name: "",
        artist: "",
        album: "",
        duration: 0,
        position: 0,
        volume: 0.7,
        artworkURL: nil,
        songURI: "",
        isShuffling: false,
        isRepeating: false
    )

    var hasTrack: Bool { !trackID.isEmpty || !name.isEmpty }
}
