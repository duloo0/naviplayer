//
//  ThumbButtons.swift
//  naviplayer
//
//  Thumb up/down rating buttons based on Navidrome's ThumbButtons.jsx
//

import SwiftUI

// MARK: - Thumb Buttons Container
struct ThumbButtons: View {
    let track: Track
    var size: CGFloat = 28
    var spacing: CGFloat = Spacing.lg
    var onRate: ((Int) async -> Void)?

    @State private var isLoading = false

    var body: some View {
        HStack(spacing: spacing) {
            ThumbDownButton(
                isActive: track.isThumbDown,
                size: size,
                isLoading: isLoading,
                action: { await handleThumbDown() }
            )

            ThumbUpButton(
                isActive: track.isThumbUp,
                size: size,
                isLoading: isLoading,
                action: { await handleThumbUp() }
            )
        }
    }

    // MARK: - Actions

    private func handleThumbUp() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        // If already thumbs up, clear rating (0). Otherwise set to 5.
        let newRating = track.isThumbUp ? 0 : 5
        await onRate?(newRating)
    }

    private func handleThumbDown() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        // If already thumbs down, clear rating (0). Otherwise set to 1.
        let newRating = track.isThumbDown ? 0 : 1
        await onRate?(newRating)
    }
}

// MARK: - Thumb Up Button
struct ThumbUpButton: View {
    let isActive: Bool
    var size: CGFloat = 28
    var isLoading: Bool = false
    var action: (() async -> Void)?

    @State private var isPressed = false

    var body: some View {
        Button {
            Task {
                await action?()
            }
        } label: {
            Image(systemName: isActive ? "hand.thumbsup.fill" : "hand.thumbsup")
                .font(.system(size: size))
                .foregroundColor(isActive ? Color.thumbUp : Color.Text.secondary)
                .opacity(isLoading ? 0.5 : 1.0)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.Navi.fast, value: isPressed)
                .animation(.Navi.standard, value: isActive)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(isActive ? "Remove thumb up rating" : "Rate thumbs up")
    }
}

// MARK: - Thumb Down Button
struct ThumbDownButton: View {
    let isActive: Bool
    var size: CGFloat = 28
    var isLoading: Bool = false
    var action: (() async -> Void)?

    @State private var isPressed = false

    var body: some View {
        Button {
            Task {
                await action?()
            }
        } label: {
            Image(systemName: isActive ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                .font(.system(size: size))
                .foregroundColor(isActive ? Color.thumbDown : Color.Text.secondary)
                .opacity(isLoading ? 0.5 : 1.0)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.Navi.fast, value: isPressed)
                .animation(.Navi.standard, value: isActive)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(isActive ? "Remove thumb down rating" : "Rate thumbs down")
    }
}

// MARK: - Love Button (Star)
struct LoveButton: View {
    let isLoved: Bool
    var size: CGFloat = 24
    var isLoading: Bool = false
    var action: (() async -> Void)?

    @State private var isPressed = false

    var body: some View {
        Button {
            Task {
                await action?()
            }
        } label: {
            Image(systemName: isLoved ? "heart.fill" : "heart")
                .font(.system(size: size))
                .foregroundColor(isLoved ? Color.loved : Color.Text.secondary)
                .opacity(isLoading ? 0.5 : 1.0)
                .scaleEffect(isPressed ? 0.85 : 1.0)
                .animation(.Navi.bounce, value: isPressed)
                .animation(.Navi.standard, value: isLoved)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(isLoved ? "Remove from favorites" : "Add to favorites")
    }
}

// MARK: - Large Thumb Buttons (For Library Radio)
struct LargeThumbButtons: View {
    let track: Track
    var onRate: ((Int) async -> Void)?

    @State private var isLoading = false

    var body: some View {
        HStack(spacing: Spacing.xl3) {
            // Thumb Down - Large
            LargeThumbButton(
                icon: track.isThumbDown ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                isActive: track.isThumbDown,
                activeColor: Color.thumbDown,
                isLoading: isLoading
            ) {
                await handleThumbDown()
            }

            // Thumb Up - Large
            LargeThumbButton(
                icon: track.isThumbUp ? "hand.thumbsup.fill" : "hand.thumbsup",
                isActive: track.isThumbUp,
                activeColor: Color.thumbUp,
                isLoading: isLoading
            ) {
                await handleThumbUp()
            }
        }
    }

    private func handleThumbUp() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let newRating = track.isThumbUp ? 0 : 5
        await onRate?(newRating)
    }

    private func handleThumbDown() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let newRating = track.isThumbDown ? 0 : 1
        await onRate?(newRating)
    }
}

// MARK: - Large Thumb Button
private struct LargeThumbButton: View {
    let icon: String
    let isActive: Bool
    let activeColor: Color
    var isLoading: Bool = false
    var action: (() async -> Void)?

    @State private var isPressed = false

    private let size: CGFloat = 64
    private let iconSize: CGFloat = 32

    var body: some View {
        Button {
            Task {
                await action?()
            }
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .fill(isActive ? activeColor.opacity(0.15) : Color.Background.elevated)
                    .frame(width: size, height: size)

                // Border
                Circle()
                    .stroke(isActive ? activeColor.opacity(0.4) : Color.Border.default, lineWidth: 1.5)
                    .frame(width: size, height: size)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(isActive ? activeColor : Color.Text.secondary)
            }
            .opacity(isLoading ? 0.5 : 1.0)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.Navi.bounce, value: isPressed)
            .animation(.Navi.standard, value: isActive)
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview
#if DEBUG
struct ThumbButtons_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Small thumb buttons
            HStack(spacing: 30) {
                ThumbButtons(
                    track: .preview(suffix: "flac"),
                    onRate: { rating in
                        print("Rate: \(rating)")
                    }
                )

                // Active states
                ThumbUpButton(isActive: true)
                ThumbDownButton(isActive: true)
            }

            // Love button
            HStack(spacing: 20) {
                LoveButton(isLoved: false)
                LoveButton(isLoved: true)
            }

            // Large buttons (Library Radio style)
            LargeThumbButtons(
                track: .preview(suffix: "flac"),
                onRate: { rating in
                    print("Rate: \(rating)")
                }
            )

            // Active large buttons
            HStack(spacing: 40) {
                LargeThumbButton(
                    icon: "hand.thumbsdown.fill",
                    isActive: true,
                    activeColor: Color.thumbDown
                )
                LargeThumbButton(
                    icon: "hand.thumbsup.fill",
                    isActive: true,
                    activeColor: Color.thumbUp
                )
            }
        }
        .padding()
        .background(Color.Background.default)
        .preferredColorScheme(.dark)
    }
}
#endif
