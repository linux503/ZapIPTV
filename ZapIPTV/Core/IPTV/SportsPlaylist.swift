import Foundation

/// Curates global sports live lists (iptv-org sports + verified regional seeds).
enum SportsPlaylist {
    private static let noiseKeys = [
        "geo-blocked", "[geo", "xxx", "adult", "porn", "shop", "infomercial",
        "radio only", "not 24/7", "offline", "test stream", "backup only",
    ]

    /// Popular / event-friendly networks bubble to the top within a category.
    private static let priorityKeys: [(String, Int)] = [
        ("cctv5", 120), ("cctv 5", 120), ("cctv-5", 120),
        ("广东体育", 100), ("五星体育", 100), ("劲爆体育", 95),
        ("espn", 110), ("sky sport", 105), ("skysports", 105), ("bein", 100),
        ("dazn", 95), ("eurosport", 90), ("fox sport", 85), ("tsn", 80),
        ("nba tv", 120), ("nba", 110), ("wnba", 100), ("睛彩篮球", 115),
        ("sky sport basket", 112), ("basket", 90), ("篮球", 95), ("cba", 92),
        ("nfl", 88), ("mlb", 82), ("nhl", 82),
        ("ufc", 90), ("formula 1", 92), ("formula", 88), ("f1", 88), ("motogp", 85),
        ("olympic", 80), ("tnt sport", 96),
        ("英超", 100), ("premier league", 98), ("sky sports main", 96), ("sky sports premier", 96),
        ("sky sports football", 94), ("premier sports", 92), ("premier", 70),
        ("西甲", 100), ("laliga", 95), ("la liga", 95), ("movistar liga", 93), ("movistar deportes", 90),
        ("德甲", 100), ("bundesliga", 95), ("sportdigital", 90), ("sky sport top", 88),
        ("意甲", 100), ("serie a", 95), ("sportitalia", 90), ("rai sport", 85), ("calcio", 82),
        ("法甲", 100), ("ligue 1", 95), ("rmc sport", 92), ("canal+ sport", 90),
        ("欧冠", 98), ("champions", 92), ("liga de campeones", 92),
        ("风云足球", 88), ("goltv", 80), ("golazo", 78), ("digi sport", 75), ("arena sport", 72),
        ("golf channel", 75), ("tennis channel", 75), ("red bull", 70),
        ("football", 40), ("soccer", 40), ("basketball", 95),
        ("sport", 20), ("体育", 25),
    ]

    private static let logoBase = "https://raw.githubusercontent.com/tv-logo/tv-logos/main/countries"

