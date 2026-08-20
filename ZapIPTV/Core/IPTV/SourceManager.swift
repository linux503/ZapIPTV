import Foundation
import SwiftUI
import SwiftData

// (name, url, sourceType, overrideGroup)
// All URLs use jsDelivr CDN — works globally, no direct GitHub access needed
// jsDelivr mirrors iptv-org/iptv daily automatically
private let defaultSources: [(name: String, url: String, type: PlaylistSource.SourceType, overrideGroup: String?)] = {
    let cdn = "https://cdn.jsdelivr.net/gh/iptv-org/iptv@gh-pages"
    return [
        // ── 中华区（优先）──────────────────────────────────────
        ("🇨🇳 中国大陆",  "\(cdn)/countries/cn.m3u", .m3u, "🇨🇳 中国大陆"),
        ("🇨🇳 国内直播",  "https://cdn.jsdelivr.net/gh/vbskycn/iptv@master/tv/iptv4.m3u", .m3u, nil),
        ("🇹🇼 台湾",      "\(cdn)/countries/tw.m3u", .m3u, "🇹🇼 台湾"),
        ("🇹🇼 华语剧场",  "\(cdn)/languages/zho.m3u", .m3u, nil),
        ("🇭🇰 香港",      "\(cdn)/countries/hk.m3u", .m3u, "🇭🇰 香港"),
        ("🇭🇰 香港直播",  "https://cdn.jsdelivr.net/gh/sammy0101/hk-iptv-auto@main/hk_live.m3u", .m3u, "🇭🇰 香港"),
        ("🇭🇰 粤语频道",  "\(cdn)/languages/yue.m3u", .m3u, nil),

        // ── 东亚 ──────────────────────────────────────────────
        ("🇯🇵 日本",      "\(cdn)/countries/jp.m3u", .m3u, "🇯🇵 日本"),
        ("🇰🇷 韩国",      "\(cdn)/countries/kr.m3u", .m3u, "🇰🇷 韩国"),
        ("🇰🇷 韩语剧场",  "\(cdn)/languages/kor.m3u", .m3u, nil),

        // ── 亚洲影视补充（筛进港台韩等地区）──────────────────
        ("🎬 亚洲电影",  "\(cdn)/categories/movies.m3u", .m3u, nil),
        ("📺 亚洲剧集",  "\(cdn)/categories/series.m3u", .m3u, nil),
        ("🎮 亚洲娱乐",  "\(cdn)/categories/entertainment.m3u", .m3u, nil),

        // ── 东南亚 ────────────────────────────────────────────
        ("🇹🇭 泰国",      "\(cdn)/countries/th.m3u", .m3u, "🇹🇭 泰国"),
        ("🇻🇳 越南",      "\(cdn)/countries/vn.m3u", .m3u, "🇻🇳 越南"),
        ("🇮🇩 印尼",      "\(cdn)/countries/id.m3u", .m3u, "🇮🇩 印尼"),
        ("🇲🇾 马来西亚",  "\(cdn)/countries/my.m3u", .m3u, "🇲🇾 马来西亚"),
        ("🇸🇬 新加坡",    "\(cdn)/countries/sg.m3u", .m3u, "🇸🇬 新加坡"),
        ("🇵🇭 菲律宾",    "\(cdn)/countries/ph.m3u", .m3u, "🇵🇭 菲律宾"),
        ("🇮🇳 印度",      "\(cdn)/countries/in.m3u", .m3u, "🇮🇳 印度"),
    ]
}()

@MainActor
class SourceManager: ObservableObject {
    @Published var sources: [PlaylistSource] = []
    @Published var channels: [Channel] = []
    @Published var movies: [Movie] = []
    @Published var seriesList: [XtreamSeries] = []
    @Published var isLoading = false
    @Published var loadingMessage = ""
    @Published var loadError: String?

    var userPlaylists: [PlaylistSource] {
        sources.filter { src in
            !defaultSources.contains { $0.url == src.url }
        }
    }
    @Published var channelGroups: [String] = []

    /// Cached group → channels for fast Live TV filtering.
    private var channelsByGroup: [String: [Channel]] = [:]
    private var modelContext: ModelContext?
    private var suppressGroupUpdate: Bool = false

