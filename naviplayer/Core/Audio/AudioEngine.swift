//
//  AudioEngine.swift
//  naviplayer
//
//  Core audio playback engine using AVQueuePlayer for gapless playback
//

import AVFoundation
import Combine
import MediaPlayer

// MARK: - Audio Engine
@MainActor
final class AudioEngine: ObservableObject {
    // MARK: - Published State
    @Published private(set) var currentTrack: Track?
    @Published private(set) var playbackState: PlaybackState = .stopped
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var progress: Double = 0
    @Published private(set) var isBuffering = false

    // MARK: - Queue State
    @Published private(set) var queue: [Track] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var shuffleEnabled = false
    @Published private(set) var repeatMode: RepeatMode = .off

    enum RepeatMode {
        case off
        case all
        case one
    }

    // MARK: - Private Properties
    private var player: AVQueuePlayer?
    private var playerItems: [String: AVPlayerItem] = [:] // Track ID -> PlayerItem
    private var timeObserver: Any?
    private var itemObservers: Set<AnyCancellable> = []
    private var preloadTasks: [String: Task<Void, Never>] = [:]

    private let client = SubsonicClient.shared
    private let nowPlayingManager = NowPlayingManager()

    // Pre-cache settings
    private let preloadCount = 3

    // MARK: - Singleton
    static let shared = AudioEngine()

