import SwiftUI

private enum MovieFilter: String, CaseIterable, Identifiable {
    case all, zh, twHK, jpKR, sea, india, live, vod

    var id: String { rawValue }

    @MainActor
    func title(_ loc: LanguageManager) -> String {
        switch self {
        case .all:   return loc.t("movies.filter.all")
        case .zh:    return loc.t("movies.filter.zh")
        case .twHK:  return loc.t("movies.filter.twhk")
        case .jpKR:  return loc.t("movies.filter.jpk")
        case .sea:   return loc.t("movies.filter.sea")
        case .india: return loc.t("movies.filter.india")
        case .live:  return loc.t("movies.filter.live")
        case .vod:   return loc.t("movies.filter.vod")
        }
    }

    func matches(_ movie: Movie) -> Bool {
        let g = movie.genres.first ?? ""
        switch self {
        case .all:   return true
        case .zh:    return g == "🎬 华语影视" || g == "🇨🇳 中国大陆"
        case .twHK:  return g == "🇹🇼 台湾" || g == "🇭🇰 香港"
        case .jpKR:  return g == "🇯🇵 日本" || g == "🇰🇷 韩国"
        case .sea:   return ["🇹🇭 泰国", "🇻🇳 越南", "🇮🇩 印尼", "🇲🇾 马来西亚",
                              "🇸🇬 新加坡", "🇵🇭 菲律宾"].contains(g)
        case .india: return g == "🇮🇳 印度"
        case .live:  return movie.sourceId.hasPrefix("live-")
        case .vod:   return !movie.sourceId.hasPrefix("live-")
        }
    }
}

struct MoviesView: View {
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager
    @EnvironmentObject private var playback: PlaybackRouter
    @State private var searchText = ""
    @State private var selectedMovie: Movie?
    @State private var selectedFilter: MovieFilter = .all
    @State private var expandedSection: String?
    @State private var tmdbTrending: [TMDBMovie] = []
    @State private var tmdbPopular: [TMDBMovie] = []
    @State private var tmdbSearchResults: [TMDBMovie] = []
    @State private var isSearchingTMDB = false
    @State private var searchTask: Task<Void, Never>?

    private var localFiltered: [Movie] {
        var list = sourceManager.movies
        if selectedFilter != .all { list = list.filter { selectedFilter.matches($0) } }
        if !searchText.isEmpty {
            list = list.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    private var favoriteMovies: [Movie] {
        sourceManager.movies.filter(\.isFavorite)
    }

    private var continueWatching: [Movie] {
        sourceManager.movies.filter { $0.watchPosition > 0 }
            .sorted { $0.watchPosition > $1.watchPosition }
    }

    private var liveCount: Int {
        sourceManager.movies.filter { $0.sourceId.hasPrefix("live-") }.count
    }

    private var vodCount: Int {
        sourceManager.movies.count - liveCount
    }

    private var showSectionedLayout: Bool {
        searchText.isEmpty && selectedFilter == .all && expandedSection == nil
    }

    private func movies(for key: String) -> [Movie] {
        let list = sourceManager.movies
        switch key {
        case "favorites": return favoriteMovies
        case "continue":  return continueWatching
        case "zh":        return list.filter { MovieFilter.zh.matches($0) }
        case "twHK":      return list.filter { MovieFilter.twHK.matches($0) }
        case "jpKR":      return list.filter { MovieFilter.jpKR.matches($0) }
        case "sea":       return list.filter { MovieFilter.sea.matches($0) }
        case "india":     return list.filter { MovieFilter.india.matches($0) }
        case "live":      return list.filter { MovieFilter.live.matches($0) }
        case "vod":       return list.filter { MovieFilter.vod.matches($0) }
        case "filter":    return localFiltered
        default:          return []
        }
    }

    private func title(for key: String) -> String {
        switch key {
        case "favorites": return loc.t("movies.favorites")
        case "continue":  return loc.t("movies.continue")
        case "zh":        return "🎬 华语影视"
        case "twHK":      return "🇹🇼 台湾 · 🇭🇰 香港"
        case "jpKR":      return "🇰🇷 韩国 · 🇯🇵 日本"
        case "sea":       return "🌏 东南亚"
        case "india":     return "🇮🇳 印度"
        case "live":      return loc.t("movies.filter.live")
        case "vod":       return loc.t("movies.filter.vod")
        case "filter":    return loc.t("movies.results")
        default:          return key
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            moviesHeader
            filterBar

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    if let key = expandedSection {
                        expandedContent(key: key)
                    } else if !searchText.isEmpty {
                        searchResultsContent
                    } else if showSectionedLayout {
                        browseContent
                    } else {
                        filteredGridContent
                    }
                }
                .padding(.bottom, 36)
            }
        }
        .background(ZapBackdrop())
        .sheet(item: $selectedMovie) { MovieDetailView(movie: $0) }
        .task { await loadCatalog() }
        .onChange(of: selectedFilter) { _, _ in expandedSection = nil }
        .onChange(of: searchText) { _, _ in expandedSection = nil }
    }

