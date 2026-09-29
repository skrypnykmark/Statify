import AppKit
import SwiftUI

struct TransportButton: View {
    let systemName: String
    var size: CGFloat = 15
    var isActive = false
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: size * 2, height: size * 1.6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(tooltip)
        .accessibilityLabel(tooltip)
    }

    private var color: Color {
        if isActive { return Theme.green }
        return hovering ? Theme.textPrimary : Theme.textSecondary
    }

    private var tooltip: String {
        switch systemName {
        case "shuffle": return "Shuffle"
        case "backward.end.fill": return "Previous"
        case "forward.end.fill": return "Next"
        case "repeat": return "Repeat"
        default: return systemName
        }
    }
}

struct PlayPauseButton: View {
    let isPlaying: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(hovering ? Theme.green : Theme.textPrimary)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.background)
                    .offset(x: isPlaying ? 0 : 1.5)
            }
            .frame(width: Metrics.playButtonSize, height: Metrics.playButtonSize)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }
}

struct SeekBar: View {
    let position: Double
    let duration: Double
    let onSeek: (Double) -> Void

    @State private var dragValue: Double?
    @State private var hovering = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let current = dragValue ?? position
            let fraction = duration > 0 ? min(max(current / duration, 0), 1) : 0

            ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.track)
                        .frame(height: 4)
                    Capsule()
                        .fill(hovering || dragValue != nil ? Theme.green : Theme.textPrimary)
                        .frame(width: max(0, width * fraction), height: 4)
                Circle()
                    .fill(Theme.textPrimary)
                    .frame(width: 10, height: 10)
                    .offset(x: width * fraction - 5)
                    .opacity(hovering || dragValue != nil ? 1 : 0)
                    .shadow(color: .black.opacity(0.4), radius: 1, y: 0.5)
            }
            .frame(height: 14)
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard width > 0 else { return }
                        dragValue = min(max(value.location.x / width, 0), 1) * duration
                    }
                    .onEnded { value in
                        guard width > 0 else { return }
                        let target = min(max(value.location.x / width, 0), 1) * duration
                        dragValue = nil
                        onSeek(target)
                    }
            )
            .onHover { hovering = $0 }
        }
        .frame(height: 14)
    }
}

struct VolumeControl: View {
    let value: Double
    let onChange: (Double) -> Void

    @State private var dragValue: Double?
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6) {
            Button(action: toggleMute) {
                Image(systemName: glyph)
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(hovering || value > 0 ? Theme.textPrimary : Theme.textSecondary)
            .help(value > 0 ? "Mute" : "Unmute")
            .accessibilityLabel(value > 0 ? "Mute" : "Unmute")

            GeometryReader { geometry in
                let width = geometry.size.width
                let current = dragValue ?? value
                let fraction = min(max(current, 0), 1)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.track)
                        .frame(height: 4)
                    Capsule()
                        .fill(hovering || dragValue != nil ? Theme.green : Theme.textPrimary)
                        .frame(width: max(0, width * fraction), height: 4)
                    Circle()
                        .fill(Theme.textPrimary)
                        .frame(width: 9, height: 9)
                        .offset(x: width * fraction - 4.5)
                        .opacity(hovering || dragValue != nil ? 1 : 0)
                        .shadow(color: .black.opacity(0.4), radius: 1, y: 0.5)
                }
                .frame(height: 12)
                .frame(maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged {
                            guard width > 0 else { return }
                            dragValue = min(max($0.location.x / width, 0), 1)
                        }
                        .onEnded { gesture in
                            guard width > 0 else { return }
                            let target = min(max(gesture.location.x / width, 0), 1)
                            dragValue = nil
                            onChange(target)
                        }
                )
                .onHover { hovering = $0 }
            }
            .frame(height: 12)
        }
    }

    private var glyph: String {
        if value <= 0 { return "speaker.slash.fill" }
        if value < 0.34 { return "speaker.fill" }
        if value < 0.67 { return "speaker.wave.1.fill" }
        return "speaker.wave.2.fill"
    }

    private func toggleMute() {
        onChange(value > 0 ? 0 : 0.7)
    }
}

struct FooterTextButton: View {
    let title: String
    var hoverColor: Color = Theme.textPrimary
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(hovering ? hoverColor : Theme.textSecondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct FooterIconButton: View {
    let systemName: String
    var hoverColor: Color = Theme.textPrimary
    let label: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(hovering ? hoverColor : Theme.textSecondary)
                .padding(2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(label)
        .accessibilityLabel(label)
    }
}

struct ArtworkView: View {
    let image: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                .fill(Theme.surfaceRaised)
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: Metrics.artworkSize, height: Metrics.artworkSize)
        .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
    }
}
