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

            // ── Category sidebar ──
            if !playback.playerFullScreen {
            VStack(spacing: 0) {
                Text(loc.t("live.categories"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(ZapColor.textTertiary)
                    .padding(.top, 16).padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(groups, id: \.self) { group in
                            GroupButton(
                                group: group,
                                count: countForGroup(group),
                                isSelected: selectedGroup == group
                            ) {
                                selectedGroup = group
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .frame(width: 148)
            .background(ZapColor.surface)

            Divider().background(ZapColor.hairline)
            }

            // ── Channel list ──
            if showChannelList && !playback.playerFullScreen {
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ZapColor.textTertiary)
                            .font(.system(size: 13))
                        TextField(loc.t("live.search"), text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(ZapColor.textPrimary)
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(ZapColor.surface2).cornerRadius(8)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, selectedChannel == nil ? 10 : 6)

                    if let playing = selectedChannel {
                        Button(action: locateCurrent) {
                            HStack(spacing: 8) {
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(ZapColor.live)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(loc.t("live.now_playing"))
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(ZapColor.textTertiary)
                                    Text(playing.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(ZapColor.textPrimary)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 4)
                                Image(systemName: "location.viewfinder")
                                    .font(.system(size: 13))
                                    .foregroundColor(ZapColor.accentStart)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(ZapColor.accentStart.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ZapColor.accentStart.opacity(0.35), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .help(loc.t("live.locate"))
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                    }

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
                .frame(width: 220)
                .background(ZapColor.bg)

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

                            if playerEngine.isBuffering {
                                VStack(spacing: 10) {
                                    ProgressView().progressViewStyle(.circular)
                                        .scaleEffect(1.4).tint(.white)
                                    Text(loc.t("live.connecting"))
                                        .font(.system(size: 13)).foregroundColor(.white.opacity(0.7))
                                }
                            }

                            if let err = playerEngine.error {
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
                            if let logo = channel.logoURL {
                                CachedAsyncImage(url: logo, contentMode: .fit)
                                    .frame(width: 36, height: 24)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(channel.name)
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(ZapColor.textPrimary)
                                Text(channel.group)
                                    .font(.system(size: 11)).foregroundColor(ZapColor.textTertiary)
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

                            // Toggle channel list
                            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showChannelList.toggle() } }) {
                                Image(systemName: showChannelList ? "sidebar.left" : "sidebar.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(ZapColor.textSecondary)
                                    .padding(6)
                                    .background(ZapColor.surface2, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .help(showChannelList ? loc.t("live.hide_list") : loc.t("live.show_list"))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(ZapColor.surface.opacity(0.95))
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
        .background(ZapColor.bg)
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
        .onChange(of: playerEngine.error?.localizedDescription) { _ in
            guard playerEngine.error != nil, let ch = selectedChannel else { return }
            failedChannelIDs.insert(ch.id)
            playNext()
        }
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
        playerEngine.load(url: ch.url)
        locateToken += 1
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

// MARK: - Group Button

enum LiveGroupLabel {
    static func split(_ group: String) -> (flag: String, title: String) {
        if let space = group.firstIndex(of: " ") {
            let flag = String(group[..<space])
            let title = String(group[group.index(after: space)...])
            if !flag.isEmpty { return (flag, title) }
        }
        return ("📡", group)
    }
}

struct GroupButton: View {
    let group: String
    var count: Int = 0
    let isSelected: Bool
    let action: () -> Void
    @State private var hovered = false

    private var parts: (flag: String, title: String) { LiveGroupLabel.split(group) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(parts.flag)
                    .font(.system(size: 18))
                    .frame(width: 26, alignment: .center)
                Text(parts.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? ZapColor.textPrimary : ZapColor.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 2)
                if count > 0 {
                    Text(count >= 1000 ? "\(count/1000)k" : "\(count)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(isSelected ? ZapColor.textSecondary : ZapColor.textTertiary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? ZapColor.accentStart.opacity(0.18) : (hovered ? ZapColor.hover : .clear))
            )
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(group)
        .onHover { hovered = $0 }
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
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(ZapColor.surface2)
                    .frame(width: 44, height: 30)
                if let logo = channel.logoURL {
                    CachedAsyncImage(url: logo, contentMode: .fit)
                        .frame(width: 36, height: 24)
                } else {
                    Image(systemName: "tv").font(.system(size: 12))
                        .foregroundColor(ZapColor.textTertiary)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(channel.name)
                    .font(.system(size: 12, weight: isPlaying ? .semibold : .regular))
                    .foregroundColor(isPlaying ? ZapColor.textPrimary : ZapColor.textSecondary)
                    .lineLimit(1)
                Text(channel.group)
                    .font(.system(size: 10)).foregroundColor(ZapColor.textTertiary)
            }
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
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(hovered && !isPlaying ? ZapColor.hover : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8))
        .onHover { hovered = $0 }
    }
}
