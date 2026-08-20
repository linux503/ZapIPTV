import Foundation

enum RegionalPlaylist {
    private static let dramaKeys = [
        "drama", "series", "theater", "theatre", "movie", "movies", "film", "cinema",
        "entertain", "variety", "showbiz", "music", "bollywood", "zee", "star", "colors", "sony",
        "戲劇", "戏剧", "劇", "剧", "劇場", "剧场", "影", "電影", "电影", "影院", "娛樂", "娱乐", "綜藝", "综艺",
        "音樂", "音乐", "偶像", "八大", "東森", "东森", "中天", "TVBS", "TVB", "Viu", "HOY", "KBS", "MBC", "SBS",
        "GEM", "AXN", "Celestial", "Cinema One", "Viva Cinema", "Tap Movies", "星河", "靖天", "纬来", "緯來",
        "龙华", "龍華", "美亚", "美亞",
    ]

    private static let indiaNewsKeys = [
        "news", "समाचार", "खबर", "bharat", "indiatv", "speed news", "aaj tak", "republic",
        "times now", "et now", "mirror now", "cnn-news18", "cnbc", "dd news", "abp", "lokshahi",
    ]

    private static let koreaDropKeys = [
        "shopping", "onstyle", "homeshopping", "home & shopping", "kshopping", "cj onstyle",
        "lotte home", "hyundai home", "gongyoung", "gs my shop", "buddhist", "radio",
    ]

    /// Short Latin tokens need word-boundary checks so "ctv" does not match "CCTV".
    private static let taiwanTokenKeys = ["tvbs", "cts", "ftv", "ttv", "ctv", "ebc", "cti"]
    private static let taiwanTextKeys = [
        "taiwan", "三立", "東森", "东森", "中天", "八大", "緯來", "纬来", "民視", "民视",
        "台视", "台視", "中视", "中視", "华视", "華視", "靖天", "龙华", "龍華", "公视", "公視",
        "好看", "影剧", "影劇", "戏剧", "戲劇", "都会", "都會", "欢乐", "歡樂", "超视", "超視",
        "洋片", "映画", "精采", "亚洲台", "亞洲台",
    ]

    private static let hongKongTokenKeys = ["tvb", "viu", "hoy", "rthk", "nowtv"]
    private static let hongKongTextKeys = [
        "hong kong", "jade", "pearl", "celestial", "翡翠", "明珠", "港台", "無線", "无线",
        "有線", "有线", "鳳凰", "凤凰", "耀才", "星河", "华丽", "華麗", "美亚", "美亞",
    ]

    private static let koreaKeys = [
        "korea", "korean", "kbs", "mbc", "sbs", "tvn", "jtbc", "arirang", "ebs",
        "channel a", "kpop", "드라마", "영화",
    ]

    private static let preferredGroups: Set<String> = [
        "🇹🇼 台湾", "🇭🇰 香港", "🇰🇷 韩国", "🇯🇵 日本", "🇺🇸 美国",
        "🇸🇬 新加坡", "🇻🇳 越南", "🇹🇭 泰国", "🇵🇭 菲律宾", "🇮🇳 印度",
        "🎬 华语影视",
    ]

    /// Pull Asia drama / movie / entertainment feeds into regional groups.
    static func refineExtra(_ channels: [Channel], sourceURL: String) -> [Channel] {
        let u = sourceURL.lowercased()

        if u.contains("guovin/iptv-api") || u.contains("suxuang/myiptv") {
            return channels.compactMap { ch -> Channel? in
                if isMainlandNoise(ch.name) { return nil }
                if isGeoBlocked(ch.name) { return nil }
                let g = (ch.group + " " + ch.name).lowercased()
                let fromHKGroup = g.contains("港") || g.contains("澳") || g.contains("台") || g.contains("港澳")
                guard fromHKGroup || looksHongKong(ch.name) || looksTaiwan(ch.name) else { return nil }
                if let mapped = mapGreaterChina(ch.name) {
                    return remapped(ch, group: mapped)
                }
                return nil
            }
        }

        if u.contains("/languages/zho.m3u") {
            // Keep only clear Taiwan/HK names — never dump mainland CCTV into 台湾.
            return channels.compactMap { ch in
                if isMainlandNoise(ch.name) || isGeoBlocked(ch.name) { return nil }
                guard let group = mapGreaterChina(ch.name) else { return nil }
                return remapped(ch, group: group)
            }
        }
        if u.contains("/languages/yue.m3u") {
            return channels.compactMap { ch in
                if isMainlandNoise(ch.name) || isGeoBlocked(ch.name) { return nil }
                return remapped(ch, group: "🇭🇰 香港")
            }
        }
        if u.contains("/languages/kor.m3u") {
            return channels
                .filter { !isKoreaNoise($0.name) && !isGeoBlocked($0.name) }
                .map { remapped($0, group: "🇰🇷 韩国") }
        }
        if u.contains("/categories/movies.m3u")
            || u.contains("/categories/series.m3u")
            || u.contains("/categories/entertainment.m3u") {
            return channels.compactMap { ch in
                if isMainlandNoise(ch.name) || isGeoBlocked(ch.name) { return nil }
                if let group = MoviePlaylist.mapCountryGroup(name: ch.name, epgId: ch.epgId) {
                    return remapped(ch, group: group)
                }
                guard let group = mapAsiaCategory(ch.name) else { return nil }
                return remapped(ch, group: group)
            }
        }
        return channels
    }

