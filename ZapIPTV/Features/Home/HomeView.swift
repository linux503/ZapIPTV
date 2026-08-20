import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var playerEngine: PlayerEngine
    @EnvironmentObject private var playback: PlaybackRouter
    @EnvironmentObject private var loc: LanguageManager
    @State private var selectedMovie: Movie?
    @State private var tmdbTrendingMovies: [TMDBMovie] = []
    @State private var tmdbTrendingTV: [TMDBTVShow] = []
    @State private var selectedTMDBMovie: TMDBMovie?
    @State private var selectedTMDBTV: TMDBTVShow?

    // Pre-computed channel groups — avoid recalculating in body every render
    @State private var zhCN: [Channel] = []
    @State private var cinema: [Channel] = []
    @State private var tw: [Channel] = []
    @State private var hk: [Channel] = []
    @State private var jp: [Channel] = []
    @State private var kr: [Channel] = []
    @State private var sea: [Channel] = []
    @State private var news: [Channel] = []
    @State private var sport: [Channel] = []
    @State private var gala: [Channel] = []

    var recentChannels: [Channel] {
        sourceManager.channels.filter { $0.lastWatched != nil }
            .sorted { ($0.lastWatched ?? .distantPast) > ($1.lastWatched ?? .distantPast) }
            .prefix(10).map { $0 }
    }

    /// Prefer favorites and items with artwork for the home library shelf.
    private var libraryMovies: [Movie] {
        sourceManager.movies.sorted { a, b in
            if a.isFavorite != b.isFavorite { return a.isFavorite && !b.isFavorite }
            let ap = a.posterURL != nil, bp = b.posterURL != nil
            if ap != bp { return ap && !bp }
            return a.title.localizedStandardCompare(b.title) == .orderedAscending
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                HeroBanner()

                if !recentChannels.isEmpty {
                    HomeSection(title: loc.t("home.continue"), icon: "play.circle.fill") {
                        ChannelRow(channels: recentChannels) { playback.playLive($0) }
                    }
                }

                if !zhCN.isEmpty {
                    HomeSection(title: "🇨🇳 中国大陆", icon: "tv.fill") {
                        ChannelRow(channels: zhCN) { playback.playLive($0) }
                    }
                }
                if !cinema.isEmpty {
                    HomeSection(title: "🎬 华语影视", icon: "film.fill") {
                        ChannelRow(channels: cinema) { playback.playLive($0) }
                    }
                }
                if !gala.isEmpty {
                    HomeSection(title: "🎆 春晚", icon: "sparkles") {
                        ChannelRow(channels: gala) { playback.playLive($0) }
                    }
                }
                if !tw.isEmpty || !hk.isEmpty {
                    HomeSection(title: "🇹🇼 台湾 · 🇭🇰 香港", icon: "tv.fill") {
                        ChannelRow(channels: tw + hk) { playback.playLive($0) }
                    }
                }
                if !jp.isEmpty {
                    HomeSection(title: "🇯🇵 日本", icon: "tv.fill") {
                        ChannelRow(channels: jp) { playback.playLive($0) }
                    }
                }
                if !kr.isEmpty {
                    HomeSection(title: "🇰🇷 韩国", icon: "tv.fill") {
                        ChannelRow(channels: kr) { playback.playLive($0) }
                    }
                }
                if !sea.isEmpty {
                    HomeSection(title: "🌏 东南亚", icon: "tv.fill") {
                        ChannelRow(channels: sea) { playback.playLive($0) }
                    }
                }
                if !news.isEmpty {
                    HomeSection(title: loc.t("home.news"), icon: "newspaper.fill") {
                        ChannelRow(channels: news) { playback.playLive($0) }
                    }
                }
                if !sport.isEmpty {
                    HomeSection(title: loc.t("home.sport"), icon: "sportscourt.fill") {
                        ChannelRow(channels: sport) { playback.playLive($0) }
                    }
                }

                if !tmdbTrendingMovies.isEmpty {
                    HomeSection(title: loc.t("home.trending_movies"), icon: "flame.fill") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(tmdbTrendingMovies) { m in
                                    PosterCard(posterURL: m.posterURL, title: m.title,
                                               subtitle: m.year, badge: m.ratingStr.isEmpty ? nil : "★ \(m.ratingStr)")
                                        .onTapGesture { selectedTMDBMovie = m }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }

                if !tmdbTrendingTV.isEmpty {
                    HomeSection(title: loc.t("home.trending_tv"), icon: "star.fill") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(tmdbTrendingTV) { s in
                                    PosterCard(posterURL: s.posterURL, title: s.name, subtitle: s.year)
                                        .onTapGesture { selectedTMDBTV = s }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }

                if !sourceManager.movies.isEmpty {
                    HomeSection(
                        title: loc.t("home.library"),
                        icon: "folder.fill",
                        trailing: {
                            HStack(spacing: 10) {
                                Text(String(format: loc.t("home.library_count"), sourceManager.movies.count))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(ZapColor.textTertiary)
                                Button(loc.t("movies.see_all")) {
                                    playback.selectedTab = .movies
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ZapColor.accentStart)
                            }
                        }
                    ) {
                        HomeLibraryRow(
                            movies: libraryMovies,
                            onSelect: { selectedMovie = $0 }
                        )
                    }
                }

                if zhCN.isEmpty && jp.isEmpty && news.isEmpty
                    && tmdbTrendingMovies.isEmpty && !sourceManager.isLoading {
                    FirstLaunchEmpty()
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 48)
        }
        .background(ZapBackdrop())
        .sheet(item: $selectedMovie) { MovieDetailView(movie: $0) }
        .sheet(item: $selectedTMDBMovie) { TMDBMovieDetailView(movie: $0) }
        .sheet(item: $selectedTMDBTV) { TMDBTVDetailView(show: $0) }
        .task { await loadTMDB() }
        .onChange(of: sourceManager.channels.count) { _ in recomputeGroups() }
        .onAppear { recomputeGroups() }
    }

    // Called only when channel count changes — not every body render
    private func recomputeGroups() {
        let all = sourceManager.channels
        zhCN  = Array(all.filter { $0.group == "🇨🇳 中国大陆" }.prefix(20))
        cinema = Array(all.filter { $0.group == "🎬 华语影视" }.prefix(28))
        gala  = Array(all.filter { $0.group == "🎆 春晚" }.prefix(24))
        tw    = Array(all.filter { $0.group == "🇹🇼 台湾" }.prefix(12))
        hk    = Array(all.filter { $0.group == "🇭🇰 香港" }.prefix(24))
        jp    = Array(all.filter { $0.group == "🇯🇵 日本" }.prefix(20))
        kr    = Array(all.filter { $0.group == "🇰🇷 韩国" }.prefix(20))
        sea   = Array(all.filter { ["🇹🇭 泰国","🇻🇳 越南","🇮🇩 印尼","🇲🇾 马来西亚"].contains($0.group) }.prefix(20))
        news  = Array(all.filter { $0.group == "📺 新闻" }.prefix(16))
        sport = Array(all.filter { $0.group == "⚽ 体育" }.prefix(16))
    }

    private func loadTMDB() async {
        guard TMDBService.shared.isConfigured else { return }
        async let movies = TMDBService.shared.trendingMovies()
        async let tv = TMDBService.shared.trendingTV()
        tmdbTrendingMovies = (try? await movies) ?? []
        tmdbTrendingTV = (try? await tv) ?? []
    }
}

// MARK: - Hero Banner (no heavy blur)

struct HeroBanner: View {
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ZapIPTV")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ZapColor.accentStart)
                Text(loc.t("tagline"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ZapColor.textPrimary)
            }

            if sourceManager.isLoading {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7).tint(ZapColor.accentEnd)
                    Text(sourceManager.loadingMessage.isEmpty ? loc.t("home.loading") : sourceManager.loadingMessage)
                        .font(.system(size: 12))
                        .foregroundColor(ZapColor.textSecondary)
                }
            } else if !sourceManager.channels.isEmpty {
                HStack(spacing: 10) {
                    HeroBadge(icon: "tv.fill",
                              value: sourceManager.channels.count >= 1000
                                ? String(format: "%.1fk", Double(sourceManager.channels.count)/1000)
                                : "\(sourceManager.channels.count)",
                              label: loc.t("nav.channels"))
                    HeroBadge(icon: "film.fill", value: "\(sourceManager.movies.count)", label: loc.t("tab.movies"))
                    HeroBadge(icon: "square.stack.3d.up.fill",
                              value: "\(sourceManager.sources.count)", label: loc.t("settings.sources"))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .zapGlassPanel(cornerRadius: 16)
        .padding(.horizontal, 24)
    }
}

