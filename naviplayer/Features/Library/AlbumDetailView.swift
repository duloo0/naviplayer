//
//  AlbumDetailView.swift
//  naviplayer
//
//  Album detail view with track list and playback controls
//

import SwiftUI
import Combine

struct AlbumDetailView: View {
    let albumId: String
    @StateObject private var viewModel: AlbumDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(albumId: String) {
        self.albumId = albumId
        self._viewModel = StateObject(wrappedValue: AlbumDetailViewModel(albumId: albumId))
    }

    var body: some View {
        ZStack {
            Color.Background.default
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.Accent.cyan))
            } else if let album = viewModel.album {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {

                        // Album header
                        albumHeader(album)

                        // Play controls
                        playControls(album)
                            .padding(.top, Spacing.lg)

                        // Track list
                        trackList(album)
                            .padding(.top, Spacing.xl)

                        // Album info
                        if viewModel.albumInfo != nil {
                            albumInfoSection
                                .padding(.top, Spacing.xl)
                        }

                        Spacer(minLength: Spacing.xl3 + 80) // Extra space for mini player
                    }
                }
            } else {
                errorView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Album")
                    .font(.Navi.labelMedium)
                    .foregroundColor(Color.Text.secondary)
            }
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Album Header
    private func albumHeader(_ album: Album) -> some View {
        VStack(spacing: Spacing.lg) {
            // Artwork
            AsyncArtwork(
                url: SubsonicClient.shared.coverArtURL(for: album.coverArt, size: 600),
                size: 240,
                cornerRadius: CornerRadius.md
            )
            .padding(.top, Spacing.lg)

            // Album info
            VStack(spacing: Spacing.xs) {
                Text(album.name)
                    .font(.Navi.headlineSmall)
                    .foregroundColor(Color.Text.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                NavigationLink {
                    if let artistId = album.artistId {
                        ArtistDetailView(artistId: artistId)
                    }
                } label: {
                    Text(album.effectiveArtist)
                        .font(.Navi.bodyMedium)
                        .foregroundColor(Color.Accent.cyan)
                }

                // Metadata row
                HStack(spacing: Spacing.sm) {
                    if let year = album.yearString {
                        metadataChip(year)
                    }

                    metadataChip(album.songCountString)

                    if let duration = album.duration, duration > 0 {
                        metadataChip(album.formattedDuration)
                    }
                }
                .padding(.top, Spacing.xs)

                // Quality & popularity
                HStack(spacing: Spacing.md) {
                    if let listeners = album.formattedListeners {
                        Text(listeners)
                            .font(.Navi.caption)
                            .foregroundColor(Color.Text.tertiary)
                    }

                    if let playCount = album.formattedPlayCount {
                        Text(playCount)
                            .font(.Navi.caption)
                            .foregroundColor(Color.Text.tertiary)
                    }
                }
                .padding(.top, Spacing.xxs)
            }
            .padding(.horizontal, Spacing.Page.horizontal)
        }
    }

    private func metadataChip(_ text: String) -> some View {
        Text(text)
            .font(.Navi.caption)
            .foregroundColor(Color.Text.secondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(Color.Background.surface)
            .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Play Controls
    private func playControls(_ album: Album) -> some View {
        HStack(spacing: Spacing.md) {
            // Play button
            Button {
                Task {
                    await viewModel.playAlbum()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Play")
                        .font(.Navi.labelLarge)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.white)
                .cornerRadius(CornerRadius.md)
            }

            // Shuffle button
            Button {
                Task {
                    await viewModel.shuffleAlbum()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Shuffle")
                        .font(.Navi.labelLarge)
                }
                .foregroundColor(Color.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.Background.elevated)
                .cornerRadius(CornerRadius.md)
            }
        }
        .padding(.horizontal, Spacing.Page.horizontal)
    }

    // MARK: - Track List
    private func trackList(_ album: Album) -> some View {
        LazyVStack(alignment: .leading, spacing: 0) {

            // Section header
            HStack {
                Text("TRACKS")
                    .font(.Navi.captionSmall)
                    .foregroundColor(Color.Text.tertiary)
                    .tracking(1)

                Spacer()

                // Total duration
                if let duration = album.duration {
                    Text(formatTotalDuration(duration))
                        .font(.Navi.caption)
                        .foregroundColor(Color.Text.tertiary)
                }
            }
            .padding(.horizontal, Spacing.Page.horizontal)
            .padding(.bottom, Spacing.md)

            // Tracks grouped by disc
            let groupedTracks = groupTracksByDisc(album.tracks)
            let hasMultipleDiscs = groupedTracks.keys.count > 1

            ForEach(groupedTracks.keys.sorted(), id: \.self) { disc in
                if hasMultipleDiscs {
                    discHeader(disc)
                }

                ForEach(groupedTracks[disc] ?? []) { track in
                    trackRow(track, in: album)
                }
            }
        }
    }

    private func discHeader(_ disc: Int) -> some View {
        HStack {
            Image(systemName: "opticaldisc")
                .font(.system(size: 12))
                .foregroundColor(Color.Text.tertiary)

            Text("Disc \(disc)")
                .font(.Navi.caption)
                .foregroundColor(Color.Text.tertiary)

            Spacer()
        }
        .padding(.horizontal, Spacing.Page.horizontal)
        .padding(.vertical, Spacing.sm)
        .background(Color.Background.surface.opacity(0.5))
    }

    private func trackRow(_ track: Track, in album: Album) -> some View {
        let isPlaying = viewModel.isTrackPlaying(track)

        return Button {
            Task {
                await viewModel.playTrack(track, in: album)
            }
        } label: {
            HStack(spacing: Spacing.md) {
                // Track number or playing indicator
                if isPlaying {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundColor(Color.Accent.cyan)
                        .frame(width: 24)
                } else {
                    Text("\(track.track ?? 0)")
                        .font(.Navi.caption)
                        .foregroundColor(Color.Text.tertiary)
                        .frame(width: 24)
                }

                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.Navi.bodyMedium)
                        .foregroundColor(isPlaying ? Color.Accent.cyan : Color.Text.primary)
                        .lineLimit(1)

                    // Show artist if different from album artist
                    if track.artist != album.artist {
                        Text(track.effectiveArtist)
                            .font(.Navi.caption)
                            .foregroundColor(Color.Text.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Quality badge (only show for hi-res/lossless)
                QualityTierBadge(track: track)

                // Duration
                Text(track.formattedDuration)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.tertiary)

                // More button
                Button {
                    viewModel.selectedTrack = track
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(Color.Text.tertiary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, Spacing.Page.horizontal)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Album Info Section
    private var albumInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("ABOUT")
                .font(.Navi.captionSmall)
                .foregroundColor(Color.Text.tertiary)
                .tracking(1)

            if let notes = viewModel.albumInfo?.notes, !notes.isEmpty {
                Text(notes)
                    .font(.Navi.bodySmall)
                    .foregroundColor(Color.Text.secondary)
                    .lineLimit(nil)
            }

            // External links would go here
        }
        .padding(.horizontal, Spacing.Page.horizontal)
    }

    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Color.Text.tertiary)

            Text("Failed to load album")
                .font(.Navi.bodyMedium)
                .foregroundColor(Color.Text.secondary)

            Button("Try Again") {
                Task {
                    await viewModel.load()
                }
            }
            .font(.Navi.labelLarge)
            .foregroundColor(Color.Accent.cyan)
        }
    }

    // MARK: - Helpers
    private func groupTracksByDisc(_ tracks: [Track]) -> [Int: [Track]] {
        var grouped: [Int: [Track]] = [:]
        for track in tracks {
            let disc = track.discNumber ?? 1
            if grouped[disc] == nil {
                grouped[disc] = []
            }
            grouped[disc]?.append(track)
        }
        // Sort tracks by track number within each disc
        for (disc, tracks) in grouped {
            grouped[disc] = tracks.sorted { ($0.track ?? 0) < ($1.track ?? 0) }
        }
        return grouped
    }

    private func formatTotalDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
    }
}

