import Foundation
import AVFoundation
import MediaPlayer
import Combine

public final class AudioPlayerService: NSObject, ObservableObject {
    public static let shared = AudioPlayerService()

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private let cacheManager = RollingCacheManager.shared

    @Published public private(set) var currentTrack: Track?
    @Published public private(set) var isPlaying: Bool = false
    @Published public var currentTime: Double = 0
    @Published public var duration: Double = 0
    @Published public var playlist: [Track] = []
    @Published public var currentIndex: Int = 0

    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
        setupNotifications()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("[XosonicLite] AudioSession error: \(error.localizedDescription)")
        }
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self, let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: positionEvent.positionTime)
            return .success
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began {
            pause()
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resume()
                }
            }
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        // Automatically pause when headphones or bluetooth are unplugged/disconnected
        if reason == .oldDeviceUnavailable {
            pause()
        }
    }

    public func playTrack(_ track: Track, in queue: [Track] = []) {
        self.currentTrack = track
        if !queue.isEmpty {
            self.playlist = queue
            if let idx = queue.firstIndex(where: { $0.id == track.id }) {
                self.currentIndex = idx
            }
        }

        // 1. Check local 3-song rolling cache
        let playUrl: URL
        if let cachedUrl = cacheManager.localCachedFile(for: track.id) {
            playUrl = cachedUrl
            print("[XosonicLite] Playing from local rolling cache: \(track.id)")
        } else if let stream = track.streamUrl, let remoteUrl = URL(string: stream) {
            playUrl = remoteUrl
            print("[XosonicLite] Streaming remote track: \(track.id)")
            // Asynchronously download to 3-song rolling cache in background
            downloadSongToRollingCache(track: track, from: remoteUrl)
        } else {
            print("[XosonicLite] No stream URL available for track: \(track.title)")
            return
        }

        cleanUpPlayer()
        let playerItem = AVPlayerItem(url: playUrl)
        player = AVPlayer(playerItem: playerItem)

        // Observe duration
        if track.durationSeconds > 0 {
            self.duration = track.durationSeconds
        }

        // Periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let currentItem = self.player?.currentItem, currentItem.duration.isValid && currentItem.duration.seconds > 0 {
                self.duration = currentItem.duration.seconds
            }
            self.updateNowPlayingInfo()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        player?.play()
        isPlaying = true
        updateNowPlayingInfo()

        // Record to local privacy history
        HistoryManager.shared.recordPlay(track: track)
    }

    private func downloadSongToRollingCache(track: Track, from url: URL) {
        URLSession.shared.downloadTask(with: url) { [weak self] tempUrl, _, error in
            guard let tempUrl = tempUrl, error == nil else { return }
            _ = self?.cacheManager.saveSongToCache(songId: track.id, tempFileUrl: tempUrl)
        }.resume()
    }

    @objc private func itemDidFinishPlaying() {
        playNext()
    }

    public func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    public func resume() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    public func playNext() {
        guard !playlist.isEmpty else { return }
        let nextIndex = (currentIndex + 1) % playlist.count
        currentIndex = nextIndex
        playTrack(playlist[nextIndex], in: playlist)
    }

    public func playPrevious() {
        guard !playlist.isEmpty else { return }
        let prevIndex = (currentIndex - 1 + playlist.count) % playlist.count
        currentIndex = prevIndex
        playTrack(playlist[prevIndex], in: playlist)
    }

    public func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time)
    }

    private func cleanUpPlayer() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        player?.pause()
        player = nil
    }

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    deinit {
        cleanUpPlayer()
    }
}
