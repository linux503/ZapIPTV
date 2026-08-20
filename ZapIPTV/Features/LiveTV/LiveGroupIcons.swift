import SwiftUI

// MARK: - Group label helpers

enum LiveGroupLabel {
    static func split(_ group: String) -> (flag: String, title: String) {
        if let space = group.firstIndex(of: " ") {
            let flag = String(group[..<space])
            let title = String(group[group.index(after: space)...])
            if !flag.isEmpty { return (flag, title) }
        }
        return ("📡", group)
    }

    static func title(of group: String) -> String { split(group).title }
}

// MARK: - Category / country icons

struct LiveGroupIcon: View {
    let group: String
    var size: CGFloat = 28

    var body: some View {
        Group {
            switch group {
            case "🇨🇳 中国大陆": ChinaFlagIcon()
            case "🎬 华语影视": HuayuCinemaIcon()
            case "🎆 春晚":     ChunwanLanternIcon()
            case "🇹🇼 台湾":     TaiwanFlagIcon()
            case "🇭🇰 香港":     HongKongFlagIcon()
            case "🇯🇵 日本":     JapanFlagIcon()
            case "🇰🇷 韩国":     KoreaFlagIcon()
            case "🇹🇭 泰国":     ThailandFlagIcon()
            case "🇻🇳 越南":     VietnamFlagIcon()
            case "🇮🇩 印尼":     IndonesiaFlagIcon()
            case "🇲🇾 马来西亚": MalaysiaFlagIcon()
            case "🇸🇬 新加坡":   SingaporeFlagIcon()
            case "🇵🇭 菲律宾":   PhilippinesFlagIcon()
            case "🇮🇳 印度":     IndiaFlagIcon()
            case "📺 新闻":     CategoryGlyphIcon(system: "newspaper.fill", colors: ["#1D4ED8", "#0EA5E9"])
            case "⚽ 体育":
                SportsCategoryIcon()
            case "🎮 娱乐":     CategoryGlyphIcon(system: "sparkles.tv.fill", colors: ["#7C3AED", "#EC4899"])
            case "🎵 音乐":     CategoryGlyphIcon(system: "music.note", colors: ["#DB2777", "#F59E0B"])
            case "🎬 电影":     HuayuCinemaIcon()
            default:
                emojiFallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
    }

    private var emojiFallback: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#3A3230"), Color(hex: "#1C1614")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Text(LiveGroupLabel.split(group).flag)
                .font(.system(size: size * 0.55))
        }
    }
}

// MARK: - Flags

private struct ChinaFlagIcon: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Color(hex: "#DE2910")
                Image(systemName: "star.fill")
                    .font(.system(size: s * 0.28))
                    .foregroundColor(Color(hex: "#FFDE00"))
                    .position(x: s * 0.26, y: s * 0.36)
                smallStar(s, x: 0.52, y: 0.18)
                smallStar(s, x: 0.62, y: 0.30)
                smallStar(s, x: 0.62, y: 0.46)
                smallStar(s, x: 0.52, y: 0.58)
            }
        }
    }

    private func smallStar(_ s: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Image(systemName: "star.fill")
            .font(.system(size: s * 0.10))
            .foregroundColor(Color(hex: "#FFDE00"))
            .position(x: s * x, y: s * y)
    }
}

private struct TaiwanFlagIcon: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                Color(hex: "#FE0000")
                ZStack {
                    Color(hex: "#000095")
                    ZStack {
                        ForEach(0..<12, id: \.self) { i in
                            Capsule()
                                .fill(Color.white)
                                .frame(width: max(1.5, w * 0.04), height: h * 0.20)
                                .offset(y: -h * 0.09)
                                .rotationEffect(.degrees(Double(i) * 30))
                        }
                        Circle().fill(Color.white).frame(width: w * 0.18, height: h * 0.18)
                        Circle()
                            .strokeBorder(Color(hex: "#000095"), lineWidth: max(1, w * 0.03))
                            .frame(width: w * 0.18, height: h * 0.18)
                    }
                }
                .frame(width: w * 0.5, height: h * 0.5)
            }
        }
    }
}

private struct HongKongFlagIcon: View {
    var body: some View {
        ZStack {
            Color(hex: "#DE2910")
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(Color.white)
                        .frame(width: 4, height: 11)
                        .offset(y: -5)
                        .rotationEffect(.degrees(Double(i) * 72))
                }
                Circle().fill(Color(hex: "#DE2910")).frame(width: 5, height: 5)
            }
        }
    }
}

private struct JapanFlagIcon: View {
    var body: some View {
        ZStack {
            Color.white
            Circle()
                .fill(Color(hex: "#BC002D"))
                .frame(width: 14, height: 14)
        }
    }
}

private struct KoreaFlagIcon: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Color.white
                // Taegeuk
                ZStack {
                    Circle().fill(Color(hex: "#CD2E3A")).frame(width: s * 0.42, height: s * 0.42)
                    Circle().fill(Color(hex: "#0047A0"))
                        .frame(width: s * 0.42, height: s * 0.21)
                        .offset(y: s * 0.105)
                        .rotationEffect(.degrees(-35))
                    Circle().fill(Color(hex: "#CD2E3A"))
                        .frame(width: s * 0.21, height: s * 0.21)
                        .offset(x: -s * 0.105)
                        .rotationEffect(.degrees(-35))
                    Circle().fill(Color(hex: "#0047A0"))
                        .frame(width: s * 0.21, height: s * 0.21)
                        .offset(x: s * 0.105)
                        .rotationEffect(.degrees(-35))
                }
                .rotationEffect(.degrees(-35))
                // Simplified trigrams as bars
                VStack(spacing: 1.5) {
                    Capsule().fill(Color.black).frame(width: s * 0.18, height: 1.5)
                    Capsule().fill(Color.black).frame(width: s * 0.18, height: 1.5)
                    Capsule().fill(Color.black).frame(width: s * 0.18, height: 1.5)
                }
                .offset(x: -s * 0.28, y: -s * 0.28)
                VStack(spacing: 1.5) {
                    Capsule().fill(Color.black).frame(width: s * 0.18, height: 1.5)
                    HStack(spacing: 1) {
                        Capsule().fill(Color.black).frame(width: s * 0.07, height: 1.5)
                        Capsule().fill(Color.black).frame(width: s * 0.07, height: 1.5)
                    }
                    Capsule().fill(Color.black).frame(width: s * 0.18, height: 1.5)
                }
                .offset(x: s * 0.28, y: s * 0.28)
            }
        }
    }
}

