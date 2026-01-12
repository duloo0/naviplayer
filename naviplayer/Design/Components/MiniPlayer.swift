//
//  MiniPlayer.swift
//  naviplayer
//
//  Mini player bar that appears at the bottom of the app
//

import SwiftUI

struct MiniPlayer: View {
    @ObservedObject var audioEngine: AudioEngine
    var onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        if let track = audioEngine.currentTrack {
            VStack(spacing: 0) {
                // Progress bar (thin line at top)
                ProgressBar(progress: audioEngine.progress)
                    .frame(height: 2)

                // Main content
                HStack(spacing: Spacing.md) {
                    // Artwork
                    MiniArtwork(
                        url: audioEngine.coverArtURL,
                        size: Spacing.Player.miniArtworkSize
                    )

                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.Navi.titleSmall)
                            .foregroundColor(Color.Text.primary)
                            .lineLimit(1)

                        Text(track.effectiveArtist)
                            .font(.Navi.caption)
                            .foregroundColor(Color.Text.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Play/Pause button
                    Button {
                        audioEngine.togglePlayPause()
                    } label: {
                        Image(systemName: audioEngine.playbackState == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.Text.primary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)

                    // Next button
                    Button {
                        Task {
                            await audioEngine.next()
                        }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.Text.secondary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .background(Color.Background.elevated)
            .overlay(
                Rectangle()
                    .fill(Color.Border.subtle)
                    .frame(height: 1),
                alignment: .top
            )
            .background(Color.Background.elevated) // Extend background under safe area
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.Navi.fast, value: isPressed)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        }
    }
}

// MARK: - Expanded Queue View
struct QueueView: View {
    @ObservedObject var audioEngine: AudioEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Background.default
                    .ignoresSafeArea()

                if audioEngine.queue.isEmpty {
                    emptyView
                } else {
                    queueList
                }
            }
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.Accent.cyan)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        audioEngine.clearQueue()
                    }
                    .foregroundColor(Color.Accent.error)
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "list.bullet")
                .font(.system(size: 48))
                .foregroundColor(Color.Text.tertiary)

            Text("Queue is empty")
                .font(.Navi.bodyMedium)
                .foregroundColor(Color.Text.secondary)
        }
    }

    private var queueList: some View {
        List {
            // Now Playing section
            if let current = audioEngine.currentTrack {
                Section {
                    queueRow(track: current, index: audioEngine.currentIndex, isPlaying: true)
                } header: {
                    Text("Now Playing")
                }
            }

            // Up Next section
            if !audioEngine.upcomingTracks.isEmpty {
                Section {
                    ForEach(Array(audioEngine.upcomingTracks.enumerated()), id: \.element.id) { offset, track in
                        let actualIndex = audioEngine.currentIndex + 1 + offset
                        queueRow(track: track, index: actualIndex, isPlaying: false)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let actualIndex = audioEngine.currentIndex + 1 + index
                            audioEngine.removeFromQueue(at: actualIndex)
                        }
                    }
                } header: {
                    Text("Up Next")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func queueRow(track: Track, index: Int, isPlaying: Bool) -> some View {
        Button {
            Task {
                await audioEngine.skipTo(index: index)
            }
        } label: {
            HStack(spacing: Spacing.md) {
                // Playing indicator or track number
                if isPlaying {
                    Image(systemName: audioEngine.playbackState == .playing ? "waveform" : "pause.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.Accent.cyan)
                        .frame(width: 24)
                } else {
                    Text("\(index + 1)")
                        .font(.Navi.caption)
                        .foregroundColor(Color.Text.tertiary)
                        .frame(width: 24)
                }

                // Artwork
                MiniArtwork(
                    url: SubsonicClient.shared.coverArtURL(for: track.coverArt, size: 100),
                    size: 44
                )

                // Info
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

                // Duration
                Text(track.formattedDuration)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.tertiary)

                // Quality badge
                QualityTierBadge(track: track)
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(isPlaying ? Color.Background.surface : Color.clear)
    }
}

// MARK: - Preview
#if DEBUG
struct MiniPlayer_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            MiniPlayer(audioEngine: AudioEngine.shared) {
                print("Tapped")
            }
        }
        .background(Color.Background.default)
        .preferredColorScheme(.dark)
    }
}
#endif
