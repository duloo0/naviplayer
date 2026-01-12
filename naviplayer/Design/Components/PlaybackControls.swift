//
//  PlaybackControls.swift
//  naviplayer
//
//  Playback control buttons for Now Playing screen
//

import SwiftUI

// MARK: - Playback State
enum PlaybackState {
    case playing
    case paused
    case loading
    case stopped
}

// MARK: - Main Playback Controls
struct PlaybackControls: View {
    let state: PlaybackState
    var onPrevious: (() -> Void)?
    var onPlayPause: (() -> Void)?
    var onNext: (() -> Void)?

    @State private var isPreviousPressed = false
    @State private var isPlayPausePressed = false
    @State private var isNextPressed = false

    var body: some View {
        HStack(spacing: Spacing.Player.controlSpacing) {
            // Previous
            ControlButton(
                icon: "backward.fill",
                size: 28,
                isPressed: $isPreviousPressed,
                action: onPrevious
            )

            // Play/Pause
            PlayPauseButton(
                state: state,
                isPressed: $isPlayPausePressed,
                action: onPlayPause
            )

            // Next
            ControlButton(
                icon: "forward.fill",
                size: 28,
                isPressed: $isNextPressed,
                action: onNext
            )
        }
    }
}

// MARK: - Play/Pause Button
struct PlayPauseButton: View {
    let state: PlaybackState
    @Binding var isPressed: Bool
    var action: (() -> Void)?

    private let size: CGFloat = 64
    private let iconSize: CGFloat = 28

    var body: some View {
        Button {
            action?()
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)

                // Icon
                Group {
                    switch state {
                    case .loading:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    case .playing:
                        Image(systemName: "pause.fill")
                            .font(.system(size: iconSize, weight: .semibold))
                    case .paused, .stopped:
                        Image(systemName: "play.fill")
                            .font(.system(size: iconSize, weight: .semibold))
                            .offset(x: 2) // Optical alignment
                    }
                }
                .foregroundColor(.black)
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.Navi.bounce, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(state == .playing ? "Pause" : "Play")
    }
}

// MARK: - Control Button (Previous/Next)
struct ControlButton: View {
    let icon: String
    var size: CGFloat = 24
    @Binding var isPressed: Bool
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(Color.Text.primary)
                .frame(width: 44, height: 44)
                .scaleEffect(isPressed ? 0.85 : 1.0)
                .animation(.Navi.fast, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Shuffle & Repeat Controls
struct ShuffleRepeatControls: View {
    @Binding var shuffleEnabled: Bool
    @Binding var repeatMode: RepeatMode

    enum RepeatMode {
        case off
        case all
        case one
    }

    var body: some View {
        HStack(spacing: Spacing.xl2) {
            // Shuffle
            Button {
                shuffleEnabled.toggle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(shuffleEnabled ? Color.Accent.cyan : Color.Text.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            // Repeat
            Button {
                cycleRepeatMode()
            } label: {
                Image(systemName: repeatIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(repeatMode != .off ? Color.Accent.cyan : Color.Text.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var repeatIcon: String {
        switch repeatMode {
        case .off, .all:
            return "repeat"
        case .one:
            return "repeat.1"
        }
    }

    private func cycleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }
}

// MARK: - Secondary Actions Row
struct SecondaryActionsRow: View {
    let track: Track
    var isLoved: Bool = false
    var showLyrics: Bool = false
    var onLove: (() async -> Void)?
    var onRate: ((Int) async -> Void)?
    var onToggleLyrics: (() -> Void)?
    var onQueue: (() -> Void)?
    var onMore: (() -> Void)?

    var body: some View {
        HStack(spacing: Spacing.xl) {
            // Love button
            LoveButton(isLoved: isLoved) {
                await onLove?()
            }

            // Thumb buttons
            ThumbButtons(track: track, size: 22, spacing: Spacing.md, onRate: onRate)

            Spacer()

            // Lyrics toggle
            Button {
                onToggleLyrics?()
            } label: {
                Image(systemName: "quote.bubble")
                    .font(.system(size: 20))
                    .foregroundColor(showLyrics ? Color.Accent.cyan : Color.Text.secondary)
            }
            .buttonStyle(.plain)

            // Queue
            Button {
                onQueue?()
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 20))
                    .foregroundColor(Color.Text.secondary)
            }
            .buttonStyle(.plain)

            // More
            Button {
                onMore?()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(Color.Text.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct PlaybackControls_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            PlaybackControls(
                state: .paused,
                onPrevious: { print("Previous") },
                onPlayPause: { print("Play/Pause") },
                onNext: { print("Next") }
            )

            PlaybackControls(
                state: .playing,
                onPrevious: { print("Previous") },
                onPlayPause: { print("Play/Pause") },
                onNext: { print("Next") }
            )

            ShuffleRepeatControls(
                shuffleEnabled: .constant(true),
                repeatMode: .constant(.all)
            )
            .padding(.horizontal)

            SecondaryActionsRow(
                track: .preview(suffix: "flac"),
                isLoved: true,
                showLyrics: false
            )
            .padding(.horizontal)
        }
        .padding()
        .background(Color.Background.default)
        .preferredColorScheme(.dark)
    }
}
#endif
