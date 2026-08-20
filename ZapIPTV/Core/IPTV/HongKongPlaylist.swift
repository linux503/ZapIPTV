import Foundation

/// Cleans Hong Kong live lists: drop unrelated feeds, unify names, keep a few backup URLs.
enum HongKongPlaylist {
    private static let maxBackups = 2

    static func refine(_ channels: [Channel], sourceURL: String) -> [Channel] {
        let u = sourceURL.lowercased()
        guard u.contains("hk-iptv-auto") || u.contains("/countries/hk.m3u") || u.contains("/streams/hk") else {
            return channels
        }

        var kept: [String: Int] = [:]
        var out: [Channel] = []
        for ch in channels {
            guard let name = canonicalName(ch.name) else { continue }
            let n = kept[name, default: 0]
            if n >= maxBackups { continue }
            kept[name] = n + 1
            out.append(Channel(
                id: ch.id,
                name: name,
                url: ch.url,
                logoURL: ch.logoURL,
                group: "🇭🇰 香港",
                epgId: ch.epgId,
                lastWatched: ch.lastWatched
            ))
        }
        return out
    }

    static func canonicalName(_ raw: String) -> String? {
        let compact = raw.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
        if compact.contains("bourdain") || compact.contains("heinow") { return nil }
        if compact.contains("nownews") || compact.contains("now14") { return nil }
        if compact.contains("arabic") || compact.contains("spanish") { return nil }

        if compact.contains("翡翠") { return "翡翠台" }
        if compact.contains("明珠") { return "明珠台" }
        if compact.contains("tvbplus") || compact.contains("無線tvbplus") || compact.contains("无线tvbplus") {
            return "TVB Plus"
        }
        if compact.contains("無線新聞") || compact.contains("无线新闻") || compact.contains("tvb無線新聞") {
            return "無線新聞台"
        }
        if compact.contains("viutv") || compact.contains("viu tv") { return "ViuTV" }
        if compact.contains("hoy") && (compact.contains("info") || compact.contains("資訊") || compact.contains("资讯")) {
            return "HOY資訊台"
        }
        if compact.contains("hoy") && compact.contains("business") { return "HOY國際財經台" }
        if compact.contains("hoy") { return "HOY TV" }
        if compact.contains("有線財經") || compact.contains("有线财经") { return "有線財經資訊台" }
        if compact.contains("有線新聞") || compact.contains("有线新闻") { return "有線新聞台" }
        if compact.contains("rthk31") || compact.contains("港台電視31") || compact.contains("港台31") {
            return "港台電視31"
        }
        if compact.contains("rthk32") || compact.contains("港台電視32") || compact.contains("港台32") {
            return "港台電視32"
        }
        if compact.contains("rthk33") || compact.contains("港台電視33") { return "港台電視33" }
        if compact.contains("rthk34") || compact.contains("港台電視34") { return "港台電視34" }
        if compact.contains("rthk35") || compact.contains("港台電視35") { return "港台電視35" }
        if compact.contains("rthk36") || compact.contains("港台電視36") { return "港台電視36" }
        if compact.contains("凤凰中文") || compact.contains("鳳凰中文") { return "鳳凰衛視中文台" }
        if compact.contains("凤凰资讯") || compact.contains("鳳凰資訊") { return "鳳凰衛視資訊台" }
        if compact.contains("耀才") { return "耀才財經台" }
        if compact.contains("celestial") { return "Celestial Movies" }
        if compact.contains("nowtv") || compact == "nowtv(720p)" { return "Now TV" }
        return raw.trimmingCharacters(in: .whitespaces)
    }
}
