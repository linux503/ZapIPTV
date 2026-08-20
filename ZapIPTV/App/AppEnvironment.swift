import SwiftUI

@MainActor
final class PlaybackRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var pendingLive: Channel?
    @Published var overlayURL: URL?
    @Published var overlayTitle: String = ""
    @Published var overlayStreamURLs: [URL] = []
    @Published var overlayStreamIndex: Int = 0
    @Published var playerFullScreen = false
    /// App navigation sidebar; auto-hidden on Live tab for more player space.
    @Published var showAppSidebar = true

    func playLive(_ channel: Channel) {
        closeOverlay()
        pendingLive = channel
        showAppSidebar = false
        selectedTab = channel.group == "⚽ 体育" ? .sports : .live
    }

    func playInline(url: URL, title: String, backups: [URL] = []) {
        pendingLive = nil
        playerFullScreen = false
        overlayTitle = title
        var seen = Set<String>()
        var urls: [URL] = []
        for u in [url] + backups {
            if seen.insert(u.absoluteString).inserted { urls.append(u) }
        }
        overlayStreamURLs = urls
        overlayStreamIndex = 0
        // Clear then set on next runloop so sheet dismiss / nested buttons don't drop the update.
        overlayURL = nil
        let first = urls.first ?? url
        DispatchQueue.main.async { [weak self] in
            self?.overlayURL = first
        }
    }

    /// Try next mirror for overlay VOD / drama playback.
    @discardableResult
    func advanceOverlayMirror() -> URL? {
        let next = overlayStreamIndex + 1
        guard next < overlayStreamURLs.count else { return nil }
        overlayStreamIndex = next
        let url = overlayStreamURLs[next]
        overlayURL = url
        return url
    }

    func closeOverlay() {
        overlayURL = nil
        overlayTitle = ""
        overlayStreamURLs = []
        overlayStreamIndex = 0
        playerFullScreen = false
        AppWindowFS.exit()
    }
}
