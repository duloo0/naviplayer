//
//  LibraryRadioView.swift
//  naviplayer
//
//  Library Radio view with smart weighted playback and thumb controls
//

import SwiftUI
import Combine

// MARK: - Decade Preset Model
struct DecadePreset: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let fromYear: Int
    let toYear: Int

    static let presets: [DecadePreset] = [
        DecadePreset(label: "2020s", icon: "sparkles", fromYear: 2020, toYear: 2029),
        DecadePreset(label: "2010s", icon: "waveform", fromYear: 2010, toYear: 2019),
        DecadePreset(label: "2000s", icon: "music.note", fromYear: 2000, toYear: 2009),
        DecadePreset(label: "90s", icon: "guitars", fromYear: 1990, toYear: 1999),
        DecadePreset(label: "80s", icon: "pianokeys", fromYear: 1980, toYear: 1989),
        DecadePreset(label: "70s", icon: "music.mic", fromYear: 1970, toYear: 1979),
        DecadePreset(label: "60s & older", icon: "record.circle", fromYear: 1900, toYear: 1969),
    ]
}

struct LibraryRadioView: View {
    @StateObject private var viewModel: LibraryRadioViewModel

    /// Optional label for decade radio (e.g., "90s Radio")
    let radioLabel: String?

    init(fromYear: Int? = nil, toYear: Int? = nil, radioLabel: String? = nil) {
        self.radioLabel = radioLabel
        _viewModel = StateObject(wrappedValue: LibraryRadioViewModel(
            fromYear: fromYear,
            toYear: toYear
        ))
    }

    var body: some View {
        ZStack {
            // Background
            Color.Background.default
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.currentTrack == nil {
                loadingView
            } else if let track = viewModel.currentTrack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Current track card
                        currentTrackSection(track: track)
                            .padding(.top, Spacing.lg)

                        // Large thumb buttons
                        LargeThumbButtons(track: track) { rating in
                            await viewModel.rate(rating)
                        }
                        .padding(.top, Spacing.xl2)

                        // Playback controls
                        PlaybackControls(
                            state: viewModel.playbackState,
                            onPrevious: viewModel.previous,
                            onPlayPause: viewModel.togglePlayPause,
                            onNext: viewModel.next
                        )
                        .padding(.top, Spacing.xl)

                        // Up next
                        if !viewModel.upNext.isEmpty {
                            upNextSection
                                .padding(.top, Spacing.xl2)
                        }

                        // Filters
                        filtersSection
                            .padding(.top, Spacing.xl2)

                        // Extra space for mini player + tab bar
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, Spacing.Page.horizontal)
                    .padding(.bottom, Spacing.lg)
                }
            } else {
                emptyView
            }
        }
        .navigationTitle(radioLabel ?? "Library Radio")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadRadio()
        }
        .refreshable {
            await viewModel.loadRadio()
        }
    }

    // MARK: - Current Track Section
    private func currentTrackSection(track: Track) -> some View {
        VStack(spacing: Spacing.lg) {
            // Large artwork
            AsyncArtwork(
                url: SubsonicClient.shared.coverArtURL(for: track.coverArt, size: 600),
                size: 280,
                cornerRadius: CornerRadius.lg
            )

            // Track info
            VStack(spacing: Spacing.xs) {
                Text(track.title)
                    .font(.Navi.headlineSmall)
                    .foregroundColor(Color.Text.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(track.effectiveArtist)
                    .font(.Navi.bodyMedium)
                    .foregroundColor(Color.Text.secondary)

                // Quality badge
                QualityBadge(track: track, showSpecs: true)
                    .padding(.top, Spacing.xs)
            }
        }
    }

    // MARK: - Up Next Section
    private var upNextSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("UP NEXT")
                .font(.Navi.captionSmall)
                .foregroundColor(Color.Text.tertiary)
                .tracking(1)

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.upNext.prefix(5)) { track in
                    upNextRow(track: track)
                }
            }
        }
    }

    private func upNextRow(track: Track) -> some View {
        HStack(spacing: Spacing.md) {
            MiniArtwork(
                url: SubsonicClient.shared.coverArtURL(for: track.coverArt, size: 100),
                size: 44
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.Navi.bodyMedium)
                    .foregroundColor(Color.Text.primary)
                    .lineLimit(1)

                Text(track.effectiveArtist)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Quality tier badge
            QualityTierBadge(track: track)
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Filters Section
    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("FILTERS")
                .font(.Navi.captionSmall)
                .foregroundColor(Color.Text.tertiary)
                .tracking(1)

            // Genre filter
            HStack {
                Text("Genre")
                    .font(.Navi.bodyMedium)
                    .foregroundColor(Color.Text.secondary)

                Spacer()

                Menu {
                    Button("All Genres") {
                        viewModel.selectedGenre = nil
                    }
                    // Add genre options here
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text(viewModel.selectedGenre ?? "All")
                            .font(.Navi.bodyMedium)
                            .foregroundColor(Color.Text.primary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(Color.Text.tertiary)
                    }
                }
            }
            .padding(.vertical, Spacing.sm)

            // Year range
            HStack {
                Text("Year")
                    .font(.Navi.bodyMedium)
                    .foregroundColor(Color.Text.secondary)

                Spacer()

                Text("All Years")
                    .font(.Navi.bodyMedium)
                    .foregroundColor(Color.Text.primary)
            }
            .padding(.vertical, Spacing.sm)
        }
        .padding(Spacing.md)
        .background(Color.Background.paper)
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.Accent.cyan))
                .scaleEffect(1.2)

            Text("Loading radio...")
                .font(.Navi.bodyMedium)
                .foregroundColor(Color.Text.secondary)
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "radio")
                .font(.system(size: 48))
                .foregroundColor(Color.Text.tertiary)

            Text("No tracks available")
                .font(.Navi.bodyMedium)
                .foregroundColor(Color.Text.secondary)

            Button("Refresh") {
                Task {
                    await viewModel.loadRadio()
                }
            }
            .font(.Navi.labelLarge)
            .foregroundColor(Color.Accent.cyan)
        }
    }
}

