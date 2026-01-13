//
//  NowPlayingView.swift
//  naviplayer
//
//  Full-screen now playing view
//

import SwiftUI

struct NowPlayingView: View {
    @StateObject private var viewModel = NowPlayingViewModel()
    @StateObject private var audioEngine = AudioEngine.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isScrubbing = false
    @State private var scrubPosition: Double = 0
    @State private var showQueue = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient
                    .ignoresSafeArea()

                if let track = viewModel.currentTrack {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            artworkSection(track: track)
                            trackInfoSection(track: track)
                            Spacer().frame(height: 12)
                            qualitySection(track: track)
                            Spacer().frame(height: 12)
                            progressSection
                            Spacer().frame(height: 8)
                            controlsSection
                            Spacer().frame(height: 8)
                            ratingSection(track: track)
                            Spacer().frame(height: 16)
                            bottomControlsBar
                            Spacer().frame(height: 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                    }
                } else {
                    emptyStateView
                }
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
        .onChange(of: viewModel.currentTime) { _, newValue in
            if !isScrubbing {
                scrubPosition = newValue
            }
        }
        .sheet(isPresented: $showQueue) {
            QueueView(audioEngine: audioEngine)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color.Background.default

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
        }
    }

    // MARK: - Artwork Section

    @ViewBuilder
    private func artworkSection(track: Track) -> some View {
        let artworkSize: CGFloat = 280

        AsyncArtwork(
            url: viewModel.coverArtURL,
            size: artworkSize,
            cornerRadius: 12
        )
        .frame(width: artworkSize, height: artworkSize)
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Track Info Section

    @ViewBuilder
    private func trackInfoSection(track: Track) -> some View {
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
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Quality Section

    @ViewBuilder
    private func qualitySection(track: Track) -> some View {
        QualityBadge(track: track, showSpecs: true)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { isScrubbing ? scrubPosition : viewModel.currentTime },
                    set: { newValue in
                        scrubPosition = newValue
                        if isScrubbing {
                            viewModel.seek(to: scrubPosition)
                        }
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
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .monospacedDigit()
                Spacer()
                Text("-\(formatTime(max(0, safeDuration - (isScrubbing ? scrubPosition : viewModel.currentTime))))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 36) {
            Button {
                viewModel.previous()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 26))
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
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Rating Section

    @ViewBuilder
    private func ratingSection(track: Track) -> some View {
        HStack(spacing: 48) {
            Button {
                Task { await viewModel.rate(track.isThumbDown ? 0 : 1) }
            } label: {
                Image(systemName: track.isThumbDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.system(size: 28))
                    .foregroundColor(track.isThumbDown ? .red : .white.opacity(0.6))
            }
            .buttonStyle(.plain)

            Button {
                Task { await viewModel.rate(track.isThumbUp ? 0 : 5) }
            } label: {
                Image(systemName: track.isThumbUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.system(size: 28))
                    .foregroundColor(track.isThumbUp ? .green : .white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Bottom Controls Bar

    private var bottomControlsBar: some View {
        HStack {
            Button {
                viewModel.toggleShuffle()
            } label: {
                Image(systemName: viewModel.shuffleEnabled ? "shuffle.circle.fill" : "shuffle")
                    .font(.title2)
                    .foregroundColor(viewModel.shuffleEnabled ? Color.Accent.cyan : .white.opacity(0.5))
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                viewModel.cycleRepeatMode()
            } label: {
                Image(systemName: viewModel.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.title2)
                    .foregroundColor(viewModel.repeatMode != .off ? Color.Accent.cyan : .white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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

// MARK: - Preview

#if DEBUG
struct NowPlayingView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView()
    }
}
#endif
