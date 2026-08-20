import Foundation

/// Filters and labels Chinese public live lists (vbskycn etc.).
/// Keeps linear TV, movie loop channels, and 春晚 year streams — not random single-title VOD.
enum ChinesePlaylist {
    static func refine(_ channels: [Channel], sourceURL: String) -> [Channel] {
        let u = sourceURL.lowercased()
        if u.contains("vbskycn/iptv") {
            return refineVbskycn(channels)
        }
        if u.contains("/countries/cn") {
            return curateMainland(channels.map {
                Channel(id: $0.id, name: displayName($0.name), url: $0.url,
                        logoURL: $0.logoURL, group: "🇨🇳 中国大陆",
                        epgId: $0.epgId, isFavorite: $0.isFavorite,
                        lastWatched: $0.lastWatched, backupURLs: $0.backupURLs)
            })
        }
        return channels
    }

    /// Drop foreign / religious / non-mainland noise, merge CCTV / 卫视 duplicates into
    /// one row with backup URLs (Live TV auto-failover), then sort CCTV → 卫视 → 地方台.
    static func curateMainland(_ channels: [Channel]) -> [Channel] {
        let filtered = channels.filter { isMainlandChannel($0.name) }
        let merged = mergeMainlandMirrors(filtered, limitBackups: 12)
        return merged.sorted { mainlandScore($0.name) > mainlandScore($1.name) }
    }

    /// Group CCTV-1 / CCTV1 / CCTV-1综合 / 央视一套 into one channel; stash other URLs as lines.
    private static func mergeMainlandMirrors(_ channels: [Channel], limitBackups: Int) -> [Channel] {
        let grouped = Dictionary(grouping: channels, by: { mainlandMirrorKey($0.name) })
        return grouped.values.compactMap { group -> Channel? in
            let ranked = group.sorted { ChannelQuality.score($0) > ChannelQuality.score($1) }
            guard var best = ranked.first else { return nil }
            best.name = preferredDisplayName(for: group.map(\.name), key: mainlandMirrorKey(best.name))

            var urls: [URL] = []
            var seen = Set<String>([best.url.absoluteString])
            for ch in ranked {
                for u in ch.allStreamURLs {
                    let key = u.absoluteString
                    guard seen.insert(key).inserted else { continue }
                    urls.append(u)
                    if urls.count >= limitBackups { break }
                }
                if urls.count >= limitBackups { break }
            }
            if best.logoURL == nil {
                best.logoURL = ranked.compactMap(\.logoURL).first
            }
            if ranked.contains(where: \.isFavorite) { best.isFavorite = true }
            if let latest = ranked.compactMap(\.lastWatched).max() {
                best.lastWatched = latest
            }
            best.backupURLs = urls
            return best
        }
    }

    /// Stable merge key so CCTV variants become one entry.
    static func mainlandMirrorKey(_ name: String) -> String {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let u = n.uppercased()

        // CCTV-5+
        if u.range(of: #"CCTV[\s\-]?5\s*[\+＋]"#, options: .regularExpression) != nil {
            return "cctv:5+"
        }
        // CCTV 4K / 8K (keep separate from SD/HD siblings)
        if u.contains("CCTV"), u.contains("4K") || u.contains("8K") {
            if let num = cctvNumber(u) { return "cctv:\(num):uhd" }
            return "cctv:uhd"
        }
        if let num = cctvNumber(u) {
            return "cctv:\(num)"
        }
        if let alias = cctvChineseAlias(n) {
            return "cctv:\(alias)"
        }

        if u.contains("CGTN") {
            if u.contains("DOC") || n.contains("纪录") || n.contains("紀錄") { return "cgtn:doc" }
            if u.contains("ESPANOL") || u.contains("ESPAÑOL") || n.contains("西班牙语") { return "cgtn:esp" }
            if u.contains("FRANÇAIS") || u.contains("FRANCAIS") || n.contains("法语") { return "cgtn:fra" }
            if u.contains("ARABIC") || n.contains("阿语") || n.contains("阿拉伯") { return "cgtn:ara" }
            if u.contains("РУССКИЙ") || u.contains("RUSSIAN") || n.contains("俄语") { return "cgtn:rus" }
            return "cgtn:en"
        }

        if n.contains("卫视") || n.contains("衛視") {
            var core = n
                .replacingOccurrences(of: "衛視", with: "卫视")
                .replacingOccurrences(
                    of: #"[\s\-_]*(HD|FHD|UHD|4K|8K|1080[Pp]?|720[Pp]?|高清|超清|备用|備用|线路\d*|\d+)$"#,
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)
            core = core.replacingOccurrences(of: " ", with: "")
            return "ws:" + core.lowercased()
        }

        return ChannelQuality.canonicalName(n)
    }

