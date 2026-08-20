import SwiftUI

private enum MovieFilter: String, CaseIterable, Identifiable {
    case all, zh, twHK, jpKR, sea, india, vod

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
        case .vod:   return !movie.sourceId.hasPrefix("live-")
        }
    }
}

struct MoviesView: View {
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager
    @State private var searchText = ""
    @State private var selectedMovie: Movie?
    @State private var selectedGenre = "All"
    @State private var selectedFilter: MovieFilter = .all
    @State private var tmdbTrending: [TMDBMovie] = []
    @State private var tmdbSearchResults: [TMDBMovie] = []
    @State private var isSearchingTMDB = false

    private var genres: [String] {
        let all = sourceManager.movies.flatMap(\.genres)
        return ["All"] + Array(Set(all)).sorted()
    }

    private var localFiltered: [Movie] {
        var list = sourceManager.movies
        if selectedFilter != .all { list = list.filter { selectedFilter.matches($0) } }
        if selectedGenre != "All" { list = list.filter { $0.genres.contains(selectedGenre) } }
        if !searchText.isEmpty {
            list = list.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    private var showSectionedLayout: Bool {
        searchText.isEmpty && selectedFilter == .all && selectedGenre == "All"
    }

    private var movieSections: [(title: String, icon: String, items: [Movie])] {
        let list = localFiltered
        return [
            ("🎬 华语影视", "film.fill", list.filter { $0.genres.contains("🎬 华语影视") }),
            ("🇹🇼 台湾 · 🇭🇰 香港", "tv.fill", list.filter {
                $0.genres.contains("🇹🇼 台湾") || $0.genres.contains("🇭🇰 香港")
            }),
            ("🇰🇷 韩国 · 🇯🇵 日本", "sparkles", list.filter {
                $0.genres.contains("🇰🇷 韩国") || $0.genres.contains("🇯🇵 日本")
            }),
            ("🌏 东南亚", "globe.asia.australia.fill", list.filter {
                ["🇹🇭 泰国", "🇻🇳 越南", "🇮🇩 印尼", "🇲🇾 马来西亚",
                 "🇸🇬 新加坡", "🇵🇭 菲律宾"].contains($0.genres.first ?? "")
            }),
            ("🇮🇳 印度", "star.fill", list.filter { $0.genres.contains("🇮🇳 印度") }),
            (loc.t("movies.filter.vod"), "folder.fill", list.filter { !$0.sourceId.hasPrefix("live-") }),
        ].filter { !$0.items.isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            moviesHeader
            filterBar
            if searchText.isEmpty { genreBar }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    if !searchText.isEmpty {
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
        .background(ZapColor.bg)
        .sheet(item: $selectedMovie) { MovieDetailView(movie: $0) }
        .task { await loadTrending() }
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
                        Text(String(format: loc.t("movies.count"), sourceManager.movies.count))
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
                        .frame(width: 220)
                        .onChange(of: searchText) { _, q in searchTMDB(q) }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ZapColor.surface2, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(ZapColor.border))
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

    private var genreBar: some View {
        Group {
            if genres.count > 2 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(genres, id: \.self) { genre in
                            GenreChip(title: genre == "All" ? loc.t("movies.filter.all") : genre,
                                      isSelected: selectedGenre == genre) {
                                selectedGenre = genre
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Content layouts

    @ViewBuilder
    private var browseContent: some View {
        if !tmdbTrending.isEmpty {
            if let hero = tmdbTrending.first {
                MoviesFeaturedHero(movie: hero)
                    .padding(.horizontal, 24)
            }
            HomeSection(title: loc.t("home.trending_movies"), icon: "flame.fill") {
                TMDBMoviePosterRow(movies: tmdbTrending)
            }
        }

        ForEach(movieSections, id: \.title) { section in
            HomeSection(title: section.title, icon: section.icon) {
                LocalMoviePosterRow(movies: section.items, onSelect: { selectedMovie = $0 })
            }
        }

        if localFiltered.isEmpty && tmdbTrending.isEmpty {
            EmptyMoviesView(hasSource: !sourceManager.sources.isEmpty)
                .padding(.top, 48)
        }
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

    private func loadTrending() async {
        guard TMDBService.shared.isConfigured else { return }
        if let movies = try? await TMDBService.shared.trendingMovies() {
            await MainActor.run { tmdbTrending = movies }
        }
    }

    private func searchTMDB(_ query: String) {
        guard !query.isEmpty, TMDBService.shared.isConfigured else {
            tmdbSearchResults = []
            return
        }
        isSearchingTMDB = true
        Task {
            let results = (try? await TMDBService.shared.searchMovies(query: query)) ?? []
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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(movies) { m in
                    PosterCard(posterURL: m.posterURL, title: m.title, subtitle: m.year ?? m.genres.first)
                        .onTapGesture { onSelect(m) }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct TMDBMoviePosterRow: View {
    let movies: [TMDBMovie]
    @State private var selected: TMDBMovie?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(movies) { t in
                    PosterCard(
                        posterURL: t.posterURL,
                        title: t.title,
                        subtitle: t.year,
                        badge: t.ratingStr.isEmpty ? nil : "★ \(t.ratingStr)"
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
            columns: [GridItem(.adaptive(minimum: 118, maximum: 148), spacing: 18)],
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
