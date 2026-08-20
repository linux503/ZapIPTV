import Foundation
import AVKit
import SwiftUI

@MainActor
class PlayerEngine: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var isMuted = false
    @Published var volume: Float = 1.0
    /// Not @Published — updating every second was invalidating Live/Sports entire UI trees.
    var currentTime: Double = 0
    var duration: Double = 0
    @Published var isBuffering = false
    @Published var error: Error?
    @Published var rate: Float = 1.0

    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    private var keepUpObserver: NSKeyValueObservation?
    private var bufferEmptyObserver: NSKeyValueObservation?
    private var stallObserver: NSObjectProtocol?
    private var failedObserver: NSObjectProtocol?
    private var loadSeq = 0
    /// User tapped pause — do not auto-resume on buffer recovery.
    private var userPaused = false
    private var connectTimeoutTask: Task<Void, Never>?

    /// Dead / geo-blocked live feeds often never fail — abandon after this.
    private let connectTimeoutSeconds: Double = 12

    func load(url: URL, startAt position: Double = 0, connectTimeout: Double? = nil) {
        cleanup()
        loadSeq += 1
        userPaused = false
        error = nil
        setBuffering(true)
        startPlayback(url: url, startAt: position)
        scheduleConnectTimeout(seq: loadSeq, seconds: connectTimeout ?? connectTimeoutSeconds)
    }

    private func setPlaying(_ value: Bool) {
        if isPlaying != value { isPlaying = value }
    }

    private func setBuffering(_ value: Bool) {
        if isBuffering != value { isBuffering = value }
    }

    private func scheduleConnectTimeout(seq: Int, seconds: Double) {
        connectTimeoutTask?.cancel()
        connectTimeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled, loadSeq == seq else { return }
            let rate = player?.rate ?? 0
            let keepUp = player?.currentItem?.isPlaybackLikelyToKeepUp == true
            let status = player?.currentItem?.status
            if status == .failed { return }
            // Still not actually playing after timeout → treat as unreachable
            if rate == 0 || (!keepUp && isBuffering) {
                error = PlaybackError.unreachable
                setBuffering(false)
                setPlaying(false)
                player?.pause()
            }
        }
    }

    private func startPlayback(url: URL, startAt position: Double) {
        let seq = loadSeq
        let headers = StreamProbe.httpHeaders(for: url)
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let item = AVPlayerItem(asset: asset)
        let liveHint = Self.looksLikeLive(url)
        // Live IPTV: start immediately; long stall-wait often means forever "connecting"
        item.preferredForwardBufferDuration = liveHint ? 2 : 8
        item.canUseNetworkResourcesForLiveStreamingWhilePaused = true

        let p = AVPlayer(playerItem: item)
        p.automaticallyWaitsToMinimizeStalling = !liveHint
        p.volume = volume
        p.isMuted = isMuted
        player = p

        if position > 0 {
            p.seek(to: CMTime(seconds: position, preferredTimescale: 600))
        }

        // Progress only — do not publish (Live/Sports observe this engine via EnvironmentObject)
        timeObserver = p.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            guard let self, self.loadSeq == seq else { return }
            self.currentTime = time.seconds
            if let dur = p.currentItem?.duration.seconds, dur.isFinite {
                self.duration = dur
            }
        }

        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self, self.loadSeq == seq else { return }
                switch item.status {
                case .readyToPlay:
                    self.setBuffering(!item.isPlaybackLikelyToKeepUp)
                    self.resumeIfNeeded()
                case .failed:
                    self.error = item.error ?? PlaybackError.unreachable
                    self.setPlaying(false)
                    self.setBuffering(false)
                default:
                    self.setBuffering(true)
                }
            }
        }

        rateObserver = p.observe(\.rate, options: [.new]) { [weak self] p, _ in
            Task { @MainActor in
                guard let self, self.loadSeq == seq else { return }
                self.setPlaying(p.rate > 0)
                if p.rate > 0 {
                    self.setBuffering(false)
                    self.connectTimeoutTask?.cancel()
                } else if !self.userPaused && self.error == nil {
                    self.setBuffering(true)
                }
            }
        }

        keepUpObserver = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self, self.loadSeq == seq else { return }
                if item.isPlaybackLikelyToKeepUp {
                    self.setBuffering(false)
                    self.resumeIfNeeded()
                } else if !self.userPaused {
                    self.setBuffering(true)
                }
            }
        }

        bufferEmptyObserver = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self, self.loadSeq == seq else { return }
                if item.isPlaybackBufferEmpty && !self.userPaused {
                    self.setBuffering(true)
                }
            }
        }

        stallObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.loadSeq == seq else { return }
            self.setBuffering(true)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard self.loadSeq == seq else { return }
                self.resumeIfNeeded()
            }
        }

        failedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] note in
            guard let self, self.loadSeq == seq else { return }
            self.error = (note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)
                ?? PlaybackError.unreachable
            self.setBuffering(false)
            self.setPlaying(false)
        }

        p.play()
        setPlaying(true)
    }

    private static func looksLikeLive(_ url: URL) -> Bool {
        let u = url.absoluteString.lowercased()
        if u.contains(".m3u8") || u.contains("/live") || u.contains("livestream") { return true }
        let ext = url.pathExtension.lowercased()
        return ext == "ts" || ext == "m3u8" || ext.isEmpty
    }

    private func resumeIfNeeded() {
        guard !userPaused, error == nil, let p = player else { return }
        guard let item = p.currentItem, item.status == .readyToPlay else { return }
        if item.isPlaybackBufferEmpty && !item.isPlaybackLikelyToKeepUp { return }
        if p.rate == 0 {
            p.play()
        }
    }

    func play() {
        userPaused = false
        player?.play()
        setPlaying(true)
    }

    func pause() {
        userPaused = true
        player?.pause()
        setPlaying(false)
        setBuffering(false)
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func seek(to seconds: Double) {
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    func seekRelative(_ delta: Double) {
        let target = max(0, currentTime + delta)
        seek(to: target)
    }

    func setVolume(_ v: Float) {
        volume = v
        player?.volume = v
    }

    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }

    func setRate(_ r: Float) {
        rate = r
        player?.rate = r
    }

    func stop() {
        loadSeq += 1
        userPaused = true
        connectTimeoutTask?.cancel()
        player?.pause()
        setPlaying(false)
        player = nil
    }

    private func cleanup() {
        connectTimeoutTask?.cancel()
        connectTimeoutTask = nil
        if let obs = timeObserver, let p = player {
            p.removeTimeObserver(obs)
        }
        if let stallObserver {
            NotificationCenter.default.removeObserver(stallObserver)
        }
        if let failedObserver {
            NotificationCenter.default.removeObserver(failedObserver)
        }
        statusObserver?.invalidate()
        rateObserver?.invalidate()
        keepUpObserver?.invalidate()
        bufferEmptyObserver?.invalidate()
        player?.pause()
        player = nil
        timeObserver = nil
        stallObserver = nil
        failedObserver = nil
        statusObserver = nil
        rateObserver = nil
        keepUpObserver = nil
        bufferEmptyObserver = nil
        currentTime = 0
        duration = 0
        setBuffering(false)
        error = nil
    }
}
