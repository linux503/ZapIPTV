import Foundation

/// Curated free / public movie channels for CN · US · JP · KR (with backup lines).
enum MoviePlaylist {
    private static let plutoLogo = "https://raw.githubusercontent.com/tv-logo/tv-logos/main/countries/united-states/pluto-tv-us.png"
    private static let cctv6Logo = "https://live.fanmingming.com/tv/CCTV6.png"

    /// (name, group, urls, logo) — URLs probed as HLS where possible.
    private static let seeds: [(name: String, group: String, urls: [String], logo: String?)] = [
        // ── 中国 / 华语 ──────────────────────────────────────────
        ("CCTV-6 电影", "🎬 华语影视", [
            "http://111.59.24.227:8181/tsfile/live/1012_1.m3u8?key=txiptv&playlive=1&authid=0",
        ], cctv6Logo),
        ("CHC 电影", "🎬 华语影视", [
            "http://183.237.95.108:9901/tsfile/live/1008_1.m3u8?key=txiptv&playlive=0&authid=0",
        ], "https://live.fanmingming.com/tv/CHC高清电影.png"),
        ("CHC 动作电影", "🎬 华语影视", [
            "http://120.198.86.186:9901/tsfile/live/1047_1.m3u8?key=txiptv&playlive=1&authid=0",
        ], "https://live.fanmingming.com/tv/CHC动作电影.png"),

        // ── 美国（免费 Pluto / FilmRise / 等）────────────────────
        ("Pluto TV Horror", "🇺🇸 美国", [
            "https://jmp2.uk/plu-569546031a619b8f07ce6e25.m3u8",
        ], plutoLogo),
        ("Pluto TV Westerns", "🇺🇸 美国", [
            "https://jmp2.uk/plu-5b4e94282d4ec87bdcbb87cd.m3u8",
        ], plutoLogo),
        ("Pluto TV Sci-Fi", "🇺🇸 美国", [
            "https://jmp2.uk/plu-5b4fc274694c027be6ed3eea.m3u8",
        ], plutoLogo),
        ("Pluto TV Adventure", "🇺🇸 美国", [
            "https://jmp2.uk/plu-69d7ebb726eeec84158e28cb.m3u8",
        ], plutoLogo),
        ("Pluto TV Comedy", "🇺🇸 美国", [
            "https://jmp2.uk/plu-5a4d3a00ad95e4718ae8d8db.m3u8",
        ], plutoLogo),
        ("Pluto TV Anime Movies", "🇺🇸 美国", [
            "https://jmp2.uk/plu-67ed8f7e443f0671bc2b2368.m3u8",
        ], plutoLogo),
        ("00s Replay", "🇺🇸 美国", [
            "https://jmp2.uk/plu-62ba60f059624e000781c436.m3u8",
        ], nil),
        ("BET Cinema", "🇺🇸 美国", [
            "https://jmp2.uk/plu-58af4c093a41ca9d4ecabe96.m3u8",
        ], nil),
        ("Classic Movie Westerns", "🇺🇸 美国", [
            "https://jmp2.uk/plu-61f33318210549000806a530.m3u8",
        ], nil),
        ("Paramount Movie Channel", "🇺🇸 美国", [
            "https://jmp2.uk/plu-5cb0cae7a461406ffe3f5213.m3u8",
        ], nil),
        ("MovieSphere", "🇺🇸 美国", [
            "https://amg00353-lionsgatestudio-moviesphere-xumo-zh5u0.amagi.tv/playlist.m3u8",
        ], nil),
        ("MyTime Movie Network", "🇺🇸 美国", [
            "https://appletree-mytimeau-samsung.amagi.tv/playlist.m3u8",
        ], nil),
        ("The Asylum", "🇺🇸 美国", [
            "https://d1i3g4v4xlfhad.cloudfront.net/The_Asylum.m3u8",
        ], nil),
        ("FilmRise Westerns", "🇺🇸 美国", [
            "https://dz05z8iljgvbe.cloudfront.net/master.m3u8",
        ], nil),
        ("Artflix Movie Classics", "🇺🇸 美国", [
            "https://amogonetworx-artflix-1-nl.samsung.wurl.tv/playlist.m3u8",
        ], nil),
        ("Grjngo Western Movies", "🇺🇸 美国", [
            "https://amogonetworx-grjngo-3-dk.samsung.wurl.tv/playlist.m3u8",
        ], nil),
        ("Wu Tang Collection", "🇺🇸 美国", [
            "https://dbrb49pjoymg4.cloudfront.net/10001/99991745/hls/master.m3u8",
        ], nil),

        // ── 日本（动画 / 电影向免费台）──────────────────────────
        ("Pluto TV Anime", "🇯🇵 日本", [
            "https://jmp2.uk/plu-5812b7d3249444e05d09cc49.m3u8",
        ], plutoLogo),
        ("FilmRise Anime", "🇯🇵 日本", [
            "https://dvu7aia8rjlfm.cloudfront.net/master.m3u8",
            "https://jmp2.uk/plu-67ed8f7e443f0671bc2b2368.m3u8",
        ], nil),
        ("Pluto TV Anime Movies", "🇯🇵 日本", [
            "https://jmp2.uk/plu-67ed8f7e443f0671bc2b2368.m3u8",
        ], plutoLogo),

        // ── 韩国 ──────────────────────────────────────────────────
        ("K-Drama Showcase", "🇰🇷 韩国", [
            "https://jmp2.uk/plu-5f31fd1b4c510e00071c3103.m3u8",
        ], nil),
        ("Pluto TV Hometown Drama", "🇰🇷 韩国", [
            "https://jmp2.uk/plu-69d6c7befde57cd5ba0160c3.m3u8",
        ], plutoLogo),
        ("FilmRise Classic TV", "🇰🇷 韩国", [
            "https://d2tv4k5moji5m7.cloudfront.net/v1/master/3722c60a815c199d9c0ef36c5b73da68154a70da/FilmRise_Classic_TV/master.m3u8",
        ], nil),
    ]

