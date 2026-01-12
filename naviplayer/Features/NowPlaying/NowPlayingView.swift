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
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isCompact: Bool {
        verticalSizeClass == .compact
    }

    private var artworkSize: CGFloat {
        isCompact ? 200 : 280
    }

    private var titleSize: CGFloat {
        isCompact ? 18 : 22
    }

    private var artistSize: CGFloat {
        isCompact ? 14 : 16
    }

    private var controlSpacing: CGFloat {
        isCompact ? 32 : 48
    }

    private var controlIconSize: CGFloat {
        isCompact ? 24 : 28
    }

    private var playPauseSize: CGFloat {
        isCompact ? 56 : 72
    }

    var body: some View {
        ZStack {
            // Background
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

            // Main content
            VStack(spacing: 0) {
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
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer(minLength: isCompact ? 8 : 16)

                // Artwork
                AsyncArtwork(
                    url: viewModel.coverArtURL,
                    size: artworkSize,
                    cornerRadius: 12
                )
                .frame(width: artworkSize, height: artworkSize)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

                Spacer(minLength: isCompact ? 12 : 24)

                // Track info
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
                        .padding(.top, 8)
                }

                Spacer(minLength: isCompact ? 12 : 20)

                // Progress slider
                VStack(spacing: 8) {
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

                Spacer(minLength: isCompact ? 8 : 16)

                // Playback controls
                HStack(spacing: controlSpacing) {
                    Button {
                        viewModel.previous()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: controlIconSize))
                            .foregroundColor(.white)
                    }

                    Button {
                        viewModel.togglePlayPause()
                    } label: {
                        Image(systemName: viewModel.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: playPauseSize))
                            .foregroundColor(.white)
                    }

                    Button {
                        viewModel.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: controlIconSize))
                            .foregroundColor(.white)
                    }
                }

                Spacer(minLength: isCompact ? 8 : 16)

                // Shuffle, thumbs, repeat row
                HStack {
                    Button {
                        viewModel.toggleShuffle()
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(viewModel.shuffleEnabled ? Color.Accent.cyan : .white.opacity(0.6))
                    }

                    Spacer()

                    if let track = viewModel.currentTrack {
                        HStack(spacing: 28) {
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
                .padding(.bottom, 16)
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
