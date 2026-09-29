import SwiftUI

@main
struct StatifyApp: App {
    @StateObject private var coordinator: PlaybackCoordinator

    init() {
        let coordinator = PlaybackCoordinator()
        coordinator.start()
        _coordinator = StateObject(wrappedValue: coordinator)
    }

    var body: some Scene {
        MenuBarExtra {
            NowPlayingPanel(coordinator: coordinator)
        } label: {
            MenuBarLabel(coordinator: coordinator)
        }
        .menuBarExtraStyle(.window)
    }
}
