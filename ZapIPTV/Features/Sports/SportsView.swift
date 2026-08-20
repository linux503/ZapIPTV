import SwiftUI
import AVKit

private enum SportFilter: Hashable {
    case all
    case category(SportCategory)

    var id: String {
        switch self {
        case .all: return "all"
        case .category(let c): return c.rawValue
        }
    }

    @MainActor
    func title(_ loc: LanguageManager) -> String {
        switch self {
        case .all: return loc.t("sports.filter.all")
        case .category(let c): return c.title(loc)
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "sportscourt.fill"
        case .category(let c): return c.systemImage
        }
    }
}

struct SportsView: View {
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var playerEngine: PlayerEngine
    @EnvironmentObject private var playback: PlaybackRouter
    @EnvironmentObject private var loc: LanguageManager

    @State private var selectedFilter: SportFilter = .all
    @State private var selectedChannel: Channel?
    @State private var searchText = ""
    @State private var showChannelList = true
    @State private var failedChannelIDs: Set<String> = []
    @State private var locateToken = 0
    @State private var streamURLs: [URL] = []
    @State private var streamIndex = 0
    @State private var mirrorLabel = ""
    @State private var isPreparingStream = false
    @State private var isSwitchingMirror = false

    private var sportsChannels: [Channel] {
        sourceManager.channels(inGroup: "⚽ 体育")
    }

    private var categoryCounts: [(SportCategory, Int)] {
        var bag: [SportCategory: Int] = [:]
        for ch in sportsChannels {
            let cat = SportCategory.classify(ch.name)
            bag[cat, default: 0] += 1
        }
        return SportCategory.allCases
            .compactMap { cat in
                let n = bag[cat] ?? 0
                return n > 0 ? (cat, n) : nil
            }
    }

    private var availableFilters: [SportFilter] {
        [.all] + categoryCounts.map { .category($0.0) }
    }

    private func count(for filter: SportFilter) -> Int {
        switch filter {
        case .all: return sportsChannels.count
        case .category(let cat):
            return categoryCounts.first(where: { $0.0 == cat })?.1 ?? 0
        }
    }

