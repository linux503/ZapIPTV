import SwiftUI
import AppKit

enum SettingsSection: String, CaseIterable, Identifiable {
    case sources, language, appearance, playback, update, about
    var id: String { rawValue }
    var titleKey: String { "settings.\(rawValue)" }
    var icon: String {
        switch self {
        case .sources:     return "square.stack.3d.up.fill"
        case .language:    return "globe"
        case .appearance:  return "circle.lefthalf.filled"
        case .playback:    return "play.rectangle.fill"
        case .update:      return "arrow.down.app.fill"
        case .about:       return "info.circle.fill"
        }
    }
}

struct SettingsView: View {
    @State private var section: SettingsSection = .sources
    @EnvironmentObject private var loc: LanguageManager
    @EnvironmentObject private var updater: UpdateChecker

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.t("tab.settings"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ZapColor.textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 8)

                ForEach(SettingsSection.allCases) { item in
                    Button {
                        section = item
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: item.icon)
                                .font(.system(size: 13))
                                .frame(width: 18)
                            Text(loc.t(item.titleKey))
                                .font(.system(size: 13, weight: section == item ? .semibold : .regular))
                            Spacer()
                            if item == .update && updater.hasUpdate {
                                Circle().fill(ZapColor.accentStart).frame(width: 7, height: 7)
                            }
                        }
                        .foregroundColor(section == item ? ZapColor.textPrimary : ZapColor.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(section == item ? ZapColor.accentStart.opacity(0.22) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                }
                Spacer()
            }
            .frame(width: 200)
            .background(ZapColor.surface)

            Divider().background(ZapColor.border)

            ScrollView {
                Group {
                    switch section {
                    case .sources:     SettingsSources()
                    case .language:    SettingsLanguage()
                    case .appearance:  SettingsAppearance()
                    case .playback:    SettingsPlayback()
                    case .update:      SettingsUpdate()
                    case .about:       SettingsAbout()
                    }
                }
                .frame(maxWidth: 640, alignment: .leading)
                .padding(28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ZapBackdrop())
        }
    }
}

// MARK: - 片源（仅展示整理后的概览，不暴露具体列表地址）

struct SettingsSources: View {
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager
    @State private var showAdd = false
    @State private var revealCustom = false

    private var libraryCards: [(icon: String, title: String, count: Int, tint: Color)] {
        let groups = sourceManager.channelGroups
        func count(in keys: [String]) -> Int {
            keys.reduce(0) { $0 + sourceManager.channels(inGroup: $1).count }
        }
        let liveKeys = groups.filter {
            $0.contains("中国") || $0.contains("台湾") || $0.contains("香港")
                || $0.contains("日本") || $0.contains("韩国") || $0.contains("春晚")
                || $0.contains("华语")
        }
        let sports = sourceManager.channels(inGroup: "⚽ 体育").count
        let movies = sourceManager.movies.count
        let series = sourceManager.seriesList.count
        let regions = groups.filter {
            !$0.contains("体育") && !$0.contains("春晚") && !$0.contains("华语")
                && ($0.contains("泰国") || $0.contains("越南") || $0.contains("印尼")
                    || $0.contains("马来") || $0.contains("新加坡") || $0.contains("菲律宾")
                    || $0.contains("印度") || $0.contains("美国"))
        }
        return [
            ("tv.fill", loc.t("settings.lib.live"), count(in: liveKeys), ZapColor.accentStart),
            ("sportscourt.fill", loc.t("settings.lib.sports"), sports, Color.orange),
            ("film.fill", loc.t("settings.lib.movies"), movies, Color.pink),
            ("rectangle.stack.fill", loc.t("settings.lib.series"), series, Color.purple),
            ("globe.asia.australia.fill", loc.t("settings.lib.regions"), count(in: regions), Color.teal),
        ]
    }

    private var loadedFraction: Double {
        let total = max(sourceManager.sources.count, 1)
        let loaded = sourceManager.sources.filter(\.isLoaded).count
        return Double(loaded) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header(loc.t("settings.sources"), loc.t("settings.sources.hint.soft"))

            // Soft status pill — no raw URLs
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(ZapColor.border, lineWidth: 3)
                        .frame(width: 36, height: 36)
                    Circle()
                        .trim(from: 0, to: loadedFraction)
                        .stroke(ZapColor.accentEnd, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 36, height: 36)
                    Image(systemName: sourceManager.isLoading ? "arrow.triangle.2.circlepath" : "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ZapColor.accentEnd)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc.t("settings.lib.ready"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ZapColor.textPrimary)
                    Text(sourceManager.isLoading
                         ? loc.t("settings.lib.syncing")
                         : String(format: loc.t("settings.lib.summary"),
                                  sourceManager.channels.count,
                                  sourceManager.movies.count))
                        .font(.system(size: 12))
                        .foregroundColor(ZapColor.textTertiary)
                        .lineLimit(2)
                }
                Spacer()
                Button(loc.t("settings.refresh")) {
                    Task { await sourceManager.refreshAll() }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ZapColor.accentEnd)
                .disabled(sourceManager.isLoading)
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(ZapColor.border.opacity(0.5), lineWidth: 0.5)
            )

