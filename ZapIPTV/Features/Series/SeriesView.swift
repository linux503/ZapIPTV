import SwiftUI

private enum SeriesFilter: String, CaseIterable, Identifiable {
    case all, zh, twHK, krJP, sea, india, live, vod

    var id: String { rawValue }

    @MainActor
    func title(_ loc: LanguageManager) -> String {
        switch self {
        case .all:   return loc.t("series.filter.all")
        case .zh:    return loc.t("series.filter.zh")
        case .twHK:  return loc.t("series.filter.twhk")
        case .krJP:  return loc.t("series.filter.krjp")
        case .sea:   return loc.t("series.filter.sea")
        case .india: return loc.t("series.filter.india")
        case .live:  return loc.t("series.filter.live")
        case .vod:   return loc.t("series.filter.vod")
        }
    }

    func matches(_ item: SeriesCatalogItem) -> Bool {
        let g = item.genres.first ?? ""
        switch self {
        case .all:   return true
        case .zh:    return g == "🎬 华语影视" || g == "🇨🇳 中国大陆" || g == "🎮 娱乐"
        case .twHK:  return g == "🇹🇼 台湾" || g == "🇭🇰 香港"
        case .krJP:  return g == "🇰🇷 韩国" || g == "🇯🇵 日本"
        case .sea:   return ["🇹🇭 泰国", "🇻🇳 越南", "🇮🇩 印尼", "🇲🇾 马来西亚",
                              "🇸🇬 新加坡", "🇵🇭 菲律宾"].contains(g)
        case .india: return g == "🇮🇳 印度"
        case .live:  return item.sourceId.hasPrefix("live-")
        case .vod:   return item.xtreamSeriesId != nil || !item.sourceId.hasPrefix("live-")
        }
    }
}

struct SeriesView: View {
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager
    @EnvironmentObject private var playback: PlaybackRouter
    @State private var searchText = ""
    @State private var selectedFilter: SeriesFilter = .all
    @State private var expandedSection: String?
    @State private var selectedSeries: SeriesCatalogItem?
    @State private var searchTask: Task<Void, Never>?

