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
    @State private var showTrackInfo = false
    @State private var dragOffset: CGFloat = 0
    @State private var thumbUpScale: CGFloat = 1.0
    @State private var thumbDownScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            contentView
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Reset scrubbing state if dismiss gesture activates (slider lost focus)
                    if isScrubbing {
                        isScrubbing = false
                    }
                    // Only allow dragging down
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    // Dismiss if dragged down more than 100 points
                    if value.translation.height > 100 {
                        dismiss()
                    } else {
                        // Spring back
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .animation(.interactiveSpring(), value: dragOffset)
        .sheet(isPresented: $showQueue) {
            QueueView(audioEngine: AudioEngine.shared)
        }
        .sheet(isPresented: $showTrackInfo) {
            if let track = viewModel.currentTrack {
                TrackDetailsView(track: track)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.currentTrack?.id) { _, _ in
            // Reset scrubbing state when track changes to prevent stale position display
            isScrubbing = false
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if let track = viewModel.currentTrack {
            VStack(spacing: 0) {
                // Drag handle
                dragHandle
                    .padding(.top, 12)

                // Playing From context
                playingFromView(track: track)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                // Artwork
                artworkView

                Spacer().frame(height: 24)

                // Track info with thumbs rating
                trackInfoView(track: track)

                Spacer().frame(height: 20)

                // Progress
                progressView

                Spacer().frame(height: 16)

                // Unified playback controls (shuffle, prev, play, next, repeat)
                playbackControls

                Spacer(minLength: 20)

                // Bottom info bar
                bottomInfoBar(track: track)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        } else {
            emptyStateView
        }
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.4))
            .frame(width: 36, height: 5)
    }

    // MARK: - Playing From

    private func playingFromView(track: Track) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("PLAYING FROM")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1)

            Text(track.album ?? track.effectiveArtist)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        GeometryReader { geo in
            let size = min(geo.size.width, 320)
            AsyncArtwork(
                url: viewModel.coverArtURL,
                size: size,
                cornerRadius: 12
            )
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 320)
    }

    // MARK: - Track Info (with thumbs rating on right)

    private func trackInfoView(track: Track) -> some View {
        let isThumbDown = viewModel.currentRating == 1
        let isThumbUp = viewModel.currentRating == 5

        return HStack(alignment: .top, spacing: 16) {
            // Title and artist on left
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(track.effectiveArtist)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            // Thumbs rating on right
            HStack(spacing: 20) {
                Button {
                    Task {
                        // Haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(isThumbDown ? .warning : .error)

                        // Animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            thumbDownScale = 1.3
                        }

                        await viewModel.rate(isThumbDown ? 0 : 1)

                        // Reset scale
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            thumbDownScale = 1.0
                        }
                    }
                } label: {
                    Image(systemName: isThumbDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.system(size: 22))
                        .foregroundColor(isThumbDown ? .red : .white.opacity(0.6))
                        .scaleEffect(thumbDownScale)
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        // Haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)

                        // Animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            thumbUpScale = 1.3
                        }

                        await viewModel.rate(isThumbUp ? 0 : 5)

                        // Reset scale
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            thumbUpScale = 1.0
                        }
                    }
                } label: {
                    Image(systemName: isThumbUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 22))
                        .foregroundColor(isThumbUp ? .green : .white.opacity(0.6))
                        .scaleEffect(thumbUpScale)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
            .animation(.easeInOut(duration: 0.2), value: viewModel.currentRating)
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

    // MARK: - Playback Controls (Unified Row)

    private var playbackControls: some View {
        HStack(spacing: 0) {
            // Shuffle button with pill highlight
            Button {
                viewModel.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.shuffleEnabled ? .white : .white.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .background(
                        viewModel.shuffleEnabled ?
                            Capsule().fill(Color.white.opacity(0.2)) : nil
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            // Previous
            Button {
                viewModel.previous()
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Spacer()

            // Play/Pause (larger)
            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.playbackState == .playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Spacer()

            // Next
            Button {
                viewModel.next()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Spacer()

            // Repeat button with pill highlight
            Button {
                viewModel.cycleRepeatMode()
            } label: {
                Image(systemName: viewModel.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.repeatMode != .off ? .white : .white.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .background(
                        viewModel.repeatMode != .off ?
                            Capsule().fill(Color.white.opacity(0.2)) : nil
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Bottom Info Bar

    private func bottomInfoBar(track: Track) -> some View {
        HStack(spacing: 0) {
            // Queue button with count (left)
            Button {
                showQueue = true
            } label: {
                HStack(spacing: 4) {
                    Text("\(AudioEngine.shared.queue.count)")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16))
                }
                .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .frame(width: 80, alignment: .leading)

            Spacer()

            // Audio quality badge (center)
            QualityBadge(track: track, showSpecs: false)

            Spacer()

            // Info button (right)
            Button {
                showTrackInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .frame(width: 80, alignment: .trailing)
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
