import AppKit
import SwiftUI

@MainActor
final class ArtworkLoader: ObservableObject {
    @Published private(set) var image: NSImage?

    private let cache = NSCache<NSString, NSImage>()
    private var task: Task<Void, Never>?
    private var key = ""

    func load(url: URL?, key newKey: String) {
        if newKey == key, image != nil { return }

        if let cached = cache.object(forKey: newKey as NSString) {
            key = newKey
            image = cached
            return
        }

        key = newKey
        task?.cancel()

        guard let url, !newKey.isEmpty else {
            image = nil
            return
        }
        image = nil

        task = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let downloaded = NSImage(data: data) else { return }
                guard let self else { return }
                self.cache.setObject(downloaded, forKey: newKey as NSString)
                if self.key == newKey {
                    self.image = downloaded
                }
            } catch {
                // Keep the placeholder on failure.
            }
        }
    }

    func clear() {
        task?.cancel()
        key = ""
        image = nil
    }
}
