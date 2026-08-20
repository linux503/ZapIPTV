import Foundation

// Parses M3U/M3U8 playlists into Channel, Movie, Series buckets
struct M3UParser {
    struct ParseResult {
        var channels: [Channel] = []
        var movies: [Channel] = []     // VOD with movie-type metadata
        var series: [Channel] = []     // VOD with series-type metadata
    }

    static func parse(content: String, sourceId: String) -> ParseResult {
        var result = ParseResult()
        let lines = content.components(separatedBy: .newlines)
        var i = 0

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("#EXTINF:") {
                let meta = parseExtInf(line)
                i += 1
                // Skip extra tags until we find URL
                while i < lines.count {
                    let next = lines[i].trimmingCharacters(in: .whitespaces)
                    if !next.hasPrefix("#") && !next.isEmpty, let url = URL(string: next) {
                        let channel = buildChannel(meta: meta, url: url, sourceId: sourceId)
                        let type_ = meta["x-tvg-type"]?.lowercased() ?? ""
                        if type_ == "movie" || meta["group-title"]?.lowercased().contains("vod") == true
                            || meta["group-title"]?.lowercased().contains("movie") == true {
                            result.movies.append(channel)
                        } else if type_ == "series" || meta["group-title"]?.lowercased().contains("series") == true
                            || meta["group-title"]?.lowercased().contains("episode") == true {
                            result.series.append(channel)
                        } else {
                            result.channels.append(channel)
                        }
                        break
                    }
                    i += 1
                }
            }
            i += 1
        }
        return result
    }

    // Parses #EXTINF:-1 tvg-id="..." tvg-name="..." tvg-logo="..." group-title="...",Display Name
    private static func parseExtInf(_ line: String) -> [String: String] {
        var meta: [String: String] = [:]

        // Extract display name (after last comma)
        if let commaRange = line.range(of: ",", options: .backwards) {
            meta["name"] = String(line[commaRange.upperBound...]).trimmingCharacters(in: .whitespaces)
        }

        // Extract key="value" attributes
        let attrPattern = #"([\w\-]+)="([^"]*?)""#
        if let regex = try? NSRegularExpression(pattern: attrPattern) {
            let nsLine = line as NSString
            let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))
            for match in matches {
                if match.numberOfRanges == 3 {
                    let key = nsLine.substring(with: match.range(at: 1)).lowercased()
                    let value = nsLine.substring(with: match.range(at: 2))
                    meta[key] = value
                }
            }
        }
        return meta
    }

    private static func buildChannel(meta: [String: String], url: URL, sourceId: String) -> Channel {
        let name = meta["tvg-name"] ?? meta["name"] ?? "Unknown"
        let logoString = meta["tvg-logo"] ?? ""
        return Channel(
            id: stableChannelId(sourceId: sourceId, url: url.absoluteString),
            name: name,
            url: url,
            logoURL: URL(string: logoString),
            group: meta["group-title"] ?? "Uncategorized",
            epgId: meta["tvg-id"]
        )
    }

    /// Deterministic id — Swift `hashValue` is not stable across launches.
    static func stableChannelId(sourceId: String, url: String) -> String {
        var h: UInt64 = 5381
        for b in url.utf8 { h = ((h << 5) &+ h) &+ UInt64(b) }
        return "\(sourceId)-\(h)"
    }
}