    static func preferredDisplayName(for names: [String], key: String) -> String {
        if key == "cctv:5+" { return "CCTV-5+" }
        if key == "cctv:uhd" { return "CCTV-4K" }
        if key.hasPrefix("cctv:"), key.hasSuffix(":uhd"),
           let num = key.split(separator: ":").dropFirst().first {
            return "CCTV-\(num) 4K"
        }
        if key.hasPrefix("cctv:"), let num = key.split(separator: ":").last, Int(num) != nil {
            return "CCTV-\(num)"
        }
        if key == "cgtn:en" { return "CGTN" }
        if key == "cgtn:doc" { return "CGTN Documentary" }
        if key == "cgtn:esp" { return "CGTN Español" }
        if key == "cgtn:fra" { return "CGTN Français" }
        if key == "cgtn:ara" { return "CGTN Arabic" }
        if key == "cgtn:rus" { return "CGTN Русский" }
        if key.hasPrefix("ws:") {
            // Prefer a clean 卫视 title without HD / 备用 suffixes
            let cleaned = names
                .map {
                    $0.replacingOccurrences(of: "衛視", with: "卫视")
                        .replacingOccurrences(
                            of: #"[\s\-_]*(HD|FHD|UHD|4K|1080[Pp]?|720[Pp]?|高清|超清|备用|備用|线路\d*)$"#,
                            with: "",
                            options: [.regularExpression, .caseInsensitive]
                        )
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .filter { $0.contains("卫视") }
            if let best = cleaned.min(by: { $0.count < $1.count }) { return best }
        }
        // Shortest non-empty original as fallback
        return names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .min(by: { $0.count < $1.count })
            ?? names.first
            ?? key
    }

    /// 「央视综合」等中文别名 → CCTV 编号
    private static func cctvChineseAlias(_ name: String) -> String? {
        let n = name.replacingOccurrences(of: " ", with: "")
        // Only when it clearly refers to a CCTV feed
        let isYangshi = n.contains("央视") || n.contains("央視") || n.contains("中央电视台")
            || n.uppercased().contains("CCTV")
        guard isYangshi || n.hasPrefix("中央") else { return nil }

        let pairs: [(String, String)] = [
            ("综合", "1"), ("綜合", "1"), ("一套", "1"),
            ("财经", "2"), ("財經", "2"), ("二套", "2"),
            ("综艺", "3"), ("綜藝", "3"), ("三套", "3"),
            ("中文国际", "4"), ("国际", "4"), ("四套", "4"),
            ("体育", "5"), ("體育", "5"), ("五套", "5"),
            ("电影", "6"), ("電影", "6"), ("六套", "6"),
            ("国防军事", "7"), ("军事", "7"), ("七套", "7"),
            ("电视剧", "8"), ("電視劇", "8"), ("八套", "8"),
            ("纪录", "9"), ("紀錄", "9"), ("九套", "9"),
            ("科教", "10"), ("十套", "10"),
            ("戏曲", "11"), ("戲曲", "11"),
            ("社会与法", "12"), ("社会与法", "12"),
            ("新闻", "13"), ("新聞", "13"),
            ("少儿", "14"), ("少兒", "14"),
            ("音乐", "15"), ("音樂", "15"),
            ("奥林匹克", "16"), ("奥运", "16"),
            ("农业农村", "17"), ("农业", "17"),
        ]
        for (key, num) in pairs where n.contains(key) {
            return num
        }
        return nil
    }

    // MARK: - vbskycn

    private static func refineVbskycn(_ channels: [Channel]) -> [Channel] {
        var gala: [Channel] = []
        var rest: [Channel] = []
        for ch in channels {
            let name = ch.name.trimmingCharacters(in: .whitespaces)
            guard keep(group: ch.group, name: name) else { continue }
            let mapped = Channel(
                id: ch.id,
                name: displayName(name),
                url: ch.url,
                logoURL: ch.logoURL,
                group: mappedGroup(group: ch.group, name: name),
                epgId: ch.epgId,
                isFavorite: ch.isFavorite,
                lastWatched: ch.lastWatched,
                backupURLs: ch.backupURLs
            )
            if mapped.group == "🎆 春晚" {
                gala.append(mapped)
            } else {
                rest.append(mapped)
            }
        }
        gala.sort { galaYear($0.name) > galaYear($1.name) }
        let mainland = curateMainland(rest.filter { $0.group == "🇨🇳 中国大陆" })
        let other = rest.filter { $0.group != "🇨🇳 中国大陆" }
        return gala + mainland + other
    }

    static func keep(group: String, name: String) -> Bool {
        if group.contains("更新") || group.contains("解说") { return false }
        if name.isEmpty { return false }
        if group.contains("春晚") || name.contains("春晚") { return true }
        if group == "电影频道" { return isLinearMovieChannel(name) }
        return true
    }

    /// Linear / themed movie channels — skip star-name single-title loops (刘德华电影 etc.).
    static func isLinearMovieChannel(_ name: String) -> Bool {
        let n = name.trimmingCharacters(in: .whitespaces)
        let u = n.uppercased()
        if u.contains("CHC") { return true }
        if u.contains("CCTV"), u.contains("6") || u.contains("8") || n.contains("剧场") { return true }
        if ["影视", "影視", "影院", "剧场", "劇場"].contains(where: { n.contains($0) }) { return true }
        if n.hasPrefix("电影") {
            let themed = ["八点", "贺岁", "賀歲", "喜剧", "嫣然", "高分", "动作", "動作",
                          "战争", "犯罪", "谍战", "諜戰", "丧尸", "功夫", "搞笑", "专场", "專場", "影厅", "片"]
            return themed.contains(where: { n.dropFirst(2).contains($0) })
        }
        let themedKeys = ["美亚", "美亞", "贺岁", "賀歲", "八点档", "八點檔", "合集", "专场", "專場",
                          "武侠", "武俠", "科幻", "嫣然", "HBO"]
        if themedKeys.contains(where: { n.contains($0) }) { return true }
        if n.hasSuffix("电影") || n.hasSuffix("電影") { return false }
        return false
    }

    static func isMovieLoop(_ name: String) -> Bool {
        isLinearMovieChannel(name)
            || ["电影", "電影"].contains(where: { name.contains($0) })
    }

    static func mappedGroup(group: String, name: String) -> String {
        let n = name.uppercased()
        if group.contains("春晚") || name.contains("春晚") { return "🎆 春晚" }
        if SportsPlaylist.isBasketballName(name) { return "⚽ 体育" }
        if group == "电影频道"
            || isMovieLoop(name)
            || n == "CCTV6" || n.contains("CCTV-6") || n.contains("CCTV6")
            || n == "CCTV8" || n.contains("CCTV-8") || n.contains("CCTV8") {
            return "🎬 华语影视"
        }
        if group.contains("纪录") { return "📖 纪录片" }
        if group.contains("儿童") { return "🧒 儿童/动画" }
        if group.contains("体育") { return "⚽ 体育" }
        if group.contains("音乐") { return "🎵 音乐" }
        return "🇨🇳 中国大陆"
    }

    // MARK: - Mainland filter / sort

    private static let foreignRejectKeys = [
        // Western / intl
        "bbc", "cnn", "fox news", "foxnews", "sky news", "al jazeera", "euronews", "france 24",
        "dw ", "deutsche welle", "bloomberg", "reuters", "nbc", "cbs news", "abc news", "msnbc",
        "discovery", "national geographic", "nat geo", "history channel", "cartoon network",
        "disney", "nickelodeon", "mtv ", "vh1", "espn", "beinsport", "dazn",
        // Asia neighbors (should not sit under 中国大陆)
        "nhk", "fuji tv", "tv tokyo", "asahi", "nippon", "kbs", "mbc", "sbs ", "tvn", "jtbc",
        "arirang", "tvbs", "三立", "東森", "东森", "中天", "民視", "民视", "緯來", "纬来", "八大",
        "翡翠", "明珠", "無線", "无线", "viutv", "viu tv", "hoy ", "rthk", "now tv",
        "abs-cbn", "gma ", "kapamilya", "channel 8", "channel u", "suria", "astro",
        "thai", "thailand", "vietnam", "viet ", "indonesia", "bollywood", "sony tv", "zee ",
        // Religious / foreign Chinese diaspora feeds often misfiled under cn.m3u
        "angel tv", "abn china", "abn ", "god tv", "tbn", "daystar", "ewtn", "cbn ",
        "hope channel", "3abn", "llbn",
        // Taiwan / HK / overseas Chinese that should not sit under mainland
        "公视", "公視", "三立", "东森", "東森", "中天", "tvbs", "八大", "纬来", "緯來",
        "民视", "民視", "台视", "台視", "中视", "中視", "华视", "華視", "翡翠", "明珠",
        "无线", "無線", "viutv", "viu tv", "hoy tv", "凤凰卫视香港", "鳳凰衛視香港",
        // Geo markers
        "geo-blocked", "[geo",
    ]

    private static let mainlandPositiveKeys = [
        "cctv", "cgtn", "cetv", "chc", "brtv", "btv",
        "卫视", "衛視", "综合", "綜合", "新闻", "新聞", "财经", "財經",
        "体育", "體育", "少儿", "少兒", "纪录", "紀錄", "综艺", "綜藝",
        "影视频道", "影视", "影視", "戏曲", "戲曲", "教育", "农业", "農業",
        "央视", "央視", "中央", "中国", "中國", "湖南", "浙江", "江苏", "江蘇",
        "东方", "東方", "北京", "上海", "广东", "廣東", "深圳", "四川", "重庆", "重慶",
        "天津", "山东", "山東", "安徽", "福建", "江西", "河南", "湖北", "湖南",
        "河北", "山西", "陕西", "陝西", "辽宁", "遼寧", "吉林", "黑龙江", "黑龍江",
        "云南", "雲南", "贵州", "貴州", "广西", "廣西", "海南", "甘肃", "甘肅",
        "青海", "宁夏", "寧夏", "新疆", "西藏", "内蒙古", "內蒙古", "厦门", "廈門",
    ]

    static func isMainlandChannel(_ name: String) -> Bool {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return false }
        let lower = n.lowercased()
        if foreignRejectKeys.contains(where: { lower.contains($0) }) { return false }

        if lower.contains("cctv") || lower.contains("cgtn") || lower.contains("cetv") { return true }
        if n.contains("卫视") || n.contains("衛視") { return true }
        if mainlandPositiveKeys.contains(where: { n.localizedCaseInsensitiveContains($0) }) { return true }

        // Chinese script + looks like a local station (台 / 频道) — not any short Han title
        let hasHan = n.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
        if hasHan {
            if ["台", "频道", "頻道", "广播", "廣播", "卫视", "衛視"].contains(where: { n.contains($0) }) {
                return true
            }
        }
        return false
    }