    private var localFiltered: [SeriesCatalogItem] {
        var list = playableSeries
        if selectedFilter != .all { list = list.filter { selectedFilter.matches($0) } }
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    /// Only entries with a real stream — Series tab is a player, not a poster browser.
    private var playableSeries: [SeriesCatalogItem] {
        sourceManager.seriesList.filter { $0.playURL != nil }
    }

    private var liveCount: Int {
        playableSeries.filter { $0.sourceId.hasPrefix("live-") }.count
    }

    private var vodCount: Int {
        playableSeries.count - liveCount
    }

    private var showSectionedLayout: Bool {
        searchText.isEmpty && selectedFilter == .all && expandedSection == nil
    }

    private func items(for key: String) -> [SeriesCatalogItem] {
        let list = playableSeries
        switch key {
        case "zh":     return list.filter { SeriesFilter.zh.matches($0) }
        case "twHK":   return list.filter { SeriesFilter.twHK.matches($0) }
        case "krJP":   return list.filter { SeriesFilter.krJP.matches($0) }
        case "sea":    return list.filter { SeriesFilter.sea.matches($0) }
        case "india":  return list.filter { SeriesFilter.india.matches($0) }
        case "live":   return list.filter { SeriesFilter.live.matches($0) }
        case "vod":    return list.filter { SeriesFilter.vod.matches($0) }
        case "filter": return localFiltered
        default:       return []
        }
    }

    private func title(for key: String) -> String {
        switch key {
        case "zh":     return "🇨🇳 华语剧场"
        case "twHK":   return "🇹🇼 台湾 · 🇭🇰 香港"
        case "krJP":   return "🇰🇷 韩国 · 🇯🇵 日本"
        case "sea":    return "🌏 东南亚"
        case "india":  return "🇮🇳 印度"
        case "live":   return loc.t("series.filter.live")
        case "vod":    return loc.t("series.filter.vod")
        case "filter": return loc.t("series.results")
        default:       return key
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            seriesHeader
            filterBar

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    if let key = expandedSection {
                        expandedContent(key: key)
                    } else if !searchText.isEmpty {
                        searchContent
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
        .sheet(item: $selectedSeries) { SeriesCatalogDetailView(item: $0) }
        .onChange(of: selectedFilter) { _, _ in expandedSection = nil }
        .onChange(of: searchText) { _, _ in expandedSection = nil }
    }

    // MARK: - Header

    private var seriesHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.t("series.title"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(ZapColor.textPrimary)
                if !playableSeries.isEmpty {
                    Text(String(format: loc.t("series.count_split"),
                                 playableSeries.count, liveCount, vodCount))
                        .font(.system(size: 12))
                        .foregroundColor(ZapColor.textTertiary)
                }
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundColor(ZapColor.textTertiary)
                TextField(loc.t("series.search"), text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(ZapColor.textPrimary)
                    .frame(width: 200)
                    .onChange(of: searchText) { _, q in
                        searchTask?.cancel()
                        _ = q
                    }
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
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
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SeriesFilter.allCases) { filter in
                    GenreChip(title: filter.title(loc), isSelected: selectedFilter == filter) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Content

    @ViewBuilder
    private var browseContent: some View {
        // Library-first: every card here has a playable stream.
        if let local = playableSeries.first {
            LocalSeriesFeaturedHero(item: local) {
                let urls = sourceManager.streamURLs(forSeries: local)
                guard let first = urls.first else { return }
                playback.playInline(url: first, title: local.name, backups: Array(urls.dropFirst()))
            } onSelect: {
                selectedSeries = local
            }
            .padding(.horizontal, 24)
        }

        catalogSection(title: "🇨🇳 华语剧场", icon: "film.fill", key: "zh", items: items(for: "zh"))
        catalogSection(title: "🇹🇼 台湾 · 🇭🇰 香港", icon: "tv.fill", key: "twHK", items: items(for: "twHK"))
        catalogSection(title: "🇰🇷 韩国 · 🇯🇵 日本", icon: "sparkles", key: "krJP", items: items(for: "krJP"))
        catalogSection(title: "🌏 东南亚", icon: "globe.asia.australia.fill", key: "sea", items: items(for: "sea"))
        catalogSection(title: "🇮🇳 印度", icon: "star.fill", key: "india", items: items(for: "india"))
        catalogSection(title: loc.t("series.filter.live"), icon: "antenna.radiowaves.left.and.right",
                       key: "live", items: items(for: "live"))
        catalogSection(title: loc.t("series.filter.vod"), icon: "folder.fill", key: "vod",
                       items: items(for: "vod"))

        if playableSeries.isEmpty {
            EmptySeriesView(hasSource: !sourceManager.sources.isEmpty)
                .padding(.top, 48)
        }
    }

    @ViewBuilder
    private func catalogSection(title: String, icon: String, key: String, items: [SeriesCatalogItem]) -> some View {
        if !items.isEmpty {
            HomeSection(title: title, icon: icon, trailing: {
                if items.count > 10 {
                    Button(loc.t("series.see_all")) { expandedSection = key }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ZapColor.accentEnd)
                }
            }) {
                SeriesPosterRow(items: Array(items.prefix(24)), onSelect: { selectedSeries = $0 }, large: true)
            }
        }
    }

    @ViewBuilder
    private func expandedContent(key: String) -> some View {
        HStack {
            Button { expandedSection = nil } label: {
                Label(loc.t("series.back"), systemImage: "chevron.left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ZapColor.accentEnd)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 24)

        MoviesSectionHeader(title: title(for: key), subtitle: "\(items(for: key).count)", icon: "square.grid.2x2")
        SeriesCatalogGrid(items: items(for: key), onSelect: { selectedSeries = $0 })
    }

    @ViewBuilder
    private var filteredGridContent: some View {
        if !localFiltered.isEmpty {
            MoviesSectionHeader(
                title: loc.t("series.results"),
                subtitle: "\(localFiltered.count)",
                icon: "square.grid.2x2"
            )
            SeriesCatalogGrid(items: localFiltered, onSelect: { selectedSeries = $0 })
        } else {
            EmptySeriesView(hasSource: !sourceManager.sources.isEmpty)
                .padding(.top, 48)
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        if !localFiltered.isEmpty {
            MoviesSectionHeader(
                title: loc.t("home.library"),
                subtitle: "\(localFiltered.count)",
                icon: "folder.fill"
            )
            SeriesCatalogGrid(items: localFiltered, onSelect: { selectedSeries = $0 })
        } else {
            EmptySeriesView(hasSource: !sourceManager.sources.isEmpty)
                .padding(.top, 48)
        }
    }
}

// MARK: - Featured heroes

struct SeriesTMDBFeaturedHero: View {
    let show: TMDBTVShow
    var onSelect: (TMDBTVShow) -> Void

    var body: some View {
        Button { onSelect(show) } label: {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let backdrop = show.backdropURL ?? show.posterURL {
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
                    if let poster = show.posterURL {
                        AsyncImage(url: poster) { img in
                            img.resizable().scaledToFill()
                        } placeholder: { ZapColor.surface2 }
                        .frame(width: 72, height: 108)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 12)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(show.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            if let year = show.year {
                                Text(year).font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        if let overview = show.overview, !overview.isEmpty {
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
    }
}

struct SeriesTVmazeFeaturedHero: View {
    let show: TVmazeService.TVmazeShow
    var onSelect: (TVmazeService.TVmazeShow) -> Void

    var body: some View {
        Button { onSelect(show) } label: {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let backdrop = show.backdropURL ?? show.posterURL {
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
                    if let poster = show.posterURL {
                        AsyncImage(url: poster) { img in
                            img.resizable().scaledToFill()
                        } placeholder: { ZapColor.surface2 }
                        .frame(width: 72, height: 108)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 12)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(show.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            if let year = show.year {
                                Text(year).font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            if !show.ratingStr.isEmpty {
                                Text("★ \(show.ratingStr)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(ZapColor.accentStart)
                            }
                        }
                        if let summary = show.summary {
                            Text(summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
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
    }
}

struct LocalSeriesFeaturedHero: View {
    let item: SeriesCatalogItem
    var onPlay: () -> Void
    var onSelect: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let poster = item.posterURL {
                    AsyncImage(url: poster) { img in
                        img.resizable().scaledToFill()
                    } placeholder: { ZapColor.surface2 }
                } else {
                    ZapColor.surface2
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture { onSelect?() }

            LinearGradient(
                colors: [.clear, .black.opacity(0.75), .black.opacity(0.92)],
                startPoint: .top, endPoint: .bottom
            )
            .allowsHitTesting(false)

            HStack(alignment: .bottom, spacing: 16) {
                if let poster = item.posterURL {
                    AsyncImage(url: poster) { img in
                        img.resizable().scaledToFill()
                    } placeholder: { ZapColor.surface2 }
                    .frame(width: 72, height: 108)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 12)
                    .onTapGesture { onSelect?() }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .onTapGesture { onSelect?() }
                    if let g = item.genres.first {
                        Text(g).font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    if item.playURL != nil {
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
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ZapColor.border))
    }
}


// MARK: - Rows & grids

struct SeriesPosterRow: View {
    let items: [SeriesCatalogItem]
    let onSelect: (SeriesCatalogItem) -> Void
    var large: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(items) { item in
                    PosterCard(
                        posterURL: item.posterURL,
                        title: item.name,
                        subtitle: item.genres.first,
                        badge: item.rating.flatMap { $0.isEmpty ? nil : "★ \($0)" },
                        width: large ? 128 : 112,
                        height: large ? 192 : 168
                    )
                    .onTapGesture { onSelect(item) }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct SeriesCatalogGrid: View {
    let items: [SeriesCatalogItem]
    let onSelect: (SeriesCatalogItem) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 128, maximum: 160), spacing: 18)],
            spacing: 22
        ) {
            ForEach(items) { item in
                PosterCard(
                    posterURL: item.posterURL,
                    title: item.name,
                    subtitle: item.genres.first,
                    badge: item.rating.flatMap { $0.isEmpty ? nil : "★ \($0)" }
                )
                .onTapGesture { onSelect(item) }
            }
        }
        .padding(.horizontal, 24)
    }
}

struct TMDBTVPosterRow: View {
    let shows: [TMDBTVShow]
    var onSelect: ((TMDBTVShow) -> Void)? = nil
    var large: Bool = false
    @State private var selected: TMDBTVShow?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(shows) { show in
                    PosterCard(
                        posterURL: show.posterURL,
                        title: show.name,
                        subtitle: show.year,
                        width: large ? 128 : 112,
                        height: large ? 192 : 168
                    )
                    .onTapGesture {
                        if let onSelect { onSelect(show) } else { selected = show }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .sheet(item: $selected) { TMDBTVDetailView(show: $0) }
    }
}

struct TVmazePosterRow: View {
    let shows: [TVmazeService.TVmazeShow]
    let onSelect: (TVmazeService.TVmazeShow) -> Void
    var large: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(shows) { show in
                    PosterCard(
                        posterURL: show.posterURL,
                        title: show.name,
                        subtitle: show.year,
                        badge: show.ratingStr.isEmpty ? nil : "★ \(show.ratingStr)",
                        width: large ? 128 : 112,
                        height: large ? 192 : 168
                    )
                    .onTapGesture { onSelect(show) }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct EmptySeriesView: View {
    let hasSource: Bool
    @EnvironmentObject private var loc: LanguageManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasSource ? "rectangle.stack" : "plus.circle")
                .font(.system(size: 48))
                .foregroundColor(ZapColor.textTertiary)
            Text(hasSource ? loc.t("series.empty_loaded") : loc.t("series.empty_no_source"))
                .font(.system(size: 15))
                .foregroundColor(ZapColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
}

// MARK: - Catalog detail (playable)

struct SeriesCatalogDetailView: View {
    let item: SeriesCatalogItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var playback: PlaybackRouter
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                if let poster = item.posterURL {
                    AsyncImage(url: poster) { img in img.resizable().scaledToFill() }
                    placeholder: { ZapColor.surface2 }
                    .frame(width: 100, height: 148)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(ZapColor.textPrimary)
                    if let genre = item.genres.first {
                        Text(genre)
                            .font(.system(size: 12))
                            .foregroundColor(ZapColor.textTertiary)
                    }
                    if let rating = item.rating, !rating.isEmpty {
                        Text("★ \(rating)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ZapColor.accentStart)
                    }
                    if item.playURL != nil {
                        Button {
                            let urls = sourceManager.streamURLs(forSeries: item)
                            guard let first = urls.first else { return }
                            let title = item.name
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                playback.playInline(
                                    url: first,
                                    title: title,
                                    backups: Array(urls.dropFirst())
                                )
                            }
                        } label: {
                            Label(loc.t("play"), systemImage: "play.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .padding(.horizontal, 24).padding(.vertical, 10)
                                .background(LinearGradient(
                                    colors: [ZapColor.accentStart, ZapColor.accentEnd],
                                    startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(ZapColor.textSecondary)
                        .padding(8)
                        .background(ZapColor.surface2, in: Circle())
                }
                .buttonStyle(.plain)
            }

            if let plot = item.plot, !plot.isEmpty {
                Text(plot)
                    .font(.system(size: 14))
                    .foregroundColor(ZapColor.textSecondary)
            }

            if item.playURL == nil && item.xtreamSeriesId != nil {
                Text(loc.t("series.xtream_hint"))
                    .font(.system(size: 12))
                    .foregroundColor(ZapColor.textTertiary)
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 320)
        .background(ZapBackdrop())
    }
}

// MARK: - Grids (TVmaze search)

struct TVShowGrid: View {
    let shows: [TVmazeService.TVmazeShow]
    let onSelect: (TVmazeService.TVmazeShow) -> Void
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 118, maximum: 148), spacing: 18)], spacing: 22) {
            ForEach(shows) { show in
                TVShowPosterCard(show: show).onTapGesture { onSelect(show) }
            }
        }
        .padding(.horizontal, 24)
    }
}

struct TMDBTVScrollRow: View {
    let shows: [TMDBTVShow]
    var body: some View {
        TMDBTVPosterRow(shows: shows)
    }
}

struct TVShowPosterCard: View {
    let show: TVmazeService.TVmazeShow
    @State private var hovered = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(ZapColor.surface2)
                    .frame(width: 120, height: 178)
                if let url = show.posterURL {
                    AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                    placeholder: { ZapColor.surface2 }
                    .frame(width: 120, height: 178).clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "rectangle.stack.fill").font(.system(size: 30))
                        .foregroundColor(ZapColor.textTertiary)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(hovered ? ZapColor.accentStart : .clear, lineWidth: 2))
            .scaleEffect(hovered ? 1.03 : 1).animation(.easeOut(duration: 0.15), value: hovered)
            .onHover { hovered = $0 }

            Text(show.name).font(.system(size: 12, weight: .medium))
                .foregroundColor(ZapColor.textPrimary).lineLimit(1).frame(width: 120)
            if let year = show.year {
                Text(year).font(.system(size: 10)).foregroundColor(ZapColor.textTertiary)
            }
        }
    }
}

struct TMDBTVPosterCard: View {
    let show: TMDBTVShow
    @State private var hovered = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(ZapColor.surface2)
                    .frame(width: 120, height: 178)
                if let url = show.posterURL {
                    AsyncImage(url: url) { img in img.resizable().scaledToFill() }
                    placeholder: { ZapColor.surface2 }
                    .frame(width: 120, height: 178).clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(hovered ? ZapColor.accentStart : .clear, lineWidth: 2))
            .scaleEffect(hovered ? 1.03 : 1).animation(.easeOut(duration: 0.15), value: hovered)
            .onHover { hovered = $0 }

            Text(show.name).font(.system(size: 12, weight: .medium))
                .foregroundColor(ZapColor.textPrimary).lineLimit(1).frame(width: 120)
            if let year = show.year {
                Text(year).font(.system(size: 10)).foregroundColor(ZapColor.textTertiary)
            }
        }
    }
}

// MARK: - Detail views

struct TVShowDetailView: View {
    let show: TVmazeService.TVmazeShow
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var playback: PlaybackRouter
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager
    @State private var seasons: [TVmazeService.TVmazeSeason] = []
    @State private var episodes: [TVmazeService.TVmazeEpisode] = []
    @State private var selectedSeason: Int = 1
    @State private var isLoading = true
    @State private var showNeedSource = false

    var seasonEpisodes: [TVmazeService.TVmazeEpisode] {
        episodes.filter { $0.season == selectedSeason }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZapColor.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    if let backdrop = show.backdropURL {
                        AsyncImage(url: backdrop) { img in img.resizable().scaledToFill() }
                        placeholder: { ZapColor.surface2 }
                        .frame(maxWidth: .infinity).frame(height: 220).clipped()
                        .overlay(LinearGradient(colors: [.clear, ZapColor.bg],
                                               startPoint: .top, endPoint: .bottom))
                    } else {
                        ZapColor.surface2.frame(height: 220)
                    }

                    HStack(alignment: .bottom, spacing: 16) {
                        if let poster = show.posterURL {
                            AsyncImage(url: poster) { img in img.resizable().scaledToFill() }
                            placeholder: { ZapColor.surface2 }
                            .frame(width: 100, height: 148).clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 12).offset(y: 30)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(show.name).font(.system(size: 24, weight: .bold)).foregroundColor(ZapColor.textPrimary)
                            HStack(spacing: 8) {
                                if let year = show.year { metaTag(year) }
                                if !show.ratingStr.isEmpty { metaTag("★ \(show.ratingStr)") }
                                if let status = show.status { metaTag(status) }
                            }
                            if let genres = show.genres, !genres.isEmpty {
                                Text(genres.joined(separator: " · "))
                                    .font(.system(size: 12)).foregroundColor(ZapColor.textTertiary)
                            }
                            Button {
                                startPlayback(title: show.name)
                            } label: {
                                Label(loc.t("play"), systemImage: "play.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 20).padding(.vertical, 9)
                                    .background(
                                        LinearGradient(
                                            colors: [ZapColor.accentStart, ZapColor.accentEnd],
                                            startPoint: .leading, endPoint: .trailing
                                        ),
                                        in: Capsule()
                                    )
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 24).padding(.bottom, 16)
                }

                if let summary = show.summary {
                    Text(summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                        .font(.system(size: 13)).foregroundColor(ZapColor.textSecondary)
                        .lineLimit(3).padding(.horizontal, 24).padding(.top, 36).padding(.bottom, 12)
                }

                if !seasons.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(seasons) { season in
                                Button(action: { selectedSeason = season.number }) {
                                    Text("Season \(season.number)")
                                        .font(.system(size: 12, weight: selectedSeason == season.number ? .semibold : .regular))
                                        .foregroundColor(selectedSeason == season.number ? .white : ZapColor.textSecondary)
                                        .padding(.horizontal, 14).padding(.vertical, 6)
                                        .background(RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedSeason == season.number
                                                  ? ZapColor.accentStart.opacity(0.6)
                                                  : ZapColor.surface2))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 8)
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(seasonEpisodes) { ep in
                            EpisodeRow(episode: ep, playable: true) {
                                startPlayback(title: "\(show.name) · \(ep.name)")
                            }
                        }
                    }
                    .padding(.horizontal, 24).padding(.bottom, 24)
                }
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white).padding(10).background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain).padding(20)

            if isLoading { ProgressView().tint(ZapColor.accentEnd).frame(maxWidth: .infinity, maxHeight: .infinity) }
        }
        .frame(minWidth: 680, minHeight: 560)
        .alert(loc.t("play"), isPresented: $showNeedSource) {
            Button(loc.t("ok"), role: .cancel) {}
        } message: {
            Text(loc.t("series.need_source"))
        }
        .task { await load() }
    }

    private func startPlayback(title: String) {
        let query = show.name
        if let hit = sourceManager.resolvePlayableStreams(forTitle: query) {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                playback.playInline(
                    url: hit.urls[0],
                    title: title,
                    backups: Array(hit.urls.dropFirst())
                )
            }
        } else {
            showNeedSource = true
        }
    }

    private func load() async {
        async let s = TVmazeService.shared.seasons(showId: show.id)
        async let e = TVmazeService.shared.episodes(showId: show.id)
        seasons = (try? await s) ?? []
        episodes = (try? await e) ?? []
        selectedSeason = seasons.first?.number ?? 1
        isLoading = false
    }

    func metaTag(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .medium)).foregroundColor(ZapColor.textSecondary)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(ZapColor.surface2).cornerRadius(4)
    }
}

struct EpisodeRow: View {
    let episode: TVmazeService.TVmazeEpisode
    var playable: Bool = false
    var onPlay: (() -> Void)? = nil

    var body: some View {
        Button {
            onPlay?()
        } label: {
            HStack(spacing: 12) {
                if let still = episode.stillURL {
                    AsyncImage(url: still) { img in img.resizable().scaledToFill() }
                    placeholder: { ZapColor.surface2 }
                    .frame(width: 100, height: 56).clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6).fill(ZapColor.surface2)
                        .frame(width: 100, height: 56)
                        .overlay(Image(systemName: "play.rectangle").foregroundColor(ZapColor.textTertiary))
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if let num = episode.number {
                            Text("E\(num)").font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ZapColor.accentStart)
                        }
                        Text(episode.name).font(.system(size: 13, weight: .medium)).foregroundColor(ZapColor.textPrimary)
                            .lineLimit(1)
                    }
                    if let summary = episode.summary {
                        Text(summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                            .font(.system(size: 11)).foregroundColor(ZapColor.textTertiary).lineLimit(2)
                    }
                }
                Spacer()
                if playable {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(ZapColor.accentEnd)
                } else if let dur = episode.durationStr {
                    Text(dur).font(.system(size: 11)).foregroundColor(ZapColor.textTertiary)
                }
            }
            .padding(10)
            .background(ZapColor.surface2).cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(!playable)
    }
}

struct TMDBTVDetailView: View {
    let show: TMDBTVShow
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var playback: PlaybackRouter
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager
    @State private var detail: TMDBTVShow?
    @State private var credits: TMDBCredits?
    @State private var showNeedSource = false

    var display: TMDBTVShow { detail ?? show }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZapColor.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                if let backdrop = display.backdropURL {
                    AsyncImage(url: backdrop) { img in img.resizable().scaledToFill() }
                    placeholder: { ZapColor.surface2 }
                    .frame(maxWidth: .infinity).frame(height: 200).clipped()
                    .overlay(LinearGradient(colors: [.clear, ZapColor.bg],
                                           startPoint: .top, endPoint: .bottom))
                }
                HStack(alignment: .top, spacing: 16) {
                    if let poster = display.posterURL {
                        AsyncImage(url: poster) { img in img.resizable().scaledToFill() }
                        placeholder: { ZapColor.surface2 }
                        .frame(width: 100, height: 148).clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 10).offset(y: -40)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(display.name).font(.system(size: 22, weight: .bold)).foregroundColor(ZapColor.textPrimary)
                        HStack(spacing: 8) {
                            if let y = display.year {
                                Text(y).font(.system(size: 12)).foregroundColor(ZapColor.textTertiary)
                            }
                            if let s = display.numberOfSeasons {
                                Text("\(s) Seasons").font(.system(size: 12)).foregroundColor(ZapColor.textTertiary)
                            }
                        }
                        Button {
                            startPlayback()
                        } label: {
                            Label(loc.t("play"), systemImage: "play.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 20).padding(.vertical, 9)
                                .background(
                                    LinearGradient(
                                        colors: [ZapColor.accentStart, ZapColor.accentEnd],
                                        startPoint: .leading, endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)

                if let overview = display.overview, !overview.isEmpty {
                    Text(overview).font(.system(size: 13)).foregroundColor(ZapColor.textSecondary)
                        .lineLimit(5).padding(.horizontal, 24)
                }
                Spacer()
            }
            Button(action: { dismiss() }) {
                Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white).padding(10).background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain).padding(20)
        }
        .frame(minWidth: 600, minHeight: 440)
        .alert(loc.t("play"), isPresented: $showNeedSource) {
            Button(loc.t("ok"), role: .cancel) {}
        } message: {
            Text(loc.t("series.need_source"))
        }
        .task {
            detail = try? await TMDBService.shared.tvDetail(id: show.id)
            credits = try? await TMDBService.shared.tvCredits(id: show.id)
        }
    }

    private func startPlayback() {
        if let hit = sourceManager.resolvePlayableStreams(forTitle: display.name) {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                playback.playInline(
                    url: hit.urls[0],
                    title: hit.displayName,
                    backups: Array(hit.urls.dropFirst())
                )
            }
        } else {
            showNeedSource = true
        }
    }
}
