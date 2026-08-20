import SwiftUI

@MainActor
final class PlaybackRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var pendingLive: Channel?
    @Published var overlayURL: URL?
    @Published var overlayTitle: String = ""
    @Published var playerFullScreen = false
  /// App navigation sidebar; auto-hidden on Live tab for more player space.
    @Published var showAppSidebar = true

    func playLive(_ channel: Channel) {
        overlayURL = nil
        overlayTitle = ""
        pendingLive = channel
        showAppSidebar = false
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