    static func mainlandScore(_ name: String) -> Int {
        let n = name.trimmingCharacters(in: .whitespaces)
        let u = n.uppercased()
        var score = 0

        if u.contains("CCTV") {
            score += 5000
            if let num = cctvNumber(u) { score += (100 - num) * 10 } // CCTV-1 first
            if u.contains("4K") || u.contains("8K") { score += 5 }
            if u.contains("5+") || u.contains("5＋") { score += 2 }
        } else if u.contains("CGTN") {
            score += 4500
        } else if u.contains("CETV") || u.contains("CHC") {
            score += 4200
        } else if n.contains("卫视") || n.contains("衛視") {
            score += 3000
            score += weishiBoost(n)
        } else if n.contains("少儿") || n.contains("少兒") || n.contains("卡酷") || lowerContains(n, "kaku") {
            score += 2000
        } else if n.contains("新闻") || n.contains("新聞") {
            score += 1800
        } else if n.contains("体育") || n.contains("體育") {
            score += 1600
        } else if n.unicodeScalars.contains(where: { $0.value >= 0x4E00 && $0.value <= 0x9FFF }) {
            score += 1000
        }

        if u.contains("HD") || u.contains("1080") { score += 8 }
        if lowerContains(n, "backup") || n.contains("备用") || n.contains("備用") { score -= 40 }
        return score
    }