    /// Verified multi-line seeds (primary + backups). Same display name merges for failover.
    private static let curatedSeeds: [(name: String, urls: [String], logo: String?)] = {
        let uk = "\(logoBase)/united-kingdom"
        let us = "\(logoBase)/united-states"
        let cnCCTV5 = "https://live.fanmingming.com/tv/CCTV5.png"
        return [
            // ── 国内（线路来自公开镜像，同名会与大陆列表合并备用）──
            ("睛彩篮球", [
                "http://gslbserv.itv.cmvideo.cn/index.m3u8?channel-id=FifastbLive&Contentid=3000000020000011529&livemode=1&stbId=YanG-1989",
            ], cnCCTV5),
            ("足球 · CCTV风云足球", [
                "http://38.75.136.137:98/gslb/dsdqpub/fyzq.m3u8?auth=testpub",
            ], cnCCTV5),

            // ── 篮球 / NBA ────────────────────────────────────────
            ("NBA TV", [
                "https://cdn1.ayitistream.com/NBATV/index.m3u8",
                "https://7nyaler.streamhostingcdn.top/stream/25/index.m3u8",
            ], "\(us)/nba-tv-us.png"),
            ("Sky Sport Basket", [
                "https://7nyaler.streamhostingcdn.top/stream/9/index.m3u8",
            ], "\(uk)/sky-sports-arena-uk.png"),

            // ── 英超 / UK 足球 ─────────────────────────────────────
            ("英超 · Sky Sports Main Event", [
                "https://7nyaler.streamhostingcdn.top/stream/19/index.m3u8",
            ], "\(uk)/sky-sports-main-event-uk.png"),
            ("英超 · Sky Sports Premier League", [
                "https://7nyaler.streamhostingcdn.top/stream/42/index.m3u8",
            ], "\(uk)/sky-sports-premier-league-uk.png"),
            ("英超 · Sky Sports Football", [
                "https://7nyaler.streamhostingcdn.top/stream/43/index.m3u8",
            ], "\(uk)/sky-sports-football-uk.png"),
            ("英超 · Sky Sports News", [
                "https://7nyaler.streamhostingcdn.top/stream/38/index.m3u8",
            ], "\(uk)/sky-sports-news-uk.png"),
            ("英超 · Premier Sports 1", [
                "https://7nyaler.streamhostingcdn.top/stream/47/index.m3u8",
                "https://7nyaler.streamhostingcdn.top/stream/40/index.m3u8",
            ], "\(uk)/premier-sports-1-uk.png"),
            ("英超 · Premier Sports 2", [
                "https://7nyaler.streamhostingcdn.top/stream/5/index.m3u8",
            ], "\(uk)/premier-sports-1-uk.png"),
            ("英超 · TNT Sports 1", [
                "https://7nyaler.streamhostingcdn.top/stream/13/index.m3u8",
            ], "\(uk)/tnt-sports-1-uk.png"),
            ("英超 · TNT Sports 2", [
                "https://7nyaler.streamhostingcdn.top/stream/14/index.m3u8",
            ], "\(uk)/tnt-sports-1-uk.png"),
            ("英超 · TNT Sports 3", [
                "https://7nyaler.streamhostingcdn.top/stream/16/index.m3u8",
            ], "\(uk)/tnt-sports-1-uk.png"),
            ("英超 · TNT Sports 4", [
                "https://7nyaler.streamhostingcdn.top/stream/17/index.m3u8",
            ], "\(uk)/tnt-sports-1-uk.png"),
            ("英超 · Match of the Day", [
                "https://7nyaler.streamhostingcdn.top/stream/41/index.m3u8",
            ], "\(uk)/sky-sports-football-uk.png"),

            // ── 西甲 / 欧冠 ────────────────────────────────────────
            ("西甲 · Movistar Deportes", [
                "https://7nyaler.streamhostingcdn.top/stream/18/index.m3u8",
            ], nil),
            ("欧冠 · Movistar Liga de Campeones", [
                "https://7nyaler.streamhostingcdn.top/stream/36/index.m3u8",
            ], nil),
            ("西甲 · GolTV", [
                "http://177.234.249.178:8888/GOLTV/index.m3u8",
            ], nil),

            // ── 德甲 ──────────────────────────────────────────────
            ("德甲 · Sky Sport Top Event", [
                "https://7nyaler.streamhostingcdn.top/stream/6/index.m3u8",
            ], nil),
            ("德甲 · Sportdigital Fussball", [
                "https://7nyaler.streamhostingcdn.top/stream/15/index.m3u8",
            ], nil),
            ("德甲 · Sky Sport Austria 1", [
                "https://7nyaler.streamhostingcdn.top/stream/31/index.m3u8",
            ], nil),

            // ── 意甲 ──────────────────────────────────────────────
            ("意甲 · Sportitalia", [
                "https://edge-001.streamup.eu/sportitalia/sihd_abr/playlist.m3u8",
            ], nil),
            ("意甲 · Rai Sport", [
                "https://7nyaler.streamhostingcdn.top/stream/2/index.m3u8",
            ], nil),

            // ── 法甲 ──────────────────────────────────────────────
            ("法甲 · RMC Sport 1", [
                "https://7nyaler.streamhostingcdn.top/stream/59/index.m3u8",
            ], nil),
            ("法甲 · Ligue 1+", [
                "https://7nyaler.streamhostingcdn.top/stream/32/index.m3u8",
            ], nil),
            ("法甲 · Canal+ Sport", [
                "https://7nyaler.streamhostingcdn.top/stream/37/index.m3u8",
            ], nil),

            // ── 综合足球 ──────────────────────────────────────────
            ("足球 · Digi Sport 1", [
                "https://7nyaler.streamhostingcdn.top/stream/79/index.m3u8",
            ], nil),
            ("足球 · Arena Sport Premium 1", [
                "https://7nyaler.streamhostingcdn.top/stream/33/index.m3u8",
            ], nil),
            ("足球 · Arena Sport Premium 2", [
                "https://7nyaler.streamhostingcdn.top/stream/48/index.m3u8",
            ], nil),
            ("足球 · Arena Sport 4", [
                "https://7nyaler.streamhostingcdn.top/stream/67/index.m3u8",
            ], nil),
            ("足球 · Golazo Network", [
                "https://jmp2.uk/plu-63a0e33a45264d000850ed7e.m3u8",
            ], nil),
            ("足球 · TV2 Sport", [
                "https://7nyaler.streamhostingcdn.top/stream/57/index.m3u8",
            ], nil),
            ("足球 · Ziggo Sport", [
                "https://7nyaler.streamhostingcdn.top/stream/34/index.m3u8",
            ], nil),
            ("足球 · Viaplay Sports 1", [
                "https://7nyaler.streamhostingcdn.top/stream/35/index.m3u8",
            ], nil),
            ("足球 · Eleven Sports 1", [
                "https://7nyaler.streamhostingcdn.top/stream/39/index.m3u8",
            ], nil),

            // ── 综合台 / 北美 ─────────────────────────────────────
            ("ESPN", [
                "http://181.78.197.59:8000/play/a07z/index.m3u8",
                "https://d3b6q2ou5kp8ke.cloudfront.net/ESPNTheOcho.m3u8",
            ], "\(us)/espn-us.png"),
            ("ESPN 3", [
                "http://190.83.2.182:8090/ESPN3/index.m3u8",
            ], "\(us)/espn-us.png"),
            ("ESPN 4", [
                "http://181.78.197.59:8000/play/a07n/index.m3u8",
            ], "\(us)/espn-us.png"),
            ("ESPN Deportes", [
                "http://168.228.44.241:9998/play/a0dz/index.m3u8",
            ], "\(us)/espn-us.png"),
            ("ESPNU", [
                "http://23.237.104.106:8080/USA_ESPNU/index.m3u8",
                "http://85.237.89.160:9590/usa-s/ESPN-U-HD/index.m3u8",
            ], "\(us)/espn-u-us.png"),
            ("ESPN8 The Ocho", [
                "https://d3b6q2ou5kp8ke.cloudfront.net/ESPNTheOcho.m3u8",
            ], "\(us)/espn-us.png"),
            ("Fox Sports 1", [
                "http://85.237.89.160:9590/usa-s/FOX-SPORTS-1/index.m3u8",
            ], "\(us)/fox-sports-1-us.png"),
            ("Fox Sports 2", [
                "https://tvsen7.aynascope.net/foxsports2/index.m3u8",
            ], "\(us)/fox-sports-2-us.png"),
            ("beIN SPORTS 1", [
                "https://7nyaler.streamhostingcdn.top/stream/29/index.m3u8",
            ], nil),
            ("beIN SPORTS 2", [
                "https://7nyaler.streamhostingcdn.top/stream/30/index.m3u8",
            ], nil),
            ("beIN SPORTS XTRA", [
                "https://bein-xtra-bein.amagi.tv/playlist.m3u8",
                "http://201.190.41.246:9060/play/a03y/index.m3u8",
            ], "\(us)/bein-sports-xtra-us.png"),
            ("DAZN 1", [
                "https://7nyaler.streamhostingcdn.top/stream/20/index.m3u8",
            ], nil),
            ("DAZN 2", [
                "https://7nyaler.streamhostingcdn.top/stream/21/index.m3u8",
            ], nil),
            ("DAZN 5", [
                "http://znty.dyndns.org:5010/hls/eleven5.m3u8",
                "https://7nyaler.streamhostingcdn.top/stream/24/index.m3u8",
            ], nil),
            ("Eurosport 1", [
                "https://7nyaler.streamhostingcdn.top/stream/22/index.m3u8",
            ], nil),
            ("Eurosport 2", [
                "https://7nyaler.streamhostingcdn.top/stream/23/index.m3u8",
            ], nil),

            // ── 美职 / 赛车 / 板球 ─────────────────────────────────
            ("NFL Network", [
                "https://7nyaler.streamhostingcdn.top/stream/27/index.m3u8",
            ], "\(us)/nfl-network-us.png"),
            ("MLB Network", [
                "https://7nyaler.streamhostingcdn.top/stream/26/index.m3u8",
            ], "\(us)/mlb-network-us.png"),
            ("NHL Network", [
                "https://7nyaler.streamhostingcdn.top/stream/28/index.m3u8",
            ], "\(us)/nhl-network-us.png"),
            ("Sky Sports F1", [
                "https://7nyaler.streamhostingcdn.top/stream/4/index.m3u8",
            ], "\(uk)/sky-sports-f1-uk.png"),
            ("Sky Sports Racing", [
                "https://7nyaler.streamhostingcdn.top/stream/11/index.m3u8",
            ], "\(uk)/sky-sports-racing-uk.png"),
            ("Sky Sports Golf", [
                "https://7nyaler.streamhostingcdn.top/stream/7/index.m3u8",
            ], "\(uk)/sky-sports-golf-uk.png"),
            ("Sky Sports Cricket", [
                "https://7nyaler.streamhostingcdn.top/stream/3/index.m3u8",
            ], "\(uk)/sky-sports-cricket-uk.png"),
            ("Sky Sports Action", [
                "https://7nyaler.streamhostingcdn.top/stream/10/index.m3u8",
            ], "\(uk)/sky-sports-action-uk.png"),
            ("Sky Sports Arena", [
                "https://7nyaler.streamhostingcdn.top/stream/8/index.m3u8",
            ], "\(uk)/sky-sports-arena-uk.png"),
            ("Sky Sports Mix", [
                "https://7nyaler.streamhostingcdn.top/stream/12/index.m3u8",
            ], "\(uk)/sky-sports-mix-uk.png"),
            ("Red Bull TV", [
                "https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8",
            ], nil),
        ]
    }()

