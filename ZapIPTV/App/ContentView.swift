import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, live, sports, movies, series, favorites, settings

    var id: String { rawValue }

    var titleKey: String { "tab.\(rawValue)" }

    var icon: String {
        switch self {
        case .home:      return "house.fill"
        case .live:      return "tv.fill"
        case .sports:    return "sportscourt.fill"
        case .movies:    return "film.fill"
        case .series:    return "rectangle.stack.fill"
        case .favorites: return "star.fill"
        case .settings:  return "gearshape.fill"
        }
    }

    static var mainTabs: [AppTab] { [.home, .live, .sports, .movies, .series, .favorites] }
}

struct ContentView: View {
    @State private var sidebarVisible: NavigationSplitViewVisibility = .all
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var playerEngine: PlayerEngine
    @EnvironmentObject private var playback: PlaybackRouter
    @EnvironmentObject private var updater: UpdateChecker
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $sidebarVisible) {
                SidebarView(selectedTab: $playback.selectedTab)
            } detail: {
                ZStack {
                    ZapBackdrop()
                    switch playback.selectedTab {
                    case .home:      HomeView()
                    case .live:      LiveTVView()
                    case .sports:    SportsView()
                    case .movies:    MoviesView()
                    case .series:    SeriesView()
                    case .favorites: FavoritesView()
                    case .settings:  SettingsView()
                    }
                }
            }

            if let url = playback.overlayURL {
                InlinePlayerOverlay(
                    url: url,
                    title: playback.overlayTitle,
                    mirrorIndex: playback.overlayStreamIndex,
                    mirrorCount: max(1, playback.overlayStreamURLs.count)
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
        .background(WindowFSConfigurator(scheme: theme.theme.scheme))
        .onAppear { syncAppSidebar() }
        .onChange(of: playback.playerFullScreen) { _, _ in syncAppSidebar() }
        .onChange(of: playback.showAppSidebar) { _, _ in syncAppSidebar() }
        .onChange(of: playback.selectedTab) { _, tab in
            if tab == .live || tab == .sports {
                playback.showAppSidebar = false
            } else {
                playback.showAppSidebar = true
            }
            syncAppSidebar()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            playback.playerFullScreen = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            playback.playerFullScreen = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .zapOpenSettings)) { _ in
            playback.selectedTab = .settings
        }
    }

    private func syncAppSidebar() {
        let collapse = playback.playerFullScreen
            || ((playback.selectedTab == .live || playback.selectedTab == .sports) && !playback.showAppSidebar)
        withAnimation(.easeOut(duration: 0.2)) {
            sidebarVisible = collapse ? .detailOnly : .all
        }
    }
}

private struct InlinePlayerOverlay: View {
    let url: URL
    let title: String
    var mirrorIndex: Int = 0
    var mirrorCount: Int = 1
    @EnvironmentObject private var playerEngine: PlayerEngine
    @EnvironmentObject private var playback: PlaybackRouter
    @EnvironmentObject private var loc: LanguageManager

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if mirrorCount > 1 {
                        Text(String(format: loc.t("live.mirror"), mirrorIndex + 1, mirrorCount))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    Spacer()
                    Button {
                        playerEngine.stop()
                        playback.closeOverlay()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                ZStack {
                    VideoPlayerView(engine: playerEngine, onClose: {
                        playerEngine.stop()
                        playback.closeOverlay()
                    })

                    if let err = playerEngine.error {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(ZapColor.accentStart)
                            Text(err.localizedDescription)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            if mirrorIndex + 1 < mirrorCount {
                                Button {
                                    if let next = playback.advanceOverlayMirror() {
                                        playerEngine.load(url: next, connectTimeout: 20)
                                    }
                                } label: {
                    Text(loc.t("live.switching_hint"))
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(ZapColor.accentEnd, in: Capsule())
                        .foregroundColor(.white)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.55))
                    }
                }
            }
        }
        .onAppear { playerEngine.load(url: url, connectTimeout: 20) }
        .onChange(of: url) { _, newURL in
            playerEngine.load(url: newURL, connectTimeout: 20)
        }
        .onReceive(playerEngine.$error) { err in
            guard err != nil, mirrorIndex + 1 < mirrorCount else { return }
            // Auto-try next mirror once per failure
            if let next = playback.advanceOverlayMirror() {
                playerEngine.load(url: next, connectTimeout: 20)
            }
        }
        .onDisappear {
            if playback.overlayURL == nil {
                playerEngine.stop()
            }
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager
    @EnvironmentObject private var updater: UpdateChecker

    var body: some View {
        VStack(spacing: 0) {

            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                VStack(alignment: .leading, spacing: 1) {
                    Text("ZapIPTV")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(ZapColor.textPrimary)
                    Text(loc.t("tagline"))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(ZapColor.textTertiary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Fixed-height progress slot — never expands/collapses the sidebar layout.
            ZStack {
                if sourceManager.isLoading {
                    ProgressView(value: sourceManager.loadProgress)
                        .progressViewStyle(.linear)
                        .tint(ZapColor.accentEnd)
                        .scaleEffect(x: 1, y: 0.6, anchor: .center)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .opacity(sourceManager.isLoading ? 1 : 0)
            .animation(.easeOut(duration: 0.25), value: sourceManager.isLoading)

            Divider().background(ZapColor.border)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(AppTab.mainTabs) { tab in
                        SidebarItem(tab: tab, isSelected: selectedTab == tab) {
                            withAnimation(.easeOut(duration: 0.15)) { selectedTab = tab }
                        }
                    }
                }
                .padding(.top, 10)
            }

            Spacer()

            Divider().background(ZapColor.border)
            SidebarItem(tab: .settings, isSelected: selectedTab == .settings, badge: updater.hasUpdate) {
                selectedTab = .settings
            }
            .padding(.bottom, 8)
        }
        .zapGlassSurface()
        .frame(minWidth: 188, idealWidth: 204, maxWidth: 220)
    }
}

struct SidebarItem: View {
    let tab: AppTab
    let isSelected: Bool
    var badge: Bool = false
    let action: () -> Void
    @EnvironmentObject private var loc: LanguageManager
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(ZapColor.accent)
                            .frame(width: 28, height: 28)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .white : ZapColor.textSecondary)
                        .frame(width: 28, height: 28)
                }
                Text(loc.t(tab.titleKey))
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? ZapColor.textPrimary : ZapColor.textSecondary)
                Spacer()
                if badge {
                    Circle().fill(ZapColor.accentStart).frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                (isSelected ? ZapColor.accentStart.opacity(0.12) : (hovered ? ZapColor.hover : Color.clear)),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}
