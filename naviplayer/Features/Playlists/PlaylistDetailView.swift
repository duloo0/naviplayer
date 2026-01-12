//
//  PlaylistDetailView.swift
//  naviplayer
//
//  Playlist detail view with track list and playback controls
//

import SwiftUI
import Combine

struct PlaylistDetailView: View {
    let playlistId: String
    @StateObject private var viewModel: PlaylistDetailViewModel

    init(playlistId: String) {
        self.playlistId = playlistId
        self._viewModel = StateObject(wrappedValue: PlaylistDetailViewModel(playlistId: playlistId))
    }

    var body: some View {
        ZStack {
            Color.Background.default
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.Accent.cyan))
            } else if let playlist = viewModel.playlist {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Playlist header
                        playlistHeader(playlist)

                        // Play controls
                        playControls(playlist)
                            .padding(.top, Spacing.lg)

                        // Smart playlist info
                        if playlist.isSmart {
                            smartPlaylistBadge
                                .padding(.top, Spacing.md)
                        }

                        // Track list
                        trackList(playlist)
                            .padding(.top, Spacing.xl)

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
                Text("Playlist")
                    .font(.Navi.labelMedium)
                    .foregroundColor(Color.Text.secondary)
            }
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Playlist Header
    private func playlistHeader(_ playlist: Playlist) -> some View {
        VStack(spacing: Spacing.lg) {
            // Artwork
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.Background.elevated)
                    .frame(width: 200, height: 200)

                if let coverArt = playlist.coverArt {
                    AsyncArtwork(
                        url: SubsonicClient.shared.coverArtURL(for: coverArt, size: 400),
                        size: 200,
                        cornerRadius: CornerRadius.md
                    )
                } else {
                    // Generate a placeholder with the playlist icon
                    VStack(spacing: Spacing.md) {
                        Image(systemName: playlist.isSmart ? "sparkles" : "music.note.list")
                            .font(.system(size: 48))
                            .foregroundColor(Color.Accent.cyan.opacity(0.7))
                    }
                }
            }
            .padding(.top, Spacing.lg)

            // Playlist info
            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Text(playlist.name)
                        .font(.Navi.headlineSmall)
                        .foregroundColor(Color.Text.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    if playlist.isSmart {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(Color.Accent.cyan)
                    }
                }

                // Owner
                if let owner = playlist.owner {
                    Text("by \(owner)")
                        .font(.Navi.bodySmall)
                        .foregroundColor(Color.Text.secondary)
                }

                // Metadata row
                HStack(spacing: Spacing.sm) {
                    metadataChip(playlist.trackCountDisplay)

                    if let duration = playlist.duration, duration > 0 {
                        metadataChip(playlist.formattedDuration)
                    }
                }
                .padding(.top, Spacing.xs)

                // Comment
                if let comment = playlist.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.Navi.caption)
                        .foregroundColor(Color.Text.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xs)
                }
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

    // MARK: - Smart Playlist Badge
    private var smartPlaylistBadge: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundColor(Color.Accent.cyan)

            Text("Smart Playlist")
                .font(.Navi.caption)
                .foregroundColor(Color.Accent.cyan)

            Text("•")
                .foregroundColor(Color.Text.tertiary)

            Text("Auto-updates based on rules")
                .font(.Navi.caption)
                .foregroundColor(Color.Text.tertiary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.Accent.cyan.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal, Spacing.Page.horizontal)
    }

    // MARK: - Play Controls
    private func playControls(_ playlist: Playlist) -> some View {
        HStack(spacing: Spacing.md) {
            // Play button
            Button {
                Task {
                    await viewModel.playPlaylist()
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
            .disabled(playlist.tracks.isEmpty)

            // Shuffle button
            Button {
                Task {
                    await viewModel.shufflePlaylist()
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
            .disabled(playlist.tracks.isEmpty)
        }
        .padding(.horizontal, Spacing.Page.horizontal)
    }

    // MARK: - Track List
    private func trackList(_ playlist: Playlist) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text("TRACKS")
                    .font(.Navi.captionSmall)
                    .foregroundColor(Color.Text.tertiary)
                    .tracking(1)

                Spacer()

                if let duration = playlist.duration {
                    Text(formatTotalDuration(duration))
                        .font(.Navi.caption)
                        .foregroundColor(Color.Text.tertiary)
                }
            }
            .padding(.horizontal, Spacing.Page.horizontal)
            .padding(.bottom, Spacing.md)

            if playlist.tracks.isEmpty {
                Text("No tracks in this playlist")
                    .font(.Navi.bodySmall)
                    .foregroundColor(Color.Text.secondary)
                    .padding(.horizontal, Spacing.Page.horizontal)
                    .padding(.vertical, Spacing.xl)
            } else {
                ForEach(Array(playlist.tracks.enumerated()), id: \.element.id) { index, track in
                    trackRow(track, index: index + 1, in: playlist)
                }
            }
        }
    }

    private func trackRow(_ track: Track, index: Int, in playlist: Playlist) -> some View {
        let isPlaying = viewModel.isTrackPlaying(track)

        return Button {
            Task {
                await viewModel.playTrack(track, in: playlist)
            }
        } label: {
            HStack(spacing: Spacing.md) {
                // Track number or playing indicator
                if isPlaying {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundColor(Color.Accent.cyan)
                        .frame(width: 28)
                } else {
                    Text("\(index)")
                        .font(.Navi.caption)
                        .foregroundColor(Color.Text.tertiary)
                        .frame(width: 28)
                }

                // Track artwork (small)
                AsyncArtwork(
                    url: SubsonicClient.shared.coverArtURL(for: track.coverArt, size: 80),
                    size: 40,
                    cornerRadius: CornerRadius.xs
                )

                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.Navi.bodyMedium)
                        .foregroundColor(isPlaying ? Color.Accent.cyan : Color.Text.primary)
                        .lineLimit(1)

                    Text(track.effectiveArtist)
                        .font(.Navi.caption)
                        .foregroundColor(Color.Text.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Quality badge
                QualityTierBadge(track: track)

                // Duration
                Text(track.formattedDuration)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.tertiary)
            }
            .padding(.horizontal, Spacing.Page.horizontal)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Color.Text.tertiary)

            Text("Failed to load playlist")
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
    private func formatTotalDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
    }
}

