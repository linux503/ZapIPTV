import Foundation
import AppKit

@MainActor
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    static let repo = "linux503/ZapIPTV"
    private static let siteVersionURL = URL(string: "https://linux503.github.io/ZapIPTV/website/version.json")!

    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available
        case downloading
        case failed(String)
    }

    @Published var status: Status = .idle
    @Published var latestVersion: String = ""
    @Published var downloadURL: URL?
    @Published var releasePage: URL?
    @Published var progress: Double = 0

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    var hasUpdate: Bool { status == .available || status == .downloading }

    func check(silent: Bool = false) async {
        if !silent { status = .checking }
        do {
            let info: VersionInfo
            if let github = try await fetchGitHub() {
                info = github
            } else {
                info = try await fetchSite()
            }
            latestVersion = info.version
            releasePage = info.page
            downloadURL = info.dmg
            if isNewer(info.version, than: currentVersion) {
                status = .available
            } else {
                status = .upToDate
            }
        } catch {
            releasePage = URL(string: "https://github.com/\(Self.repo)/releases/latest")
            if !silent {
                status = .failed("settings.update.fail")
            }
        }
    }

    func install() async {
        guard let url = downloadURL else {
            if let page = releasePage { NSWorkspace.shared.open(page) }
            return
        }
        status = .downloading
        progress = 0
        do {
            let (temp, _) = try await URLSession.shared.download(from: url)
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("ZapIPTV-\(latestVersion).dmg")
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: temp, to: dest)
            NSWorkspace.shared.open(dest)
            status = .available
        } catch {
            status = .failed("settings.update.fail")
            if let page = releasePage { NSWorkspace.shared.open(page) }
        }
    }

    func openReleases() {
        let page = releasePage ?? URL(string: "https://github.com/\(Self.repo)/releases/latest")!
        NSWorkspace.shared.open(page)
    }

    private struct VersionInfo {
        var version: String
        var dmg: URL?
        var page: URL?
    }

    private func fetchGitHub() async throws -> VersionInfo? {
        var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(Self.repo)/releases/latest")!)
        req.setValue("ZapIPTV/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 12
        let (data, response) = try await URLSession.shared.data(for: req)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else { return nil }
        guard let release = try? JSONDecoder().decode(GitHubRelease.self, from: data) else { return nil }
        let version = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let dmg = (release.assets ?? []).first(where: { ($0.name ?? "").lowercased().hasSuffix(".dmg") })
            .flatMap { URL(string: $0.browser_download_url ?? "") }
        return VersionInfo(
            version: version,
            dmg: dmg,
            page: URL(string: release.html_url ?? "")
        )
    }

    private func fetchSite() async throws -> VersionInfo {
        var req = URLRequest(url: Self.siteVersionURL)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 12
        let (data, response) = try await URLSession.shared.data(for: req)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else { throw URLError(.badServerResponse) }
        let site = try JSONDecoder().decode(SiteVersion.self, from: data)
        return VersionInfo(
            version: site.version.trimmingCharacters(in: CharacterSet(charactersIn: "vV")),
            dmg: URL(string: site.dmg),
            page: URL(string: site.page)
        )
    }

    private func isNewer(_ remote: String, than local: String) -> Bool {
        remote.compare(local, options: .numeric) == .orderedDescending
    }
}

private struct GitHubRelease: Decodable {
    let tag_name: String
    let html_url: String?
    let assets: [Asset]?
    struct Asset: Decodable {
        let name: String?
        let browser_download_url: String?
    }
}

private struct SiteVersion: Decodable {
    let version: String
    let dmg: String
    let page: String
}

extension Notification.Name {
    static let zapOpenSettings = Notification.Name("zapOpenSettings")
}