    static func curatedBasketballChannels() -> [Channel] {
        curatedSeedChannels().filter { SportCategory.classify($0.name) == .basketball }
    }

    static func curatedFootballChannels() -> [Channel] {
        curatedSeedChannels().filter { SportCategory.classify($0.name) == .football }
    }

    static func curatedSeedChannels() -> [Channel] {
        curatedSeeds.enumerated().compactMap { idx, item in
            let urls = item.urls.compactMap { URL(string: $0) }
            guard let primary = urls.first else { return nil }
            return Channel(
                id: "seed-sport-\(idx)-\(item.name)",
                name: item.name,
                url: primary,
                logoURL: item.logo.flatMap { URL(string: $0) },
                group: "⚽ 体育",
                epgId: nil,
                backupURLs: Array(urls.dropFirst())
            )
        }
    }

    /// Names that should live under Sports → 篮球 (even if they arrived in mainland lists).
    static func isBasketballName(_ name: String) -> Bool {
        SportCategory.classify(name) == .basketball
    }

    /// Move NBA / 篮球 names into the Sports group (safe to run after overrideGroup).
    static func relabelBasketballGroups(_ channels: [Channel]) -> [Channel] {
        channels.map { ch in
            guard isBasketballName(ch.name) else { return ch }
            var copy = ch
            copy.group = "⚽ 体育"
            return copy
        }
    }

