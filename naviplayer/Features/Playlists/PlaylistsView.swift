//
//  PlaylistsView.swift
//  naviplayer
//
//  Playlists view with smart and regular playlist sections
//

import SwiftUI
import Combine

// MARK: - Playlists View
struct PlaylistsView: View {
    @StateObject private var viewModel = PlaylistsViewModel()

    var body: some View {
        ZStack {
            Color.Background.default
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Compact header row
                HStack {
                    Text("Playlists")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, Spacing.Page.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

                if viewModel.isLoading && viewModel.playlists.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.Accent.cyan))
                    Spacer()
                } else if viewModel.playlists.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            // Smart playlists section
                            if !viewModel.smartPlaylists.isEmpty {
                                playlistSection(
                                    title: "SMART PLAYLISTS",
                                    icon: "sparkles",
                                    playlists: viewModel.smartPlaylists
                                )
                            }

                            // Regular playlists section
                            if !viewModel.regularPlaylists.isEmpty {
                                playlistSection(
                                    title: "PLAYLISTS",
                                    icon: "music.note.list",
                                    playlists: viewModel.regularPlaylists
                                )
                            }

                            Spacer(minLength: Spacing.xl3 + 80) // Extra space for mini player
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(Color.Text.tertiary)

            Text("No Playlists")
                .font(.Navi.titleMedium)
                .foregroundColor(Color.Text.primary)

            Text("Create playlists on your Navidrome server\nto see them here.")
                .font(.Navi.bodySmall)
                .foregroundColor(Color.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Playlist Section
    private func playlistSection(title: String, icon: String, playlists: [Playlist]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(Color.Text.tertiary)

                Text(title)
                    .font(.Navi.captionSmall)
                    .foregroundColor(Color.Text.tertiary)
                    .tracking(1)
            }
            .padding(.horizontal, Spacing.Page.horizontal)
            .padding(.top, Spacing.lg)

            // Playlist rows
            ForEach(playlists) { playlist in
                NavigationLink {
                    PlaylistDetailView(playlistId: playlist.id)
                } label: {
                    playlistRow(playlist)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Playlist Row
    private func playlistRow(_ playlist: Playlist) -> some View {
        HStack(spacing: Spacing.md) {
            // Playlist artwork
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.Background.elevated)
                    .frame(width: 56, height: 56)

                if let coverArt = playlist.coverArt {
                    AsyncArtwork(
                        url: SubsonicClient.shared.coverArtURL(for: coverArt, size: 112),
                        size: 56,
                        cornerRadius: CornerRadius.sm
                    )
                } else {
                    Image(systemName: playlist.isSmart ? "sparkles" : "music.note.list")
                        .font(.system(size: 20))
                        .foregroundColor(Color.Text.tertiary)
                }
            }

            // Playlist info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(playlist.name)
                        .font(.Navi.bodyMedium)
                        .foregroundColor(Color.Text.primary)
                        .lineLimit(1)

                    if playlist.isSmart {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundColor(Color.Accent.cyan)
                    }
                }

                HStack(spacing: Spacing.xs) {
                    if let count = playlist.songCount {
                        Text("\(count) tracks")
                            .font(.Navi.caption)
                            .foregroundColor(Color.Text.secondary)
                    }

                    if let duration = playlist.duration, duration > 0 {
                        Text("•")
                            .font(.Navi.caption)
                            .foregroundColor(Color.Text.tertiary)

                        Text(playlist.formattedDuration)
                            .font(.Navi.caption)
                            .foregroundColor(Color.Text.secondary)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.Text.tertiary)
        }
        .padding(.horizontal, Spacing.Page.horizontal)
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
    }
}

// MARK: - Playlists ViewModel
@MainActor
final class PlaylistsViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var isLoading = false

    private let client = SubsonicClient.shared

    var smartPlaylists: [Playlist] {
        playlists.filter { $0.isSmart }
    }

    var regularPlaylists: [Playlist] {
        playlists.filter { !$0.isSmart }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            playlists = try await client.getPlaylists()
        } catch {
            print("Failed to load playlists: \(error)")
        }
    }
}

// MARK: - Preview
#if DEBUG
struct PlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PlaylistsView()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
