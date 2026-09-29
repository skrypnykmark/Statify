import Foundation

/// Abstraction over a playback backend so alternative implementations
/// (for example the Spotify Web API) can be added without touching the UI.
protocol NowPlayingSource {
    func fetchState() async throws -> PlaybackState
    func send(_ command: TransportCommand) async throws
}
