import SwiftUI

struct SettingsPanel: View {
    @ObservedObject var coordinator: PlaybackCoordinator
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Settings")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button(action: onClose) {
                    Text("Done")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.green)
                }
                .buttonStyle(.plain)
            }

            Toggle(isOn: $coordinator.showTrackInMenuBar) {
                settingLabel("Show track in menu bar")
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Toggle(isOn: $coordinator.launchAtLogin) {
                settingLabel("Launch at login")
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Divider().overlay(Theme.surfaceRaised)

            HStack {
                Text("Statify 0.1.0")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
                Spacer()
                Button(action: coordinator.quit) {
                    Text("Quit")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func settingLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(Theme.textSecondary)
    }
}
