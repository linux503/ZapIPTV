import SwiftUI

@MainActor
final class PlaybackRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var pendingLive: Channel?
    @Published var overlayURL: URL?
    @Published var overlayTitle: String = ""
    @Published var playerFullScreen = false

    func playLive(_ channel: Channel) {
        overlayURL = nil
        overlayTitle = ""
        pendingLive = channel
        selectedTab = .live
    }

    func playInline(url: URL, title: String) {
        pendingLive = nil
        overlayTitle = title
        overlayURL = url
    }

    func closeOverlay() {
        overlayURL = nil
        overlayTitle = ""
        playerFullScreen = false
        AppWindowFS.exit()
    }
}
