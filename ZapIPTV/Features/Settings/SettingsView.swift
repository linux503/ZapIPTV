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
            .background(ZapColor.bg)
        }
    }
}

// MARK: - 片源

struct SettingsSources: View {
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var loc: LanguageManager
    @State private var showAdd = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header(loc.t("settings.sources"), loc.t("settings.sources.hint"))

            Button {
                showAdd = true
            } label: {
                Label(loc.t("nav.add_source_cta"), systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ZapColor.accent, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if sourceManager.userPlaylists.isEmpty {
                Text(loc.t("settings.sources.empty"))
                    .font(.system(size: 13))
                    .foregroundColor(ZapColor.textTertiary)
            } else {
                VStack(spacing: 0) {
                    ForEach(sourceManager.userPlaylists) { source in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(source.isLoaded ? ZapColor.live : ZapColor.orange)
                                .frame(width: 7, height: 7)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(ZapColor.textPrimary)
                                Text(loc.t("source.type.\(source.type.rawValue)"))
                                    .font(.system(size: 11))
                                    .foregroundColor(ZapColor.textTertiary)
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
                        Divider().background(ZapColor.border)
                    }
                }
            }

            HStack(spacing: 12) {
                Button(loc.t("settings.refresh")) {
                    Task { await sourceManager.refreshAll() }
                }
                .buttonStyle(.plain)
                .foregroundColor(ZapColor.accentEnd)
            }
        }
        .sheet(isPresented: $showAdd) { AddSourceView() }
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
        .background(ZapColor.surface2, in: RoundedRectangle(cornerRadius: 10))
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
            .background(ZapColor.surface2, in: RoundedRectangle(cornerRadius: 10))

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
                        .background(ZapColor.surface2, in: RoundedRectangle(cornerRadius: 8))
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
