import SwiftUI

struct NowPlayingPanel: View {
    @ObservedObject var coordinator: PlaybackCoordinator
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showSettings {
                SettingsPanel(coordinator: coordinator) { showSettings = false }
            } else {
                content
            }
        }
        .padding(14)
        .frame(width: Metrics.panelWidth)
        .background(Theme.background)
    }

    @ViewBuilder
    private var content: some View {
        if coordinator.permissionBlocked {
            EmptyStateView(
                icon: "lock.fill",
                title: "Allow Statify to control Spotify",
                message: "Enable Statify under System Settings \u{203A} Privacy & Security \u{203A} Automation, then reopen this menu.",
                actionTitle: "Open System Settings",
                action: coordinator.openAutomationSettings
            )
        } else if !coordinator.state.isRunning {
            EmptyStateView(
                icon: "music.note",
                title: "Spotify isn't running",
                message: "Open Spotify to see and control playback.",
                actionTitle: "Launch Spotify",
                action: coordinator.launchSpotify
            )
        } else if !coordinator.state.hasTrack {
            EmptyStateView(
                icon: "pause.circle",
                title: "Nothing playing",
                message: "Start a track in Spotify.",
                actionTitle: nil,
                action: {}
            )
        } else {
            header
            controls
            timeline
        }

        if !showSettings {
            footer
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ArtworkView(image: coordinator.artwork.image)

            VStack(alignment: .leading, spacing: 2) {
                Text(coordinator.state.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
    }

    private var controls: some View {
        HStack(spacing: 4) {
            Spacer(minLength: 0)
            TransportButton(systemName: "shuffle", size: 13, isActive: coordinator.state.isShuffling) {
                coordinator.toggleShuffle()
            }
            Spacer(minLength: 8)
            TransportButton(systemName: "backward.end.fill", size: 15) {
                coordinator.previous()
            }
            Spacer(minLength: 8)
            PlayPauseButton(isPlaying: coordinator.state.isPlaying) {
                coordinator.togglePlayPause()
            }
            Spacer(minLength: 8)
            TransportButton(systemName: "forward.end.fill", size: 15) {
                coordinator.next()
            }
            Spacer(minLength: 8)
            TransportButton(systemName: "repeat", size: 13, isActive: coordinator.state.isRepeating) {
                coordinator.toggleRepeat()
            }
            Spacer(minLength: 0)
        }
    }

    private var timeline: some View {
        HStack(spacing: 8) {
            Text(TimeFormatting.string(from: coordinator.state.position))
            SeekBar(
                position: coordinator.state.position,
                duration: coordinator.state.duration
            ) { coordinator.seek(to: $0) }
            Text(TimeFormatting.string(from: coordinator.state.duration))
        }
        .font(.system(size: 10, weight: .medium).monospacedDigit())
        .foregroundStyle(Theme.textSecondary)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            VolumeControl(value: coordinator.state.volume) { coordinator.setVolume($0) }
                .frame(width: 88)

            Spacer(minLength: 8)

            FooterIconButton(systemName: "arrow.up.forward.app", label: "Open in Spotify") {
                coordinator.openCurrentTrackInSpotify()
            }

            FooterTextButton(title: "Quit", hoverColor: .red) {
                coordinator.quit()
            }
        }
        .padding(.top, 2)
    }

    private var subtitle: String {
        let artist = coordinator.state.artist
        let album = coordinator.state.album
        if artist.isEmpty { return album }
        if album.isEmpty { return artist }
        return "\(artist) \u{2022} \(album)"
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(Theme.textSecondary)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.background)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.green))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

enum TimeFormatting {
    static func string(from seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}