    static func refine(_ channels: [Channel], sourceURL: String) -> [Channel] {
        let u = sourceURL.lowercased()
        // Basketball-focused extract from mixed Chinese aggregates
        if u.contains("yang-1989") || u.contains("gather.m3u") {
            let bb = channels
                .filter { isBasketballName($0.name) || $0.name.uppercased().contains("NBA") }
                .map { ch -> Channel in
                    var copy = ch
                    copy.group = "⚽ 体育"
                    return copy
                }
            return curate(bb)
        }
        guard u.contains("/categories/sports") || u.contains("/sport") || u.hasSuffix("sports.m3u") else {
            return relabelBasketballGroups(channels)
        }
        // iptv-org sports: keep recognizable brands only (drop most dead geo feeds)
        let useful = channels.filter { isUsefulRemoteSport($0.name) }.map {
            Channel(
                id: $0.id,
                name: $0.name,
                url: $0.url,
                logoURL: $0.logoURL,
                group: "⚽ 体育",
                epgId: $0.epgId,
                isFavorite: $0.isFavorite,
                lastWatched: $0.lastWatched,
                backupURLs: $0.backupURLs
            )
        }
        return curate(useful)
    }

    static func curate(_ channels: [Channel]) -> [Channel] {
        let combined = channels + curatedSeedChannels()
        let filtered = combined.filter { keep($0.name) && ChannelQuality.isCandidate($0) }
        let cleaned = filtered.map { ch -> Channel in
            var copy = ch
            copy.name = tidyDisplayName(ch.name)
            if copy.logoURL == nil {
                copy.logoURL = SportLogoMap.url(for: copy.name)
            }
            return copy
        }
        let merged = ChannelQuality.mergeMirrors(cleaned, limitBackups: 15)
        return merged.sorted(by: channelLessThan)
    }

