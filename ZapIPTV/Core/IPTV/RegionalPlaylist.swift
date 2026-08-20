import Foundation

enum RegionalPlaylist {
    private static let dramaKeys = [
        "drama", "series", "theater", "theatre", "movie", "movies", "film", "cinema",
        "entertain", "variety", "showbiz", "music", "bollywood", "zee", "star", "colors", "sony",
        "戲劇", "戏剧", "劇", "剧", "劇場", "剧场", "影", "電影", "电影", "影院", "娛樂", "娱乐", "綜藝", "综艺",
        "音樂", "音乐", "偶像", "八大", "東森", "东森", "中天", "TVBS", "TVB", "Viu", "HOY", "KBS", "MBC", "SBS",
        "GEM", "AXN", "Celestial", "Cinema One", "Viva Cinema", "Tap Movies",
    ]

    private static let indiaNewsKeys = [
        "news", "समाचार", "खबर", "bharat", "indiatv", "speed news", "aaj tak", "republic",
        "times now", "et now", "mirror now", "cnn-news18", "cnbc", "dd news", "abp", "lokshahi",
    ]

    private static let koreaDropKeys = [
        "shopping", "onstyle", "homeshopping", "home & shopping", "kshopping", "cj onstyle",
        "lotte home", "hyundai home", "gongyoung", "gs my shop", "buddhist", "radio",
    ]

    private static let taiwanKeys = [
        "taiwan", "tvbs", "cts", "ftv", "ttv", "ctv", "ebc", "cti", "set ", "三立",
        "東森", "东森", "中天", "八大", "緯來", "纬来", "民視", "民视", "台视", "台視",
        "中视", "中視", "华视", "華視", "綜藝", "综合台", "綜合台",
    ]

    private static let hongKongKeys = [
        "hong kong", "tvb", "viu", "hoy", "jade", "pearl", "rthk", "celestial",
        "翡翠", "明珠", "港台", "無線", "无线", "有線", "有线", "鳳凰", "凤凰", "耀才",
    ]

    private static let koreaKeys = [
        "korea", "korean", "kbs", "mbc", "sbs", "tvn", "jtbc", "arirang", "ebs",
        "channel a", "kpop", "드라마", "영화",
    ]

    private static let preferredGroups: Set<String> = [
        "🇹🇼 台湾", "🇭🇰 香港", "🇰🇷 韩国", "🇸🇬 新加坡", "🇻🇳 越南", "🇹🇭 泰国", "🇵🇭 菲律宾", "🇮🇳 印度",
    ]

    /// Pull Asia drama / movie / entertainment feeds into regional groups.
    static func refineExtra(_ channels: [Channel], sourceURL: String) -> [Channel] {
        let u = sourceURL.lowercased()
        if u.contains("/languages/zho.m3u") {
            return channels.compactMap { ch in
                guard let group = mapChineseLanguage(ch.name) else { return nil }
                return remapped(ch, group: group)
            }
        }
        if u.contains("/languages/yue.m3u") {
            return channels.map { remapped($0, group: "🇭🇰 香港") }
        }
        if u.contains("/languages/kor.m3u") {
            return channels
                .filter { !isKoreaNoise($0.name) }
                .map { remapped($0, group: "🇰🇷 韩国") }
        }
        if u.contains("/categories/movies.m3u")
            || u.contains("/categories/series.m3u")
            || u.contains("/categories/entertainment.m3u") {
            return channels.compactMap { ch in
                guard let group = mapAsiaCategory(ch.name) else { return nil }
                return remapped(ch, group: group)
            }
        }
        return channels
    }

    static func curate(_ channels: [Channel], group: String) -> [Channel] {
        guard preferredGroups.contains(group) else { return channels }

        var filtered = channels
        if group == "🇮🇳 印度" {
            filtered = channels.filter { shouldKeepIndia($0.name) }
        }
        if group == "🇰🇷 韩国" {
            filtered = channels.filter { !isKoreaNoise($0.name) }
        }

        return filtered.sorted { score($0.name, group: group) > score($1.name, group: group) }
    }

    private static func remapped(_ ch: Channel, group: String) -> Channel {
        Channel(
            id: ch.id,
            name: ch.name,
            url: ch.url,
            logoURL: ch.logoURL,
            group: group,
            epgId: ch.epgId,
            lastWatched: ch.lastWatched
        )
    }

    private static func mapChineseLanguage(_ name: String) -> String? {
        let lower = name.lowercased()
        if hongKongKeys.contains(where: { lower.contains($0.lowercased()) }) { return "🇭🇰 香港" }
        if taiwanKeys.contains(where: { lower.contains($0.lowercased()) }) { return "🇹🇼 台湾" }
        return nil
    }

    private static func mapAsiaCategory(_ name: String) -> String? {
        let lower = name.lowercased()
        if hongKongKeys.contains(where: { lower.contains($0.lowercased()) })
            || lower.contains("celestial") {
            return "🇭🇰 香港"
        }
        if taiwanKeys.contains(where: { lower.contains($0.lowercased()) })
            || lower.contains("axn asia taiwan") {
            return "🇹🇼 台湾"
        }
        if koreaKeys.contains(where: { lower.contains($0.lowercased()) })
            || lower.contains("persiana korea")
            || lower.contains("mbc drama")
            || lower.contains("mbc+") {
            return "🇰🇷 韩国"
        }
        // Shared Asian drama brands useful for TW/HK audiences
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
        if lower.contains("hd") || lower.contains("1080") { score += 12 }

        switch group {
        case "🇹🇼 台湾":
            if taiwanKeys.contains(where: { lower.contains($0.lowercased()) }) { score += 40 }
        case "🇭🇰 香港":
            if hongKongKeys.contains(where: { lower.contains($0.lowercased()) }) { score += 40 }
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
