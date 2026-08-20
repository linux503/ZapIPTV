import SwiftUI
import AppKit

enum AppWindowFS {
    static func targetWindow() -> NSWindow? {
        if let w = NSApp.keyWindow, w.isVisible, !w.isSheet { return w }
        if let w = NSApp.mainWindow, w.isVisible { return w }
        return NSApp.windows.first { $0.isVisible && $0.canBecomeMain && !$0.isSheet }
    }

    static func enable(_ window: NSWindow) {
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.styleMask.insert(.resizable)
        window.styleMask.insert(.titled)
        var behavior = window.collectionBehavior
        behavior.remove(.fullScreenNone)
        behavior.remove(.fullScreenAuxiliary)
        behavior.insert(.fullScreenPrimary)
        window.collectionBehavior = behavior
    }

    static func enter() {
        guard let window = targetWindow() else { return }
        enable(window)
        window.makeKeyAndOrderFront(nil)
        if !window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }

    static func exit() {
        guard let window = targetWindow() else { return }
        if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }

    static func toggle() {
        guard let window = targetWindow() else { return }
        enable(window)
        window.makeKeyAndOrderFront(nil)
        window.toggleFullScreen(nil)
    }
}

struct WindowFSConfigurator: NSViewRepresentable {
    var scheme: ColorScheme = .dark

    func makeNSView(context: Context) -> NSView { FSHookView() }
    func updateNSView(_ view: NSView, context: Context) {
        guard let window = view.window else { return }
        AppWindowFS.enable(window)
        window.appearance = NSAppearance(named: scheme == .light ? .aqua : .darkAqua)
        if scheme == .light {
            window.isOpaque = false
            window.backgroundColor = NSColor(hexString: "#F6F3EE").withAlphaComponent(0.78)
        } else {
            window.isOpaque = true
            window.backgroundColor = NSColor(hexString: "#0A0A0A")
        }
        window.titlebarAppearsTransparent = true
    }
}

private final class FSHookView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window { AppWindowFS.enable(window) }
    }
}

// MARK: - Global Design Tokens
// Color theme: Black + Red-Orange (unified with app icon)
enum ZapColor {
    static let bg        = Color.adaptive(light: "#F6F3EE", dark: "#0A0A0A")
    static let surface   = Color.adaptive(light: "#FFFCFA", dark: "#141414")
    static let surface2  = Color.adaptive(light: "#EDE7E0", dark: "#1E1E1E")
    static let border    = Color.adaptive(light: "#D4CBC2", dark: "#2A2A2A")
    static let hover     = Color.adaptive(light: "#E6DFD6", dark: "#2A2A2A")
    static let hairline  = Color.adaptive(light: "#C9BFB5", dark: "#333333")

    static let accentStart = Color(hex: "#D70F24")
    static let accentMid   = Color(hex: "#E8192C")
    static let accentEnd   = Color(hex: "#F24A1A")

    static var accent: LinearGradient {
        LinearGradient(colors: [accentStart, accentEnd],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var accentH: LinearGradient {
        LinearGradient(colors: [accentStart, accentEnd],
                       startPoint: .leading, endPoint: .trailing)
    }

    static let textPrimary   = Color.adaptive(light: "#1C1612", dark: "#F6F3EE")
    static let textSecondary = Color.adaptive(light: "#5A524B", dark: "#A39A91")
    static let textTertiary  = Color.adaptive(light: "#8A8078", dark: "#6B625A")

    static let live   = Color.adaptive(light: "#15803D", dark: "#22C55E")
    static let orange = Color.adaptive(light: "#C2410C", dark: "#FF6B35")

    /// Dark plate behind channel logos so white/light marks stay readable in light mode.
    static let logoPlate = Color.adaptive(light: "#2A2420", dark: "#222222")
    /// Soft row selection — warm taupe in light (avoids harsh pink wash).
    static let selection = Color.adaptive(light: "#EDE3D8", dark: "#2A1A1C")
    static let selectionStrong = Color.adaptive(light: "#E4D5C8", dark: "#3A2024")
}

// MARK: - Light-mode glass surfaces

struct ZapBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if colorScheme == .light {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#FAF6F1"), Color(hex: "#E8E0D6"), Color(hex: "#F4EBE3")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(ZapColor.accentStart.opacity(0.05))
                    .frame(width: 440, height: 440)
                    .offset(x: -260, y: -200)
                    .blur(radius: 2)
                Circle()
                    .fill(ZapColor.accentEnd.opacity(0.04))
                    .frame(width: 380, height: 380)
                    .offset(x: 300, y: 220)
                    .blur(radius: 2)
            }
            .ignoresSafeArea()
        } else {
            ZapColor.bg.ignoresSafeArea()
        }
    }
}