    /// Remote sports.m3u rows worth keeping (seeds always win via merge).
    private static func isUsefulRemoteSport(_ name: String) -> Bool {
        guard keep(name) else { return false }
        let cat = SportCategory.classify(name)
        if cat == .other { return score(name) >= 70 }
        // Drop ultra-obscure geo regional feeds unless they look like known nets
        if score(name) >= 40 { return true }
        return cat == .china || cat == .football || cat == .basketball
    }

    /// Strip noisy suffixes so Sky Sports 1 HD / Sky Sports 1 merge cleanly.
    static func tidyDisplayName(_ name: String) -> String {
        var s = name.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: #"\s*\([^)]*geo[^)]*\)"#, with: "", options: [.regularExpression, .caseInsensitive])
        s = s.replacingOccurrences(of: #"\s*\[[^\]]*geo[^\]]*\]"#, with: "", options: [.regularExpression, .caseInsensitive])
        s = s.replacingOccurrences(
            of: #"[\s\-_]*((f?hd|uhd|4k|8k|1080p?|720p?|高清|超清)\s*)+$"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        s = s.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Stable display order: category → league/brand → score → name.
    static func channelLessThan(_ a: Channel, _ b: Channel) -> Bool {
        let ca = SportCategory.classify(a.name)
        let cb = SportCategory.classify(b.name)
        if ca.sortIndex != cb.sortIndex { return ca.sortIndex < cb.sortIndex }
        if ca == .football {
            let la = FootballLeague.classify(a.name)
            let lb = FootballLeague.classify(b.name)
            if la.sortIndex != lb.sortIndex { return la.sortIndex < lb.sortIndex }
        }
        if ca == .network || ca == .other || ca == .american {
            let fa = SportBrandFamily.classify(a.name)
            let fb = SportBrandFamily.classify(b.name)
            if fa.sortIndex != fb.sortIndex { return fa.sortIndex < fb.sortIndex }
        }
        let sa = score(a.name)
        let sb = score(b.name)
        if sa != sb { return sa > sb }
        return a.name.localizedStandardCompare(b.name) == .orderedAscending
    }

    static func keep(_ name: String) -> Bool {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return false }
        let lower = n.lowercased()
        if noiseKeys.contains(where: { lower.contains($0) }) { return false }
        return true
    }

    static func score(_ name: String) -> Int {
        let lower = name.lowercased()
        var n = 0
        for (key, pts) in priorityKeys where lower.contains(key) {
            n = max(n, pts)
        }
        if lower.contains("4k") || lower.contains("uhd") { n += 8 }
        else if lower.contains("1080") || lower.contains("hd") { n += 4 }
        return n
    }
}

// MARK: - Brand logos (playlist logo → tv-logos CDN → EPG)

enum SportLogoMap {
    private static let base = "https://raw.githubusercontent.com/tv-logo/tv-logos/main/countries"
    private static let rules: [(keys: [String], url: String)] = [
        (["nba tv", "nba"], "\(base)/united-states/nba-tv-us.png"),
        (["espn"], "\(base)/united-states/espn-us.png"),
        (["fox sports 1", "fox sport 1"], "\(base)/united-states/fox-sports-1-us.png"),
        (["fox sports 2", "fox sport 2"], "\(base)/united-states/fox-sports-2-us.png"),
        (["nfl"], "\(base)/united-states/nfl-network-us.png"),
        (["mlb"], "\(base)/united-states/mlb-network-us.png"),
        (["nhl"], "\(base)/united-states/nhl-network-us.png"),
        (["bein sports xtra", "bein xtra"], "\(base)/united-states/bein-sports-xtra-us.png"),
        (["sky sports main", "main event"], "\(base)/united-kingdom/sky-sports-main-event-uk.png"),
        (["sky sports premier", "premier league"], "\(base)/united-kingdom/sky-sports-premier-league-uk.png"),
        (["sky sports football"], "\(base)/united-kingdom/sky-sports-football-uk.png"),
        (["sky sports news"], "\(base)/united-kingdom/sky-sports-news-uk.png"),
        (["sky sports f1", "formula"], "\(base)/united-kingdom/sky-sports-f1-uk.png"),
        (["sky sports golf"], "\(base)/united-kingdom/sky-sports-golf-uk.png"),
        (["sky sports cricket"], "\(base)/united-kingdom/sky-sports-cricket-uk.png"),
        (["sky sports action"], "\(base)/united-kingdom/sky-sports-action-uk.png"),
        (["sky sports arena", "sky sport basket"], "\(base)/united-kingdom/sky-sports-arena-uk.png"),
        (["sky sports racing"], "\(base)/united-kingdom/sky-sports-racing-uk.png"),
        (["sky sports mix"], "\(base)/united-kingdom/sky-sports-mix-uk.png"),
        (["tnt sport"], "\(base)/united-kingdom/tnt-sports-1-uk.png"),
        (["premier sports"], "\(base)/united-kingdom/premier-sports-1-uk.png"),
        (["cctv-5", "cctv5", "cctv 5", "睛彩", "风云足球"], "https://live.fanmingming.com/tv/CCTV5.png"),
        (["广东体育"], "https://live.fanmingming.com/tv/广东体育.png"),
        (["五星体育"], "https://live.fanmingming.com/tv/五星体育.png"),
    ]

    static func url(for name: String) -> URL? {
        let n = name.lowercased()
        for rule in rules where rule.keys.contains(where: { n.contains($0) }) {
            return URL(string: rule.url)
        }
        return nil
    }
}

/// Exclusive sport bucket used for filters and section headers.
enum SportCategory: String, CaseIterable, Identifiable {
    case china
    case football
    case basketball
    case tennis
    case golf
    case motor
    case combat
    case network   // Sky / beIN / DAZN / Eurosport 综合台
    case american  // NFL / MLB / NHL / Rugby
    case cricket
    case other

    var id: String { rawValue }

    /// Display order in pickers / “全部” sections.
    var sortIndex: Int {
        switch self {
        case .china: return 0
        case .football: return 1
        case .basketball: return 2
        case .tennis: return 3
        case .golf: return 4
        case .motor: return 5
        case .combat: return 6
        case .network: return 7
        case .american: return 8
        case .cricket: return 9
        case .other: return 10
        }
    }

    var systemImage: String {
        switch self {
        case .china: return "flag.fill"
        case .football: return "soccerball"
        case .basketball: return "basketball.fill"
        case .tennis: return "tennis.racket"
        case .golf: return "figure.golf"
        case .motor: return "flag.checkered"
        case .combat: return "figure.boxing"
        case .network: return "tv.fill"
        case .american: return "american.football.fill"
        case .cricket: return "baseball.fill"
        case .other: return "ellipsis.circle"
        }
    }

    var accent: (r: Double, g: Double, b: Double) {
        switch self {
        case .china: return (0.90, 0.22, 0.21)
        case .football: return (0.18, 0.72, 0.35)
        case .basketball: return (0.95, 0.45, 0.12)
        case .tennis: return (0.45, 0.78, 0.25)
        case .golf: return (0.20, 0.55, 0.35)
        case .motor: return (0.85, 0.15, 0.20)
        case .combat: return (0.75, 0.20, 0.35)
        case .network: return (0.25, 0.45, 0.95)
        case .american: return (0.15, 0.35, 0.75)
        case .cricket: return (0.20, 0.65, 0.55)
        case .other: return (0.45, 0.45, 0.50)
        }
    }

    @MainActor
    func title(_ loc: LanguageManager) -> String {
        switch self {
        case .china: return loc.t("sports.filter.china")
        case .football: return loc.t("sports.filter.football")
        case .basketball: return loc.t("sports.filter.basketball")
        case .tennis: return loc.t("sports.filter.tennis")
        case .golf: return loc.t("sports.filter.golf")
        case .motor: return loc.t("sports.filter.motor")
        case .combat: return loc.t("sports.filter.combat")
        case .network: return loc.t("sports.filter.network")
        case .american: return loc.t("sports.filter.american")
        case .cricket: return loc.t("sports.filter.cricket")
        case .other: return loc.t("sports.filter.other")
        }
    }

    /// First matching rule wins — channels belong to exactly one category.
    static func classify(_ name: String) -> SportCategory {
        let n = name.lowercased()

        // Explicit football / Big Five labels beat basketball heuristics
        if matches(n, [
            "英超", "西甲", "德甲", "意甲", "法甲", "欧冠", "风云足球",
            "足球 ·", "足球·", "football ·", "tnt sport", "match of the day",
            "ligue 1", "canal+ sport", "ziggo sport", "viaplay sport", "eleven sport",
        ]) {
            return .football
        }

        // Basketball — NBA / 篮球 only (ESPN/Fox go to network)
        if matches(n, [
            "basketball", "nba", "wnba", "ncaa basket", "ncaa basketball",
            "euroleague", "fiba", "baloncesto", "basket", "nbl", "pba",
            "cba", "篮球", "籃球", "篮板", "籃板", "睛彩篮球", "睛彩籃球",
            "sky sport basket",
        ]) {
            return .basketball
        }

        if matches(n, [
            "cctv5", "cctv 5", "cctv-5", "cctv5+", "cctv 5+",
            "广东体育", "五星体育", "劲爆体育", "超级体育", "体育频道",
            "天行体育", "新视觉",
        ]) || (n.contains("体育") && !n.contains("足球") && !n.contains("篮球")
               && n.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }) {
            return .china
        }
        if matches(n, [
            "football", "soccer", "premier", "laliga", "la liga", "bundesliga",
            "serie a", "ligue 1", "champions league", "europa league",
            "world cup", "fifa", "mls", "eredi", "primeira",
            "sky sports main", "sky sports premier", "sky sports football", "sky sports news",
            "sky sport top", "sky sport austria", "premier sports",
            "movistar liga", "movistar deportes", "liga de campeones",
            "sportdigital", "fussball", "fußball", "sportitalia", "rai sport",
            "rmc sport", "canal+ sport", "canal plus sport",
            "goltv", "golazo", "digi sport", "arena sport", "tv2 sport", "tv2sport",
            "风云足球", "solocalcio", "calcio",
            "足球", "英超", "西甲", "德甲", "意甲", "法甲", "中超", "欧冠", "世界杯",
        ]) {
            return .football
        }
        if matches(n, ["tennis", "atp", "wta", "roland", "wimbledon", "网球"]) {
            return .tennis
        }
        if matches(n, ["golf", "pga", "lpga", "高尔夫", "sky sports golf"]) {
            return .golf
        }
        if matches(n, [
            "formula", "f1", "motogp", "moto gp", "nascar", "indycar",
            "rally", "赛车", "摩托", "wrx", "sky sports f1", "sky sports racing", "red bull",
        ]) {
            return .motor
        }
        if matches(n, ["ufc", "boxing", "wwe", "mma", "拳击", "格斗", "wrestling"]) {
            return .combat
        }
        if matches(n, [
            "nfl", "mlb", "nhl", "rugby", "ncaa football", "cfl",
            "redzone", "mlb network", "nhl network", "nfl network",
        ]) {
            return .american
        }
        if matches(n, ["cricket", "ipl", "t20", "willow", "板球", "sky sports cricket"]) {
            return .cricket
        }
        if matches(n, [
            "sky sport", "skysports", "sky sports",
            "bein sport", "beinsport", "bein sports", "bein",
            "dazn", "eurosport", "supersport", "super sport",
            "espn", "fox sport", "foxsports",
            "tsn", "rds", "sporttv", "sport tv", "movistar",
            "stadium", "olympic", "olympics", "sport1", "sport 1",
            "sport 2", "sport2", "arena sport", "digi sport",
            "polsat sport", "nova sport", "canal+ sport", "canal plus sport",
            "bt sport", "tnt sport", "tntsports", "nbc sport", "cbs sport",
            "abc sport", "s sport", "one sports", "premier sports",
            "solar sports", "ert sport", "sportextra", "sport extra",
            "综合体育", "体育台",
        ]) {
            return .network
        }
        return .other
    }

    private static func matches(_ name: String, _ keys: [String]) -> Bool {
        keys.contains { name.contains($0) }
    }
}

/// Finer buckets inside「综合 / 其他」so long lists stay readable.
enum SportBrandFamily: String, CaseIterable {
    case sky, bein, dazn, euro, usNet, latin, asia, misc

