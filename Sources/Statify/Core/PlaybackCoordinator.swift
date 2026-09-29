import AppKit
import Foundation

@MainActor
final class PlaybackCoordinator: ObservableObject {
    @Published private(set) var state: PlaybackState = .notRunning
    @Published private(set) var permissionBlocked = false

    @Published var showTrackInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showTrackInMenuBar, forKey: Keys.showTrack) }
    }

    @Published var launchAtLogin: Bool {
        didSet { LaunchAtLogin.set(launchAtLogin) }
    }

    let artwork = ArtworkLoader()

    private enum Keys {
        static let showTrack = "showTrackInMenuBar"
    }

    private let client = AppleScriptSpotifyClient()
    private var ticker: Timer?
    private var tickCount = 0
    private var isRefreshing = false
    private var isAdjustingVolume = false
    private var volumeTask: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []
    private var pendingCommandCount = 0

    init() {
        showTrackInMenuBar = UserDefaults.standard.bool(forKey: Keys.showTrack)
        launchAtLogin = LaunchAtLogin.isEnabled
        observeSpotify()
    }

    deinit {
        ticker?.invalidate()
        volumeTask?.cancel()
        let distributed = DistributedNotificationCenter.default()
        let workspace = NSWorkspace.shared.notificationCenter
        for observer in observers {
            distributed.removeObserver(observer)
            workspace.removeObserver(observer)
        }
    }

    func start() {
        Task { await refresh() }
        ticker?.invalidate()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    // MARK: - Transport

    func togglePlayPause() {
        guard state.isRunning else { return }
        let shouldPlay = !state.isPlaying
        state.isPlaying = shouldPlay
        send(shouldPlay ? .play : .pause)
    }

    func next() {
        guard state.isRunning else { return }
        state.position = 0
        send(.next)
    }

    func previous() {
        guard state.isRunning else { return }
        state.position = 0
        send(.previous)
    }

    func seek(to seconds: Double) {
        guard state.isRunning else { return }
        state.position = min(max(seconds, 0), state.duration)
        send(.seek(seconds))
    }

    func toggleShuffle() {
        guard state.isRunning else { return }
        state.isShuffling.toggle()
        send(.toggleShuffle)
    }

    func toggleRepeat() {
        guard state.isRunning else { return }
        state.isRepeating.toggle()
        send(.toggleRepeat)
    }

    func setVolume(_ level: Double) {
        guard state.isRunning else { return }
        isAdjustingVolume = true
        state.volume = min(max(level, 0), 1)
        volumeTask?.cancel()
        let target = state.volume
        volumeTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 60_000_000)
            guard !Task.isCancelled, let self else { return }
            try? await self.client.send(.setVolume(target))
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            self.isAdjustingVolume = false
            await self.refresh()
        }
    }

    func launchSpotify() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client") else {
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { [weak self] _, _ in
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await self?.refresh()
            }
        }
    }

    func openCurrentTrackInSpotify() {
        var uri = state.songURI
        if uri.isEmpty, !state.trackID.isEmpty {
            uri = state.trackID.hasPrefix("spotify:") ? state.trackID : "spotify:track:\(state.trackID)"
        }
        guard !uri.isEmpty, let url = URL(string: uri) else { return }
        NSWorkspace.shared.open(url)
    }

    func quit() {
        NSApp.terminate(nil)
    }

    func openAutomationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Refresh loop

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            apply(try await client.fetchState())
            permissionBlocked = false
        } catch let error as SpotifyError where error.isPermissionFailure {
            permissionBlocked = true
            state.isRunning = spotifyIsRunning
        } catch {
            // Transient AppleScript failures are ignored; the next tick retries.
        }
    }

    private var spotifyIsRunning: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.spotify.client" }
    }

    private func send(_ command: TransportCommand) {
        pendingCommandCount += 1
        Task { [weak self] in
            guard let self else { return }
            defer {
                self.pendingCommandCount = max(0, self.pendingCommandCount - 1)
            }
            try? await self.client.send(command)
            try? await Task.sleep(nanoseconds: 250_000_000)
            await self.refresh()
        }
    }

    private func tick() {
        tickCount += 1
        if state.isRunning, state.isPlaying, state.duration > 0 {
            state.position = min(state.position + 0.5, state.duration)
        }
        if tickCount % 4 == 0 {
            Task { await refresh() }
        }
    }

    private func apply(_ new: PlaybackState) {
        var incoming = new
        if isAdjustingVolume, incoming.isRunning, state.isRunning {
            incoming.volume = state.volume
        }

        if pendingCommandCount > 0, incoming.isRunning, state.isRunning, incoming.trackID == state.trackID {
            incoming.isPlaying = state.isPlaying
            incoming.isShuffling = state.isShuffling
            incoming.isRepeating = state.isRepeating
        }

        // The local ticker interpolates position between polls. A poll returns a
        // coarser value, so only snap when it genuinely disagrees (a seek, a
        // skip, or clock drift) instead of yanking the displayed time backwards
        // every two seconds.
        if incoming.isRunning, state.isRunning,
           incoming.trackID == state.trackID,
           incoming.isPlaying, state.isPlaying,
           abs(incoming.position - state.position) < 2 {
            incoming.position = state.position
        }

        let trackChanged = incoming.trackID != state.trackID
        state = incoming

        if incoming.isRunning, incoming.hasTrack {
            if trackChanged || artwork.image == nil {
                artwork.load(url: incoming.artworkURL, key: incoming.trackID.isEmpty ? incoming.name : incoming.trackID)
            }
        } else {
            artwork.clear()
        }
    }

    // MARK: - Notifications

    private func observeSpotify() {
        let distributed = DistributedNotificationCenter.default()
        let playback = Notification.Name("com.spotify.client.PlaybackStateChanged")
        observers.append(
            distributed.addObserver(forName: playback, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in await self?.refresh() }
            }
        )

        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
            observers.append(
                workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                    guard
                        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                        app.bundleIdentifier == "com.spotify.client"
                    else { return }
                    Task { @MainActor in await self?.refresh() }
                }
            )
        }
    }
}
