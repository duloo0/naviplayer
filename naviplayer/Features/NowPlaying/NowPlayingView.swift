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
    @State private var showLyrics = false
    @State private var showSignalPath = false
    @State private var showQueue = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Blurred background
            BlurredArtworkBackground(
                url: viewModel.coverArtURL,
                blurRadius: 60,
                opacity: 0.5
            )

            // Gradient overlay
            GradientOverlay()

            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with dismiss
                    headerSection

                    // Artwork - use screen width for sizing
                    artworkSection

                    // Track info
                    trackInfoSection
                        .padding(.top, Spacing.xl)

                    // Quality & metadata
                    metadataSection
                        .padding(.top, Spacing.sm)

                    // Progress slider
                    ProgressSlider(
                        progress: $viewModel.progress,
                        duration: viewModel.duration,
                        onSeek: viewModel.seek
                    )
                    .padding(.top, Spacing.xl)
                    .padding(.horizontal, Spacing.Page.horizontal)

                    // Playback controls
                    PlaybackControls(
                        state: viewModel.playbackState,
                        onPrevious: viewModel.previous,
                        onPlayPause: viewModel.togglePlayPause,
                        onNext: viewModel.next
                    )
                    .padding(.top, Spacing.lg)

                    // Shuffle & Repeat
                    shuffleRepeatSection
                        .padding(.top, Spacing.lg)
                        .padding(.horizontal, Spacing.xl3)

                    // Actions row
                    if let track = viewModel.currentTrack {
                        SecondaryActionsRow(
                            track: track,
                            isLoved: viewModel.isLoved,
                            showLyrics: showLyrics,
                            onLove: viewModel.toggleLove,
                            onRate: viewModel.rate,
                            onToggleLyrics: { withAnimation { showLyrics.toggle() } },
                            onQueue: { showQueue = true },
                            onMore: { /* Show more options */ }
                        )
                        .padding(.top, Spacing.xl)
                        .padding(.horizontal, Spacing.Page.horizontal)
                    }

                    // Signal path (expandable)
                    if showSignalPath, let track = viewModel.currentTrack {
                        EnhancedSignalPathView(
                            track: track,
                            outputDevice: audioEngine.currentOutputDevice
                        )
                        .padding(.top, Spacing.lg)
                        .padding(.horizontal, Spacing.Page.horizontal)
                        .transition(.slideFromBottom)
                    }

                    // Lyrics (expandable)
                    if showLyrics, let lyrics = viewModel.lyrics {
                        lyricsSection(lyrics: lyrics)
                            .padding(.top, Spacing.lg)
                            .transition(.slideFromBottom)
                    }

                    // Bottom spacing for safe area
                    Spacer(minLength: 50)
                }
                .padding(.bottom, Spacing.xl)
            }
        }
        .ignoresSafeArea(edges: .top)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showQueue) {
            QueueView(audioEngine: audioEngine)
        }
    }

    // MARK: - Shuffle & Repeat Section
    private var shuffleRepeatSection: some View {
        HStack(spacing: Spacing.xl2) {
            // Shuffle
            Button {
                viewModel.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(viewModel.shuffleEnabled ? Color.Accent.cyan : Color.Text.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            // Repeat
            Button {
                viewModel.cycleRepeatMode()
            } label: {
                Image(systemName: repeatIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(viewModel.repeatMode != .off ? Color.Accent.cyan : Color.Text.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var repeatIcon: String {
        switch viewModel.repeatMode {
        case .off, .all:
            return "repeat"
        case .one:
            return "repeat.1"
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.Text.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("NOW PLAYING")
                    .font(.Navi.captionSmall)
                    .foregroundColor(Color.Text.tertiary)
                    .tracking(1)

                if let album = viewModel.currentTrack?.album {
                    Text(album)
                        .font(.Navi.caption)
                        .foregroundColor(Color.Text.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Signal path toggle
            Button {
                withAnimation(.Navi.smooth) {
                    showSignalPath.toggle()
                }
            } label: {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(showSignalPath ? Color.Accent.cyan : Color.Text.secondary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.top, Spacing.sm)
    }

    // MARK: - Artwork Section
    private var artworkSection: some View {
        // Calculate artwork size based on screen width
        let screenWidth = UIScreen.main.bounds.width
        let artworkSize = min(screenWidth - Spacing.Page.horizontal * 2, 320)

        return AsyncArtwork(
            url: viewModel.coverArtURL,
            size: artworkSize,
            cornerRadius: CornerRadius.lg
        )
        .shadow(color: viewModel.dominantColor.opacity(0.5), radius: 40, y: 20)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    if horizontalAmount < -50 {
                        // Swipe left - next track
                        viewModel.next()
                    } else if horizontalAmount > 50 {
                        // Swipe right - previous track
                        viewModel.previous()
                    }
                }
        )
        .padding(.top, Spacing.lg)
    }

    // MARK: - Track Info Section
    private var trackInfoSection: some View {
        VStack(spacing: Spacing.xs) {
            // Title
            Text(viewModel.currentTrack?.title ?? "Not Playing")
                .font(.Navi.titleLarge)
                .foregroundColor(Color.Text.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // Artist
            Text(viewModel.currentTrack?.effectiveArtist ?? "")
                .font(.Navi.bodyMedium)
                .foregroundColor(Color.Text.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.Page.horizontal)
    }

    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(spacing: Spacing.sm) {
            // Quality badge
            if let track = viewModel.currentTrack {
                QualityBadge(track: track, showSpecs: true)
            }

            // Additional metadata
            if let track = viewModel.currentTrack {
                HStack(spacing: Spacing.md) {
                    // Year
                    if let year = track.year, year > 0 {
                        metadataItem(text: String(year))
                    }

                    // Listeners
                    if let listeners = track.lastfmListeners, listeners > 0 {
                        metadataItem(text: formatListeners(listeners))
                    }

                    // Play count
                    if let playCount = track.playCount, playCount > 0 {
                        metadataItem(text: "\(playCount) plays")
                    }
                }
            }
        }
    }

    private func metadataItem(text: String) -> some View {
        Text(text)
            .font(.Navi.caption)
            .foregroundColor(Color.Text.tertiary)
    }

    private func formatListeners(_ count: Int64) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM listeners", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK listeners", Double(count) / 1_000)
        }
        return "\(count) listeners"
    }

    // MARK: - Lyrics Section
    private func lyricsSection(lyrics: StructuredLyrics) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("LYRICS")
                .font(.Navi.captionSmall)
                .foregroundColor(Color.Text.tertiary)
                .tracking(1)
                .padding(.horizontal, Spacing.Page.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(lyrics.lines) { line in
                        let display = LyricsDisplay(lyrics: lyrics, currentTime: viewModel.currentTime)
                        let isActive = display.isLineActive(line)
                        let isPassed = display.isLinePassed(line)

                        Text(line.value)
                            .font(isActive ? .Navi.titleMedium : .Navi.bodyMedium)
                            .foregroundColor(
                                isActive ? Color.Text.primary :
                                isPassed ? Color.Text.tertiary : Color.Text.secondary
                            )
                            .opacity(line.isInstrumental ? 0.5 : 1.0)
                            .italic(line.isInstrumental)
                            .animation(.Navi.standard, value: isActive)
                    }
                }
                .padding(.horizontal, Spacing.Page.horizontal)
            }
            .frame(maxHeight: 200)
        }
        .padding(.vertical, Spacing.md)
        .background(Color.Background.surface.opacity(0.5))
        .cornerRadius(CornerRadius.md)
        .padding(.horizontal, Spacing.Page.horizontal)
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
