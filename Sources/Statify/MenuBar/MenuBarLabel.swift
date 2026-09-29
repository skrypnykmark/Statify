import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var coordinator: PlaybackCoordinator

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            if coordinator.showTrackInMenuBar, coordinator.state.hasTrack {
                Text(shortTitle)
            }
        }
        .accessibilityLabel("Statify")
    }

    private var symbol: String {
        if !coordinator.state.isRunning { return "music.note.list" }
        return coordinator.state.isPlaying ? "music.note" : "pause.circle"
    }

    private var shortTitle: String {
        let name = coordinator.state.name
        return name.count > 18 ? String(name.prefix(17)) + "\u{2026}" : name
    }
}
