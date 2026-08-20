import Foundation

// TVmaze — no API key required
actor TVmazeService {
    static let shared = TVmazeService()
    private let base = "https://api.tvmaze.com"
    private let session = URLSession.shared

    struct TVmazeShow: Codable, Identifiable {
        let id: Int
        let name: String
        let summary: String?
        let premiered: String?
        let rating: TVmazeRating?
        let genres: [String]?
        let image: TVmazeImage?
        let network: TVmazeNetwork?
        let status: String?

        var posterURL: URL? { image?.medium.flatMap(URL.init) }
        var backdropURL: URL? { image?.original.flatMap(URL.init) }
        var year: String? { premiered?.prefix(4).description }
        var ratingStr: String { rating?.average.map { String(format: "%.1f", $0) } ?? "" }
    }

    struct TVmazeRating: Codable { let average: Double? }
    struct TVmazeImage: Codable  { let medium: String?; let original: String? }
    struct TVmazeNetwork: Codable { let name: String? }

    struct TVmazeSeason: Codable, Identifiable {
        let id: Int
        let number: Int
        let episodeOrder: Int?
        let premiereDate: String?
        let image: TVmazeImage?

        enum CodingKeys: String, CodingKey {
            case id, number, image
            case episodeOrder  = "episodeOrder"
            case premiereDate  = "premiereDate"
        }
        var posterURL: URL? { image?.medium.flatMap(URL.init) }
    }

    struct TVmazeEpisode: Codable, Identifiable {
        let id: Int
        let name: String
        let season: Int
        let number: Int?
        let summary: String?
        let airdate: String?
        let runtime: Int?
        let image: TVmazeImage?

        var stillURL: URL? { image?.medium.flatMap(URL.init) }
        var durationStr: String? { runtime.map { "\($0)m" } }
    }

    struct TVmazeSearchResult: Codable {
        let score: Double
        let show: TVmazeShow
    }

    // MARK: - API

    func search(query: String) async throws -> [TVmazeShow] {
        let data = try await get("/search/shows", params: ["q": query])
        let results = try JSONDecoder().decode([TVmazeSearchResult].self, from: data)
        return results.map(\.show)
    }

    func showDetail(id: Int) async throws -> TVmazeShow {
        let data = try await get("/shows/\(id)")
        return try JSONDecoder().decode(TVmazeShow.self, from: data)
    }

    func seasons(showId: Int) async throws -> [TVmazeSeason] {
        let data = try await get("/shows/\(showId)/seasons")
        return try JSONDecoder().decode([TVmazeSeason].self, from: data)
    }

    func episodes(showId: Int) async throws -> [TVmazeEpisode] {
        let data = try await get("/shows/\(showId)/episodes")
        return try JSONDecoder().decode([TVmazeEpisode].self, from: data)
    }

    func episodesBySeason(showId: Int, season: Int) async throws -> [TVmazeEpisode] {
        let all = try await episodes(showId: showId)
        return all.filter { $0.season == season }
    }

    func schedule(country: String = "US", date: String? = nil) async throws -> [TVmazeEpisode] {
        var params = ["country": country]
        if let date { params["date"] = date }
        let data = try await get("/schedule", params: params)
        return try JSONDecoder().decode([TVmazeEpisode].self, from: data)
    }

    /// Browse catalog — no API key required.
    func browseShows(page: Int = 0) async throws -> [TVmazeShow] {
        let data = try await get("/shows", params: ["page": "\(page)"])
        return try JSONDecoder().decode([TVmazeShow].self, from: data)
    }

    // MARK: - Private

    private func get(_ path: String, params: [String: String] = [:]) async throws -> Data {
        var components = URLComponents(string: base + path)!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