    static func curate(_ channels: [Channel], group: String) -> [Channel] {
        guard preferredGroups.contains(group) else { return channels }

        var filtered = channels.filter { !isGeoBlocked($0.name) }
        if group == "🇮🇳 印度" {
            filtered = filtered.filter { shouldKeepIndia($0.name) }
        }
        if group == "🇰🇷 韩国" {
            filtered = filtered.filter { !isKoreaNoise($0.name) }
        }
        if group == "🇹🇼 台湾" {
            filtered = filtered.filter { !isMainlandNoise($0.name) && (looksTaiwan($0.name) || isDramaLike($0.name.lowercased())) }
            // Drop residual CCTV / mainland leftovers
            filtered = filtered.filter { !isMainlandNoise($0.name) }
        }
        if group == "🇭🇰 香港" {
            filtered = filtered.filter { !isMainlandNoise($0.name) }
        }

        return ChannelQuality.mergeMirrors(filtered, limitBackups: 15)
            .sorted { score($0.name, group: group) > score($1.name, group: group) }
    }

    private static func remapped(_ ch: Channel, group: String) -> Channel {
        Channel(
            id: ch.id,
            name: ch.name,
            url: ch.url,
            logoURL: ch.logoURL,
            group: group,
            epgId: ch.epgId,
            isFavorite: ch.isFavorite,
            lastWatched: ch.lastWatched,
            backupURLs: ch.backupURLs
        )
    }

    private static func mapGreaterChina(_ name: String) -> String? {
        if isMainlandNoise(name) { return nil }
        if looksHongKong(name) { return "🇭🇰 香港" }
        if looksTaiwan(name) { return "🇹🇼 台湾" }
        return nil
    }

    private static func looksTaiwan(_ name: String) -> Bool {
        let lower = name.lowercased()
        if isMainlandNoise(name) { return false }
        if taiwanTextKeys.contains(where: { lower.contains($0.lowercased()) }) { return true }
        return taiwanTokenKeys.contains(where: { containsToken(lower, $0) })
    }

    private static func looksHongKong(_ name: String) -> Bool {
        let lower = name.lowercased()
        if isMainlandNoise(name) { return false }
        if hongKongTextKeys.contains(where: { lower.contains($0.lowercased()) }) { return true }
        return hongKongTokenKeys.contains(where: { containsToken(lower, $0) })
    }

    /// Avoid "ctv" matching inside "cctv".
    private static func containsToken(_ haystack: String, _ token: String) -> Bool {
        guard !token.isEmpty else { return false }
        var search = haystack
        var start = search.startIndex
        while let range = search.range(of: token, range: start..<search.endIndex) {
            let beforeOK: Bool = {
                if range.lowerBound == search.startIndex { return true }
                let prev = search[search.index(before: range.lowerBound)]
                return !prev.isLetter && !prev.isNumber
            }()
            let afterOK: Bool = {
                if range.upperBound == search.endIndex { return true }
                let next = search[range.upperBound]
                return !next.isLetter && !next.isNumber
            }()
            if beforeOK && afterOK { return true }
            start = range.upperBound
        }
        return false
    }

    private static func isMainlandNoise(_ name: String) -> Bool {
        let lower = name.lowercased()
        if lower.contains("cctv") || lower.contains("cntv") || lower.contains("央视") || lower.contains("央視") {
            return true
        }
        if lower.contains("卫视") && (lower.contains("湖南") || lower.contains("浙江") || lower.contains("东方") || lower.contains("江苏")) {
            return true
        }
        return false
    }

