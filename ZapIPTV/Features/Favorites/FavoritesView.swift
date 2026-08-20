import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var playback: PlaybackRouter
    @EnvironmentObject private var loc: LanguageManager

    var favoriteChannels: [Channel] { sourceManager.channels.filter { $0.isFavorite } }
    var favoriteMovies: [Movie]     { sourceManager.movies.filter { $0.isFavorite } }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text(loc.t("favorites.title"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ZapColor.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                if favoriteChannels.isEmpty && favoriteMovies.isEmpty {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(ZapColor.accentStart.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "star")
                                .font(.system(size: 36))
                                .foregroundStyle(ZapColor.accentH)
                        }
                        Text(loc.t("favorites.empty"))
                            .font(.system(size: 18, weight: .semibold)).foregroundColor(ZapColor.textPrimary)
                        Text(loc.t("favorites.hint"))
                            .font(.system(size: 13)).foregroundColor(ZapColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 80)

                } else {
                    if !favoriteChannels.isEmpty {
                        HomeSection(title: loc.t("favorites.channels"), icon: "tv.fill") {
                            ChannelRow(channels: favoriteChannels, onSelect: { playback.playLive($0) })
                        }
                    }
                    if !favoriteMovies.isEmpty {
                        HomeSection(title: loc.t("favorites.movies"), icon: "film.fill") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(favoriteMovies) { m in
                                        PosterCard(posterURL: m.posterURL, title: m.title, subtitle: m.year)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                }
            }
        }
        .background(ZapColor.bg)
    }
}
