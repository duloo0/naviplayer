//
//  NowPlayingView.swift
//  naviplayer
//
//  Premium Now Playing screen with proper layout for all iPhone sizes
//

import SwiftUI

struct NowPlayingView: View {
    @StateObject private var viewModel = NowPlayingViewModel()
    @StateObject private var audioEngine = AudioEngine.shared
    @State private var showQueue = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            let screenWidth = geo.size.width
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom

            // Calculate sizes based on available space
            let availableHeight = screenHeight - safeTop - safeBottom
            let artworkSize = min(screenWidth - 80, availableHeight * 0.38)

            ZStack {
                // Background layers
                backgroundLayers

                // Scrollable content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Top spacing
                        Spacer()
                            .frame(height: safeTop + 8)

                        // Header
                        headerView
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)

                        // Artwork
                        artworkView(size: artworkSize)
                            .padding(.bottom, 20)

                        // Track info
                        trackInfoView
                            .padding(.horizontal, 40)
                            .padding(.bottom, 8)

                        // Quality badge
                        qualityBadgeView
                            .padding(.bottom, 20)

                        // Progress slider
                        progressView
                            .padding(.horizontal, 32)
                            .padding(.bottom, 16)

                        // Main playback controls
                        playbackControlsView
                            .padding(.bottom, 16)

                        // Secondary controls (shuffle, thumbs, repeat)
                        secondaryControlsView
                            .padding(.horizontal, 32)

                        // Bottom spacing
                        Spacer()
                            .frame(height: safeBottom + 20)
                    }
                    .frame(minHeight: screenHeight)
                }
            }
        }
        .background(Color.Background.default)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showQueue) {
            QueueView(audioEngine: audioEngine)
        }
    }

    // MARK: - Background

    private var backgroundLayers: some View {
        ZStack {
            Color.Background.default
                .ignoresSafeArea()

            BlurredArtworkBackground(
                url: viewModel.coverArtURL,
                blurRadius: 60,
                opacity: 0.5
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("NOW PLAYING")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.2)

                if let album = viewModel.currentTrack?.album {
                    Text(album)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                showQueue = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Artwork

    private func artworkView(size: CGFloat) -> some View {
        AsyncArtwork(
            url: viewModel.coverArtURL,
            size: size,
            cornerRadius: 12
        )
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
    }

    // MARK: - Track Info

    private var trackInfoView: some View {
        VStack(spacing: 6) {
            Text(viewModel.currentTrack?.title ?? "Not Playing")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.currentTrack?.effectiveArtist ?? "")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
    }

    // MARK: - Quality Badge

    private var qualityBadgeView: some View {
        Group {
            if let track = viewModel.currentTrack {
                QualityBadge(track: track, showSpecs: true)
            }
        }
    }

    // MARK: - Progress

    private var progressView: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { viewModel.progress },
                    set: { viewModel.seek(to: $0 * viewModel.duration) }
                ),
                in: 0...1
            )
            .tint(.white)

            HStack {
                Text(formatTime(viewModel.currentTime))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Text(formatTime(viewModel.duration))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Playback Controls

    private var playbackControlsView: some View {
        HStack(spacing: 44) {
            Button {
                viewModel.previous()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.white)
            }

            Button {
                viewModel.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Secondary Controls

    private var secondaryControlsView: some View {
        HStack {
            // Shuffle
            Button {
                viewModel.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(viewModel.shuffleEnabled ? Color.Accent.cyan : .white.opacity(0.5))
            }
            .frame(width: 44, height: 44)

            Spacer()

            // Thumbs
            if let track = viewModel.currentTrack {
                HStack(spacing: 32) {
                    Button {
                        Task { await viewModel.rate(track.isThumbDown ? 0 : 1) }
                    } label: {
                        Image(systemName: track.isThumbDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 22))
                            .foregroundColor(track.isThumbDown ? .red : .white.opacity(0.5))
                    }

                    Button {
                        Task { await viewModel.rate(track.isThumbUp ? 0 : 5) }
                    } label: {
                        Image(systemName: track.isThumbUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 22))
                            .foregroundColor(track.isThumbUp ? .green : .white.opacity(0.5))
                    }
                }
            }

            Spacer()

            // Repeat
            Button {
                viewModel.cycleRepeatMode()
            } label: {
                Image(systemName: viewModel.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(viewModel.repeatMode != .off ? Color.Accent.cyan : .white.opacity(0.5))
            }
            .frame(width: 44, height: 44)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview

#if DEBUG
struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView()
    }
}
#endif
