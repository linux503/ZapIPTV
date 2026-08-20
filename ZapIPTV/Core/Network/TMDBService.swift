import Foundation

// MARK: - Config
// Replace with your free key from https://www.themoviedb.org/settings/api
// Leave as-is and the app still compiles; metadata will be skipped when key is empty.
enum TMDBConfig {
    static var apiKey: String = ""   // ← paste your key here
    static let baseURL = "https://api.themoviedb.org/3"
    static let imageBase = "https://image.tmdb.org/t/p"

    static func posterURL(_ path: String, size: String = "w342") -> URL? {
        URL(string: "\(imageBase)/\(size)\(path)")
    }
    static func backdropURL(_ path: String, size: String = "w1280") -> URL? {
        URL(string: "\(imageBase)/\(size)\(path)")
    }
}

// MARK: - TMDB Models

struct TMDBMovie: Codable, Identifiable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let genreIds: [Int]?
    let genres: [TMDBGenre]?
    let runtime: Int?
    let tagline: String?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, tagline, genres
        case posterPath   = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate  = "release_date"
        case voteAverage  = "vote_average"
        case genreIds     = "genre_ids"
    }

    var posterURL: URL?   { posterPath.flatMap { TMDBConfig.posterURL($0) } }
    var backdropURL: URL? { backdropPath.flatMap { TMDBConfig.backdropURL($0) } }
    var year: String?     { releaseDate?.prefix(4).description }
    var ratingStr: String { voteAverage.map { String(format: "%.1f", $0) } ?? "" }
    var durationStr: String? { runtime.map { "\($0 / 60)h \($0 % 60)m" } }
}

struct TMDBTVShow: Codable, Identifiable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let genreIds: [Int]?
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case posterPath      = "poster_path"
        case backdropPath    = "backdrop_path"
        case firstAirDate    = "first_air_date"
        case voteAverage     = "vote_average"
        case genreIds        = "genre_ids"
        case numberOfSeasons  = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
    }

    var posterURL: URL?  { posterPath.flatMap { TMDBConfig.posterURL($0) } }
    var backdropURL: URL? { posterPath.flatMap { TMDBConfig.backdropURL($0) } }
    var year: String?    { firstAirDate?.prefix(4).description }
}

struct TMDBSeason: Codable, Identifiable {
    let id: Int
    let seasonNumber: Int
    let name: String
    let episodeCount: Int?
    let posterPath: String?
    let episodes: [TMDBEpisode]?

    enum CodingKeys: String, CodingKey {
        case id, name, episodes
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case posterPath   = "poster_path"
    }
    var posterURL: URL? { posterPath.flatMap { TMDBConfig.posterURL($0) } }
}

struct TMDBEpisode: Codable, Identifiable {
    let id: Int
    let episodeNumber: Int
    let seasonNumber: Int
    let name: String
    let overview: String?
    let stillPath: String?
    let airDate: String?
    let runtime: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case episodeNumber = "episode_number"
        case seasonNumber  = "season_number"
        case stillPath     = "still_path"
        case airDate       = "air_date"
        case runtime
    }
    var stillURL: URL? { stillPath.flatMap { TMDBConfig.posterURL($0, size: "w300") } }
}

struct TMDBCastMember: Codable, Identifiable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }
    var profileURL: URL? { profilePath.flatMap { TMDBConfig.posterURL($0, size: "w185") } }
}

struct TMDBCredits: Codable {
    let cast: [TMDBCastMember]
    let crew: [TMDBCrewMember]

    var director: String? {
        crew.first { $0.job == "Director" }?.name
    }
}

struct TMDBCrewMember: Codable, Identifiable {
    let id: Int
    let name: String
    let job: String?
    let department: String?
}

struct TMDBGenre: Codable, Identifiable {
    let id: Int
    let name: String
}

struct TMDBPageResult<T: Codable>: Codable {
    let results: [T]
    let totalResults: Int?
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case results
        case totalResults = "total_results"
        case totalPages   = "total_pages"
    }
}

// MARK: - Service