            // Organized library cards (blurred / abstract — no source names)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(libraryCards.enumerated()), id: \.offset) { _, card in
                    libraryCard(card)
                }
            }

            // Custom playlists — names obscured unless revealed
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(loc.t("settings.lib.custom"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ZapColor.textSecondary)
                    Spacer()
                    if !sourceManager.userPlaylists.isEmpty {
                        Button(revealCustom ? loc.t("settings.lib.hide") : loc.t("settings.lib.reveal")) {
                            withAnimation(.easeInOut(duration: 0.2)) { revealCustom.toggle() }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ZapColor.textTertiary)
                    }
                }

                if sourceManager.userPlaylists.isEmpty {
                    Text(loc.t("settings.sources.empty"))
                        .font(.system(size: 12))
                        .foregroundColor(ZapColor.textTertiary)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(sourceManager.userPlaylists.enumerated()), id: \.element.id) { idx, source in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(source.isLoaded ? ZapColor.live : ZapColor.orange)
                                    .frame(width: 7, height: 7)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(revealCustom
                                         ? source.name
                                         : String(format: loc.t("settings.lib.custom_item"), idx + 1))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ZapColor.textPrimary)
                                        .blur(radius: revealCustom ? 0 : 0) // label already masked
                                    Text(revealCustom
                                         ? maskedURL(source.url)
                                         : loc.t("source.type.\(source.type.rawValue)"))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(ZapColor.textTertiary)
                                        .lineLimit(1)
                                        .blur(radius: revealCustom ? 0 : 3.5)
                                }
                                Spacer()
                                Button(loc.t("settings.remove")) {
                                    sourceManager.removeSource(source)
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.85))
                            }
                            .padding(.vertical, 10)
                            if idx < sourceManager.userPlaylists.count - 1 {
                                Divider().background(ZapColor.border)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .background(ZapColor.surface2.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showAdd = true
                } label: {
                    Label(loc.t("nav.add_source_cta"), systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ZapColor.accentEnd)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showAdd) { AddSourceView() }
    }

    private func libraryCard(_ card: (icon: String, title: String, count: Int, tint: Color)) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(card.tint.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: card.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(card.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ZapColor.textSecondary)
                Text("\(card.count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(ZapColor.textPrimary)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ZapColor.border.opacity(0.4), lineWidth: 0.5)
        )
    }

    /// Soften URL: keep scheme + host blur-friendly truncation.
    private func maskedURL(_ raw: String) -> String {
        guard let url = URL(string: raw), let host = url.host else {
            return String(raw.prefix(18)) + "…"
        }
        return "\(url.scheme ?? "https")://\(host)/••••"
    }

    private func header(_ title: String, _ hint: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 22, weight: .bold)).foregroundColor(ZapColor.textPrimary)
            Text(hint).font(.system(size: 13)).foregroundColor(ZapColor.textTertiary)
        }
    }
}

// MARK: - 语言

struct SettingsLanguage: View {
    @EnvironmentObject private var loc: LanguageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(loc.t("settings.language"))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(ZapColor.textPrimary)
            Text(loc.t("settings.language.hint"))
                .font(.system(size: 13))
                .foregroundColor(ZapColor.textTertiary)