    // MARK: - Header

    private var moviesHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.t("movies.title"))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(ZapColor.textPrimary)
                    if !sourceManager.movies.isEmpty {
                        Text(String(format: loc.t("movies.count_split"),
                                     sourceManager.movies.count, liveCount, vodCount))
                            .font(.system(size: 12))
                            .foregroundColor(ZapColor.textTertiary)
                    }
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ZapColor.textTertiary)
                    TextField(loc.t("home.search_movies"), text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(ZapColor.textPrimary)
                        .frame(width: 200)
                        .onChange(of: searchText) { _, q in searchTMDB(q) }
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            tmdbSearchResults = []
                            isSearchingTMDB = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ZapColor.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .zapGlassInset(cornerRadius: 10)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MovieFilter.allCases) { filter in
                    GenreChip(title: filter.title(loc), isSelected: selectedFilter == filter) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Content layouts

    @ViewBuilder
    private var browseContent: some View {
        if let hero = tmdbTrending.first {
            MoviesFeaturedHero(movie: hero)
                .padding(.horizontal, 24)
        } else if let local = favoriteMovies.first ?? continueWatching.first ?? sourceManager.movies.first {
            LocalMoviesFeaturedHero(movie: local) {
                playback.playInline(url: local.url, title: local.title)
            } onSelect: {
                selectedMovie = local
            }
            .padding(.horizontal, 24)
        }

        catalogSection(title: loc.t("movies.favorites"), icon: "heart.fill", key: "favorites",
                       movies: favoriteMovies)
        catalogSection(title: loc.t("movies.continue"), icon: "play.circle.fill", key: "continue",
                       movies: continueWatching)

        if !tmdbTrending.isEmpty {
            HomeSection(title: loc.t("home.trending_movies"), icon: "flame.fill") {
                TMDBMoviePosterRow(movies: tmdbTrending, large: true)
            }
        }
        if !tmdbPopular.isEmpty {
            HomeSection(title: loc.t("movies.popular"), icon: "star.fill") {
                TMDBMoviePosterRow(movies: tmdbPopular, large: true)
            }
        }

        catalogSection(title: "🎬 华语影视", icon: "film.fill", key: "zh",
                       movies: movies(for: "zh"))
        catalogSection(title: "🇹🇼 台湾 · 🇭🇰 香港", icon: "tv.fill", key: "twHK",
                       movies: movies(for: "twHK"))
        catalogSection(title: "🇰🇷 韩国 · 🇯🇵 日本", icon: "sparkles", key: "jpKR",
                       movies: movies(for: "jpKR"))
        catalogSection(title: "🌏 东南亚", icon: "globe.asia.australia.fill", key: "sea",
                       movies: movies(for: "sea"))
        catalogSection(title: "🇮🇳 印度", icon: "star.fill", key: "india",
                       movies: movies(for: "india"))
        catalogSection(title: loc.t("movies.filter.live"), icon: "antenna.radiowaves.left.and.right",
                       key: "live", movies: movies(for: "live"))
        catalogSection(title: loc.t("movies.filter.vod"), icon: "folder.fill", key: "vod",
                       movies: movies(for: "vod"))

        if sourceManager.movies.isEmpty && tmdbTrending.isEmpty && tmdbPopular.isEmpty {
            EmptyMoviesView(hasSource: !sourceManager.sources.isEmpty)
                .padding(.top, 48)
        }
    }

    @ViewBuilder
    private func catalogSection(title: String, icon: String, key: String, movies: [Movie]) -> some View {
        if !movies.isEmpty {
            HomeSection(title: title, icon: icon, trailing: {
                if movies.count > 10 {
                    Button(loc.t("movies.see_all")) { expandedSection = key }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ZapColor.accentEnd)
                }
            }) {
                LocalMoviePosterRow(movies: Array(movies.prefix(24)), onSelect: { selectedMovie = $0 }, large: true)
            }
        }
    }

    @ViewBuilder
    private func expandedContent(key: String) -> some View {
        HStack {
            Button {
                expandedSection = nil
            } label: {
                Label(loc.t("movies.back"), systemImage: "chevron.left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ZapColor.accentEnd)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 24)

        MoviesSectionHeader(title: title(for: key), subtitle: "\(movies(for: key).count)", icon: "square.grid.2x2")
        LocalMovieGrid(movies: movies(for: key), onSelect: { selectedMovie = $0 })
    }

    @ViewBuilder
    private var filteredGridContent: some View {
        if !localFiltered.isEmpty {
            MoviesSectionHeader(
                title: loc.t("movies.results"),
                subtitle: "\(localFiltered.count)",
                icon: "square.grid.2x2"
            )
            LocalMovieGrid(movies: localFiltered, onSelect: { selectedMovie = $0 })
        } else {
            EmptyMoviesView(hasSource: !sourceManager.sources.isEmpty)
                .padding(.top, 48)
        }
    }

    @ViewBuilder
    private var searchResultsContent: some View {
        if isSearchingTMDB {
            HStack { Spacer(); ProgressView().tint(ZapColor.accentEnd); Spacer() }
                .padding(.top, 40)
        } else if !tmdbSearchResults.isEmpty {
            MoviesSectionHeader(title: "TMDB", subtitle: "\(tmdbSearchResults.count)", icon: "magnifyingglass")
            TMDBMovieGrid(movies: tmdbSearchResults)
        }
        if !localFiltered.isEmpty {
            MoviesSectionHeader(
                title: loc.t("home.library"),
                subtitle: "\(localFiltered.count)",
                icon: "folder.fill"
            )
            LocalMovieGrid(movies: localFiltered, onSelect: { selectedMovie = $0 })
        } else if !isSearchingTMDB && tmdbSearchResults.isEmpty {
            EmptyMoviesView(hasSource: !sourceManager.sources.isEmpty)
                .padding(.top, 48)
        }
    }

    private func loadCatalog() async {
        guard TMDBService.shared.isConfigured else { return }
        async let trendingTask = TMDBService.shared.trendingMovies()
        async let popularTask = TMDBService.shared.popularMovies()
        let trending = try? await trendingTask
        let popular = try? await popularTask
        await MainActor.run {
            if let trending { tmdbTrending = trending }
            if let popular { tmdbPopular = popular }
        }
    }

    private func searchTMDB(_ query: String) {
        searchTask?.cancel()
        guard !query.isEmpty, TMDBService.shared.isConfigured else {
            tmdbSearchResults = []
            isSearchingTMDB = false
            return
        }
        isSearchingTMDB = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let results = (try? await TMDBService.shared.searchMovies(query: query)) ?? []
            guard !Task.isCancelled else { return }
            await MainActor.run { tmdbSearchResults = results; isSearchingTMDB = false }
        }
    }
}


// MARK: - Featured hero

struct MoviesFeaturedHero: View {
    let movie: TMDBMovie
    @State private var selected: TMDBMovie?

    var body: some View {
        Button { selected = movie } label: {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let backdrop = movie.backdropURL {
                        AsyncImage(url: backdrop) { img in
                            img.resizable().scaledToFill()
                        } placeholder: { ZapColor.surface2 }
                    } else {
                        ZapColor.surface2
                    }
                }
                .frame(height: 200)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.75), .black.opacity(0.92)],
                    startPoint: .top, endPoint: .bottom
                )

                HStack(alignment: .bottom, spacing: 16) {
                    if let poster = movie.posterURL {
                        AsyncImage(url: poster) { img in
                            img.resizable().scaledToFill()
                        } placeholder: { ZapColor.surface2 }
                        .frame(width: 72, height: 108)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("🔥 " + movie.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            if let year = movie.year {
                                Text(year).font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            if !movie.ratingStr.isEmpty {
                                Text("★ \(movie.ratingStr)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(ZapColor.accentStart)
                            }
                        }
                        if let overview = movie.overview, !overview.isEmpty {
                            Text(overview)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.55))
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(ZapColor.border))
        }
        .buttonStyle(.plain)
        .sheet(item: $selected) { TMDBMovieDetailView(movie: $0) }
    }
}