actor TMDBService {
    static let shared = TMDBService()
    private let session = URLSession.shared

    nonisolated var isConfigured: Bool { !TMDBConfig.apiKey.isEmpty }

    // MARK: Movies

    func trendingMovies(timeWindow: String = "week") async throws -> [TMDBMovie] {
        let data = try await get("/trending/movie/\(timeWindow)")
        return try decode(TMDBPageResult<TMDBMovie>.self, from: data).results
    }

    func popularMovies(page: Int = 1) async throws -> [TMDBMovie] {
        let data = try await get("/movie/popular", params: ["page": "\(page)"])
        return try decode(TMDBPageResult<TMDBMovie>.self, from: data).results
    }

    func searchMovies(query: String, page: Int = 1) async throws -> [TMDBMovie] {
        let data = try await get("/search/movie", params: ["query": query, "page": "\(page)"])
        return try decode(TMDBPageResult<TMDBMovie>.self, from: data).results
    }

    func movieDetail(id: Int) async throws -> TMDBMovie {
        let data = try await get("/movie/\(id)")
        return try decode(TMDBMovie.self, from: data)
    }

    func movieCredits(id: Int) async throws -> TMDBCredits {
        let data = try await get("/movie/\(id)/credits")
        return try decode(TMDBCredits.self, from: data)
    }

    // MARK: TV Shows

    func trendingTV(timeWindow: String = "week") async throws -> [TMDBTVShow] {
        let data = try await get("/trending/tv/\(timeWindow)")
        return try decode(TMDBPageResult<TMDBTVShow>.self, from: data).results
    }

    func popularTV(page: Int = 1) async throws -> [TMDBTVShow] {
        let data = try await get("/tv/popular", params: ["page": "\(page)"])
        return try decode(TMDBPageResult<TMDBTVShow>.self, from: data).results
    }

    func searchTV(query: String) async throws -> [TMDBTVShow] {
        let data = try await get("/search/tv", params: ["query": query])
        return try decode(TMDBPageResult<TMDBTVShow>.self, from: data).results
    }

    func tvDetail(id: Int) async throws -> TMDBTVShow {
        let data = try await get("/tv/\(id)")
        return try decode(TMDBTVShow.self, from: data)
    }

    func tvSeason(showId: Int, season: Int) async throws -> TMDBSeason {
        let data = try await get("/tv/\(showId)/season/\(season)")
        return try decode(TMDBSeason.self, from: data)
    }

    func tvCredits(id: Int) async throws -> TMDBCredits {
        let data = try await get("/tv/\(id)/credits")
        return try decode(TMDBCredits.self, from: data)
    }

    // MARK: Multi-search

    struct MultiResult: Codable {
        let id: Int
        let mediaType: String
        let title: String?
        let name: String?
        let posterPath: String?
        let overview: String?

        enum CodingKeys: String, CodingKey {
            case id, title, name, overview
            case mediaType  = "media_type"
            case posterPath = "poster_path"
        }
        var displayTitle: String { title ?? name ?? "Unknown" }
        var posterURL: URL? { posterPath.flatMap { TMDBConfig.posterURL($0) } }
    }

    func multiSearch(query: String) async throws -> [MultiResult] {
        let data = try await get("/search/multi", params: ["query": query])
        return try decode(TMDBPageResult<MultiResult>.self, from: data).results
    }

    // MARK: - Private

    private func get(_ path: String, params: [String: String] = [:]) async throws -> Data {
        guard isConfigured else { throw TMDBError.noAPIKey }

        var components = URLComponents(string: TMDBConfig.baseURL + path)!
        var items = [URLQueryItem(name: "api_key", value: TMDBConfig.apiKey),
                     URLQueryItem(name: "language", value: "en-US")]
        items += params.map { URLQueryItem(name: $0.key, value: $0.value) }
        components.queryItems = items

        guard let url = components.url else { throw URLError(.badURL) }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func decode<T: Codable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}

enum TMDBError: LocalizedError {
    case noAPIKey
    var errorDescription: String? {
        "TMDB API key not configured. Add your key in TMDBConfig.apiKey."
    }
}