private struct ThailandFlagIcon: View {
    var body: some View {
        VStack(spacing: 0) {
            Color(hex: "#A51931")
            Color(hex: "#F4F5F8")
            Color(hex: "#2D2A4A")
            Color(hex: "#F4F5F8")
            Color(hex: "#A51931")
        }
    }
}

private struct VietnamFlagIcon: View {
    var body: some View {
        ZStack {
            Color(hex: "#DA251D")
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#FFFF00"))
        }
    }
}

private struct IndonesiaFlagIcon: View {
    var body: some View {
        VStack(spacing: 0) {
            Color(hex: "#CE1126")
            Color.white
        }
    }
}

private struct MalaysiaFlagIcon: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { i in
                        (i % 2 == 0 ? Color(hex: "#CC0001") : Color.white)
                    }
                }
                ZStack(alignment: .leading) {
                    Color(hex: "#010066")
                    HStack(spacing: 2) {
                        ZStack {
                            Circle().fill(Color(hex: "#FFCC00")).frame(width: w * 0.22, height: h * 0.28)
                            Circle().fill(Color(hex: "#010066"))
                                .frame(width: w * 0.18, height: h * 0.24)
                                .offset(x: w * 0.04)
                        }
                        Image(systemName: "star.fill")
                            .font(.system(size: h * 0.16))
                            .foregroundColor(Color(hex: "#FFCC00"))
                    }
                    .padding(.leading, 3)
                }
                .frame(width: w * 0.5, height: h * 0.54)
            }
        }
    }
}

private struct SingaporeFlagIcon: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            VStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    Color(hex: "#EF3340")
                    HStack(spacing: 2) {
                        ZStack {
                            Circle().strokeBorder(Color.white, lineWidth: 1.2)
                                .frame(width: w * 0.22, height: h * 0.28)
                            Circle().fill(Color(hex: "#EF3340"))
                                .frame(width: w * 0.18, height: h * 0.24)
                                .offset(x: w * 0.04)
                        }
                        VStack(spacing: 1) {
                            Image(systemName: "star.fill").font(.system(size: 4)).foregroundColor(.white)
                            HStack(spacing: 1) {
                                Image(systemName: "star.fill").font(.system(size: 3.5)).foregroundColor(.white)
                                Image(systemName: "star.fill").font(.system(size: 3.5)).foregroundColor(.white)
                            }
                            HStack(spacing: 1) {
                                Image(systemName: "star.fill").font(.system(size: 3.5)).foregroundColor(.white)
                                Image(systemName: "star.fill").font(.system(size: 3.5)).foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
                Color.white
            }
        }
    }
}

private struct PhilippinesFlagIcon: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .leading) {
                VStack(spacing: 0) {
                    Color(hex: "#0038A8")
                    Color(hex: "#CE1126")
                }
                // White triangle
                Path { p in
                    p.move(to: .zero)
                    p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.5))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(Color.white)
                Image(systemName: "sun.max.fill")
                    .font(.system(size: h * 0.22))
                    .foregroundColor(Color(hex: "#FCD116"))
                    .offset(x: w * 0.08)
            }
        }
    }
}

private struct IndiaFlagIcon: View {
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Color(hex: "#FF9933")
                Color.white
                Color(hex: "#138808")
            }
            Circle()
                .strokeBorder(Color(hex: "#000080"), lineWidth: 1)
                .frame(width: 10, height: 10)
            Image(systemName: "asterisk")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(Color(hex: "#000080"))
        }
    }
}

private struct HuayuCinemaIcon: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1A1A1A"), Color(hex: "#3D1A14"), Color(hex: "#8B1520")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            HStack {
                sprocket
                Spacer()
                sprocket
            }
            .padding(.horizontal, 3)
            Image(systemName: "movieclapper.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#FFD36A"), Color(hex: "#F24A1A")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        }
    }

    private var sprocket: some View {
        VStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 3, height: 3)
            }
        }
    }
}

private struct ChunwanLanternIcon: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#4A0A10"), Color(hex: "#C41E3A"), Color(hex: "#8B0000")],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 0) {
                Capsule().fill(Color(hex: "#FFD36A")).frame(width: 8, height: 3)
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF4D4D"), Color(hex: "#B01020")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 16, height: 18)
                    .overlay(
                        Text("福")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#FFD36A"))
                    )
                Capsule().fill(Color(hex: "#FFD36A")).frame(width: 3, height: 4)
            }
            .offset(y: 1)
        }
    }
}

private struct CategoryGlyphIcon: View {
    let system: String
    let colors: [String]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colors.map { Color(hex: $0) },
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Image(systemName: system)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

/// Sports category — pitch green + ball motif
private struct SportsCategoryIcon: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#14532D"), Color(hex: "#22C55E"), Color(hex: "#15803D")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            // Simple pitch lines
            VStack(spacing: 0) {
                Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
            }
            .padding(.vertical, 6)
            Image(systemName: "soccerball")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
        }
    }
}