// MARK: - Local featured hero

struct LocalMoviesFeaturedHero: View {
    let movie: Movie
    var onPlay: () -> Void
    var onSelect: (() -> Void)? = nil

    var body: some View {
        Button { onSelect?() } label: {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let backdrop = movie.backdropURL ?? movie.posterURL {
                        AsyncImage(url: backdrop) { img in
                            img.resizable().scaledToFill()
                        } placeholder: { ZapColor.surface2 }
                    } else {
                        ZapColor.surface2
                    }
                }
                .frame(height: 200)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.75), .black.opacity(0.92)],
                    startPoint: .top, endPoint: .bottom
                )

                HStack(alignment: .bottom, spacing: 16) {
                    if let poster = movie.posterURL {
                        AsyncImage(url: poster) { img in
                            img.resizable().scaledToFill()
                        } placeholder: { ZapColor.surface2 }
                        .frame(width: 72, height: 108)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(movie.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            if let year = movie.year {
                                Text(year).font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            if let rating = movie.rating, !rating.isEmpty {
                                Text("★ \(rating)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(ZapColor.accentStart)
                            }
                            if let g = movie.genres.first {
                                Text(g).font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.55))
                                    .lineLimit(1)
                            }
                        }
                        if let plot = movie.plot, !plot.isEmpty {
                            Text(plot)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.55))
                                .lineLimit(2)
                        }
                        Button(action: onPlay) {
                            Label("Play", systemImage: "play.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(ZapColor.accentEnd, in: Capsule())
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(ZapColor.border))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section header

struct MoviesSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ZapColor.accentH)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(ZapColor.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ZapColor.textTertiary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(ZapColor.surface2, in: Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        MoviesSectionHeader(title: title, icon: icon)
    }
}

