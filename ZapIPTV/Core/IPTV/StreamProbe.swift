import Foundation

enum StreamKind {
    case hls, mpegts, flv, html, dead, unknown
}

enum PlaybackError: LocalizedError {
    case unsupportedFormat
    case unreachable

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "此频道格式系统播放器无法打开（FLV/非 HLS），已跳过。"
        case .unreachable:
            return "此频道暂时无法连接。"
        }
    }
}

enum StreamProbe {
    static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    static func httpHeaders(for url: URL) -> [String: String] {
        var headers = [
            "User-Agent": userAgent,
            "Accept": "*/*",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
        ]
        if let host = url.host {
            let origin = "\(url.scheme ?? "http")://\(host)"
            headers["Referer"] = origin + "/"
            headers["Origin"] = origin
        }
        return headers
    }

    static func check(_ url: URL) async -> StreamKind {
        var request = URLRequest(url: url, timeoutInterval: 2.5)
        request.httpMethod = "GET"
        request.setValue("bytes=0-255", forHTTPHeaderField: "Range")
        for (k, v) in httpHeaders(for: url) {
            request.setValue(v, forHTTPHeaderField: k)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .unknown }
            // Range is often rejected by CDNs; don't treat 403 as dead
            if http.statusCode == 404 || http.statusCode == 410 { return .dead }
            if http.statusCode == 403 { return .unknown }
            if http.statusCode >= 500 { return .dead }

            if data.starts(with: Data("#EXTM3U".utf8)) || data.contains(Data("#EXTINF".utf8)) {
                return .hls
            }
            if data.starts(with: Data([0x46, 0x4C, 0x56])) { // FLV
                return .flv
            }
            let prefix = String(data: data.prefix(80), encoding: .utf8)?.lowercased() ?? ""
            if prefix.contains("<html") || prefix.contains("<!doctype") {
                return .html
            }
            let ctype = (http.value(forHTTPHeaderField: "Content-Type") ?? "").lowercased()
            if ctype.contains("mpegurl") || ctype.contains("vnd.apple.mpegurl") { return .hls }
            if ctype.contains("flv") { return .flv }
            if !data.isEmpty && data[0] == 0x47 { return .mpegts }
            if (200...206).contains(http.statusCode) { return .unknown }
            return .dead
        } catch {
            return .unknown
        }
    }

    static func isLikelyPlayable(_ kind: StreamKind) -> Bool {
        switch kind {
        case .hls, .mpegts, .unknown: return true
        case .flv, .html, .dead: return false
        }
    }
}

enum ChannelQuality {
    static func optimize(_ channels: [Channel]) -> [Channel] {
        // Keep alternate URLs as backup lines (not hard-drop duplicates)
        mergeMirrors(channels.filter { isCandidate($0) }, limitBackups: 15)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func isCandidate(_ ch: Channel) -> Bool {
        let name = ch.name.lowercased()
        if name.contains("geo-blocked") { return false }
        guard let scheme = ch.url.scheme?.lowercased() else { return false }
        if ["rtmp", "rtsp", "rtp", "udp", "mms"].contains(scheme) { return false }
        let u = ch.url.absoluteString.lowercased()
        if u.contains(".flv") { return false }
        if u.contains("183.207.248.71") { return false }
        if u.contains("/gitv/live") { return false }
        if u.contains("/cntv/live1/") && !u.contains(".m3u8") { return false }
        return true
    }

    static func canonicalName(_ name: String) -> String {
        var s = name
        s = s.replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s*\[[^\]]*\]"#, with: "", options: .regularExpression)
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let u = s.uppercased()
        // CCTV-5+ before plain CCTV-5
        if u.range(of: #"CCTV[\s\-]?5\s*[\+＋]"#, options: .regularExpression) != nil {
            return "cctv-5+"
        }
        // CCTV-1 / CCTV1 / CCTV 1 综合 → cctv-1
        if let re = try? NSRegularExpression(pattern: #"CCTV[\s\-]?(\d{1,2})"#, options: .caseInsensitive),
           let m = re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
           let numRange = Range(m.range(at: 1), in: s) {
            return "cctv-\(s[numRange])"
        }
        s = s.lowercased()
        s = s.replacingOccurrences(of: #"[\s\-_]*((f?hd|uhd|4k|8k|1080p?|720p?|高清|超清|备用|備用)\s*)+$"#,
                                   with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return s
    }

    static func score(_ ch: Channel) -> Int {
        var n = 0
        let u = ch.url.absoluteString.lowercased()
        let host = (ch.url.host ?? "").lowercased()

        // Prefer known sports seed CDNs (verified mirrors)
        if u.contains("7nyaler.streamhostingcdn") || u.contains("ayitistream")
            || u.contains("amagi.tv") || u.contains("streamup.eu")
            || u.contains("jmp2.uk") || u.contains("akamaized.net") {
            n += 16
        }
        // Prefer domestic / known-good Chinese live mirrors over iptv-org geo feeds
        if u.contains("vbskycn") || host.contains("live.fanmingming")
            || u.contains("fanmingming") || u.contains("iptv4") || u.contains("iptv6")
            || u.contains("yuechan") {
            n += 14
        }
        if u.contains("guovin") || u.contains("suxuang") || u.contains("hk-iptv") {
            n += 6
        }
        // iptv-org CN list often geo-blocks / hangs AVPlayer outside CN CDNs
        if u.contains("iptv-org") { n -= 8 }
        // Global sports category is still useful despite iptv-org host
        if u.contains("/categories/sports") { n += 12 }
        if ch.name.lowercased().contains("geo-blocked") || u.contains("geo-blocked") { n -= 20 }

        if ch.url.scheme?.lowercased() == "https" { n += 4 }
        if u.contains(".m3u8") { n += 8 }
        if u.contains("1080") || ch.name.contains("1080") { n += 2 }
        if u.contains("720") || ch.name.contains("720") { n += 1 }
        if host.allSatisfy({ $0.isNumber || $0 == "." }) { n -= 2 }
        if ch.name.lowercased().contains("not 24/7") { n -= 2 }
        return n
    }

    /// Keep one channel per display name; stash other URLs as ranked backups.
    static func mergeMirrors(_ channels: [Channel], limitBackups: Int = 15) -> [Channel] {
        let grouped = Dictionary(grouping: channels, by: { canonicalName($0.name) })
        return grouped.values.compactMap { group -> Channel? in
            let ranked = group.sorted { score($0) > score($1) }
            guard var best = ranked.first else { return nil }
            var backups: [URL] = []
            var seen = Set<String>([best.url.absoluteString])
            for ch in ranked {
                for u in ch.allStreamURLs {
                    let key = u.absoluteString
                    guard seen.insert(key).inserted else { continue }
                    backups.append(u)
                    if backups.count >= limitBackups { break }
                }
                if backups.count >= limitBackups { break }
            }
            // Prefer logo / favorites from any mirror
            if best.logoURL == nil {
                best.logoURL = ranked.compactMap(\.logoURL).first
            }
            if ranked.contains(where: \.isFavorite) { best.isFavorite = true }
            if let latest = ranked.compactMap(\.lastWatched).max() {
                best.lastWatched = latest
            }
            best.backupURLs = backups
            return best
        }
    }

    /// Keep one stream per display name, preferring higher `score`.
    static func dedupePreferringQuality(_ channels: [Channel]) -> [Channel] {
        mergeMirrors(channels, limitBackups: 15)
    }
}
