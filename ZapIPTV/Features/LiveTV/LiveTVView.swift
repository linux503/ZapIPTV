import SwiftUI
import AVKit

struct LiveTVView: View {
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var playerEngine: PlayerEngine
    @EnvironmentObject private var playback: PlaybackRouter
    @EnvironmentObject private var loc: LanguageManager
    @State private var selectedGroup = "🇨🇳 中国大陆"
    @State private var selectedChannel: Channel?
    @State private var searchText = ""
    @State private var showChannelList = true
    @State private var groupCounts: [String: Int] = [:]
    @State private var failedChannelIDs: Set<String> = []
    @State private var locateToken = 0
    @State private var streamURLs: [URL] = []
    @State private var streamIndex = 0
    @State private var mirrorLabel = ""
    @State private var isPreparingStream = false
    @State private var isSwitchingMirror = false

    private static let asianGroupOrder = [
        "🇨🇳 中国大陆", "🎬 华语影视", "🎆 春晚", "🇹🇼 台湾", "🇭🇰 香港",
        "🇯🇵 日本", "🇰🇷 韩国", "🇹🇭 泰国", "🇻🇳 越南",
        "🇮🇩 印尼", "🇲🇾 马来西亚", "🇸🇬 新加坡", "🇵🇭 菲律宾", "🇮🇳 印度",
    ]

    var groups: [String] {
        let available = Set(sourceManager.channelGroups)
        let ordered = Self.asianGroupOrder.filter { available.contains($0) }
        return ordered.isEmpty ? ["🇨🇳 中国大陆"] : ordered
    }

    func countForGroup(_ group: String) -> Int {
        groupCounts[group] ?? 0
    }

