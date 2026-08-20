import SwiftUI
import AppKit

// MARK: - Logo URL resolver (playlist logo → public EPG logos → nil)

enum ChannelLogoResolver {
    /// Ordered candidate logo URLs for a channel (capped for scroll performance).
    static func candidates(for channel: Channel) -> [URL] {
        var urls: [URL] = []
        var seen = Set<String>()

        func append(_ url: URL?) {
            guard let url else { return }
            let key = url.absoluteString
            guard !seen.contains(key) else { return }
            seen.insert(key)
            urls.append(url)
        }

        append(channel.logoURL)

        // At most one normalized name × two CDNs to avoid waterfall stalls while scrolling
        if let name = normalizedNames(channel.name).first,
           let enc = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            append(URL(string: "https://epg.112114.xyz/logo/\(enc).png"))
            append(URL(string: "https://live.fanmingming.com/tv/\(enc).png"))
        }

        return Array(urls.prefix(3))
    }

    private static func normalizedNames(_ raw: String) -> [String] {
        var base = raw
            .replacingOccurrences(of: #"\[.*?\]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\(.*?\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"【.*?】"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Drop common quality suffixes
        for token in ["超清", "高清", "标清", "蓝光", "HDR", "HD", "FHD", "UHD", "4K", "8K", "HEVC", "H265"] {
            if base.uppercased().hasSuffix(token.uppercased()) {
                base = String(base.dropLast(token.count)).trimmingCharacters(in: .whitespaces)
            }
        }

        let compact = base.replacingOccurrences(of: " ", with: "")
        var names = [compact, base].filter { !$0.isEmpty }

        // CCTV aliases: CCTV-1 / CCTV1 / 央视综合
        if let m = compact.range(of: #"^CCTV-?(\d{1,2})"#, options: [.regularExpression, .caseInsensitive]) {
            let digits = compact[m].filter(\.isNumber)
            names.append("CCTV\(digits)")
            names.append("CCTV-\(digits)")
        }

        // Deduplicate preserving order
        var out: [String] = []
        var seen = Set<String>()
        for n in names where seen.insert(n).inserted {
            out.append(n)
        }
        return out
    }
}

// MARK: - Channel logo view

struct ChannelLogoView: View {
    let channel: Channel
    var width: CGFloat = 48
    var height: CGFloat = 32
    var cornerRadius: CGFloat = 7
    var showGroupFallback: Bool = true

    @State private var image: NSImage?
    @State private var loading = false
    @State private var triedIndex = 0

    /// Channel ids that already exhausted candidates — skip network on reuse/scroll.
    private static var failedIDs = Set<String>()

    private var candidates: [URL] { ChannelLogoResolver.candidates(for: channel) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(ZapColor.surface2)

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(4)
            } else if loading {
                ProgressView().scaleEffect(0.55).tint(ZapColor.textTertiary)
            } else {
                fallbackArtwork
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(ZapColor.border.opacity(0.7), lineWidth: 0.5)
        )
        .task(id: channel.id) {
            if Self.failedIDs.contains(channel.id) {
                image = nil
                loading = false
                return
            }
            // Keep existing image if we already resolved this row (avoid flash on parent redraw)
            if image != nil { return }
            triedIndex = 0
            await loadNext()
        }
    }

    @ViewBuilder
    private var fallbackArtwork: some View {
        if showGroupFallback {
            ZStack {
                LinearGradient(
                    colors: [ZapColor.surface2, ZapColor.surface],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                // Lightweight fallback — letter only (flag composites are expensive in long lists)
                Text(String(channel.name.prefix(1)))
                    .font(.system(size: max(11, height * 0.38), weight: .bold, design: .rounded))
                    .foregroundColor(ZapColor.textSecondary)
            }
        } else {
            Image(systemName: "tv")
                .font(.system(size: height * 0.35))
                .foregroundColor(ZapColor.textTertiary)
        }
    }

    private func loadNext() async {
        let list = candidates
        guard triedIndex < list.count else {
            Self.failedIDs.insert(channel.id)
            return
        }
        loading = true
        defer { loading = false }

        while triedIndex < list.count {
            let url = list[triedIndex]
            triedIndex += 1

            if let cached = await ImageCache.shared.image(for: url) {
                image = cached
                return
            }

            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 3
                request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    continue
                }
                // Skip tiny / empty / HTML responses
                guard data.count > 400, let nsImg = NSImage(data: data), nsImg.size.width > 8 else {
                    continue
                }
                await ImageCache.shared.store(nsImg, for: url)
                image = nsImg
                return
            } catch {
                continue
            }
        }
        Self.failedIDs.insert(channel.id)
    }
}