    /// Flat filtered list (already curated order from SourceManager).
    private var filteredChannels: [Channel] {
        var list = sportsChannels
        if case .category(let cat) = selectedFilter {
            list = list.filter { SportCategory.classify($0.name) == cat }
        }
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    /// Sectioned rows for the channel list.
    private var channelSections: [(title: String, icon: String, channels: [Channel])] {
        let list = filteredChannels
        if !searchText.isEmpty {
            return list.isEmpty ? [] : [(loc.t("sports.search"), "magnifyingglass", list)]
        }
        if case .category(let cat) = selectedFilter {
            // 足球：按五大联赛分段；综合 / 其他：再按品牌分段
            if cat == .football {
                return footballLeagueSections(from: list)
            }
            if cat == .american {
                return brandSections(from: list)
            }
            if cat == .network || cat == .other {
                return brandSections(from: list)
            }
            return list.isEmpty ? [] : [(cat.title(loc), cat.systemImage, list)]
        }
        // 全部：按分类分段，类内已排序
        var buckets: [SportCategory: [Channel]] = [:]
        for ch in list {
            buckets[SportCategory.classify(ch.name), default: []].append(ch)
        }
        return SportCategory.allCases.compactMap { cat in
            guard let rows = buckets[cat], !rows.isEmpty else { return nil }
            return (cat.title(loc), cat.systemImage, rows)
        }
    }

    private func brandSections(from list: [Channel]) -> [(title: String, icon: String, channels: [Channel])] {
        var bags: [SportBrandFamily: [Channel]] = [:]
        for ch in list {
            bags[SportBrandFamily.classify(ch.name), default: []].append(ch)
        }
        return SportBrandFamily.allCases.compactMap { family in
            guard var rows = bags[family], !rows.isEmpty else { return nil }
            rows.sort(by: SportsPlaylist.channelLessThan)
            return (family.title(loc), family.systemImage, rows)
        }
    }

    private func footballLeagueSections(from list: [Channel]) -> [(title: String, icon: String, channels: [Channel])] {
        var bags: [FootballLeague: [Channel]] = [:]
        for ch in list {
            bags[FootballLeague.classify(ch.name), default: []].append(ch)
        }
        return FootballLeague.allCases.compactMap { league in
            guard var rows = bags[league], !rows.isEmpty else { return nil }
            rows.sort(by: SportsPlaylist.channelLessThan)
            return (league.title(loc), league.systemImage, rows)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            if showChannelList && !playback.playerFullScreen {
                channelPanel
                    .frame(width: 288)
                    .zapGlassSurface()
                Divider().background(ZapColor.hairline)
            }
            playerPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(ZapBackdrop())
        .onAppear {
            consumePending()
            sanitizeFilter()
        }
        .onChange(of: playback.pendingLive?.id) { _ in consumePending() }
        .onChange(of: sportsChannels.count) { _ in sanitizeFilter() }
        .onChange(of: playerEngine.isPlaying) { _, playing in
            if playing {
                isSwitchingMirror = false
                isPreparingStream = false
            }
        }
        .onChange(of: playerEngine.error?.localizedDescription) { _ in
            guard playerEngine.error != nil, let ch = selectedChannel else { return }
            if streamIndex + 1 < streamURLs.count {
                isSwitchingMirror = true
                isPreparingStream = true
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

    private func sanitizeFilter() {
        let ids = Set(availableFilters.map(\.id))
        if !ids.contains(selectedFilter.id) {
            selectedFilter = .all
        }
    }

    // MARK: - Channel panel

    private var channelPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                appSidebarToggleButton()
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.t("tab.sports"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ZapColor.textPrimary)
                    Text(String(format: loc.t("sports.count"), sportsChannels.count))
                        .font(.system(size: 11))
                        .foregroundColor(ZapColor.textTertiary)
                }
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
            .padding(.horizontal, 12)
            .padding(.top, 14)
            .padding(.bottom, 10)

            SportCategoryPicker(
                filters: availableFilters,
                selected: $selectedFilter,
                countFor: { count(for: $0) }
            )
            .padding(.horizontal, 10)
            .padding(.bottom, 8)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ZapColor.textTertiary)
                    .font(.system(size: 13))
                TextField(loc.t("sports.search"), text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(ZapColor.textPrimary)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .zapGlassInset(cornerRadius: 8)
            .padding(.horizontal, 10)
            .padding(.bottom, 8)

            if channelSections.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 32))
                        .foregroundColor(ZapColor.textTertiary)
                    Text(loc.t("sports.empty"))
                        .font(.system(size: 13))
                        .foregroundColor(ZapColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(channelSections, id: \.title) { section in
                                Section {
                                    ForEach(section.channels) { ch in
                                        ChannelListRow(
                                            channel: ch,
                                            isPlaying: selectedChannel?.id == ch.id,
                                            onFavorite: { sourceManager.toggleFavorite(channelId: ch.id) }
                                        )
                                        .id(ch.id)
                                        .contentShape(Rectangle())
                                        .onTapGesture { playChannel(ch) }
                                        .padding(.horizontal, 8)
                                    }
                                } header: {
                                    let showHeader: Bool = {
                                        if !searchText.isEmpty { return false }
                                        if case .category(let cat) = selectedFilter {
                                            // 足球按联赛、综合/美职按品牌分段
                                            return cat == .network || cat == .other
                                                || cat == .football || cat == .american
                                        }
                                        return true // 全部时按大类吸顶
                                    }()
                                    if showHeader {
                                        sportSectionHeader(title: section.title, icon: section.icon, count: section.channels.count)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: locateToken) { _, _ in
                        guard let id = selectedChannel?.id else { return }
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func sportSectionHeader(title: String, icon: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ZapColor.accentStart)
                .frame(width: 16)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ZapColor.textSecondary)
            Text("\(count)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(ZapColor.textTertiary)
                .monospacedDigit()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
    }

    // MARK: - Player

    private var playerPanel: some View {
        ZStack {
            Color.black
            if let channel = selectedChannel {
                VStack(spacing: 0) {
                    ZStack {
                        VideoPlayerView(engine: playerEngine)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        if (isPreparingStream || isSwitchingMirror || playerEngine.isBuffering)
                            && playerEngine.error == nil {
                            let switching = isSwitchingMirror || streamIndex > 0
                            VStack(spacing: 12) {
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
                                }
                            }
                            .padding(.horizontal, 28)
                            .padding(.vertical, 22)
                            .background(.ultraThinMaterial.opacity(0.92), in: RoundedRectangle(cornerRadius: 14))
                        }

                        if playerEngine.error != nil && !isSwitchingMirror && !isPreparingStream {
                            VStack(spacing: 14) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 36)).foregroundColor(.orange)
                                Text(loc.t("live.unavailable"))
                                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                if let err = playerEngine.error {
                                    Text(err.localizedDescription)
                                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                                }
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
                        HStack(spacing: 12) {
                            ChannelLogoView(channel: channel, width: 52, height: 34, cornerRadius: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(channel.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(ZapColor.textPrimary)
                                HStack(spacing: 6) {
                                    let cat = SportCategory.classify(channel.name)
                                    Image(systemName: cat.systemImage)
                                        .font(.system(size: 10))
                                        .foregroundColor(ZapColor.textTertiary)
                                    Text(cat.title(loc))
                                        .font(.system(size: 11))
                                        .foregroundColor(ZapColor.textTertiary)
                                    if !mirrorLabel.isEmpty {
                                        Text("·").foregroundColor(ZapColor.textTertiary)
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
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { showChannelList.toggle() }
                            } label: {
                                Image(systemName: showChannelList ? "sidebar.left" : "sidebar.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(ZapColor.textSecondary)
                                    .padding(6)
                                    .zapGlassInset(cornerRadius: 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .zapGlassSurface()
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.2))
                    Text(loc.t("sports.select"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                    if !filteredChannels.isEmpty {
                        Text(String(format: loc.t("sports.count"), filteredChannels.count))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.25))
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func consumePending() {
        guard let ch = playback.pendingLive, ch.group == "⚽ 体育" else { return }
        playback.pendingLive = nil
        let cat = SportCategory.classify(ch.name)
        selectedFilter = .category(cat)
        playChannel(ch)
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
        if index > 0 {
            isSwitchingMirror = true
            isPreparingStream = true
        } else {
            isPreparingStream = true
        }
        let url = streamURLs[index]
        let remaining = streamURLs.count - index - 1
        mirrorLabel = streamURLs.count > 1
            ? String(format: loc.t("live.mirror"), index + 1, streamURLs.count)
            : ""

        if index > 0 {
            playerEngine.load(url: url, connectTimeout: remaining > 0 ? 4.5 : 8)
            return
        }

        Task { @MainActor in
            let kind = await StreamProbe.check(url)
            guard selectedChannel?.id == ch.id, streamIndex == index else { return }
            if kind == .flv || kind == .html || kind == .dead {
                if index + 1 < streamURLs.count {
                    isSwitchingMirror = true
                    isPreparingStream = true
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
            isPreparingStream = true
            playerEngine.load(url: url, connectTimeout: remaining > 0 ? 6 : 10)
        }
    }

    private func locateCurrent() {
        searchText = ""
        if let ch = selectedChannel {
            selectedFilter = .category(SportCategory.classify(ch.name))
        } else {
            selectedFilter = .all
        }
        locateToken += 1
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
}

// MARK: - Category picker

private struct SportCategoryPicker: View {
    let filters: [SportFilter]
    @Binding var selected: SportFilter
    let countFor: (SportFilter) -> Int
    @EnvironmentObject private var loc: LanguageManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: selected.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ZapColor.accentStart)
                        .frame(width: 32, height: 32)
                        .background(ZapColor.accentStart.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loc.t("sports.categories"))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(ZapColor.textTertiary)
                        HStack(spacing: 6) {
                            Text(selected.title(loc))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ZapColor.textPrimary)
                                .lineLimit(1)
                            let n = countFor(selected)
                            if n > 0 {
                                Text("\(n)")
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
                    ForEach(filters, id: \.id) { filter in
                        SportCategoryTile(
                            title: filter.title(loc),
                            icon: filter.systemImage,
                            count: countFor(filter),
                            isSelected: selected.id == filter.id
                        ) {
                            withAnimation(.easeOut(duration: 0.15)) {
                                selected = filter
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

private struct SportCategoryTile: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? ZapColor.accentStart : ZapColor.textSecondary)
                    .frame(height: 28)
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? ZapColor.textPrimary : ZapColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(count > 0 ? "\(count)" : "—")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ZapColor.textTertiary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected
                          ? ZapColor.accentStart.opacity(colorScheme == .light ? 0.12 : 0.18)
                          : (hovered ? ZapColor.surface2.opacity(0.8) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? ZapColor.accentStart.opacity(0.45) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}