    private static func isGeoBlocked(_ name: String) -> Bool {
        let lower = name.lowercased()
        return lower.contains("geo-blocked") || lower.contains("[geo")
    }

    private static func mapAsiaCategory(_ name: String) -> String? {
        if let mapped = MoviePlaylist.mapCountryGroup(name: name, epgId: nil) {
            return mapped
        }
        if looksHongKong(name) { return "🇭🇰 香港" }
        if looksTaiwan(name) || name.lowercased().contains("axn asia taiwan") { return "🇹🇼 台湾" }
        let lower = name.lowercased()
        if koreaKeys.contains(where: { lower.contains($0.lowercased()) })
            || lower.contains("persiana korea")
            || lower.contains("mbc drama")
            || lower.contains("mbc+") {
            return "🇰🇷 韩国"
        }
        if lower.contains("gem drama") || lower.contains("gem series") || lower.contains("gem film") {
            return "🇹🇼 台湾"
        }
        if lower.contains("cinema one") || lower.contains("viva cinema") || lower.contains("tap movies") {
            return "🇵🇭 菲律宾"
        }
        if lower.contains("on movies") || lower.contains("on vie") || lower.contains("tvb vietnam") {
            return "🇻🇳 越南"
        }
        if lower.contains("zee nung") {
            return "🇹🇭 泰国"
        }
        return nil
    }

    private static func isKoreaNoise(_ name: String) -> Bool {
        let lower = name.lowercased()
        return koreaDropKeys.contains(where: { lower.contains($0) })
    }

    private static func shouldKeepIndia(_ name: String) -> Bool {
        let lower = name.lowercased()
        if isDramaLike(lower) { return true }
        return !indiaNewsKeys.contains(where: { lower.contains($0) })
    }

    private static func score(_ name: String, group: String) -> Int {
        let lower = name.lowercased()
        var score = 0

        if isDramaLike(lower) { score += 140 }
        if lower.contains("hd") || lower.contains("1080") || lower.contains("4k") { score += 12 }
        if lower.contains("backup") { score -= 5 }

        switch group {
        case "🇹🇼 台湾":
            if looksTaiwan(name) { score += 50 }
            if ["戏剧", "戲劇", "电影", "電影", "综艺", "綜藝", "综合", "綜合", "都会", "都會", "超视", "洋片", "精采"].contains(where: { lower.contains($0.lowercased()) }) {
                score += 35
            }
            if lower.contains("新闻") || lower.contains("新聞") { score -= 40 }
        case "🇭🇰 香港":
            if looksHongKong(name) { score += 50 }
            if ["翡翠", "明珠", "星河", "viu", "hoy", "电影", "電影", "凤凰", "鳳凰"].contains(where: { lower.contains($0.lowercased()) }) {
                score += 35
            }
            if lower.contains("新闻") || lower.contains("新聞") { score -= 25 }
        case "🇰🇷 韩国":
            if koreaKeys.contains(where: { lower.contains($0.lowercased()) }) { score += 40 }
            if ["drama", "movie", "film", "kbs", "mbc", "sbs", "tvn"].contains(where: { lower.contains($0) }) {
                score += 30
            }
        case "🇸🇬 新加坡":
            if ["channel 8", "channel u", "suria", "vasantham", "mewatch"].contains(where: { lower.contains($0) }) { score += 40 }
        case "🇻🇳 越南":
            if ["vie", "htv", "vtvcab", "on movies", "tvb vietnam"].contains(where: { lower.contains($0) }) { score += 40 }
        case "🇹🇭 泰国":
            if ["one31", "gmm", "workpoint", "mono", "true", "zee nung"].contains(where: { lower.contains($0) }) { score += 40 }
        case "🇵🇭 菲律宾":
            if ["cinema one", "tap movies", "viva cinema", "axn", "kapamilya", "gma"].contains(where: { lower.contains($0) }) { score += 40 }
        case "🇮🇳 印度":
            if ["movies", "cinema", "bollywood", "entertainment", "colors", "sony", "star", "zee", "music"].contains(where: { lower.contains($0) }) { score += 40 }
            if indiaNewsKeys.contains(where: { lower.contains($0) }) { score -= 200 }
        default:
            break
        }

        return score
    }

    private static func isDramaLike(_ lower: String) -> Bool {
        dramaKeys.contains(where: { lower.contains($0.lowercased()) })
    }
}