    private static func lowerContains(_ name: String, _ key: String) -> Bool {
        name.lowercased().contains(key)
    }

    private static func cctvNumber(_ upper: String) -> Int? {
        // CCTV-1 / CCTV1 / CCTV 13
        let pattern = #"CCTV[\s\-]?(\d{1,2})"#
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: upper, range: NSRange(upper.startIndex..., in: upper)),
              m.numberOfRanges >= 2,
              let range = Range(m.range(at: 1), in: upper) else { return nil }
        return Int(upper[range])
    }

    private static func weishiBoost(_ name: String) -> Int {
        let order = ["湖南", "浙江", "江苏", "江蘇", "东方", "東方", "北京", "广东", "廣東",
                     "深圳", "安徽", "山东", "山東", "四川", "天津", "重庆", "重慶",
                     "辽宁", "遼寧", "黑龙江", "黑龍江", "江西", "河北", "河南", "湖北",
                     "福建", "广西", "廣西", "云南", "雲南", "贵州", "貴州", "陕西", "陝西"]
        if let idx = order.firstIndex(where: { name.contains($0) }) {
            return (order.count - idx) * 5
        }
        return 0
    }

    private static func displayName(_ name: String) -> String {
        name.replacingOccurrences(of: "  ", with: " ")
    }

    private static func galaYear(_ name: String) -> Int {
        let digits = name.prefix(while: { $0.isNumber })
        return Int(digits) ?? 0
    }
}