    // Limits parallel refresh tasks to avoid CPU/network bursts during app launch
    actor AsyncSemaphore {
        private var value: Int
        private var waiters: [CheckedContinuation<Void, Never>] = []

        init(_ value: Int) { self.value = value }

        func wait() async {
            if value > 0 {
                value -= 1
                return
            }
            await withCheckedContinuation { cont in
                waiters.append(cont)
            }
        }

        func signal() {
            if let cont = waiters.first {
                waiters.removeFirst()
                cont.resume()
            } else {
                value += 1
            }
        }
    }

    // Bump when default catalog changes — triggers one-time channel reload
    private static let catalogVersion = 9

    private static let legacySourceNames: Set<String> = [
        "News (Global)", "Sports (Global)", "Movies & Films", "Kids & Family",
        "Music TV", "General (Global)", "Documentary", "Entertainment",
        "USA Channels", "UK Channels", "Japan Channels", "Korea Channels",
        "Germany Channels", "France Channels", "India Channels",
        "Russia Channels", "Saudi Channels", "UAE Channels", "Turkey Channels",
    ]

    // Called from AppRoot — modelContext is guaranteed non-nil
    func setup(context: ModelContext) async {
        setupContext(context: context)
        await ensureAsianCatalog()
        await refreshAll()
    }

    /// Ensures only Asia-first built-in sources exist; adds missing defaults automatically.
    func ensureAsianCatalog() async {
        guard let context = modelContext else { return }

        let storedVersion = UserDefaults.standard.integer(forKey: "catalogVersion")
        let needsFullReload = storedVersion < Self.catalogVersion

        await syncOverrideGroupsForKnownSources()

        let allowedByURL = Dictionary(uniqueKeysWithValues: defaultSources.map { ($0.url, $0) })
        let descriptor = FetchDescriptor<PlaylistSource>()
        var existing = (try? context.fetch(descriptor)) ?? []
        var changed = false

        for src in existing {
            if src.type != .m3u { continue }

            // Keep current Asia defaults; rename old copies that share the same URL
            if let keep = allowedByURL[src.url] {
                if src.name != keep.name || src.overrideGroup != keep.overrideGroup {
                    src.name = keep.name
                    src.overrideGroup = keep.overrideGroup
                    changed = true
                }
                continue
            }

            if shouldDropBuiltInSource(src) {
                channels.removeAll { $0.id.hasPrefix(src.id) }
                movies.removeAll { $0.sourceId == src.id }
                context.delete(src)
                changed = true
            }
        }

        if changed {
            try? context.save()
            existing = (try? context.fetch(descriptor)) ?? []
            loadSources()
        }

        let existingURLs = Set(existing.map { $0.url })
        for s in defaultSources where !existingURLs.contains(s.url) {
            context.insert(PlaylistSource(
                name: s.name, type: s.type, url: s.url, overrideGroup: s.overrideGroup
            ))
            changed = true
        }

        if changed || needsFullReload {
            channels = []
            movies = []
            channelGroups = []
            for src in (try? context.fetch(descriptor)) ?? [] {
                src.isLoaded = false
                src.lastRefreshed = nil
            }
            try? context.save()
            loadSources()
        }

        UserDefaults.standard.set(Self.catalogVersion, forKey: "catalogVersion")
    }

    private func shouldDropBuiltInSource(_ src: PlaylistSource) -> Bool {
        if Self.legacySourceNames.contains(src.name) { return true }
        if src.name.contains("(Global)") { return true }
        if src.url.contains("/categories/") { return true }
        let western = ["/countries/us.m3u", "/countries/gb.m3u", "/countries/ru.m3u",
                       "/countries/de.m3u", "/countries/fr.m3u", "/countries/sa.m3u",
                       "/countries/ae.m3u", "/countries/tr.m3u", "/countries/au.m3u",
                       "/countries/ca.m3u", "/countries/br.m3u", "/countries/mx.m3u"]
        if western.contains(where: { src.url.contains($0) }) { return true }
        return isBuiltInIPTVOrg(src)
    }

    private func isBuiltInIPTVOrg(_ src: PlaylistSource) -> Bool {
        let url = src.url.lowercased()
        return url.contains("iptv-org.github.io/iptv")
            || url.contains("cdn.jsdelivr.net/gh/iptv-org/iptv")
            || url.contains("raw.githubusercontent.com/iptv-org/iptv")
    }

