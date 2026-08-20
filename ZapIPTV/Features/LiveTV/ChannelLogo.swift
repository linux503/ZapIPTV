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
            // Skip known-dead hosts that often return “image does not exist” placeholders
            let host = (url.host ?? "").lowercased()
            if host.contains("imgur.com") || host.contains("i.imgur.com") {
                // Prefer EPG CDNs first; still allow imgur later as last resort below
                return
            }
            seen.insert(key)
            urls.append(url)
        }

        // Reliable Chinese EPG logos first (avoid broken playlist imgur links)
        let names = normalizedNames(channel.name)
        if let name = names.first,
           let enc = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            append(URL(string: "https://live.fanmingming.com/tv/\(enc).png"))
            append(URL(string: "https://epg.112114.xyz/logo/\(enc).png"))
        }
        for alt in names.dropFirst().prefix(2) {
            if let enc = alt.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                append(URL(string: "https://live.fanmingming.com/tv/\(enc).png"))
            }
        }

        append(SportLogoMap.url(for: channel.name))

        // Playlist logo last (often imgur / stale)
        if let logo = channel.logoURL {
            let host = (logo.host ?? "").lowercased()
            if !host.contains("imgur.com") {
                append(logo)
            } else if urls.count < 3 {
                // imgur only if nothing else queued
                let key = logo.absoluteString
                if seen.insert(key).inserted { urls.append(logo) }
            }
        }

        return Array(urls.prefix(5))
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
        if let m = compact.range(of: #"^CCTV-?(\d{1,2}\+?)"#, options: [.regularExpression, .caseInsensitive]) {
            let token = String(compact[m])
            let digits = token.filter { $0.isNumber || $0 == "+" }
            names.append("CCTV\(digits)")
            names.append("CCTV-\(digits)")
        }
        if compact.uppercased().contains("CCTV4K") || compact.uppercased().contains("CCTV-4K") {
            names.append("CCTV4K")
        }
        if compact.uppercased().contains("CCTV8K") || compact.uppercased().contains("CCTV-8K") {
            names.append("CCTV8K")
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

    @Environment(\.colorScheme) private var colorScheme
    @State private var image: NSImage?
    @State private var loading = false
    @State private var triedIndex = 0
    /// True when logo is mostly light ink (needs dark plate).
    @State private var needsDarkPlate = false

    /// Channel ids that already exhausted candidates — skip network on reuse/scroll.
    private static var failedIDs = Set<String>()

    private var candidates: [URL] { ChannelLogoResolver.candidates(for: channel) }

    private var plateColor: Color {
        if colorScheme == .light {
            return needsDarkPlate || image != nil ? ZapColor.logoPlate : ZapColor.surface2
        }
        return ZapColor.surface2
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(plateColor)

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(5)
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
                .strokeBorder(
                    colorScheme == .light ? Color.black.opacity(0.08) : ZapColor.border.opacity(0.7),
                    lineWidth: 0.5
                )
        )
        .shadow(color: colorScheme == .light ? .black.opacity(0.06) : .clear, radius: 1, y: 1)
        .task(id: channel.id) {
            if Self.failedIDs.contains(channel.id) {
                image = nil
                loading = false
                return
            }
            if image != nil { return }
            triedIndex = 0
            needsDarkPlate = colorScheme == .light
            await loadNext()
        }
    }

    @ViewBuilder
    private var fallbackArtwork: some View {
        if channel.group == "⚽ 体育" {
            let cat = SportCategory.classify(channel.name)
            let c = cat.accent
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius - 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: c.r, green: c.g, blue: c.b).opacity(0.9),
                                Color(red: c.r, green: c.g, blue: c.b).opacity(0.55),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: cat.systemImage)
                    .font(.system(size: max(12, height * 0.42), weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
            }
        } else if showGroupFallback {
            ZStack {
                if colorScheme == .light {
                    RoundedRectangle(cornerRadius: cornerRadius - 2, style: .continuous)
                        .fill(ZapColor.logoPlate)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius - 2, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [ZapColor.surface2, ZapColor.surface],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                }
                Text(fallbackGlyph)
                    .font(.system(size: max(11, height * 0.36), weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .light ? .white.opacity(0.92) : ZapColor.textSecondary)
            }
        } else {
            Image(systemName: "tv")
                .font(.system(size: height * 0.35))
                .foregroundColor(ZapColor.textTertiary)
        }
    }

    private var fallbackGlyph: String {
        let n = channel.name.trimmingCharacters(in: .whitespaces)
        if let m = n.uppercased().range(of: #"CCTV-?\d+"#, options: .regularExpression) {
            let digits = n[m].filter(\.isNumber)
            return digits.isEmpty ? "C" : digits
        }
        return String(n.prefix(1))
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
                if Self.isUsableLogo(cached) {
                    needsDarkPlate = Self.isMostlyLightInk(cached) || colorScheme == .light
                    image = cached
                    return
                }
                continue
            }

            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 3
                request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    continue
                }
                guard data.count > 400, let nsImg = NSImage(data: data), nsImg.size.width > 8 else {
                    continue
                }
                guard Self.isUsableLogo(nsImg) else { continue }
                await ImageCache.shared.store(nsImg, for: url)
                needsDarkPlate = Self.isMostlyLightInk(nsImg) || colorScheme == .light
                image = nsImg
                return
            } catch {
                continue
            }
        }
        Self.failedIDs.insert(channel.id)
    }

    /// Reject imgur “does not exist” black error cards and tiny garbage.
    private static func isUsableLogo(_ image: NSImage) -> Bool {
        guard let rep = rasterRep(image) else { return true }
        let w = rep.pixelsWide
        let h = rep.pixelsHigh
        guard w > 12, h > 12 else { return false }

        var dark = 0
        var bright = 0
        var samples = 0
        let stepX = max(1, w / 24)
        let stepY = max(1, h / 16)
        for y in stride(from: 0, to: h, by: stepY) {
            for x in stride(from: 0, to: w, by: stepX) {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                rep.colorAt(x: x, y: y)?.getRed(&r, green: &g, blue: &b, alpha: &a)
                if a < 0.08 { continue }
                let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                samples += 1
                if lum < 0.12 { dark += 1 }
                if lum > 0.82 { bright += 1 }
            }
        }
        guard samples > 20 else { return false }
        let darkRatio = Double(dark) / Double(samples)
        let brightRatio = Double(bright) / Double(samples)
        // Classic imgur error: nearly all black with a bit of white text
        if darkRatio > 0.82 && brightRatio > 0.02 && brightRatio < 0.22 {
            return false
        }
        return true
    }

    /// White / light-gray logo marks need a dark plate in light mode.
    private static func isMostlyLightInk(_ image: NSImage) -> Bool {
        guard let rep = rasterRep(image) else { return false }
        let w = rep.pixelsWide
        let h = rep.pixelsHigh
        var ink = 0
        var lightInk = 0
        let stepX = max(1, w / 20)
        let stepY = max(1, h / 14)
        for y in stride(from: 0, to: h, by: stepY) {
            for x in stride(from: 0, to: w, by: stepX) {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                rep.colorAt(x: x, y: y)?.getRed(&r, green: &g, blue: &b, alpha: &a)
                if a < 0.15 { continue }
                ink += 1
                let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                if lum > 0.72 { lightInk += 1 }
            }
        }
        guard ink > 10 else { return false }
        return Double(lightInk) / Double(ink) > 0.55
    }

    private static func rasterRep(_ image: NSImage) -> NSBitmapImageRep? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep
    }
}
