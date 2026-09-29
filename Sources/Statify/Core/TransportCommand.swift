import Foundation

enum TransportCommand {
    case play
    case pause
    case next
    case previous
    case seek(TimeInterval)
    case setVolume(Double)
    case toggleShuffle
    case toggleRepeat
}
