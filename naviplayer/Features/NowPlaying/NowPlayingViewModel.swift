//
//  NowPlayingViewModel.swift
//  naviplayer
//
//  ViewModel for the Now Playing screen - wraps AudioEngine
//

import SwiftUI
import Combine

@MainActor
final class NowPlayingViewModel: ObservableObject {
    // MARK: - Published Properties (forwarded from AudioEngine)
    @Published var currentTrack: Track?
    @Published var playbackState: PlaybackState = .stopped
    @Published var progress: Double = 0
    @Published var duration: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0
    @Published var lyrics: StructuredLyrics?
    @Published var isLoved: Bool = false
    @Published var isBuffering: Bool = false

    // Shuffle & Repeat
    @Published var shuffleEnabled: Bool = false
    @Published var repeatMode: AudioEngine.RepeatMode = .off

    // MARK: - Dependencies
    private let audioEngine = AudioEngine.shared
    private let client = SubsonicClient.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var coverArtURL: URL? {
        audioEngine.coverArtURL
    }

    var artistImageURL: URL? {
        guard let artistId = currentTrack?.artistId else { return nil }
        return client.coverArtURL(for: artistId, size: 400)
    }

    var hasNext: Bool {
        audioEngine.hasNext
    }

    var hasPrevious: Bool {
        audioEngine.hasPrevious
    }

    // MARK: - Initialization

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Forward audio engine state
        audioEngine.$currentTrack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] track in
                self?.currentTrack = track
                self?.isLoved = track?.isStarred ?? false
                // Load lyrics when track changes
                if track != nil {
                    Task { [weak self] in
                        await self?.loadLyrics()
                    }
                }
            }
            .store(in: &cancellables)

        audioEngine.$playbackState
            .receive(on: DispatchQueue.main)
            .assign(to: &$playbackState)

        audioEngine.$progress
            .receive(on: DispatchQueue.main)
            .assign(to: &$progress)

        audioEngine.$duration
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)

        audioEngine.$currentTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentTime)

        audioEngine.$isBuffering
            .receive(on: DispatchQueue.main)
            .assign(to: &$isBuffering)

        audioEngine.$shuffleEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: &$shuffleEnabled)

        audioEngine.$repeatMode
            .receive(on: DispatchQueue.main)
            .assign(to: &$repeatMode)
    }

    // MARK: - Playback Control

    func togglePlayPause() {
        audioEngine.togglePlayPause()
    }

    func previous() {
        Task {
            await audioEngine.previous()
        }
    }

    func next() {
        Task {
            await audioEngine.next()
        }
    }

    func seek(to time: TimeInterval) {
        audioEngine.seek(to: time)
    }

    func toggleShuffle() {
        audioEngine.toggleShuffle()
    }

    func cycleRepeatMode() {
        audioEngine.cycleRepeatMode()
    }

    // MARK: - Rating Actions

    func toggleLove() async {
        guard let track = currentTrack else { return }

        do {
            if isLoved {
                try await client.unstar(id: track.id)
            } else {
                try await client.star(id: track.id)
            }
            isLoved.toggle()
        } catch {
            print("Failed to toggle love: \(error)")
        }
    }

    func rate(_ rating: Int) async {
        guard let track = currentTrack else { return }

        do {
            try await client.setRating(id: track.id, rating: rating)
        } catch {
            print("Failed to rate: \(error)")
        }
    }

    // MARK: - Lyrics

    func loadLyrics() async {
        guard let track = currentTrack else {
            lyrics = nil
            return
        }

        do {
            lyrics = try await client.getLyrics(songId: track.id)
        } catch {
            print("Failed to load lyrics: \(error)")
            lyrics = nil
        }
    }
}