// MARK: - Poster rows & grids

struct LocalMoviePosterRow: View {
    let movies: [Movie]
    let onSelect: (Movie) -> Void
    var large: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(movies) { m in
                    PosterCard(
                        posterURL: m.posterURL,
                        title: m.title,
                        subtitle: m.year ?? m.genres.first,
                        width: large ? 128 : 112,
                        height: large ? 192 : 168
                    )
                    .onTapGesture { onSelect(m) }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct TMDBMoviePosterRow: View {
    let movies: [TMDBMovie]
    var large: Bool = false
    @State private var selected: TMDBMovie?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(movies) { t in
                    PosterCard(
                        posterURL: t.posterURL,
                        title: t.title,
                        subtitle: t.year,
                        badge: t.ratingStr.isEmpty ? nil : "★ \(t.ratingStr)",
                        width: large ? 128 : 112,
                        height: large ? 192 : 168
                    )
                    .onTapGesture { selected = t }
                }
            }
            .padding(.horizontal, 24)
        }
        .sheet(item: $selected) { TMDBMovieDetailView(movie: $0) }
    }
}

struct TMDBMovieScrollRow: View {
    let movies: [TMDBMovie]
    var body: some View {
        TMDBMoviePosterRow(movies: movies)
    }
}

struct TMDBMovieGrid: View {
    let movies: [TMDBMovie]
    @State private var selected: TMDBMovie?

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 118, maximum: 148), spacing: 18)],
            spacing: 22
        ) {
            ForEach(movies) { m in
                PosterCard(
                    posterURL: m.posterURL,
                    title: m.title,
                    subtitle: m.year,
                    badge: m.ratingStr.isEmpty ? nil : "★ \(m.ratingStr)"
                )
                .onTapGesture { selected = m }
            }
        }
        .padding(.horizontal, 24)
        .sheet(item: $selected) { TMDBMovieDetailView(movie: $0) }
    }
}

struct LocalMovieGrid: View {
    let movies: [Movie]
    let onSelect: (Movie) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 128, maximum: 160), spacing: 18)],
            spacing: 22
        ) {
            ForEach(movies) { m in
                PosterCard(posterURL: m.posterURL, title: m.title, subtitle: m.year ?? m.genres.first)
                    .onTapGesture { onSelect(m) }
            }
        }
        .padding(.horizontal, 24)
    }
}

