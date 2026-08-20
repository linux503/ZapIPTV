import Foundation
import AVKit
import SwiftUI

@MainActor
class PlayerEngine: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var isMuted = false
    @Published var volume: Float = 1.0
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isBuffering = false
    @Published var error: Error?
    @Published var rate: Float = 1.0

    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    private var keepUpObserver: NSKeyValueObservation?
    private var bufferEmptyObserver: NSKeyValueObservation?
    private var stallObserver: NSObjectProtocol?
    private var loadSeq = 0
    /// User tapped pause — do not auto-resume on buffer recovery.
    private var userPaused = false

    func load(url: URL, startAt position: Double = 0) {
        cleanup()
        loadSeq += 1
        userPaused = false
        isBuffering = true
        startPlayback(url: url, startAt: position)
    }

    private func startPlayback(url: URL, startAt position: Double) {
        let seq = loadSeq
        let headers = StreamProbe.httpHeaders(for: url)
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 8
        item.canUseNetworkResourcesForLiveStreamingWhilePaused = true

        let p = AVPlayer(playerItem: item)
        // Must stay true: otherwise a live stall sets rate=0 and never starts again.
        p.automaticallyWaitsToMinimizeStalling = true
        p.volume = volume
        p.isMuted = isMuted
        player = p

        if position > 0 {
            p.seek(to: CMTime(seconds: position, preferredTimescale: 600))
        }

        timeObserver = p.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            DispatchQueue.main.async {
                guard let self, self.loadSeq == seq else { return }
                self.currentTime = time.seconds
                if let dur = p.currentItem?.duration.seconds, dur.isFinite {
                    self.duration = dur
                }
            }
        }

        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self, self.loadSeq == seq else { return }
                switch item.status {
                case .readyToPlay:
                    self.isBuffering = !item.isPlaybackLikelyToKeepUp
                    self.resumeIfNeeded()
                case .failed:
                    self.error = item.error ?? PlaybackError.unreachable
                    self.isPlaying = false
                    self.isBuffering = false
                default:
                    self.isBuffering = true
                }
            }
        }

        rateObserver = p.observe(\.rate, options: [.new]) { [weak self] p, _ in
            DispatchQueue.main.async {
                guard let self, self.loadSeq == seq else { return }
                self.isPlaying = p.rate > 0
                if p.rate == 0 && !self.userPaused && self.error == nil {
                    self.isBuffering = true
                }
            }
        }

        keepUpObserver = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self, self.loadSeq == seq else { return }
                if item.isPlaybackLikelyToKeepUp {
                    self.isBuffering = false
                    self.resumeIfNeeded()
                } else if !self.userPaused {
                    self.isBuffering = true
                }
            }
        }

        bufferEmptyObserver = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self, self.loadSeq == seq else { return }
                if item.isPlaybackBufferEmpty && !self.userPaused {
                    self.isBuffering = true
                }
            }
        }

        stallObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.loadSeq == seq else { return }
            self.isBuffering = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                guard self.loadSeq == seq else { return }
                self.resumeIfNeeded()
            }
        }

        p.play()
        isPlaying = true
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
        isPlaying = true
    }

    func pause() {
        userPaused = true
        player?.pause()
        isPlaying = false
        isBuffering = false
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
        player?.pause()
        isPlaying = false
        player = nil
    }

    private func cleanup() {
        if let obs = timeObserver, let p = player {
            p.removeTimeObserver(obs)
        }
        if let stallObserver {
            NotificationCenter.default.removeObserver(stallObserver)
        }
        statusObserver?.invalidate()
        rateObserver?.invalidate()
        keepUpObserver?.invalidate()
        bufferEmptyObserver?.invalidate()
        player?.pause()
        player = nil
        timeObserver = nil
        stallObserver = nil
        statusObserver = nil
        rateObserver = nil
        keepUpObserver = nil
        bufferEmptyObserver = nil
        currentTime = 0
        duration = 0
        isBuffering = false
        error = nil
    }
}