// MARK: - Playlist Detail ViewModel
@MainActor
final class PlaylistDetailViewModel: ObservableObject {
    @Published var playlist: Playlist?
    @Published var isLoading = false

    let playlistId: String
    private let client = SubsonicClient.shared
    private let audioEngine = AudioEngine.shared

    init(playlistId: String) {
        self.playlistId = playlistId
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            playlist = try await client.getPlaylist(id: playlistId)
        } catch {
            print("Failed to load playlist: \(error)")
        }
    }

    func playPlaylist() async {
        guard let playlist = playlist else { return }
        await audioEngine.setQueue(playlist.tracks)
        audioEngine.play()
    }

    func shufflePlaylist() async {
        guard let playlist = playlist else { return }
        var shuffled = playlist.tracks
        shuffled.shuffle()
        await audioEngine.setQueue(shuffled)
        audioEngine.play()
    }

    func playTrack(_ track: Track, in playlist: Playlist) async {
        guard let index = playlist.tracks.firstIndex(where: { $0.id == track.id }) else { return }
        await audioEngine.setQueue(playlist.tracks, startIndex: index)
        audioEngine.play()
    }

    func isTrackPlaying(_ track: Track) -> Bool {
        audioEngine.currentTrack?.id == track.id
    }
}

// MARK: - Preview
#if DEBUG
struct PlaylistDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PlaylistDetailView(playlistId: "preview")
        }
        .preferredColorScheme(.dark)
    }
}
#endif
