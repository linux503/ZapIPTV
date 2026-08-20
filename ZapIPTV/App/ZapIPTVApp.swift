import SwiftUI
import SwiftData

@main
struct ZapIPTVApp: App {
    @StateObject private var sourceManager = SourceManager()
    @StateObject private var playerEngine  = PlayerEngine()
    @StateObject private var playbackRouter = PlaybackRouter()

    // SwiftData container — recreate on schema errors (dev builds)
    let container: ModelContainer = {
        let schema = Schema([
            PlaylistSource.self,
            ChannelEntity.self,
            MovieEntity.self,
            SeriesEntity.self,
            WatchHistoryEntry.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema migration failed — wipe and recreate
            try? FileManager.default.removeItem(at: config.url)
            return (try? ModelContainer(for: schema, configurations: [config]))
                ?? { fatalError("Cannot create ModelContainer") }()
        }
    }()

    var body: some Scene {
        Window("ZapIPTV", id: "main") {
            AppRoot()
                .environmentObject(sourceManager)
                .environmentObject(playerEngine)
                .environmentObject(playbackRouter)
                .environmentObject(LanguageManager.shared)
                .environmentObject(UpdateChecker.shared)
                .environmentObject(ThemeManager.shared)
                .modelContainer(container)
                .background(WindowFSConfigurator(scheme: ThemeManager.shared.theme.scheme))
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(LanguageManager.shared.t("tab.settings")) {
                    NotificationCenter.default.post(name: .zapOpenSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(replacing: .newItem) {}
        }
    }
}

// AppRoot reads modelContext (guaranteed available as child of .modelContainer)
struct AppRoot: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sourceManager: SourceManager
    @EnvironmentObject private var updater: UpdateChecker
    @EnvironmentObject private var theme: ThemeManager
    @State private var ready = false

    var body: some View {
        Group {
            if ready {
                ContentView()
            } else {
                SplashView()
            }
        }
        .preferredColorScheme(theme.theme.scheme)
        .background(WindowFSConfigurator(scheme: theme.theme.scheme))
        .onAppear {
            guard !ready else { return }
            // Setup DB context + seed sources, then immediately show UI
            // Sources load concurrently in background after UI is visible
            Task { @MainActor in
                sourceManager.setupContext(context: modelContext)
                await sourceManager.ensureAsianCatalog()
                withAnimation(.easeInOut(duration: 0.4)) { ready = true }
                Task { await sourceManager.refreshAll() }
                Task { await updater.check(silent: true) }
            }
        }
    }
}

struct SplashView: View {
    @State private var pulse = false
    @EnvironmentObject private var loc: LanguageManager

    var body: some View {
        ZStack {
            ZapBackdrop()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(ZapColor.accentStart.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulse ? 1.15 : 1)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                                   value: pulse)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(ZapColor.accent)
                        .frame(width: 72, height: 72)
                    Text("Z")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                VStack(spacing: 6) {
                    Text("ZapIPTV")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(ZapColor.textPrimary)
                    Text(loc.t("tagline"))
                        .font(.system(size: 13))
                        .foregroundColor(ZapColor.textSecondary)
                        .multilineTextAlignment(.center)
                    Text(loc.t("splash.loading"))
                        .font(.system(size: 13))
                        .foregroundColor(ZapColor.textTertiary)
                }
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(ZapColor.accentEnd)
                    .scaleEffect(1.1)
            }
        }
        .onAppear { pulse = true }
    }
}