struct HeroBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(ZapColor.accentH)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 15, weight: .bold)).foregroundColor(ZapColor.textPrimary)
                Text(label).font(.system(size: 10)).foregroundColor(ZapColor.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .zapGlassInset(cornerRadius: 10)
    }
}

// MARK: - Section wrapper

struct HomeSection<Content: View, Trailing: View>: View {
    let title: String
    let icon: String
    let trailing: Trailing
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) where Trailing == EmptyView {
        self.title = title
        self.icon = icon
        self.trailing = EmptyView()
        self.content = content()
    }

    init(title: String, icon: String,
         @ViewBuilder trailing: () -> Trailing,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ZapColor.accentH)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ZapColor.textPrimary)
                Spacer(minLength: 8)
                trailing
            }
            .padding(.horizontal, 24)
            content
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Channel Row (Lazy)

struct ChannelRow: View {
    let channels: [Channel]
    let onSelect: (Channel) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(channels) { ch in
                    ChannelTile(channel: ch).onTapGesture { onSelect(ch) }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct ChannelTile: View {
    let channel: Channel
    @State private var hovered = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ZapColor.surface2)
                    .frame(width: 124, height: 78)

                if let logo = channel.logoURL {
                    CachedAsyncImage(url: logo, contentMode: .fit)
                        .frame(width: 100, height: 60)
                        .clipped()
                } else {
                    Image(systemName: "tv").font(.system(size: 22))
                        .foregroundColor(ZapColor.textTertiary)
                }

                if hovered {
                    RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.5))
                    Image(systemName: "play.fill").font(.system(size: 16)).foregroundColor(.white)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(hovered ? ZapColor.accentStart : ZapColor.border, lineWidth: 1.5)
            )
            .scaleEffect(hovered ? 1.04 : 1)
            .animation(.easeOut(duration: 0.12), value: hovered)
            .contentShape(Rectangle())
            .onHover { hovered = $0 }

            Text(channel.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ZapColor.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 124, height: 28, alignment: .top)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Home library shelf

