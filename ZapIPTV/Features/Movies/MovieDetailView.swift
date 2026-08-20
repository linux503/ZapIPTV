import SwiftUI

// Detail view for local-library Movie items (from M3U / Xtream VOD)
struct MovieDetailView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var playerEngine: PlayerEngine
    @EnvironmentObject private var playback: PlaybackRouter
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager
    @State private var tmdbMatch: TMDBMovie?
    @State private var credits: TMDBCredits?

    private var liveMovie: Movie {
        sourceManager.movies.first(where: { $0.id == movie.id }) ?? movie
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Backdrop
            Group {
                if let backdrop = tmdbMatch?.backdropURL ?? liveMovie.backdropURL ?? liveMovie.posterURL {
                    AsyncImage(url: backdrop) { img in img.resizable().scaledToFill() }
                    placeholder: { ZapColor.surface }
                } else { ZapColor.surface }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
            .overlay(LinearGradient(
                colors: [.black.opacity(0.2), .black.opacity(0.85), .black],
                startPoint: .top, endPoint: .bottom
            ))

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 160)

                HStack(alignment: .bottom, spacing: 20) {
                    let poster = tmdbMatch?.posterURL ?? liveMovie.posterURL
                    if let poster {
                        AsyncImage(url: poster) { img in img.resizable().scaledToFill() }
                        placeholder: { ZapColor.surface2 }
                        .frame(width: 140, height: 208).clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 20)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(tmdbMatch?.title ?? liveMovie.title)
                            .font(.system(size: 32, weight: .bold)).foregroundColor(.white)

                        HStack(spacing: 12) {
                            if let y = tmdbMatch?.year ?? liveMovie.year { metaTag(y) }
                            if let d = tmdbMatch?.durationStr ?? liveMovie.duration { metaTag(d) }
                            let r = tmdbMatch?.ratingStr ?? liveMovie.rating ?? ""
                            if !r.isEmpty { metaTag("★ \(r)") }
                        }

                        if let genres = tmdbMatch?.genres?.map(\.name), !genres.isEmpty {
                            Text(genres.joined(separator: " · "))
                                .font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                        } else if !liveMovie.genres.isEmpty {
                            Text(liveMovie.genres.joined(separator: " · "))
                                .font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                        }

                        HStack(spacing: 12) {
                            Button(action: {
                                playback.playInline(url: liveMovie.url, title: liveMovie.title)
                                dismiss()
                            }) {
                                Label(loc.t("play"), systemImage: "play.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .padding(.horizontal, 24).padding(.vertical, 10)
                                    .background(LinearGradient(
                                        colors: [ZapColor.accentStart, ZapColor.accentEnd],
                                        startPoint: .leading, endPoint: .trailing))
                                    .foregroundColor(.white).cornerRadius(10)
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                sourceManager.toggleFavorite(movieId: liveMovie.id)
                            }) {
                                Label(loc.t("favorite"), systemImage: liveMovie.isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                    .background(ZapColor.surface2)
                                    .foregroundColor(.white).cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 32)

                let plot = tmdbMatch?.overview ?? liveMovie.plot ?? ""
                if !plot.isEmpty {
                    Text(plot).font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                        .lineLimit(4).padding(.horizontal, 32).padding(.top, 20)
                }

                // TMDB cast
                if let cast = credits?.cast.prefix(8), !cast.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(loc.t("cast")).font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4)).padding(.horizontal, 32)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) { ForEach(cast) { CastCard(member: $0) } }
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.top, 16)
                }

                HStack(spacing: 24) {
                    if let dir = credits?.director ?? liveMovie.director { infoRow("Director", dir) }
                    if let cast = liveMovie.cast { infoRow("Cast", cast) }
                }
                .padding(.horizontal, 32).padding(.top, 12).padding(.bottom, 32)
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white).padding(10).background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain).padding(20)
        }
        .frame(minWidth: 700, minHeight: 480)
        .background(Color.black)
        .task { await enrichFromTMDB() }
    }

    private func enrichFromTMDB() async {
        guard TMDBService.shared.isConfigured else { return }
        if let results = try? await TMDBService.shared.searchMovies(query: liveMovie.title),
           let first = results.first {
            tmdbMatch = first
            credits = try? await TMDBService.shared.movieCredits(id: first.id)
        }
    }

    func metaTag(_ text: String) -> some View {
        Text(text).font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.white.opacity(0.12)).cornerRadius(4)
    }

    func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
            Text(value).font(.system(size: 13)).foregroundColor(.white.opacity(0.75)).lineLimit(2)
        }
    }
}