    var filteredChannels: [Channel] {
        var list = sourceManager.channels(inGroup: selectedGroup)
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── Channel list (category + channels in one panel) ──
            if showChannelList && !playback.playerFullScreen {
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        appSidebarToggleButton()
                        Spacer(minLength: 0)
                        if selectedChannel != nil {
                            Button(action: locateCurrent) {
                                Image(systemName: "location.viewfinder")
                                    .font(.system(size: 13))
                                    .foregroundColor(ZapColor.accentStart)
                                    .frame(width: 32, height: 32)
                                    .background(ZapColor.accentStart.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .help(loc.t("live.locate"))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                    LiveCategoryPicker(
                        groups: groups,
                        selectedGroup: $selectedGroup,
                        countForGroup: { countForGroup($0) }
                    )
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)

                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ZapColor.textTertiary)
                            .font(.system(size: 13))
                        TextField(loc.t("live.search"), text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(ZapColor.textPrimary)
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .zapGlassInset(cornerRadius: 8)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)

                    // Loading banner
                    if sourceManager.isLoading {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.7).tint(ZapColor.accentEnd)
                            Text(sourceManager.loadingMessage)
                                .font(.system(size: 11))
                                .foregroundColor(ZapColor.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 12).padding(.bottom, 6)
                    }

                    if let err = sourceManager.loadError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange).font(.system(size: 11))
                            Text(err)
                                .font(.system(size: 11)).foregroundColor(.orange)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 12).padding(.bottom, 6)
                    }

                    if filteredChannels.isEmpty && !sourceManager.isLoading {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 32)).foregroundColor(ZapColor.textTertiary)
                            Text(sourceManager.sources.isEmpty
                                 ? loc.t("live.add_source_hint")
                                 : loc.t("live.no_channels"))
                                .font(.system(size: 13)).foregroundColor(ZapColor.textSecondary)
                        }
                        Spacer()
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredChannels) { ch in
                                        ChannelListRow(
                                            channel: ch,
                                            isPlaying: selectedChannel?.id == ch.id,
                                            onFavorite: { sourceManager.toggleFavorite(channelId: ch.id) }
                                        )
                                            .id(ch.id)
                                            .background(
                                                selectedChannel?.id == ch.id
                                                ? ZapColor.accentStart.opacity(0.2)
                                                : Color.clear
                                            )
                                            .contentShape(Rectangle())
                                            .onTapGesture { playChannel(ch) }
                                            .padding(.horizontal, 8)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onChange(of: locateToken) { _, _ in
                                scrollToCurrent(proxy)
                            }
                        }
                    }
                }
                .frame(width: 196)
                .zapGlassSurface()

                Divider().background(ZapColor.hairline)
            }

            // ── Player area (fills remaining space) ──
            ZStack {
                Color.black

                if let channel = selectedChannel {
                    VStack(spacing: 0) {
                        // Player fills all available height
                        ZStack {
                            VideoPlayerView(engine: playerEngine)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                            if showLiveStatusOverlay {
                                liveStatusOverlay
                            }

                            if showLiveErrorOverlay, let err = playerEngine.error {
                                VStack(spacing: 14) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 36)).foregroundColor(.orange)
                                    Text(loc.t("live.unavailable"))
                                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                    Text(err.localizedDescription)
                                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                                    Button(loc.t("live.try_next")) { playNext() }
                                        .buttonStyle(.plain)
                                        .foregroundColor(ZapColor.accentStart)
                                        .padding(.horizontal, 20).padding(.vertical, 8)
                                        .background(ZapColor.accentStart.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                                }
                                .padding(30)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        if !playback.playerFullScreen {
                        // Channel info bar
                        HStack(spacing: 12) {
                            ChannelLogoView(channel: channel, width: 52, height: 34, cornerRadius: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(channel.name)
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(ZapColor.textPrimary)
                                HStack(spacing: 6) {
                                    Text(channel.group)
                                        .font(.system(size: 11)).foregroundColor(ZapColor.textTertiary)
                                    if !mirrorLabel.isEmpty {
                                        Text("·")
                                            .font(.system(size: 11)).foregroundColor(ZapColor.textTertiary)
                                        Text(mirrorLabel)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(ZapColor.accentStart)
                                    }
                                }
                            }
                            Spacer()

                            if playerEngine.isPlaying {
                                HStack(spacing: 4) {
                                    Circle().fill(ZapColor.live).frame(width: 6, height: 6)
                                    Text("LIVE").font(.system(size: 10, weight: .bold))
                                        .foregroundColor(ZapColor.live)
                                }
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(ZapColor.live.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                            }

                            appSidebarToggleButton()

                            // Toggle channel list
                            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showChannelList.toggle() } }) {
                                Image(systemName: showChannelList ? "sidebar.left" : "sidebar.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(ZapColor.textSecondary)
                                    .padding(6)
                                    .zapGlassInset(cornerRadius: 6)
                            }
                            .buttonStyle(.plain)
                            .help(showChannelList ? loc.t("live.hide_list") : loc.t("live.show_list"))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .zapGlassSurface()
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 20) {
                        if sourceManager.isLoading {
                            VStack(spacing: 14) {
                                ProgressView().progressViewStyle(.circular)
                                    .scaleEffect(1.5).tint(ZapColor.accentStart)
                                Text(sourceManager.loadingMessage.isEmpty
                                     ? loc.t("live.connecting") : sourceManager.loadingMessage)
                                    .font(.system(size: 15)).foregroundColor(.white.opacity(0.6))
                            }
                        } else {
                            Image(systemName: "tv")
                                .font(.system(size: 56)).foregroundColor(.white.opacity(0.1))
                            Text(loc.t("live.select"))
                                .font(.system(size: 18, weight: .medium)).foregroundColor(.white.opacity(0.4))
                            if !filteredChannels.isEmpty {
                                Text(String(format: loc.t("live.count"), filteredChannels.count))
                                    .font(.system(size: 13)).foregroundColor(.white.opacity(0.25))
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(ZapBackdrop())
        .onAppear {
            recomputeGroupCounts()
            ensureValidGroup()
            consumePendingLive()
        }
        .onChange(of: sourceManager.channels.count) { _, _ in
            recomputeGroupCounts()
            ensureValidGroup()
        }
        .onChange(of: playback.pendingLive?.id) { _ in consumePendingLive() }
        .onChange(of: playerEngine.isPlaying) { _, playing in
            if playing {
                isSwitchingMirror = false
                isPreparingStream = false
            }
        }
        .onChange(of: playerEngine.error?.localizedDescription) { _ in
            guard playerEngine.error != nil, let ch = selectedChannel else { return }
            // Try next mirror of the same channel before skipping to another channel
            if streamIndex + 1 < streamURLs.count {
                beginMirrorSwitch()
                playerEngine.error = nil
                streamIndex += 1
                loadStream(at: streamIndex, for: ch)
                return
            }
            isSwitchingMirror = false
            isPreparingStream = false
            failedChannelIDs.insert(ch.id)
            playNext()
        }
    }

    private var showLiveStatusOverlay: Bool {
        (isPreparingStream || isSwitchingMirror || playerEngine.isBuffering)
            && playerEngine.error == nil
    }

    private var showLiveErrorOverlay: Bool {
        playerEngine.error != nil && !isSwitchingMirror && !isPreparingStream
    }

    private var liveStatusOverlay: some View {
        let switching = isSwitchingMirror || streamIndex > 0
        return VStack(spacing: 12) {
            ProgressView().progressViewStyle(.circular)
                .scaleEffect(1.35).tint(.white)
            Text(loc.t(switching ? "live.switching" : "live.connecting"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Text(loc.t(switching ? "live.switching_hint" : "live.connecting_hint"))
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
            if !mirrorLabel.isEmpty {
                Text(mirrorLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ZapColor.accentStart)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .background(.ultraThinMaterial.opacity(0.92), in: RoundedRectangle(cornerRadius: 14))
    }

    private func beginMirrorSwitch() {
        isSwitchingMirror = true
        isPreparingStream = true
    }

    private func consumePendingLive() {
        guard let ch = playback.pendingLive else { return }
        playback.pendingLive = nil
        if groups.contains(ch.group) {
            selectedGroup = ch.group
        }
        playChannel(ch)
    }

    private func recomputeGroupCounts() {
        var counts: [String: Int] = [:]
        for ch in sourceManager.channels {
            let key = ch.group
            if key == "🇨🇳 中国大陆", !ChinesePlaylist.isMainlandChannel(ch.name) { continue }
            counts[key, default: 0] += 1
        }
        groupCounts = counts
    }

    private func ensureValidGroup() {
        if countForGroup(selectedGroup) > 0 { return }
        if let first = groups.first(where: { countForGroup($0) > 0 }) {
            selectedGroup = first
        }
    }

    private func playChannel(_ ch: Channel) {
        selectedChannel = ch
        sourceManager.markWatched(ch)
        locateToken += 1
        streamURLs = ch.allStreamURLs
        streamIndex = 0
        isSwitchingMirror = false
        isPreparingStream = true
        loadStream(at: 0, for: ch)
    }

    private func loadStream(at index: Int, for ch: Channel) {
        guard index < streamURLs.count else {
            isSwitchingMirror = false
            isPreparingStream = false
            failedChannelIDs.insert(ch.id)
            playNext()
            return
        }
        if index > 0 { beginMirrorSwitch() }
        else { isPreparingStream = true }

        let url = streamURLs[index]
        mirrorLabel = streamURLs.count > 1
            ? String(format: loc.t("live.mirror"), index + 1, streamURLs.count)
            : ""
        Task { @MainActor in
            let kind = await StreamProbe.check(url)
            guard selectedChannel?.id == ch.id, streamIndex == index else { return }
            if kind == .flv || kind == .html || kind == .dead {
                if index + 1 < streamURLs.count {
                    beginMirrorSwitch()
                    streamIndex = index + 1
                    loadStream(at: streamIndex, for: ch)
                } else {
                    isSwitchingMirror = false
                    isPreparingStream = false
                    failedChannelIDs.insert(ch.id)
                    playerEngine.error = kind == .flv
                        ? PlaybackError.unsupportedFormat
                        : PlaybackError.unreachable
                }
                return
            }
            // Hand off to AVPlayer — keep preparing until buffering/playing updates
            isPreparingStream = true
            playerEngine.load(url: url)
        }
    }

    private func locateCurrent() {
        guard let ch = selectedChannel else { return }
        searchText = ""
        if groups.contains(ch.group) {
            selectedGroup = ch.group
        }
        locateToken += 1
    }

    private func scrollToCurrent(_ proxy: ScrollViewProxy) {
        guard let id = selectedChannel?.id else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }

    @ViewBuilder
    private func appSidebarToggleButton() -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                playback.showAppSidebar.toggle()
            }
        } label: {
            Image(systemName: playback.showAppSidebar ? "sidebar.left" : "line.3.horizontal")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(playback.showAppSidebar ? ZapColor.textSecondary : ZapColor.accentStart)
                .frame(width: 32, height: 32)
                .zapGlassInset(cornerRadius: 8)
        }
        .buttonStyle(.plain)
        .help(playback.showAppSidebar ? loc.t("live.hide_menu") : loc.t("live.show_menu"))
    }

    private func playNext() {
        let list = filteredChannels.filter { !failedChannelIDs.contains($0.id) }
        guard !list.isEmpty else { return }
        if let current = selectedChannel,
           let idx = list.firstIndex(where: { $0.id == current.id }) {
            playChannel(list[(idx + 1) % list.count])
            return
        }
        playChannel(list[0])
    }
}

// MARK: - Category picker (expandable 2-column icon grid)

struct LiveCategoryPicker: View {
    let groups: [String]
    @Binding var selectedGroup: String
    let countForGroup: (String) -> Int
    @EnvironmentObject private var loc: LanguageManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var expanded = false

    private var selectedTitle: String { LiveGroupLabel.title(of: selectedGroup) }
    private var selectedCount: Int { countForGroup(selectedGroup) }

    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    LiveGroupIcon(group: selectedGroup, size: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loc.t("live.categories"))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(ZapColor.textTertiary)
                        HStack(spacing: 6) {
                            Text(selectedTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ZapColor.textPrimary)
                                .lineLimit(1)
                            if selectedCount > 0 {
                                Text("\(selectedCount)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(ZapColor.textTertiary)
                                    .monospacedDigit()
                            }
                        }
                    }
                    Spacer(minLength: 4)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(ZapColor.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .zapGlassInset(cornerRadius: 10)
            }
            .buttonStyle(.plain)

            if expanded {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                    ],
                    spacing: 8
                ) {
                    ForEach(groups, id: \.self) { group in
                        LiveCategoryTile(
                            group: group,
                            count: countForGroup(group),
                            isSelected: selectedGroup == group
                        ) {
                            withAnimation(.easeOut(duration: 0.15)) {
                                selectedGroup = group
                                expanded = false
                            }
                        }
                    }
                }
                .padding(8)
                .background(panelBackground)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private var panelBackground: some View {
        if colorScheme == .light {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ZapColor.surface2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(ZapColor.border, lineWidth: 1)
                )
        }
    }
}

struct LiveCategoryTile: View {
    let group: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var hovered = false

    private var title: String { LiveGroupLabel.title(of: group) }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                LiveGroupIcon(group: group, size: 36)
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? ZapColor.textPrimary : ZapColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(count > 0 ? (count >= 1000 ? "\(count / 1000)k" : "\(count)") : "—")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(ZapColor.textTertiary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tileFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? ZapColor.accentStart : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .help(group)
        .onHover { hovered = $0 }
    }

    private var tileFill: Color {
        if isSelected { return ZapColor.accentStart.opacity(0.16) }
        if hovered { return ZapColor.hover }
        return colorScheme == .light ? Color.white.opacity(0.35) : ZapColor.surface.opacity(0.6)
    }
}

// MARK: - Channel List Row

struct ChannelListRow: View {
    let channel: Channel
    let isPlaying: Bool
    var onFavorite: (() -> Void)? = nil
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 10) {
            ChannelLogoView(channel: channel, width: 52, height: 34)
            Text(channel.name)
                .font(.system(size: 12, weight: isPlaying ? .semibold : .regular))
                .foregroundColor(isPlaying ? ZapColor.textPrimary : ZapColor.textSecondary)
                .lineLimit(1)
            Spacer()
            if let onFavorite {
                Button(action: onFavorite) {
                    Image(systemName: channel.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 11))
                        .foregroundColor(channel.isFavorite ? ZapColor.accentStart : ZapColor.textTertiary)
                }
                .buttonStyle(.plain)
            }
            if isPlaying {
                Image(systemName: "waveform").font(.system(size: 11))
                    .foregroundColor(ZapColor.accentStart)
                    .symbolEffect(.variableColor.iterative)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 7)
        .background(hovered && !isPlaying ? ZapColor.hover : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8))
        .onHover { hovered = $0 }
    }
}