struct HomeLibraryRow: View {
    let movies: [Movie]
    let onSelect: (Movie) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 14) {
                ForEach(Array(movies.prefix(28))) { movie in
                    LibraryMovieCard(movie: movie)
                        .onTapGesture { onSelect(movie) }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 2)
        }
    }
}

struct LibraryMovieCard: View {
    let movie: Movie
    @Environment(\.colorScheme) private var colorScheme
    @State private var hovered = false

    private var isLive: Bool { movie.sourceId.hasPrefix("live-") }
    private let cardW: CGFloat = 148
    private let artH: CGFloat = 210

    private var genreLabel: String? {
        guard let g = movie.genres.first, !g.isEmpty else { return nil }
        if let space = g.firstIndex(of: " ") {
            return String(g[g.index(after: space)...])
        }
        return g
    }

    private var subtitle: String {
        var parts: [String] = []
        if let year = movie.year, !year.isEmpty { parts.append(year) }
        if let genre = genreLabel { parts.append(genre) }
        if let rating = movie.rating, !rating.isEmpty { parts.append("★ \(rating)") }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                artwork
                    .frame(width: cardW, height: artH)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                hovered ? ZapColor.accentStart.opacity(0.9) : Color.white.opacity(colorScheme == .light ? 0.45 : 0.08),
                                lineWidth: hovered ? 1.5 : 1
                            )
                    )
                    .shadow(color: .black.opacity(hovered ? 0.28 : 0.14), radius: hovered ? 16 : 8, y: hovered ? 8 : 4)

                badgeStack
                    .padding(8)

                if hovered {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.black.opacity(0.05), .black.opacity(0.55)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .shadow(radius: 8)
                }
            }
            .frame(width: cardW, height: artH)
            .scaleEffect(hovered ? 1.03 : 1)
            .animation(.easeOut(duration: 0.15), value: hovered)

            VStack(alignment: .leading, spacing: 3) {
                Text(movie.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ZapColor.textPrimary)
                    .lineLimit(2)
                    .frame(width: cardW, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ZapColor.textTertiary)
                        .lineLimit(1)
                        .frame(width: cardW, alignment: .leading)
                }
            }
        }
        .frame(width: cardW, alignment: .topLeading)
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
    }

    @ViewBuilder
    private var artwork: some View {
        if movie.posterURL != nil {
            if isLive {
                ZStack {
                    placeholderGradient
                    CachedAsyncImage(url: movie.posterURL, contentMode: .fit)
                        .padding(18)
                }
            } else {
                CachedAsyncImage(url: movie.posterURL, contentMode: .fill)
            }
        } else {
            ZStack {
                placeholderGradient
                VStack(spacing: 10) {
                    Text(String(movie.title.prefix(1)).uppercased())
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                    Image(systemName: isLive ? "tv.fill" : "film.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [
                ZapColor.accentStart.opacity(0.75),
                ZapColor.accentEnd.opacity(0.55),
                Color(hex: colorScheme == .light ? "#2A2220" : "#1A1412"),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var badgeStack: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(isLive ? "LIVE" : "VOD")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    (isLive ? ZapColor.live : ZapColor.accentStart).opacity(0.92),
                    in: Capsule()
                )
            if movie.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.black.opacity(0.45), in: Circle())
            }
        }
    }
}

