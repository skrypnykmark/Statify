import Foundation

enum SpotifyScripts {
    static let fieldSeparator = "|||"

    /// AppleScript renders reals using the current locale, so `1.5` can arrive as
    /// `1,5`. Normalise before handing the string to `Double`.
    static func decimal(from string: String) -> Double? {
        Double(string.replacingOccurrences(of: ",", with: "."))
    }

    static let readState = """
    if application "Spotify" is running then
        tell application "Spotify"
            set sState to "stopped"
            try
                set sState to (player state as text)
            end try
            set sPos to 0
            try
                set sPos to (player position as text)
            end try
            set sName to ""
            try
                set sName to (name of current track)
            end try
            set sArtist to ""
            try
                set sArtist to (artist of current track)
            end try
            set sAlbum to ""
            try
                set sAlbum to (album of current track)
            end try
            set sDur to 0
            try
                set sDur to (duration of current track as integer)
            end try
            set sID to ""
            try
                set sID to (id of current track as text)
            end try
            set sArt to ""
            try
                set sArt to (artwork url of current track as text)
            end try
            set sShuf to "false"
            try
                set sShuf to (shuffling as text)
            end try
            set sRep to "false"
            try
                set sRep to (repeating as text)
            end try
            set sVol to 70
            try
                set sVol to (round (sound volume))
            end try
            set sURI to ""
            try
                set sURI to (spotify url of current track as text)
            end try
            return "OK|||" & sState & "|||" & sPos & "|||" & sName & "|||" & sArtist & "|||" & sAlbum & "|||" & sDur & "|||" & sID & "|||" & sArt & "|||" & sShuf & "|||" & sRep & "|||" & sVol & "|||" & sURI
        end tell
    else
        return "NOTRUNNING"
    end if
    """

    static func command(_ command: TransportCommand) -> String {
        switch command {
        case .play:
            return guarded("tell application \"Spotify\" to play")
        case .pause:
            return guarded("tell application \"Spotify\" to pause")
        case .next:
            return guarded("tell application \"Spotify\" to next track")
        case .previous:
            return guarded("tell application \"Spotify\" to previous track")
        case .toggleShuffle:
            return """
            if application "Spotify" is running then
                tell application "Spotify"
                    if shuffling then
                        set shuffling to false
                    else
                        set shuffling to true
                    end if
                end tell
            end if
            """
        case .toggleRepeat:
            return """
            if application "Spotify" is running then
                tell application "Spotify"
                    if repeating then
                        set repeating to false
                    else
                        set repeating to true
                    end if
                end tell
            end if
            """
        case .seek(let seconds):
            let value = String(format: "%.3f", max(0, seconds))
            return guarded("tell application \"Spotify\" to set player position to \(value)")
        case .setVolume(let level):
            let value = Int((min(max(level, 0), 1) * 100).rounded())
            return guarded("tell application \"Spotify\" to set sound volume to \(value)")
        }
    }

    private static func guarded(_ body: String) -> String {
        """
        if application "Spotify" is running then
            \(body)
        end if
        """
    }
}