    // Step 1: inject context and load existing sources from SwiftData
    func setupContext(context: ModelContext) {
        self.modelContext = context
        loadSources()
    }

    // Patch existing stored sources so their overrideGroup matches current build rules.
    // This fixes “upgrade之后没有 🇨🇳/🇹🇼/🇭🇰 分类”的问题.
    private func syncOverrideGroupsForKnownSources() async {
        guard let context = modelContext else { return }
        let cdnPrefix = "https://cdn.jsdelivr.net/gh/iptv-org/iptv@gh-pages"
        let overrideByURL: [String: String] = {
            var dict: [String: String] = [:]
            for s in defaultSources {
                if let og = s.overrideGroup { dict[s.url] = og }
            }
            return dict
        }()

        let descriptor = FetchDescriptor<PlaylistSource>()
        let existing = (try? context.fetch(descriptor)) ?? []
        var changed = false
        for src in existing {
            // Migrate old iptv-org.github.io URLs to jsDelivr CDN mirror
            if src.url.contains("https://iptv-org.github.io/iptv/") {
                let path = src.url.replacingOccurrences(of: "https://iptv-org.github.io/iptv", with: "")
                src.url = cdnPrefix + path
                changed = true
            }
            if let og = overrideByURL[src.url], src.overrideGroup != og {
                src.overrideGroup = og
                changed = true
            }
        }
        if changed {
            try? context.save()
        }
    }

    // Step 2: seed defaults only if SwiftData is empty
    func seedDefaultSourcesIfNeededPublic() async {
        await seedDefaultSourcesIfNeeded()
    }

    // MARK: - Default sources on first launch

    private func seedDefaultSourcesIfNeeded() async {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<PlaylistSource>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        await seedDefaultSources()
    }

    func seedDefaultSources() async {
        guard let context = modelContext else { return }
        for s in defaultSources {
            let source = PlaylistSource(name: s.name, type: s.type, url: s.url,
                                        overrideGroup: s.overrideGroup)
            context.insert(source)
        }
        try? context.save()
        loadSources()
    }

    func resetAndReseed() async {
        guard let context = modelContext else { return }
        // Delete all existing
        let descriptor = FetchDescriptor<PlaylistSource>()
        let all = (try? context.fetch(descriptor)) ?? []
        for s in all { context.delete(s) }
        try? context.save()
        channels = []
        movies = []
        channelGroups = []
        sources = []
        await seedDefaultSources()
        await refreshAll()
    }

