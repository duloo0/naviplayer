//
//  NowPlayingView.swift
//  naviplayer
//
//  Premium Now Playing screen with Tidal/Roon aesthetic
//

import SwiftUI

// MARK: - Now Playing View
struct NowPlayingView: View {
    @StateObject private var viewModel = NowPlayingViewModel()
    @StateObject private var audioEngine = AudioEngine.shared
    @State private var showQueue = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let extraTop: CGFloat = 8
            let extraBottom: CGFloat = 16
            let contentHeight = max(geometry.size.height - safeArea.top - safeArea.bottom - extraTop - extraBottom, 0)
            let contentWidth = geometry.size.width
            let isCompact = contentHeight < 650
            let artworkMax: CGFloat = isCompact ? 240 : 300
            let artworkScale: CGFloat = isCompact ? 0.32 : 0.4
            let artworkSize = min(geometry.size.width - 64, min(artworkMax, contentHeight * artworkScale))
            let titleSize: CGFloat = isCompact ? 20 : 22
            let artistSize: CGFloat = isCompact ? 14 : 16
            let controlSpacing: CGFloat = isCompact ? 32 : 48
            let controlIconSize: CGFloat = isCompact ? 24 : 28
            let playPauseSize: CGFloat = isCompact ? 64 : 72
            let thumbSpacing: CGFloat = isCompact ? 20 : 32

            ZStack {
                // Background color
                Color.Background.default
                    .ignoresSafeArea()

                // Blurred background
                BlurredArtworkBackground(
                    url: viewModel.coverArtURL,
                    blurRadius: 60,
                    opacity: 0.5
                )

                // Gradient overlay
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

                ScrollView(.vertical, showsIndicators: false) {
                    // Main content - uses spacing instead of spacers for reliable scrolling
                    VStack(spacing: isCompact ? 16 : 24) {
                        // Header
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
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .tracking(1)

                                if let album = viewModel.currentTrack?.album {
                                    Text(album)
                                        .font(.system(size: 12))
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
                        .padding(.horizontal, 8)

                        // Artwork - centered
                        AsyncArtwork(
                            url: viewModel.coverArtURL,
                            size: artworkSize,
                            cornerRadius: 12
                        )
                        .frame(width: artworkSize, height: artworkSize)

                        // Track info - centered
                        VStack(spacing: 4) {
                            Text(viewModel.currentTrack?.title ?? "Not Playing")
                                .font(.system(size: titleSize, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)

                            Text(viewModel.currentTrack?.effectiveArtist ?? "")
                                .font(.system(size: artistSize))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 32)

                        // Quality badge
                        if let track = viewModel.currentTrack {
                            QualityBadge(track: track, showSpecs: true)
                                .padding(.top, 4)
                        }

                        // Progress slider
                        VStack(spacing: 8) {
                            // Slider
                            Slider(
                                value: Binding(
                                    get: { viewModel.progress },
                                    set: { newValue in
                                        viewModel.seek(to: newValue * viewModel.duration)
                                    }
                                ),
                                in: 0...1
                            )
                            .tint(Color.white)

                            // Time labels
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
                        .padding(.horizontal, 32)

                        // Playback controls
                        HStack(spacing: controlSpacing) {
                            // Previous
                            Button {
                                viewModel.previous()
                            } label: {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: controlIconSize))
                                    .foregroundColor(.white)
                            }

                            // Play/Pause
                            Button {
                                viewModel.togglePlayPause()
                            } label: {
                                Image(systemName: viewModel.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: playPauseSize))
                                    .foregroundColor(.white)
                            }

                            // Next
                            Button {
                                viewModel.next()
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: controlIconSize))
                                    .foregroundColor(.white)
                            }
                        }

                        // Shuffle & Repeat
                        HStack {
                            Button {
                                viewModel.toggleShuffle()
                            } label: {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(viewModel.shuffleEnabled ? Color.Accent.cyan : .white.opacity(0.6))
                            }

                            Spacer()

                            // Thumb buttons
                            if let track = viewModel.currentTrack {
                                HStack(spacing: thumbSpacing) {
                                    Button {
                                        Task { await viewModel.rate(track.isThumbDown ? 0 : 1) }
                                    } label: {
                                        Image(systemName: track.isThumbDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                            .font(.system(size: 22))
                                            .foregroundColor(track.isThumbDown ? .red : .white.opacity(0.6))
                                    }

                                    Button {
                                        Task { await viewModel.rate(track.isThumbUp ? 0 : 5) }
                                    } label: {
                                        Image(systemName: track.isThumbUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                                            .font(.system(size: 22))
                                            .foregroundColor(track.isThumbUp ? .green : .white.opacity(0.6))
                                    }
                                }
                            }

                            Spacer()

                            Button {
                                viewModel.cycleRepeatMode()
                            } label: {
                                Image(systemName: viewModel.repeatMode == .one ? "repeat.1" : "repeat")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(viewModel.repeatMode != .off ? Color.Accent.cyan : .white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .frame(width: contentWidth, alignment: .center)
                    .frame(minHeight: contentHeight, alignment: .center)
                    .padding(.top, safeArea.top + extraTop)
                    .padding(.bottom, safeArea.bottom + extraBottom)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)

#if DEBUG
                VStack {
                    Text("NP DEBUG")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(8)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, safeArea.top + 6)
                .padding(.leading, 12)
#endif
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showQueue) {
            QueueView(audioEngine: audioEngine)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
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
