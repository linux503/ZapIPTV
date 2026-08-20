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

enum LiveGroupLabel {
    static func split(_ group: String) -> (flag: String, title: String) {
        if let space = group.firstIndex(of: " ") {
            let flag = String(group[..<space])
            let title = String(group[group.index(after: space)...])
            if !flag.isEmpty { return (flag, title) }
        }
        return ("📡", group)
    }

    static func title(of group: String) -> String { split(group).title }
}

// MARK: - Realistic group icons

struct LiveGroupIcon: View {
    let group: String
    var size: CGFloat = 28

    var body: some View {
        Group {
            switch group {
            case "🇨🇳 中国大陆":
                ChinaFlagIcon()
            case "🎬 华语影视":
                HuayuCinemaIcon()
            case "🎆 春晚":
                ChunwanLanternIcon()
            case "🇹🇼 台湾":
                TaiwanFlagIcon()
            case "🇭🇰 香港":
                HongKongFlagIcon()
            default:
                emojiFallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
    }

    private var emojiFallback: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#3A3230"), Color(hex: "#1C1614")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Text(LiveGroupLabel.split(group).flag)
                .font(.system(size: size * 0.55))
        }
    }
}

/// PRC flag — red field + yellow stars
private struct ChinaFlagIcon: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack(alignment: .topLeading) {
                Color(hex: "#DE2910")
                Image(systemName: "star.fill")
                    .font(.system(size: s * 0.30))
                    .foregroundColor(Color(hex: "#FFDE00"))
                    .position(x: s * 0.26, y: s * 0.36)
                Group {
                    star(at: CGPoint(x: 0.52, y: 0.18), size: s * 0.10)
                    star(at: CGPoint(x: 0.62, y: 0.30), size: s * 0.10)
                    star(at: CGPoint(x: 0.62, y: 0.46), size: s * 0.10)
                    star(at: CGPoint(x: 0.52, y: 0.58), size: s * 0.10)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func star(at p: CGPoint, size: CGFloat) -> some View {
        GeometryReader { geo in
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundColor(Color(hex: "#FFDE00"))
                .position(x: geo.size.width * p.x, y: geo.size.height * p.y)
        }
    }
}

/// Taiwan (ROC) flag — red field, blue canton, white sun
private struct TaiwanFlagIcon: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                Color(hex: "#FE0000")
                ZStack {
                    Color(hex: "#000095")
                    ZStack {
                        ForEach(0..<12, id: \.self) { i in
                            Capsule()
                                .fill(Color.white)
                                .frame(width: max(1.5, w * 0.04), height: h * 0.20)
                                .offset(y: -h * 0.09)
                                .rotationEffect(.degrees(Double(i) * 30))
                        }
                        Circle()
                            .fill(Color.white)
                            .frame(width: w * 0.18, height: h * 0.18)
                        Circle()
                            .strokeBorder(Color(hex: "#000095"), lineWidth: max(1, w * 0.03))
                            .frame(width: w * 0.18, height: h * 0.18)
                    }
                }
                .frame(width: w * 0.5, height: h * 0.5)
            }
        }
    }
}

/// Hong Kong flag — red field + white Bauhinia (simplified flower)
private struct HongKongFlagIcon: View {
    var body: some View {
        ZStack {
            Color(hex: "#DE2910")
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(Color.white)
                        .frame(width: 4, height: 11)
                        .offset(y: -5)
                        .rotationEffect(.degrees(Double(i) * 72))
                }
                Circle()
                    .fill(Color(hex: "#DE2910"))
                    .frame(width: 5, height: 5)
            }
        }
    }
}

/// 华语影视 — cinema clapper / film look
private struct HuayuCinemaIcon: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1A1A1A"), Color(hex: "#3D1A14"), Color(hex: "#8B1520")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            // Film strip edge marks
            HStack {
                VStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 3, height: 3)
                    }
                }
                .padding(.leading, 3)
                Spacer()
                VStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 3, height: 3)
                    }
                }
                .padding(.trailing, 3)
            }
            Image(systemName: "movieclapper.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#FFD36A"), Color(hex: "#F24A1A")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
        }
    }
}

/// 春晚 — festive red lantern
private struct ChunwanLanternIcon: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#4A0A10"), Color(hex: "#C41E3A"), Color(hex: "#8B0000")],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color(hex: "#FFD36A"))
                    .frame(width: 8, height: 3)
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF4D4D"), Color(hex: "#B01020")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 16, height: 18)
                    .overlay(
                        Text("福")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#FFD36A"))
                    )
                Capsule()
                    .fill(Color(hex: "#FFD36A"))
                    .frame(width: 3, height: 4)
            }
            .offset(y: 1)
        }
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
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(hovered && !isPlaying ? ZapColor.hover : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8))
        .onHover { hovered = $0 }
    }
}