    static func curatedChannels() -> [Channel] {
        seeds.enumerated().compactMap { idx, item in
            let urls = item.urls.compactMap { URL(string: $0) }
            guard let primary = urls.first else { return nil }
            return Channel(
                id: "seed-movie-\(idx)-\(item.name)",
                name: item.name,
                url: primary,
                logoURL: item.logo.flatMap { URL(string: $0) },
                group: item.group,
                epgId: nil,
                backupURLs: Array(urls.dropFirst())
            )
        }
    }

    static func curatedMovies() -> [Movie] {
        curatedChannels().map { ch in
            Movie(
                id: ch.id,
                title: ch.name,
                url: ch.url,
                posterURL: ch.logoURL,
                genres: [ch.group],
                sourceId: "seed-movie"
            )
        }
    }

    /// Map a movies.m3u / cinema channel into a country group using name + tvg-id.
    static func mapCountryGroup(name: String, epgId: String?) -> String? {
        let n = name.lowercased()
        let id = (epgId ?? "").lowercased()

        if id.contains(".cn")
            || ["cctv-6", "cctv6", "chc", "动作电影", "家庭影院", "高清电影", "影迷", "黑莓电影",
                "江苏影视", "江西电影", "吉林电影", "哈尔滨电影", "storm theater", "first theater"].contains(where: { n.contains($0) }) {
            return "🎬 华语影视"
        }
        if id.contains(".hk") || id.contains(".tw")
            || n.contains("celestial") || n.contains("scm") || n.contains("美亚") || n.contains("美亞")
            || n.contains("卫视电影") || n.contains("東森電影") || n.contains("东森电影")
            || n.contains("纬来电影") || n.contains("緯來電影") || n.contains("龙华") || n.contains("龍華") {
            if n.contains("taiwan") || n.contains("台湾") || n.contains("東森") || n.contains("东森")
                || n.contains("纬来") || n.contains("緯來") || n.contains("龙华") || n.contains("龍華") {
                return "🇹🇼 台湾"
            }
            return "🇭🇰 香港"
        }
        if id.contains(".jp")
            || ["japan", "japanese", "映画", "wowow", "star channel", "toku", "anime", "retrocrush", "filmrise anime"].contains(where: { n.contains($0) }) {
            return "🇯🇵 日本"
        }
        if id.contains(".kr")
            || ["korea", "korean", "영화", "kbs", "mbc", "ocn", "cgv", "kmovie", "k-drama", "arirang", "hometown drama"].contains(where: { n.contains($0) }) {
            return "🇰🇷 韩国"
        }
        if id.contains(".us") || id.contains(".ca")
            || ["pluto", "moviesphere", "mytime", "filmrise", "asylum", "bet cinema",
                "paramount movie", "sony movie", "hallmark movie", "amc", "showtime",
                "cinemax", "starz", "free movies", "classic movie", "western movie",
                "00s replay", "80s rewind", "90s throwback", "wu tang", "artflix", "grjngo"].contains(where: { n.contains($0) }) {
            return "🇺🇸 美国"
        }
        return nil
    }
}
