import Foundation
import SwiftData

// MARK: - Runtime Models (not persisted)

struct Channel: Identifiable, Hashable {
    let id: String
    var name: String
    var url: URL
    var logoURL: URL?
    var group: String
    var epgId: String?
    var isFavorite: Bool = false
    var lastWatched: Date?
    /// Alternate stream URLs for the same channel (tried on connect failure).
    var backupURLs: [URL] = []

    /// Primary + backups, de-duplicated.
    var allStreamURLs: [URL] {
        var seen = Set<String>()
        var out: [URL] = []
        for u in [url] + backupURLs {
            let key = u.absoluteString
            if seen.insert(key).inserted { out.append(u) }
        }
        return out
    }
}

struct Movie: Identifiable, Hashable {
    let id: String
    var title: String
    var url: URL
    var posterURL: URL?
    var backdropURL: URL?
    var year: String?
    var duration: String?
    var genres: [String] = []
    var plot: String?
    var director: String?
    var cast: String?
    var rating: String?
    var isFavorite: Bool = false
    var watchPosition: Double = 0
    var sourceId: String
}

/// Unified series entry for live drama channels, M3U VOD, and Xtream series.
struct SeriesCatalogItem: Identifiable, Hashable {
    let id: String
    var name: String
    var posterURL: URL?
    var plot: String?
    var rating: String?
    var genres: [String] = []
    var sourceId: String
    var playURL: URL?
    var xtreamSeriesId: Int?
    var xtreamSourceId: String?
}

struct Series: Identifiable, Hashable {
    let id: String
    var name: String
    var posterURL: URL?
    var backdropURL: URL?
    var year: String?
    var genres: [String] = []
    var plot: String?
    var rating: String?
    var isFavorite: Bool = false
    var seasons: [Season] = []
    var sourceId: String
}

struct Season: Identifiable, Hashable {
    let id: String
    var number: Int
    var episodes: [Episode] = []
}

struct Episode: Identifiable, Hashable {
    let id: String
    var title: String
    var number: Int
    var season: Int
    var url: URL
    var duration: String?
    var plot: String?
    var watchPosition: Double = 0
    var isWatched: Bool = false
}

struct EPGProgram: Identifiable, Hashable {
    let id: String
    var channelId: String
    var title: String
    var start: Date
    var end: Date
    var description: String?
    var category: String?
}

// MARK: - Persisted SwiftData models

@Model
class PlaylistSource {
    var id: String
    var name: String
    var type: SourceType
    var url: String
    var username: String?
    var password: String?
    var isLoaded: Bool = false
    var lastRefreshed: Date?
    var createdAt: Date
    // When set, all channels loaded from this source are assigned this group label
    var overrideGroup: String?

    enum SourceType: String, Codable {
        case m3u, xtream, local
    }

    init(id: String = UUID().uuidString, name: String, type: SourceType, url: String,
         username: String? = nil, password: String? = nil, overrideGroup: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.url = url
        self.username = username
        self.password = password
        self.overrideGroup = overrideGroup
        self.createdAt = Date()
    }
}

@Model
class ChannelEntity {
    var id: String
    var name: String
    var urlString: String
    var logoURLString: String?
    var group: String
    var epgId: String?
    var isFavorite: Bool = false
    var lastWatched: Date?
    var sourceId: String

    init(from channel: Channel, sourceId: String) {
        self.id = channel.id
        self.name = channel.name
        self.urlString = channel.url.absoluteString
        self.logoURLString = channel.logoURL?.absoluteString
        self.group = channel.group
        self.epgId = channel.epgId
        self.isFavorite = channel.isFavorite
        self.lastWatched = channel.lastWatched
        self.sourceId = sourceId
    }
}

@Model
class MovieEntity {
    var id: String
    var title: String
    var urlString: String
    var posterURLString: String?
    var isFavorite: Bool = false
    var watchPosition: Double = 0
    var sourceId: String

    init(id: String, title: String, urlString: String, posterURLString: String? = nil, sourceId: String) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.posterURLString = posterURLString
        self.sourceId = sourceId
    }
}

@Model
class SeriesEntity {
    var id: String
    var name: String
    var posterURLString: String?
    var isFavorite: Bool = false
    var sourceId: String

    init(id: String, name: String, posterURLString: String? = nil, sourceId: String) {
        self.id = id
        self.name = name
        self.posterURLString = posterURLString
        self.sourceId = sourceId
    }
}

@Model
class WatchHistoryEntry {
    var id: String
    var itemId: String
    var itemType: String  // "channel" | "movie" | "episode"
    var title: String
    var thumbnailURL: String?
    var watchedAt: Date
    var position: Double

    init(itemId: String, itemType: String, title: String, thumbnailURL: String? = nil, position: Double = 0) {
        self.id = UUID().uuidString
        self.itemId = itemId
        self.itemType = itemType
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.watchedAt = Date()
        self.position = position
    }
}