    var sortIndex: Int {
        switch self {
        case .sky: return 0
        case .bein: return 1
        case .dazn: return 2
        case .euro: return 3
        case .usNet: return 4
        case .latin: return 5
        case .asia: return 6
        case .misc: return 7
        }
    }

    var systemImage: String {
        switch self {
        case .sky: return "cloud.fill"
        case .bein: return "play.tv.fill"
        case .dazn: return "play.rectangle.fill"
        case .euro: return "globe.europe.africa.fill"
        case .usNet: return "globe.americas.fill"
        case .latin: return "globe.americas"
        case .asia: return "globe.asia.australia.fill"
        case .misc: return "ellipsis.circle"
        }
    }

    @MainActor
    func title(_ loc: LanguageManager) -> String {
        switch self {
        case .sky: return loc.t("sports.brand.sky")
        case .bein: return loc.t("sports.brand.bein")
        case .dazn: return loc.t("sports.brand.dazn")
        case .euro: return loc.t("sports.brand.euro")
        case .usNet: return loc.t("sports.brand.us")
        case .latin: return loc.t("sports.brand.latin")
        case .asia: return loc.t("sports.brand.asia")
        case .misc: return loc.t("sports.brand.misc")
        }
    }

    static func classify(_ name: String) -> SportBrandFamily {
        let n = name.lowercased()
        if n.contains("sky sport") || n.contains("skysports") { return .sky }
        if n.contains("bein") { return .bein }
        if n.contains("dazn") { return .dazn }
        if n.contains("eurosport") || n.contains("supersport") || n.contains("digi sport")
            || n.contains("polsat sport") || n.contains("nova sport") || n.contains("canal+")
            || n.contains("bt sport") || n.contains("tnt sport") || n.contains("sport1")
            || n.contains("sport 1") || n.contains("arena sport") || n.contains("eleven")
            || n.contains("viaplay") || n.contains("ziggo") {
            return .euro
        }
        if n.contains("espn") || n.contains("fox sport") || n.contains("nbc")
            || n.contains("cbs sport") || n.contains("stadium") || n.contains("tsn") {
            return .usNet
        }
        if n.contains("movistar") || n.contains("deportes") || n.contains("espn deportes")
            || n.contains("tyc") || n.contains("espn latin") {
            return .latin
        }
        if n.contains("one sport") || n.contains("premier sport") || n.contains("solar sport")
            || n.contains("astro") || n.contains("s sport") || n.contains("ert sport")
            || n.unicodeScalars.contains(where: { $0.value >= 0x4E00 && $0.value <= 0x9FFF }) {
            return .asia
        }
        return .misc
    }
}

/// Big Five + UCL buckets inside「足球」so the list reads like a league guide.
enum FootballLeague: String, CaseIterable {
    case premier   // 英超
    case laliga    // 西甲
    case bundesliga
    case serieA
    case ligue1
    case ucl       // 欧冠 / UEFA
    case other

