import Foundation

/// Curates global sports live lists (iptv-org sports + regional sports channels).
enum SportsPlaylist {
    private static let noiseKeys = [
        "geo-blocked", "[geo", "xxx", "adult", "porn", "shop", "infomercial",
        "radio only", "not 24/7", "offline",
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
        ("olympic", 80), ("premier league", 78), ("premier", 70),
        ("laliga", 70), ("bundesliga", 68), ("serie a", 68), ("champions", 68),
        ("golf channel", 75), ("tennis channel", 75),
        ("football", 40), ("soccer", 40), ("basketball", 95),
        ("sport", 20), ("体育", 25),
    ]

    /// Extra public basketball / NBA-adjacent seeds (merged as backup lines when names match).
    private static let basketballSeeds: [(name: String, url: String)] = [
        ("NBA TV", "https://cdn1.ayitistream.com/NBATV/index.m3u8"),
        ("Sky Sport Basket", "https://7nyaler.streamhostingcdn.top/stream/9/index.m3u8"),
        ("睛彩篮球", "http://gslbserv.itv.cmvideo.cn/index.m3u8?channel-id=FifastbLive&Contentid=3000000020000011529&livemode=1&stbId=YanG-1989"),
        ("ESPN", "http://181.78.197.59:8000/play/a07z/index.m3u8"),
        ("ESPN 3", "http://190.83.2.182:8090/ESPN3/index.m3u8"),
        ("ESPN 4", "http://181.78.197.59:8000/play/a07n/index.m3u8"),
        ("ESPN Deportes", "http://168.228.44.241:9998/play/a0dz/index.m3u8"),
        ("ESPNU", "http://23.237.104.106:8080/USA_ESPNU/index.m3u8"),
        ("ESPNU HD", "http://85.237.89.160:9590/usa-s/ESPN-U-HD/index.m3u8"),
        ("ESPN8 The Ocho", "https://d3b6q2ou5kp8ke.cloudfront.net/ESPNTheOcho.m3u8"),
        ("Fox Sports 1", "http://85.237.89.160:9590/usa-s/FOX-SPORTS-1/index.m3u8"),
        ("Fox Sports 2", "https://tvsen7.aynascope.net/foxsports2/index.m3u8"),
        ("beIN SPORTS XTRA", "https://bein-xtra-bein.amagi.tv/playlist.m3u8"),
        ("beIN SPORTS XTRA Español", "http://201.190.41.246:9060/play/a03y/index.m3u8"),
        ("Zona DAZN", "https://7nyaler.streamhostingcdn.top/stream/24/index.m3u8"),
        ("DAZN 5", "http://znty.dyndns.org:5010/hls/eleven5.m3u8"),
    ]

    static func curatedBasketballChannels() -> [Channel] {
        basketballSeeds.enumerated().compactMap { idx, item in
            guard let url = URL(string: item.url) else { return nil }
            return Channel(
                id: "seed-bb-\(idx)-\(item.name)",
                name: item.name,
                url: url,
                logoURL: nil,
                group: "⚽ 体育",
                epgId: nil
            )
        }
    }

    /// Names that should live under Sports → 篮球 (even if they arrived in mainland lists).
    static func isBasketballName(_ name: String) -> Bool {
        SportCategory.classify(name) == .basketball
    }

    /// Move NBA / 篮球 / ESPN-style names into the Sports group (safe to run after overrideGroup).
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
        return curate(channels.map {
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
        })
    }

    static func curate(_ channels: [Channel]) -> [Channel] {
        let combined = channels + curatedBasketballChannels()
        let filtered = combined.filter { keep($0.name) && ChannelQuality.isCandidate($0) }
        let cleaned = filtered.map { ch -> Channel in
            var copy = ch
            copy.name = tidyDisplayName(ch.name)
            return copy
        }
        let merged = ChannelQuality.mergeMirrors(cleaned, limitBackups: 8)
        return merged.sorted(by: channelLessThan)
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

    /// Stable display order: category → brand family → score → name.
    static func channelLessThan(_ a: Channel, _ b: Channel) -> Bool {
        let ca = SportCategory.classify(a.name)
        let cb = SportCategory.classify(b.name)
        if ca.sortIndex != cb.sortIndex { return ca.sortIndex < cb.sortIndex }
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

        // Basketball first so NBA / 篮球 / ESPN nets are not swallowed by「国内体育」
        if matches(n, [
            "basketball", "nba", "wnba", "ncaa basket", "ncaa basketball",
            "euroleague", "fiba", "baloncesto", "basket", "nbl", "pba",
            "cba", "篮球", "籃球", "篮板", "籃板", "睛彩篮球", "睛彩籃球",
            "espn", "espnu", "fox sport", "foxsports", "bein sports xtra",
            "zona dazn", "dazn 5", "dazn5",
        ]) {
            return .basketball
        }

        if matches(n, [
            "cctv5", "cctv 5", "cctv-5", "cctv5+", "cctv 5+",
            "广东体育", "五星体育", "劲爆体育", "超级体育", "体育频道",
            "天行体育", "新视觉", "睛彩",
        ]) || (n.contains("体育") && n.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }) {
            return .china
        }
        if matches(n, [
            "football", "soccer", "premier", "laliga", "la liga", "bundesliga",
            "serie a", "ligue 1", "champions league", "europa league",
            "world cup", "fifa", "mls", "eredi", "primeira",
            "足球", "英超", "西甲", "德甲", "意甲", "法甲", "中超", "欧冠", "世界杯",
        ]) {
            return .football
        }
        if matches(n, ["tennis", "atp", "wta", "roland", "wimbledon", "网球"]) {
            return .tennis
        }
        if matches(n, ["golf", "pga", "lpga", "高尔夫"]) {
            return .golf
        }
        if matches(n, [
            "formula", "f1", "motogp", "moto gp", "nascar", "indycar",
            "rally", "赛车", "摩托", "wrx",
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
        if matches(n, ["cricket", "ipl", "t20", "willow", "板球"]) {
            return .cricket
        }
        if matches(n, [
            "sky sport", "skysports", "sky sports",
            "bein sport", "beinsport", "bein sports",
            "dazn", "eurosport", "supersport", "super sport",
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
            || n.contains("sport 1") || n.contains("arena sport") {
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