struct TMDBPosterCard: View {
    let movie: TMDBMovie
    var body: some View {
        PosterCard(
            posterURL: movie.posterURL,
            title: movie.title,
            subtitle: movie.year,
            badge: movie.ratingStr.isEmpty ? nil : "★ \(movie.ratingStr)"
        )
    }
}

// MARK: - TMDB Movie Detail

struct TMDBMovieDetailView: View {
    let movie: TMDBMovie
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var playerEngine: PlayerEngine
    @State private var detail: TMDBMovie?
    @State private var credits: TMDBCredits?
    @State private var isLoading = true

    var displayMovie: TMDBMovie { detail ?? movie }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let backdrop = displayMovie.backdropURL {
                    AsyncImage(url: backdrop) { img in
                        img.resizable().scaledToFill()
                    } placeholder: { ZapColor.surface }
                } else { ZapColor.surface }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [.black.opacity(0.1), .black.opacity(0.8), .black],
                    startPoint: .top, endPoint: .bottom
                )
            )

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 140)

                HStack(alignment: .bottom, spacing: 20) {
                    if let poster = displayMovie.posterURL {
                        AsyncImage(url: poster) { img in
                            img.resizable().scaledToFill()
                        } placeholder: { ZapColor.surface2 }
                        .frame(width: 140, height: 208)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 20)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(displayMovie.title)
                            .font(.system(size: 30, weight: .bold)).foregroundColor(.white)

                        HStack(spacing: 10) {
                            if let y = displayMovie.year { metaTag(y) }
                            if let d = displayMovie.durationStr { metaTag(d) }
                            if !displayMovie.ratingStr.isEmpty { metaTag("★ \(displayMovie.ratingStr)") }
                        }

                        if let genres = displayMovie.genres, !genres.isEmpty {
                            Text(genres.map(\.name).joined(separator: " · "))
                                .font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                        }

                        if let tagline = displayMovie.tagline, !tagline.isEmpty {
                            Text("\"\(tagline)\"")
                                .font(.system(size: 13, weight: .medium).italic())
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Text("Add this title's stream URL via a playlist source to play.")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.35))
                    }
                    Spacer()
                }
                .padding(.horizontal, 32)

                if let overview = displayMovie.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                        .lineLimit(5).padding(.horizontal, 32).padding(.top, 16)
                }

                if let cast = credits?.cast.prefix(8), !cast.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CAST").font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4)).padding(.horizontal, 32)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(cast) { member in
                                    CastCard(member: member)
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.top, 16)
                }

                Spacer(minLength: 32)
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    .padding(10).background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain).padding(20)

            if isLoading {
                ProgressView().tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 720, minHeight: 500)
        .background(Color.black)
        .task { await load() }
    }

    private func load() async {
        async let d = TMDBService.shared.movieDetail(id: movie.id)
        async let c = TMDBService.shared.movieCredits(id: movie.id)
        detail = try? await d
        credits = try? await c
        isLoading = false
    }

    func metaTag(_ text: String) -> some View {
        Text(text).font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.white.opacity(0.12)).cornerRadius(4)
    }
}

struct CastCard: View {
    let member: TMDBCastMember
    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: member.profileURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                ZStack {
                    ZapColor.surface2
                    Image(systemName: "person.fill").foregroundColor(.white.opacity(0.3))
                }
            }
            .frame(width: 56, height: 56).clipShape(Circle())

            Text(member.name).font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8)).lineLimit(1).frame(width: 70)
            if let ch = member.character {
                Text(ch).font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
                    .lineLimit(1).frame(width: 70)
            }
        }
    }
}

// MARK: - Reused helpers

struct GenreChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : ZapColor.textSecondary)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected
                              ? LinearGradient(colors: [ZapColor.accentStart, ZapColor.accentEnd], startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(colors: [ZapColor.surface2], startPoint: .leading, endPoint: .trailing))
                )
        }
        .buttonStyle(.plain)
    }
}

struct EmptyMoviesView: View {
    let hasSource: Bool
    @EnvironmentObject private var loc: LanguageManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasSource ? "film.slash" : "plus.circle")
                .font(.system(size: 48)).foregroundColor(ZapColor.textTertiary)
            Text(hasSource ? loc.t("movies.empty_loaded") : loc.t("movies.empty_no_source"))
                .font(.system(size: 16)).foregroundColor(ZapColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
