import SwiftUI
import AVKit
import AppKit

// Native player using AVPlayerLayer — AVPlayerView crashes on macOS 26/27
// (EXC_BREAKPOINT inside AVKit SwiftUI Binding when drawing inline controls).
struct VideoPlayerView: View {
    @ObservedObject var engine: PlayerEngine
    var onClose: (() -> Void)?
    @EnvironmentObject private var playback: PlaybackRouter
    @EnvironmentObject private var loc: LanguageManager

    var body: some View {
        ZStack {
            Color.black

            if let player = engine.player {
                PlayerLayerRepresentable(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Image(systemName: "tv.slash")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.3))
            }

            if engine.isBuffering && engine.player != nil {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    .tint(.white)
                    .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { engine.togglePlayPause() }) {
                        Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)

                    Button(action: { engine.toggleMute() }) {
                        Image(systemName: engine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if let onClose {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: toggleFullScreen) {
                        Image(systemName: playback.playerFullScreen
                              ? "arrow.down.right.and.arrow.up.left"
                              : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .help(loc.t("player.fullscreen"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WindowFSConfigurator())
        .onKeyPress(.leftArrow)  { engine.seekRelative(-10); return .handled }
        .onKeyPress(.rightArrow) { engine.seekRelative(10);  return .handled }
        .onKeyPress("m") { engine.toggleMute();               return .handled }
        .onKeyPress("f") { toggleFullScreen(); return .handled }
        .onKeyPress(.escape) {
            guard playback.playerFullScreen else { return .ignored }
            exitFullScreen()
            return .handled
        }
    }

    private func toggleFullScreen() {
        if playback.playerFullScreen {
            exitFullScreen()
        } else {
            enterFullScreen()
        }
    }

    private func enterFullScreen() {
        playback.playerFullScreen = true
        AppWindowFS.enter()
    }

    private func exitFullScreen() {
        playback.playerFullScreen = false
        AppWindowFS.exit()
    }
}

struct PlayerLayerRepresentable: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.player = player
        return view
    }

    func updateNSView(_ view: PlayerContainerView, context: Context) {
        if view.player !== player {
            view.player = player
        }
    }
}

final class PlayerContainerView: NSView {
    var player: AVPlayer? {
        didSet { playerLayer.player = player }
    }

    private let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        playerLayer.videoGravity = .resizeAspect
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        playerLayer.videoGravity = .resizeAspect
        layer?.addSublayer(playerLayer)
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}
