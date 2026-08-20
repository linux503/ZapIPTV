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
        var request = URLRequest(url: url, timeoutInterval: 4)
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
        let filtered = channels.filter { isCandidate($0) }
        let grouped = Dictionary(grouping: filtered, by: { canonicalName($0.name) })
        return grouped.values.compactMap { group in
            group.max(by: { score($0) < score($1) })
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
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
        return s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func score(_ ch: Channel) -> Int {
        var n = 0
        let u = ch.url.absoluteString.lowercased()
        if ch.url.scheme?.lowercased() == "https" { n += 6 }
        if u.contains(".m3u8") { n += 5 }
        if u.contains("1080") || ch.name.contains("1080") { n += 2 }
        if u.contains("720") || ch.name.contains("720") { n += 1 }
        if let host = ch.url.host, host.allSatisfy({ $0.isNumber || $0 == "." }) {
            n -= 1
        }
        if ch.name.lowercased().contains("not 24/7") { n -= 2 }
        return n
    }
}
