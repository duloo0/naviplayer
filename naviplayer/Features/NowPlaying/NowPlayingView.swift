//
//  NowPlayingView.swift
//  naviplayer
//
//  Full-screen now playing view
//

import SwiftUI

struct NowPlayingView: View {
    @StateObject private var viewModel = NowPlayingViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var isScrubbing = false
    @State private var scrubPosition: Double = 0
    @State private var showQueue = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                contentView
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showQueue = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
        }
        .sheet(isPresented: $showQueue) {
            QueueView(audioEngine: AudioEngine.shared)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if let track = viewModel.currentTrack {
            VStack(spacing: 0) {
                // Artwork
                artworkView
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Track info
                trackInfoView(track: track)

                Spacer().frame(height: 8)

                // Quality badge
                QualityBadge(track: track, showSpecs: true)

                Spacer().frame(height: 8)

                // Progress
                progressView

                Spacer().frame(height: 4)

                // Playback controls
                playbackControls

                Spacer().frame(height: 4)

                // Rating
                ratingView(track: track)

                Spacer(minLength: 16)

                // Bottom bar
                bottomBar
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        } else {
            emptyStateView
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        Color.Background.default
            .overlay(
                BlurredArtworkBackground(
                    url: viewModel.coverArtURL,
                    blurRadius: 60,
                    opacity: 0.5
                )
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.1),
                        Color.black.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    // MARK: - Artwork

    private var artworkView: some View {
        AsyncArtwork(
            url: viewModel.coverArtURL,
            size: 260,
            cornerRadius: 12
        )
        .frame(width: 260, height: 260)
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }

    // MARK: - Track Info

    private func trackInfoView(track: Track) -> some View {
        VStack(spacing: 4) {
            Text(track.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(track.effectiveArtist)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)

            if let album = track.album {
                Text(album)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Progress

    private var progressView: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { isScrubbing ? scrubPosition : viewModel.currentTime },
                    set: { newValue in
                        scrubPosition = newValue
                    }
                ),
                in: 0...max(safeDuration, 1),
                onEditingChanged: { editing in
                    if editing {
                        isScrubbing = true
                        scrubPosition = viewModel.currentTime
                    } else {
                        isScrubbing = false
                        viewModel.seek(to: scrubPosition)
                    }
                }
            )
            .tint(.white)
            .disabled(viewModel.duration <= 0.5)

            HStack {
                Text(formatTime(isScrubbing ? scrubPosition : viewModel.currentTime))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .monospacedDigit()
                Spacer()
                Text("-\(formatTime(max(0, safeDuration - (isScrubbing ? scrubPosition : viewModel.currentTime))))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 40) {
            Button {
                viewModel.previous()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Rating

    private func ratingView(track: Track) -> some View {
        HStack(spacing: 48) {
            Button {
                Task { await viewModel.rate(track.isThumbDown ? 0 : 1) }
            } label: {
                Image(systemName: track.isThumbDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.system(size: 24))
                    .foregroundColor(track.isThumbDown ? .red : .white.opacity(0.6))
            }
            .buttonStyle(.plain)

            Button {
                Task { await viewModel.rate(track.isThumbUp ? 0 : 5) }
            } label: {
                Image(systemName: track.isThumbUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.system(size: 24))
                    .foregroundColor(track.isThumbUp ? .green : .white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button {
                viewModel.toggleShuffle()
            } label: {
                Image(systemName: viewModel.shuffleEnabled ? "shuffle.circle.fill" : "shuffle")
                    .font(.system(size: 22))
                    .foregroundColor(viewModel.shuffleEnabled ? Color.Accent.cyan : .white.opacity(0.6))
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                viewModel.cycleRepeatMode()
            } label: {
                Image(systemName: viewModel.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 22))
                    .foregroundColor(viewModel.repeatMode != .off ? Color.Accent.cyan : .white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.5))
            Text("Nothing is playing")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Text("Start playback from the library")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Helpers

    private var safeDuration: TimeInterval {
        let d = viewModel.duration
        guard d.isFinite && d > 0 else { return 1 }
        return d
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "--:--" }
        let total = Int(seconds.rounded())
        let minutes = total / 60
        let remaining = total % 60
        return String(format: "%d:%02d", minutes, remaining)
    }
}

#if DEBUG
struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView()
    }
}
#endif