            langRow("zh-Hant", loc.t("nav.lang_hant"))
            langRow("zh-Hans", loc.t("nav.lang_hans"))
            langRow("en", loc.t("nav.lang_en"))
            langRow("", loc.t("settings.lang.system"))
        }
    }

    private func langRow(_ code: String, _ title: String) -> some View {
        let on = loc.selection == code
        return Button {
            loc.selection = code
        } label: {
            HStack {
                Text(title).foregroundColor(ZapColor.textPrimary)
                Spacer()
                if on {
                    Image(systemName: "checkmark")
                        .foregroundColor(ZapColor.accentEnd)
                }
            }
            .padding(14)
            .background(on ? ZapColor.accentStart.opacity(0.18) : ZapColor.surface2,
                        in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 外观

struct SettingsAppearance: View {
    @EnvironmentObject private var loc: LanguageManager
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(loc.t("settings.appearance"))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(ZapColor.textPrimary)
            Text(loc.t("settings.appearance.hint"))
                .font(.system(size: 13))
                .foregroundColor(ZapColor.textTertiary)

            ForEach(AppTheme.allCases) { item in
                Button {
                    theme.theme = item
                } label: {
                    HStack {
                        Text(loc.t(item.titleKey)).foregroundColor(ZapColor.textPrimary)
                        Spacer()
                        if theme.theme == item {
                            Image(systemName: "checkmark")
                                .foregroundColor(ZapColor.accentEnd)
                        }
                    }
                    .padding(14)
                    .background(theme.theme == item ? ZapColor.accentStart.opacity(0.18) : ZapColor.surface2,
                                in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - 播放

struct SettingsPlayback: View {
    @EnvironmentObject private var loc: LanguageManager
    @AppStorage("hardwareDecoding") private var hardwareDecoding = true
    @AppStorage("autoPlay") private var autoPlay = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(loc.t("settings.playback"))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(ZapColor.textPrimary)

            toggle(loc.t("settings.hw"), $hardwareDecoding)
            toggle(loc.t("settings.autoplay"), $autoPlay)
        }
    }

    private func toggle(_ title: String, _ value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            Text(title).foregroundColor(ZapColor.textPrimary)
        }
        .toggleStyle(.switch)
        .padding(14)
        .zapGlassInset(cornerRadius: 10)
    }
}

// MARK: - 更新

struct SettingsUpdate: View {
    @EnvironmentObject private var loc: LanguageManager
    @EnvironmentObject private var updater: UpdateChecker

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(loc.t("settings.update"))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(ZapColor.textPrimary)

            HStack {
                Text(loc.t("settings.current"))
                    .foregroundColor(ZapColor.textTertiary)
                Spacer()
                Text("v\(updater.currentVersion)")
                    .foregroundColor(ZapColor.textPrimary)
                    .fontWeight(.semibold)
            }
            .padding(14)
            .zapGlassInset(cornerRadius: 10)

            statusText

            HStack(spacing: 10) {
                Button {
                    Task { await updater.check() }
                } label: {
                    Text(loc.t("settings.check"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ZapColor.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .zapGlassInset(cornerRadius: 8)
                }
                .buttonStyle(.plain)
                .disabled(updater.status == .checking || updater.status == .downloading)

                if updater.hasUpdate {
                    Button {
                        Task { await updater.install() }
                    } label: {
                        Text(updater.status == .downloading ? loc.t("settings.downloading") : loc.t("settings.download"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(ZapColor.accent, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(updater.status == .downloading)
                }
            }

            Text(loc.t("settings.update.hint"))
                .font(.system(size: 12))
                .foregroundColor(ZapColor.textTertiary)
        }
        .onAppear {
            if updater.status == .idle {
                Task { await updater.check(silent: true) }
            }
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch updater.status {
        case .idle:
            EmptyView()
        case .checking:
            Text(loc.t("settings.checking")).foregroundColor(ZapColor.textTertiary)
        case .upToDate:
            Text(loc.t("settings.latest")).foregroundColor(ZapColor.live)
        case .available:
            Text(String(format: loc.t("settings.new"), updater.latestVersion))
                .foregroundColor(ZapColor.orange)
        case .downloading:
            Text(loc.t("settings.downloading")).foregroundColor(ZapColor.textTertiary)
        case .failed(let msg):
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.t(msg)).font(.system(size: 13)).foregroundColor(.orange)
                Button(loc.t("settings.update.open")) { updater.openReleases() }
                    .buttonStyle(.plain)
                    .foregroundColor(ZapColor.accentStart)
                    .font(.system(size: 13, weight: .semibold))
            }
        }
    }
}

// MARK: - 关于

struct SettingsAbout: View {
    @EnvironmentObject private var loc: LanguageManager
    @EnvironmentObject private var updater: UpdateChecker

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text("ZapIPTV").font(.system(size: 22, weight: .bold)).foregroundColor(ZapColor.textPrimary)
                    Text("v\(updater.currentVersion)").foregroundColor(ZapColor.textTertiary)
                }
            }
            Text(loc.t("tagline")).foregroundColor(ZapColor.textSecondary)
            Text(loc.t("settings.about.body"))
                .font(.system(size: 13))
                .foregroundColor(ZapColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
