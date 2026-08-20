import Foundation

// Parses TvBox JSON format and extracts playable live M3U URLs
// TvBox "sites" require proprietary JAR plugins — we only extract "lives"
struct TvBoxParser {

    struct LiveSource {
        let name: String
        let m3uURL: String
        let epgURL: String?
    }

    static func extractLiveSources(from json: Data) -> [LiveSource] {
        guard let dict = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let lives = dict["lives"] as? [[String: Any]] else {
            return []
        }

        var results: [LiveSource] = []

        for live in lives {
            let epg = live["epg"] as? String
            let group = live["group"] as? String ?? ""

            // Skip redirect/proxy entries
            if group == "redirect" { continue }

            if let url = live["url"] as? String, url.hasPrefix("http") {
                let name = live["name"] as? String ?? "Live"
                results.append(LiveSource(name: name, m3uURL: url, epgURL: epg))
            }
        }

        return results
    }

    // Fetch TvBox JSON and return live M3U URLs
    static func fetchLiveSources(from tvboxURL: String) async throws -> [LiveSource] {
        guard let url = URL(string: tvboxURL) else { throw URLError(.badURL) }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("ZapIPTV/1.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        return extractLiveSources(from: data)
    }
}