    var sortIndex: Int {
        switch self {
        case .premier: return 0
        case .laliga: return 1
        case .bundesliga: return 2
        case .serieA: return 3
        case .ligue1: return 4
        case .ucl: return 5
        case .other: return 6
        }
    }

    var systemImage: String {
        switch self {
        case .premier: return "crown.fill"
        case .laliga: return "sun.max.fill"
        case .bundesliga: return "shield.fill"
        case .serieA: return "flag.fill"
        case .ligue1: return "flame.fill"
        case .ucl: return "trophy.fill"
        case .other: return "soccerball"
        }
    }

    @MainActor
    func title(_ loc: LanguageManager) -> String {
        switch self {
        case .premier: return loc.t("sports.league.premier")
        case .laliga: return loc.t("sports.league.laliga")
        case .bundesliga: return loc.t("sports.league.bundesliga")
        case .serieA: return loc.t("sports.league.seriea")
        case .ligue1: return loc.t("sports.league.ligue1")
        case .ucl: return loc.t("sports.league.ucl")
        case .other: return loc.t("sports.league.other")
        }
    }

    static func classify(_ name: String) -> FootballLeague {
        let n = name.lowercased()
        if matches(n, ["英超", "premier league", "sky sports main", "sky sports premier",
                        "sky sports football", "sky sports news", "premier sports",
                        "tnt sport", "match of the day"]) {
            return .premier
        }
        if matches(n, ["西甲", "laliga", "la liga", "movistar deportes", "goltv"]) {
            return .laliga
        }
        if matches(n, ["德甲", "bundesliga", "sportdigital", "sky sport top", "sky sport austria", "fussball", "fußball"]) {
            return .bundesliga
        }
        if matches(n, ["意甲", "serie a", "sportitalia", "rai sport", "calcio"]) {
            return .serieA
        }
        if matches(n, ["法甲", "ligue 1", "rmc sport", "canal+ sport", "canal plus sport"]) {
            return .ligue1
        }
        if matches(n, ["欧冠", "champions", "liga de campeones", "ucl"]) {
            return .ucl
        }
        return .other
    }

    private static func matches(_ name: String, _ keys: [String]) -> Bool {
        keys.contains { name.contains($0) }
    }
}