// MARK: - Universal Poster Card

struct PosterCard: View {
    let posterURL: URL?
    let title: String
    let subtitle: String?
    var badge: String? = nil
    var width: CGFloat = 112
    var height: CGFloat = 168
    @State private var hovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ZapColor.surface2)
                    .frame(width: width, height: height)

                if posterURL != nil {
                    CachedAsyncImage(url: posterURL, contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo").font(.system(size: 26))
                        .foregroundColor(ZapColor.textTertiary)
                        .frame(width: width, height: height)
                }

                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
                        .padding(5)
                }

                if hovered {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.clear, .black.opacity(0.65)],
                                             startPoint: .top, endPoint: .bottom))
                    HStack {
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24)).foregroundColor(.white)
                        Spacer()
                    }
                    .frame(height: height)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(hovered ? ZapColor.accentStart : ZapColor.border, lineWidth: 1.5)
            )
            .scaleEffect(hovered ? 1.03 : 1)
            .animation(.easeOut(duration: 0.12), value: hovered)
            .contentShape(Rectangle())
            .onHover { hovered = $0 }

            Text(title)
                .font(.system(size: 11, weight: .medium)).foregroundColor(ZapColor.textPrimary)
                .lineLimit(2)
                .frame(width: width, alignment: .leading)
            if let sub = subtitle {
                Text(sub).font(.system(size: 10)).foregroundColor(ZapColor.textTertiary)
                    .lineLimit(1).frame(width: width, alignment: .leading)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
    }
}

// MARK: - First-launch empty

struct FirstLaunchEmpty: View {
    @EnvironmentObject private var loc: LanguageManager
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(ZapColor.accentStart.opacity(0.1)).frame(width: 90, height: 90)
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 38))
                    .foregroundStyle(ZapColor.accentH)
            }
            Text(loc.t("home.loading"))
                .font(.system(size: 18, weight: .semibold)).foregroundColor(ZapColor.textPrimary)
            Text(loc.t("home.loading_hint"))
                .font(.system(size: 13)).foregroundColor(ZapColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
