import AppKit
import Foundation

enum SpotifyError: LocalizedError {
    case scriptCompilation
    case appleScript(message: String, number: Int)
    case unexpectedOutput

    var errorDescription: String? {
        switch self {
        case .scriptCompilation:
            return "Could not compile the AppleScript."
        case .appleScript(let message, _):
            return message.isEmpty ? "Spotify returned an AppleScript error." : message
        case .unexpectedOutput:
            return "Spotify returned an unexpected response."
        }
    }

    var isPermissionFailure: Bool {
        guard case .appleScript(let message, let number) = self else { return false }
        return number == -1743 || number == -1744
            || message.localizedCaseInsensitiveContains("not authorized")
            || message.localizedCaseInsensitiveContains("not allowed")
    }
}

final class AppleScriptSpotifyClient: NowPlayingSource {
    private let queue = DispatchQueue(label: "com.statify.Statify.applescript")

    func fetchState() async throws -> PlaybackState {
        let output = try await run(SpotifyScripts.readState).stringValue ?? ""
        if output == "NOTRUNNING" {
            return .notRunning
        }
        let fields = output.components(separatedBy: SpotifyScripts.fieldSeparator)
        guard fields.first == "OK", fields.count >= 13 else {
            throw SpotifyError.unexpectedOutput
        }

        let durationMilliseconds = SpotifyScripts.decimal(from: fields[6]) ?? 0
        let artwork = fields[8].trimmingCharacters(in: .whitespacesAndNewlines)

        return PlaybackState(
            isRunning: true,
            isPlaying: fields[1].lowercased() == "playing",
            trackID: fields[7],
            name: fields[3],
            artist: fields[4],
            album: fields[5],
            duration: durationMilliseconds / 1000,
            position: SpotifyScripts.decimal(from: fields[2]) ?? 0,
            volume: (SpotifyScripts.decimal(from: fields[11]) ?? 70) / 100,
            artworkURL: artwork.hasPrefix("http") ? URL(string: artwork) : nil,
            songURI: fields[12],
            isShuffling: fields[9].lowercased() == "true",
            isRepeating: fields[10].lowercased() == "true"
        )
    }

    func send(_ command: TransportCommand) async throws {
        _ = try await run(SpotifyScripts.command(command))
    }

    @discardableResult
    func run(_ source: String) async throws -> NSAppleEventDescriptor {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                guard let script = NSAppleScript(source: source) else {
                    continuation.resume(throwing: SpotifyError.scriptCompilation)
                    return
                }
                var error: NSDictionary?
                let result = script.executeAndReturnError(&error)
                if let error {
                    let message = (error[NSAppleScript.errorMessage] as? String) ?? ""
                    let number = (error[NSAppleScript.errorNumber] as? Int) ?? 0
                    continuation.resume(throwing: SpotifyError.appleScript(message: message, number: number))
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }
}