// MARK: - Library Radio ViewModel
@MainActor
final class LibraryRadioViewModel: ObservableObject {
    @Published var currentTrack: Track?
    @Published var upNext: [Track] = []
    @Published var playbackState: PlaybackState = .stopped
    @Published var isLoading = false
    @Published var selectedGenre: String?
    @Published var fromYear: Int?
    @Published var toYear: Int?

    private let client = SubsonicClient.shared
    private let audioEngine = AudioEngine.shared

    // MARK: - Initialization

    init(fromYear: Int? = nil, toYear: Int? = nil) {
        self.fromYear = fromYear
        self.toYear = toYear
        setupBindings()
    }

    private func setupBindings() {
        // Forward state from audio engine
        audioEngine.$currentTrack
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentTrack)

        audioEngine.$playbackState
            .receive(on: DispatchQueue.main)
            .assign(to: &$playbackState)

        // Map upcoming tracks from queue
        audioEngine.$queue
            .combineLatest(audioEngine.$currentIndex)
            .receive(on: DispatchQueue.main)
            .map { queue, index in
                guard index + 1 < queue.count else { return [] }
                return Array(queue[(index + 1)...])
            }
            .assign(to: &$upNext)
    }

    // MARK: - Load Radio

    func loadRadio() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let songs = try await client.getLibraryRadio(
                count: 50,
                genre: selectedGenre,
                fromYear: fromYear,
                toYear: toYear
            )

            if !songs.isEmpty {
                // Set the queue in the audio engine
                await audioEngine.setQueue(songs)
                audioEngine.play()
            }
        } catch {
            print("Failed to load library radio: \(error)")
        }
    }

    // MARK: - Playback

    func togglePlayPause() {
        audioEngine.togglePlayPause()
    }

    func next() {
        Task {
            await audioEngine.next()

            // Load more tracks if running low
            if upNext.count < 5 {
                await loadMoreTracks()
            }
        }
    }

    func previous() {
        Task {
            await audioEngine.previous()
        }
    }

    private func loadMoreTracks() async {
        do {
            let songs = try await client.getLibraryRadio(
                count: 20,
                genre: selectedGenre,
                fromYear: fromYear,
                toYear: toYear
            )
            audioEngine.addToQueue(songs)
        } catch {
            print("Failed to load more tracks: \(error)")
        }
    }

    // MARK: - Rating

    func rate(_ rating: Int) async {
        guard let track = currentTrack else { return }

        do {
            try await client.setRating(id: track.id, rating: rating)

            // Update local track state immediately for UI feedback
            audioEngine.updateCurrentTrackRating(rating)

            // If thumb down (rating 1), skip to next track
            // Because thumb-down songs are excluded from radio
            if rating == 1 {
                await audioEngine.next()
            }
        } catch {
            print("Failed to rate track: \(error)")
        }
    }
}

// MARK: - Preview
#if DEBUG
struct LibraryRadioView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                LibraryRadioView()
            }

            NavigationStack {
                LibraryRadioView(fromYear: 1990, toYear: 1999, radioLabel: "90s Radio")
            }
        }
    }
}
#endif