// MARK: - Album Detail ViewModel
@MainActor
final class AlbumDetailViewModel: ObservableObject {
    @Published var album: Album?
    @Published var albumInfo: AlbumInfo?
    @Published var isLoading = false
    @Published var selectedTrack: Track?

    let albumId: String
    private let client = SubsonicClient.shared
    private let audioEngine = AudioEngine.shared

    init(albumId: String) {
        self.albumId = albumId
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            album = try await client.getAlbum(id: albumId)
            // Could load album info here if needed
        } catch {
            print("Failed to load album: \(error)")
        }
    }

    func playAlbum() async {
        guard let album = album else { return }
        await audioEngine.setQueue(album.tracks)
        audioEngine.play()
    }

    func shuffleAlbum() async {
        guard let album = album else { return }
        var shuffled = album.tracks
        shuffled.shuffle()
        await audioEngine.setQueue(shuffled)
        audioEngine.play()
    }

    func playTrack(_ track: Track, in album: Album) async {
        guard let index = album.tracks.firstIndex(where: { $0.id == track.id }) else { return }
        await audioEngine.setQueue(album.tracks, startIndex: index)
        audioEngine.play()
    }

    func isTrackPlaying(_ track: Track) -> Bool {
        audioEngine.currentTrack?.id == track.id
    }
}

// MARK: - Album Info (if available)
struct AlbumInfo: Codable {
    let notes: String?
    let musicBrainzId: String?
    let lastFmUrl: String?
    let smallImageUrl: String?
    let mediumImageUrl: String?
    let largeImageUrl: String?
}

// MARK: - Preview
#if DEBUG
struct AlbumDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AlbumDetailView(albumId: "preview")
        }
    }
}
#endif