    func loadSources() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<PlaylistSource>(sortBy: [SortDescriptor(\.createdAt)])
        sources = (try? context.fetch(descriptor)) ?? []
    }

    func addSource(_ source: PlaylistSource) {
        modelContext?.insert(source)
        try? modelContext?.save()
        sources.append(source)
        Task { await refreshSource(source) }
    }

    func removeSource(_ source: PlaylistSource) {
        modelContext?.delete(source)
        try? modelContext?.save()
        sources.removeAll { $0.id == source.id }
        channels.removeAll { $0.id.hasPrefix(source.id) }
        updateGroups()
    }

    // MARK: - Refresh

    func refreshAll() async {
        isLoading = true
        loadingMessage = "Loading \(sources.count) sources…"

        suppressGroupUpdate = true

        let snapshot = sources
        let semaphore = AsyncSemaphore(4) // max parallel refresh tasks

        await withTaskGroup(of: Void.self) { group in
            for source in snapshot {
                group.addTask {
                    await semaphore.wait()
                    defer { Task { await semaphore.signal() } }
                    await self.refreshSource(source)
                }
            }
        }

        suppressGroupUpdate = false
        updateGroups()
        rebuildGroupIndex()

        isLoading = false
        loadingMessage = ""
    }

    func refreshSource(_ source: PlaylistSource) async {
        isLoading = true
        loadingMessage = "Loading \(source.name)…"
        loadError = nil

        do {
            switch source.type {
            case .m3u:   try await loadM3U(source: source)
            case .xtream: try await loadXtream(source: source)
            case .local:  try await loadLocalM3U(source: source)
            }
            source.isLoaded = true
            source.lastRefreshed = Date()
            try? modelContext?.save()
            print("[SourceManager] ✓ \(source.name) — channels:\(channels.count) movies:\(movies.count)")
        } catch {
            loadError = "Failed to load \"\(source.name)\": \(error.localizedDescription)"
            source.isLoaded = false
            print("[SourceManager] ✗ \(source.name): \(error)")
        }

        // Clear loading state only when all are done
        let anyLoading = sources.contains { !$0.isLoaded && $0.lastRefreshed == nil }
        if !anyLoading {
            isLoading = false
            loadingMessage = ""
        }
    }

    // MARK: - Loaders

    private func loadM3U(source: PlaylistSource) async throws {
        guard let url = URL(string: source.url) else { throw URLError(.badURL) }
        let sourceId = source.id

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) ZapIPTV/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Detect TvBox JSON format — parse lives and load each as sub-M3U
        if let firstByte = data.first, firstByte == UInt8(ascii: "{") || firstByte == UInt8(ascii: " ") {
            let liveSources = TvBoxParser.extractLiveSources(from: data)
            if !liveSources.isEmpty {
                let asianLives = liveSources.filter { Self.isAsianLiveFeed($0) }
                let feeds = asianLives.isEmpty ? liveSources : asianLives
                for liveSource in feeds {
                    guard let liveURL = URL(string: liveSource.m3uURL) else { continue }
                    if Self.isWesternIPTVOrgURL(liveSource.m3uURL) { continue }
                    var liveRequest = URLRequest(url: liveURL, timeoutInterval: 20)
                    liveRequest.setValue("ZapIPTV/1.0", forHTTPHeaderField: "User-Agent")
                    if let (liveData, liveResp) = try? await URLSession.shared.data(for: liveRequest),
                       let liveHTTP = liveResp as? HTTPURLResponse, liveHTTP.statusCode == 200 {
                        let content = String(data: liveData, encoding: .utf8) ?? ""
                        if content.contains("#EXTM3U") || content.contains("#EXTINF") {
                            let liveSourceId = sourceId + "-" + liveSource.name
                            let result = await Task.detached {
                                M3UParser.parse(content: content, sourceId: liveSourceId)
                            }.value
                            mergeChannels(result.channels, sourceId: source.id)
                        } else {
                            // Some live.txt files use a simpler "Name,URL" or "#name\nurl" format
                            let chans = await Task.detached {
                                SourceManager.parseSimpleLiveTxt(content: content, sourceId: sourceId, group: liveSource.name)
                            }.value
                            mergeChannels(chans, sourceId: source.id)
                        }
                    }
                }
                Task { await pruneUnplayableChannels(sourceId: source.id) }
                return
            }
        }

        let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        guard !content.isEmpty else { throw URLError(.zeroByteResource) }

        var result = await Task.detached {
            M3UParser.parse(content: content, sourceId: sourceId)
        }.value

        result.channels = ChinesePlaylist.refine(result.channels, sourceURL: source.url)
        result.channels = HongKongPlaylist.refine(result.channels, sourceURL: source.url)
        result.channels = RegionalPlaylist.refineExtra(result.channels, sourceURL: source.url)

        // If the source has an overrideGroup, stamp every channel with it
        if let og = source.overrideGroup {
            result.channels = result.channels.map {
                Channel(id: $0.id, name: $0.name, url: $0.url, logoURL: $0.logoURL,
                        group: og, lastWatched: $0.lastWatched)
            }
            result.channels = RegionalPlaylist.curate(result.channels, group: og)
        } else {
            // Extra language / category feeds may already carry regional groups.
            let byGroup = Dictionary(grouping: result.channels, by: \.group)
            result.channels = byGroup.flatMap { RegionalPlaylist.curate($0.value, group: $0.key) }
        }

        mergeChannels(result.channels, sourceId: source.id)
        if !result.movies.isEmpty {
            mergeMoviesFromChannels(result.movies, sourceId: source.id)
        }
        Task { await pruneUnplayableChannels(sourceId: source.id) }
    }

    private nonisolated static func isAsianLiveFeed(_ live: TvBoxParser.LiveSource) -> Bool {
        let name = live.name.lowercased()
        let url = live.m3uURL.lowercased()
        let urlKeys = ["/countries/cn", "/countries/tw", "/countries/hk", "/countries/jp",
                       "/countries/kr", "/countries/th", "/countries/vn", "/countries/id",
                       "/countries/my", "/countries/sg", "/countries/ph", "/countries/in"]
        if urlKeys.contains(where: { url.contains($0) }) { return true }
        let nameKeys = ["china", "taiwan", "hong kong", "hongkong", "japan", "korea",
                        "thai", "viet", "indo", "malay", "singapore", "philippine", "india",
                        "中国", "台湾", "香港", "日本", "韩国", "泰国", "越南", "印尼",
                        "马来", "新加坡", "菲律宾", "印度", "央视", "卫视", "直播"]
        if nameKeys.contains(where: { name.contains($0) }) { return true }
        return live.name.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
    }

    private nonisolated static func isWesternIPTVOrgURL(_ url: String) -> Bool {
        let u = url.lowercased()
        guard u.contains("iptv-org") else { return false }
        if u.contains("/countries/cn") || u.contains("/countries/tw") || u.contains("/countries/hk")
            || u.contains("/countries/jp") || u.contains("/countries/kr")
            || u.contains("/countries/th") || u.contains("/countries/vn")
            || u.contains("/countries/id") || u.contains("/countries/my")
            || u.contains("/countries/sg") || u.contains("/countries/ph")
            || u.contains("/countries/in") {
            return false
        }
        return u.contains("/categories/") || u.contains("/countries/")
    }

    // Parse "ChannelName,URL" or "#Group\nName,URL" format used by some TvBox live.txt
    private nonisolated static func parseSimpleLiveTxt(content: String, sourceId: String, group: String) -> [Channel] {
        var channels: [Channel] = []
        var currentGroup = group
        for line in content.components(separatedBy: .newlines) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { continue }
            if t.hasPrefix("#") {
                currentGroup = t.dropFirst().trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: ",").first ?? currentGroup
                continue
            }
            let parts = t.components(separatedBy: ",")
            if parts.count >= 2 {
                let name = parts[0].trimmingCharacters(in: .whitespaces)
                let urlStr = parts[1].trimmingCharacters(in: .whitespaces)
                if let url = URL(string: urlStr), !name.isEmpty {
                    channels.append(Channel(
                        id: "\(sourceId)-\(urlStr.hashValue)",
                        name: name, url: url,
                        logoURL: nil,
                        group: currentGroup
                    ))
                }
            }
        }
        return channels
    }

    private func loadLocalM3U(source: PlaylistSource) async throws {
        let content = try String(contentsOfFile: source.url, encoding: .utf8)
        let result = await Task.detached {
            M3UParser.parse(content: content, sourceId: source.id)
        }.value
        mergeChannels(result.channels, sourceId: source.id)
    }

    private func loadXtream(source: PlaylistSource) async throws {
        guard let user = source.username, let pass = source.password else {
            throw NSError(domain: "ZapIPTV", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Xtream source missing username/password"])
        }
        let api = XtreamCodesAPI(baseURL: source.url, username: user, password: pass)
        let live = try await api.getLiveStreams()
        mergeChannels(live, sourceId: source.id)
        let vod = try await api.getVODStreams()
        movies.removeAll { $0.sourceId == source.id }
        movies.append(contentsOf: vod)
    }

    // MARK: - Merge helpers

    private func mergeChannels(_ new: [Channel], sourceId: String) {
        // Batch array mutation to minimise @Published triggers
        var updated = channels.filter { !$0.id.hasPrefix(sourceId) }
        updated.append(contentsOf: ChannelQuality.optimize(new))
        channels = updated
        rebuildGroupIndex()
        if !suppressGroupUpdate {
            updateGroups()
        }
    }

    /// Drop channels confirmed as FLV / HTML / 404. Keep unknowns so CDNs that
    /// reject Range still get a real AVPlayer attempt.
    private func pruneUnplayableChannels(sourceId: String) async {
        let snapshot = channels.filter { $0.id.hasPrefix(sourceId) }
        guard snapshot.count >= 6 else { return }

        let semaphore = AsyncSemaphore(6)
        var drop = Set<String>()
        await withTaskGroup(of: (String, StreamKind).self) { group in
            for ch in snapshot {
                // 春晚 / 华语影视：HLS 点播或国内 CDN，Range 探测慢且易误杀
                if ch.group == "🎆 春晚" || ch.group == "🎬 华语影视" { continue }
                group.addTask {
                    await semaphore.wait()
                    defer { Task { await semaphore.signal() } }
                    let kind = await StreamProbe.check(ch.url)
                    return (ch.id, kind)
                }
            }
            for await (id, kind) in group {
                if kind == .flv || kind == .html || kind == .dead {
                    drop.insert(id)
                }
            }
        }

        let remaining = snapshot.count - drop.count
        guard remaining >= max(3, snapshot.count / 5) else { return }
        guard !drop.isEmpty else { return }
        channels.removeAll { drop.contains($0.id) }
        rebuildGroupIndex()
        if !suppressGroupUpdate {
            updateGroups()
        }
    }

    private func rebuildGroupIndex() {
        var index: [String: [Channel]] = [:]
        for ch in channels {
            index[ch.group, default: []].append(ch)
            let norm = normaliseGroup(ch.group)
            if norm != ch.group {
                index[norm, default: []].append(ch)
            }
        }
        channelsByGroup = index
    }

    private func mergeMoviesFromChannels(_ vod: [Channel], sourceId: String) {
        let converted = vod.map { ch in
            Movie(id: ch.id, title: ch.name, url: ch.url, posterURL: ch.logoURL,
                  genres: [ch.group], sourceId: sourceId)
        }
        movies.removeAll { $0.sourceId == sourceId + "-vod" }
        movies.append(contentsOf: converted)
    }

    private func updateGroups() {
        // Use channel.group directly (already set via overrideGroup for built-in sources)
        // Only normalise groups that don't already look like our canonical labels
        let raw = Set(channels.map { $0.group.trimmingCharacters(in: .whitespaces) })
        let mapped = raw.map { g -> String in
            // If already a canonical label (starts with flag emoji or our known prefixes), keep it
            let isCanonical = groupSortOrder.contains(g)
            return isCanonical ? g : normaliseGroup(g)
        }
        channelGroups = Array(Set(mapped)).sorted { a, b in
            let order = groupSortOrder
            let ai = order.firstIndex(of: a) ?? 999
            let bi = order.firstIndex(of: b) ?? 999
            return ai == bi ? a < b : ai < bi
        }
    }

    // Maps raw M3U group-title strings → unified display category
    func normaliseGroup(_ raw: String) -> String {
        let s = raw.lowercased()
        switch true {
        // 中文
        case s.contains("中央") || s.contains("cctv") || s.contains("中国") || s.contains("china") || s.contains("chinese"):
            return "🇨🇳 中国大陆"
        case s.contains("台湾") || s.contains("taiwan") || s.contains("tvbs") || s.contains("中天") || s.contains("东森"):
            return "🇹🇼 台湾"
        case s.contains("香港") || s.contains("hong kong") || s.contains("tvb") || s.contains("无线") || s.contains("無線")
             || s.contains("明珠") || s.contains("翡翠") || s.contains("viutv") || s.contains("港台") || s.contains("hoy"):
            return "🇭🇰 香港"
        // 亚洲
        case s.contains("日本") || s.contains("japan") || s.contains("nhk") || s.contains("japanese"):
            return "🇯🇵 日本"
        case s.contains("韩国") || s.contains("korea") || s.contains("kbs") || s.contains("mbc"):
            return "🇰🇷 韩国"
        case s.contains("泰国") || s.contains("thailand") || s.contains("thai"):
            return "🇹🇭 泰国"
        case s.contains("越南") || s.contains("vietnam") || s.contains("viet"):
            return "🇻🇳 越南"
        case s.contains("印尼") || s.contains("indonesia") || s.contains("indonesian"):
            return "🇮🇩 印度尼西亚"
        case s.contains("菲律宾") || s.contains("philippine") || s.contains("filipino"):
            return "🇵🇭 菲律宾"
        case s.contains("马来") || s.contains("malaysia") || s.contains("malay"):
            return "🇲🇾 马来西亚"
        case s.contains("新加坡") || s.contains("singapore"):
            return "🇸🇬 新加坡"
        case s.contains("印度") || s.contains("india") || s.contains("hindi") || s.contains("bollywood"):
            return "🇮🇳 印度"
        // 中东
        case s.contains("arab") || s.contains("arabic") || s.contains("saudi") || s.contains("沙特"):
            return "🌙 阿拉伯/中东"
        case s.contains("turkey") || s.contains("turkish") || s.contains("土耳其"):
            return "🇹🇷 土耳其"
        // 欧美
        case s.contains("usa") || s.contains("us ") || s.contains("american") || s.contains("english") || s == "us":
            return "🇺🇸 美国/英语"
        case s.contains("uk") || s.contains("british") || s.contains("england"):
            return "🇬🇧 英国"
        case s.contains("german") || s.contains("deutsch"):
            return "🇩🇪 德国"
        case s.contains("french") || s.contains("france"):
            return "🇫🇷 法国"
        case s.contains("russia") || s.contains("russian") || s.contains("русск"):
            return "🇷🇺 俄罗斯"
        // 内容类型
        case s.contains("news") || s.contains("新闻"):
            return "📺 新闻"
        case s.contains("sport") || s.contains("体育") || s.contains("足球") || s.contains("篮球"):
            return "⚽ 体育"
        case s.contains("movie") || s.contains("film") || s.contains("cinema") || s.contains("电影"):
            return "🎬 电影"
        case s.contains("entertainment") || s.contains("娱乐") || s.contains("综艺"):
            return "🎮 娱乐"
        case s.contains("music") || s.contains("音乐") || s.contains("mtv"):
            return "🎵 音乐"
        case s.contains("kids") || s.contains("child") || s.contains("儿童") || s.contains("少儿") || s.contains("cartoon"):
            return "🧒 儿童/动画"
        case s.contains("animation") || s.contains("anime") || s.contains("动漫") || s.contains("动画"):
            return "🧒 儿童/动画"
        case s.contains("documentary") || s.contains("纪录") || s.contains("探索"):
            return "📖 纪录片"
        case s.contains("science") || s.contains("科学") || s.contains("科技"):
            return "🔬 科学/科技"
        case s.contains("travel") || s.contains("旅游") || s.contains("旅行"):
            return "✈️ 旅游"
        case s.contains("cook") || s.contains("food") || s.contains("美食"):
            return "🍳 美食"
        case s.contains("business") || s.contains("finance") || s.contains("经济") || s.contains("财经"):
            return "💼 财经"
        case s.contains("lifestyle") || s.contains("生活") || s.contains("时尚"):
            return "🌿 生活"
        case s.contains("auto") || s.contains("car") || s.contains("汽车"):
            return "🚗 汽车"
        case s.contains("religious") || s.contains("religi") || s.contains("宗教"):
            return "🕌 宗教"
        case s.isEmpty || s == "undefined" || s == "general" || s == "other" || s == "其他":
            return "📡 综合"
        default:
            // Keep short original names; truncate long ones
            return raw.count <= 20 ? raw : "📡 综合"
        }
    }

    private let groupSortOrder = [
        "🇨🇳 中国大陆", "🎬 华语影视", "🎆 春晚", "🇹🇼 台湾", "🇭🇰 香港",
        "🇯🇵 日本", "🇰🇷 韩国", "🇹🇭 泰国", "🇻🇳 越南",
        "🇮🇩 印度尼西亚", "🇲🇾 马来西亚", "🇸🇬 新加坡", "🇵🇭 菲律宾", "🇮🇳 印度",
        "🌙 阿拉伯/中东", "🇹🇷 土耳其",
        "🇺🇸 美国/英语", "🇬🇧 英国", "🇩🇪 德国", "🇫🇷 法国", "🇷🇺 俄罗斯",
        "📺 新闻", "⚽ 体育", "🎬 电影", "🎮 娱乐", "🎵 音乐",
        "🧒 儿童/动画", "📖 纪录片", "🔬 科学/科技", "✈️ 旅游", "🍳 美食",
        "💼 财经", "🌿 生活", "🚗 汽车", "🕌 宗教", "📡 综合",
    ]

    // MARK: - Convenience

    var allChannels: [Channel] { channels }

    func channels(inGroup group: String) -> [Channel] {
        guard group != "All" else { return channels }
        if let cached = channelsByGroup[group], !cached.isEmpty {
            return cached
        }
        return channels.filter { ch in
            ch.group == group || normaliseGroup(ch.group) == group
        }
    }

    func search(query: String) -> [Channel] {
        guard !query.isEmpty else { return channels }
        return channels.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