    private init() {
        setupAudioSession()
        setupRemoteCommands()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Remote Command Setup

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.play()
            }
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.pause()
            }
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.togglePlayPause()
            }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                await self?.next()
            }
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                await self?.previous()
            }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in
                self?.seek(to: event.positionTime)
            }
            return .success
        }
    }

    // MARK: - Queue Management

    /// Set queue and start playback
    func setQueue(_ tracks: [Track], startIndex: Int = 0) async {
        guard !tracks.isEmpty else { return }

        // Clear existing
        stop()
        clearPreloads()

        queue = tracks
        currentIndex = min(startIndex, tracks.count - 1)

        // Create player
        player = AVQueuePlayer()
        player?.actionAtItemEnd = .advance

        // Setup time observer
        setupTimeObserver()

        // Load current and preload upcoming
        await loadCurrentTrack()
        preloadUpcomingTracks()
    }

    /// Add tracks to end of queue
    func addToQueue(_ tracks: [Track]) {
        queue.append(contentsOf: tracks)
        preloadUpcomingTracks()
    }

    /// Insert tracks after current
    func insertNext(_ tracks: [Track]) {
        let insertIndex = currentIndex + 1
        queue.insert(contentsOf: tracks, at: min(insertIndex, queue.count))
        preloadUpcomingTracks()
    }

    /// Remove track from queue
    func removeFromQueue(at index: Int) {
        guard index >= 0 && index < queue.count else { return }

        // Don't remove currently playing
        if index == currentIndex {
            return
        }

        queue.remove(at: index)

        // Adjust current index if needed
        if index < currentIndex {
            currentIndex -= 1
        }
    }

    /// Clear queue
    func clearQueue() {
        stop()
        queue = []
        currentIndex = 0
        clearPreloads()
    }

    // MARK: - Playback Control

    func play() {
        guard player != nil else { return }
        player?.play()
        playbackState = .playing
        nowPlayingManager.updatePlaybackState(isPlaying: true)
    }

    func pause() {
        player?.pause()
        playbackState = .paused
        nowPlayingManager.updatePlaybackState(isPlaying: false)
    }

    func togglePlayPause() {
        if playbackState == .playing {
            pause()
        } else {
            play()
        }
    }

    func stop() {
        player?.pause()
        player?.removeAllItems()
        player = nil
        removeTimeObserver()
        playbackState = .stopped
        currentTime = 0
        progress = 0
        nowPlayingManager.clear()
    }

    func next() async {
        guard !queue.isEmpty else { return }

        let nextIndex: Int
        if repeatMode == .one {
            // Repeat same track
            nextIndex = currentIndex
        } else if currentIndex < queue.count - 1 {
            nextIndex = currentIndex + 1
        } else if repeatMode == .all {
            nextIndex = 0
        } else {
            // End of queue
            stop()
            return
        }

        currentIndex = nextIndex
        await loadCurrentTrack()
        play()
        preloadUpcomingTracks()
    }

    func previous() async {
        guard !queue.isEmpty else { return }

        // If more than 3 seconds in, restart current track
        if currentTime > 3 {
            seek(to: 0)
            return
        }

        let prevIndex: Int
        if currentIndex > 0 {
            prevIndex = currentIndex - 1
        } else if repeatMode == .all {
            prevIndex = queue.count - 1
        } else {
            // Beginning of queue, restart
            seek(to: 0)
            return
        }

        currentIndex = prevIndex
        await loadCurrentTrack()
        play()
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
        if duration > 0 {
            progress = time / duration
        }
        nowPlayingManager.updateProgress(currentTime: time, duration: duration)
    }

    func skipTo(index: Int) async {
        guard index >= 0 && index < queue.count else { return }
        currentIndex = index
        await loadCurrentTrack()
        play()
        preloadUpcomingTracks()
    }

    // MARK: - Shuffle & Repeat

    func toggleShuffle() {
        shuffleEnabled.toggle()

        if shuffleEnabled {
            // Shuffle remaining tracks (keep current track position)
            let currentTrack = queue[currentIndex]
            var remaining = queue
            remaining.remove(at: currentIndex)
            remaining.shuffle()
            queue = [currentTrack] + remaining
            currentIndex = 0
        }
        // Note: Unshuffle would need original order storage
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }

    // MARK: - Track Loading

    private func loadCurrentTrack() async {
        guard currentIndex < queue.count else { return }

        let track = queue[currentIndex]
        currentTrack = track
        duration = track.durationInterval
        currentTime = 0
        progress = 0
        isBuffering = true

        // Get or create player item
        let playerItem: AVPlayerItem
        if let cached = playerItems[track.id] {
            playerItem = cached
        } else {
            guard let url = client.streamURL(for: track) else {
                print("Failed to get stream URL for track: \(track.id)")
                isBuffering = false
                return
            }

            let asset = AVURLAsset(url: url)
            playerItem = AVPlayerItem(asset: asset)
            playerItems[track.id] = playerItem
        }

        // Setup item observer
        observePlayerItem(playerItem, for: track)

        // Replace current item
        player?.removeAllItems()
        player?.insert(playerItem, after: nil)

        // Update now playing
        await updateNowPlaying(for: track)

        isBuffering = false
    }

    private func observePlayerItem(_ item: AVPlayerItem, for track: Track) {
        // Clear old observers
        itemObservers.removeAll()

        // Observe status
        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.isBuffering = false
                case .failed:
                    print("Player item failed: \(item.error?.localizedDescription ?? "unknown")")
                    self?.isBuffering = false
                default:
                    break
                }
            }
            .store(in: &itemObservers)

        // Observe playback buffer
        item.publisher(for: \.isPlaybackBufferEmpty)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEmpty in
                self?.isBuffering = isEmpty
            }
            .store(in: &itemObservers)

        // Observe when item finishes
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleTrackFinished(track)
                }
            }
            .store(in: &itemObservers)
    }

    private func handleTrackFinished(_ track: Track) async {
        // Scrobble
        Task {
            try? await client.scrobble(id: track.id)
        }

        // Play next
        await next()
    }

    // MARK: - Pre-caching

    private func preloadUpcomingTracks() {
        // Cancel old preload tasks
        clearPreloads()

        // Preload next N tracks
        for i in 1...preloadCount {
            let nextIndex = currentIndex + i
            guard nextIndex < queue.count else { break }

            let track = queue[nextIndex]

            // Skip if already cached
            if playerItems[track.id] != nil { continue }

            let task = Task { [weak self] in
                guard let self = self else { return }
                await self.preloadTrack(track)
            }
            preloadTasks[track.id] = task
        }
    }

    private func preloadTrack(_ track: Track) async {
        guard let url = client.streamURL(for: track) else { return }

        let asset = AVURLAsset(url: url)

        // Load asset asynchronously
        do {
            _ = try await asset.load(.isPlayable, .duration)

            // Only cache if still in queue and not cancelled
            if queue.contains(where: { $0.id == track.id }) && !Task.isCancelled {
                let item = AVPlayerItem(asset: asset)
                playerItems[track.id] = item
            }
        } catch {
            print("Failed to preload track \(track.id): \(error)")
        }
    }

    private func clearPreloads() {
        preloadTasks.values.forEach { $0.cancel() }
        preloadTasks.removeAll()

        // Keep only current track's item
        if let currentId = currentTrack?.id {
            let currentItem = playerItems[currentId]
            playerItems.removeAll()
            if let item = currentItem {
                playerItems[currentId] = item
            }
        } else {
            playerItems.removeAll()
        }
    }

    // MARK: - Time Observer

    private func setupTimeObserver() {
        removeTimeObserver()

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.currentTime = time.seconds
                if self.duration > 0 {
                    self.progress = time.seconds / self.duration
                }

                // Update now playing less frequently
                if Int(time.seconds) % 5 == 0 {
                    self.nowPlayingManager.updateProgress(
                        currentTime: self.currentTime,
                        duration: self.duration
                    )
                }
            }
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    // MARK: - Now Playing

    private func updateNowPlaying(for track: Track) async {
        // Load artwork
        var artwork: UIImage?
        if let url = client.coverArtURL(for: track.coverArt, size: 600) {
            artwork = await loadImage(from: url)
        }

        nowPlayingManager.update(
            track: track,
            artwork: artwork,
            duration: duration,
            currentTime: currentTime,
            isPlaying: playbackState == .playing
        )
    }

    private func loadImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Convenience Extensions

extension AudioEngine {
    /// Current track's cover art URL
    var coverArtURL: URL? {
        client.coverArtURL(for: currentTrack?.coverArt, size: 600)
    }

    /// Whether there's a next track
    var hasNext: Bool {
        currentIndex < queue.count - 1 || repeatMode == .all
    }

    /// Whether there's a previous track
    var hasPrevious: Bool {
        currentIndex > 0 || repeatMode == .all || currentTime > 3
    }

    /// Upcoming tracks (not including current)
    var upcomingTracks: [Track] {
        guard currentIndex + 1 < queue.count else { return [] }
        return Array(queue[(currentIndex + 1)...])
    }
}
