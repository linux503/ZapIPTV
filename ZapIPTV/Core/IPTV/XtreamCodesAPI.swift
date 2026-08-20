import Foundation

// Xtream Codes API client
actor XtreamCodesAPI {
    let baseURL: String
    let username: String
    let password: String

    private var session: URLSession = .shared

    init(baseURL: String, username: String, password: String) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.username = username
        self.password = password
    }

    // MARK: - API requests

    func getLiveStreams() async throws -> [Channel] {
        let data = try await get(path: "/get.php?action=get_live_streams")
        let items = try JSONDecoder().decode([XtreamStream].self, from: data)
        return items.map { $0.toChannel(base: baseURL, user: username, pass: password) }
    }

    func getLiveCategories() async throws -> [XtreamCategory] {
        let data = try await get(path: "/player_api.php?action=get_live_categories")
        return try JSONDecoder().decode([XtreamCategory].self, from: data)
    }

    func getVODStreams() async throws -> [Movie] {
        let data = try await get(path: "/get.php?action=get_vod_streams")
        let items = try JSONDecoder().decode([XtreamVOD].self, from: data)
        return items.map { $0.toMovie(base: baseURL, user: username, pass: password) }
    }

    func getSeriesList() async throws -> [XtreamSeries] {
        let data = try await get(path: "/player_api.php?action=get_series")
        return try JSONDecoder().decode([XtreamSeries].self, from: data)
    }

    func getSeriesInfo(id: Int) async throws -> XtreamSeriesInfo {
        let data = try await get(path: "/player_api.php?action=get_series_info&series_id=\(id)")
        return try JSONDecoder().decode(XtreamSeriesInfo.self, from: data)
    }

    // MARK: - Private

    private func get(path: String) async throws -> Data {
        let urlString = "\(baseURL)\(path)&username=\(username)&password=\(password)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

// MARK: - Xtream JSON models

struct XtreamCategory: Codable, Identifiable {
    var id: String { categoryId }
    let categoryId: String
    let categoryName: String

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case categoryName = "category_name"
    }
}

struct XtreamStream: Codable {
    let streamId: Int
    let name: String
    let streamIcon: String?
    let epgChannelId: String?
    let categoryId: String?
    let containerExtension: String?

    enum CodingKeys: String, CodingKey {
        case streamId = "stream_id"
        case name
        case streamIcon = "stream_icon"
        case epgChannelId = "epg_channel_id"
        case categoryId = "category_id"
        case containerExtension = "container_extension"
    }

    func toChannel(base: String, user: String, pass: String) -> Channel {
        let ext = containerExtension ?? "ts"
        let urlStr = "\(base)/live/\(user)/\(pass)/\(streamId).\(ext)"
        return Channel(
            id: "xt-live-\(streamId)",
            name: name,
            url: URL(string: urlStr) ?? URL(string: "about:blank")!,
            logoURL: streamIcon.flatMap { URL(string: $0) },
            group: categoryId ?? "Live",
            epgId: epgChannelId
        )
    }
}

struct XtreamVOD: Codable {
    let streamId: Int
    let name: String
    let streamIcon: String?
    let categoryId: String?
    let containerExtension: String?
    let rating: String?
    let plot: String?
    let director: String?
    let cast: String?
    let year: String?
    let genre: String?
    let duration: String?
    let backdropPath: [String]?

    enum CodingKeys: String, CodingKey {
        case streamId = "stream_id"
        case name
        case streamIcon = "stream_icon"
        case categoryId = "category_id"
        case containerExtension = "container_extension"
        case rating
        case plot
        case director
        case cast
        case year
        case genre
        case duration
        case backdropPath = "backdrop_path"
    }

    func toMovie(base: String, user: String, pass: String) -> Movie {
        let ext = containerExtension ?? "mp4"
        let urlStr = "\(base)/movie/\(user)/\(pass)/\(streamId).\(ext)"
        return Movie(
            id: "xt-vod-\(streamId)",
            title: name,
            url: URL(string: urlStr) ?? URL(string: "about:blank")!,
            posterURL: streamIcon.flatMap { URL(string: $0) },
            backdropURL: backdropPath?.first.flatMap { URL(string: $0) },
            year: year,
            duration: duration,
            genres: genre?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [],
            plot: plot,
            director: director,
            cast: cast,
            rating: rating,
            sourceId: "xtream"
        )
    }
}

struct XtreamSeries: Codable, Identifiable {
    let seriesId: Int
    var id: Int { seriesId }
    let name: String
    let cover: String?
    let plot: String?
    let rating: String?
    let genre: String?
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case seriesId = "series_id"
        case name
        case cover
        case plot
        case rating
        case genre
        case releaseDate = "releaseDate"
    }
}

struct XtreamSeriesInfo: Codable {
    let info: XtreamSeries
    let episodes: [String: [XtreamEpisode]]
}

struct XtreamEpisode: Codable {
    let id: String
    let episodeNum: Int
    let title: String
    let containerExtension: String
    let info: XtreamEpisodeInfo?

    enum CodingKeys: String, CodingKey {
        case id
        case episodeNum = "episode_num"
        case title
        case containerExtension = "container_extension"
        case info
    }
}

struct XtreamEpisodeInfo: Codable {
    let plot: String?
    let duration: String?
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case plot
        case duration
        case releaseDate = "releasedate"
    }
}