struct ZapGlassPanelModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if colorScheme == .light {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(Color.white.opacity(0.38))
                        )
                        .shadow(color: .black.opacity(0.06), radius: 14, y: 5)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.58), lineWidth: 1)
                )
        } else {
            content
                .background(ZapColor.surface, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(ZapColor.border, lineWidth: 1))
        }
    }
}

struct ZapGlassSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if colorScheme == .light {
            content.background {
                ZStack {
                    Rectangle().fill(.thinMaterial)
                    LinearGradient(
                        colors: [Color.white.opacity(0.44), Color.white.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        } else {
            content.background(ZapColor.surface)
        }
    }
}

struct ZapGlassInsetModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if colorScheme == .light {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(Color.white.opacity(0.32))
                        )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.52), lineWidth: 0.5)
                )
        } else {
            content.background(ZapColor.surface2, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

extension View {
    func zapGlassPanel(cornerRadius: CGFloat = 12) -> some View {
        modifier(ZapGlassPanelModifier(cornerRadius: cornerRadius))
    }

    func zapGlassSurface() -> some View {
        modifier(ZapGlassSurfaceModifier())
    }

    func zapGlassInset(cornerRadius: CGFloat = 8) -> some View {
        modifier(ZapGlassInsetModifier(cornerRadius: cornerRadius))
    }
}

extension Color {
    static func adaptive(light: String, dark: String) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hexString: isDark ? dark : light)
        })
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}

extension NSColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(srgbRed: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a)/255)
    }
}

// MARK: - Cached Async Image (prevents re-download on scroll)
// Uses NSCache to store decoded images in memory
actor ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSURL, NSImage>()

    init() { cache.countLimit = 300 }

    func image(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }

    func store(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

struct CachedAsyncImage: View {
    let url: URL?
    var contentMode: ContentMode = .fit

    @State private var image: NSImage?
    @State private var loading = false

    var body: some View {
        Group {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle()
                    .fill(ZapColor.surface2)
                    .overlay(
                        loading ? AnyView(ProgressView().scaleEffect(0.5).tint(ZapColor.textTertiary))
                                : AnyView(Image(systemName: "photo").foregroundColor(ZapColor.textTertiary))
                    )
            }
        }
        .task(id: url?.absoluteString) {
            await load()
        }
    }

    private func load() async {
        guard let url else { return }
        // Check cache first
        if let cached = await ImageCache.shared.image(for: url) {
            image = cached; return
        }
        loading = true
        defer { loading = false }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let nsImg = NSImage(data: data) else { return }
        await ImageCache.shared.store(nsImg, for: url)
        image = nsImg
    }
}

// MARK: - Reusable UI Components

struct ZapGradientText: View {
    let text: String
    let font: Font
    var body: some View {
        Text(text).font(font).foregroundStyle(ZapColor.accent)
    }
}

struct ZapPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 13, weight: .semibold)) }
                Text(title).font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20).padding(.vertical, 9)
            .background(ZapColor.accent, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct ZapCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .zapGlassPanel(cornerRadius: 12)
    }
}

struct LiveBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(ZapColor.live).frame(width: 5, height: 5)
            Text("LIVE").font(.system(size: 9, weight: .black)).foregroundColor(ZapColor.live)
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(ZapColor.live.opacity(0.15), in: Capsule())
    }
}
