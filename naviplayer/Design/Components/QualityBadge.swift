//
//  QualityBadge.swift
//  naviplayer
//
//  Audio quality badge component based on Navidrome's QualityBadge.jsx
//

import SwiftUI

// MARK: - Quality Badge
struct QualityBadge: View {
    let track: Track
    var showSpecs: Bool = false
    var size: BadgeSize = .medium
    var transcodingQuality: TranscodingQuality? = nil

    enum BadgeSize {
        case small
        case medium

        var fontSize: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4)
            case .medium: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            }
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            // Quality tier badge
            Text(badgeText)
                .font(.system(size: size.fontSize, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(size.padding)
                .foregroundColor(badgeColor)
                .background(badgeColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(badgeColor.opacity(0.4), lineWidth: 1)
                )
                .cornerRadius(4)

            // Optional specs display
            if showSpecs, let specs = specsString {
                Text(specs)
                    .font(.Navi.monoSmall)
                    .foregroundColor(Color.Text.tertiary)
            }
        }
    }

    // MARK: - Badge Properties

    private var badgeText: String {
        // If transcoded, show transcoded format
        if let transcoding = transcodingQuality, transcoding != .original {
            return transcoding.formatDisplayName
        }

        // Otherwise show original quality
        switch track.qualityTier {
        case .hiRes:
            return "Hi-Res"
        case .lossless:
            return "Lossless"
        case .dsd:
            return "DSD"
        case .lossy:
            return track.suffix?.uppercased() ?? "Audio"
        }
    }

    private var badgeColor: Color {
        // If transcoded, use a distinct color (orange/amber)
        if let transcoding = transcodingQuality, transcoding != .original {
            return Color.orange
        }

        // Otherwise use original quality colors
        switch track.qualityTier {
        case .hiRes:
            return Color.Quality.hiRes
        case .lossless:
            return Color.Quality.lossless
        case .dsd:
            return Color.Quality.dsd
        case .lossy:
            return Color.Quality.standard
        }
    }

    private var specsString: String? {
        // If transcoded, show transcoded specs
        if let transcoding = transcodingQuality, transcoding != .original {
            if let bitRate = transcoding.maxBitRate, let format = transcoding.format {
                return "\(format.uppercased()) \(bitRate) kbps"
            }
        }

        // Otherwise show original specs
        var parts: [String] = []

        if let sampleRate = track.formattedSampleRate {
            parts.append(sampleRate)
        }

        if let bitDepth = track.formattedBitDepth {
            parts.append(bitDepth)
        }

        // Show bitrate for lossy
        if track.qualityTier == .lossy, let bitRate = track.formattedBitRate {
            parts.append(bitRate)
        }

        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }
}

// MARK: - Quality Tier Badge (Simplified)
struct QualityTierBadge: View {
    let track: Track
    var transcodingQuality: TranscodingQuality? = nil

    var body: some View {
        // Show if non-lossy quality OR if transcoded
        if track.qualityTier != .lossy || (transcodingQuality != nil && transcodingQuality != .original) {
            QualityBadge(track: track, showSpecs: false, size: .small, transcodingQuality: transcodingQuality)
        }
    }
}

// MARK: - Format Display (Text Only)
struct FormatDisplay: View {
    let track: Track

    var body: some View {
        Text(track.qualitySpecs)
            .font(.Navi.mono)
            .foregroundColor(Color.Text.tertiary)
    }
}

// MARK: - Enhanced Signal Path Display (Roon-style)
struct EnhancedSignalPathView: View {
    let track: Track
    let outputDevice: String
    let isShuffleMode: Bool
    let isAlbumPlayback: Bool
    let transcodingQuality: TranscodingQuality?
    @State private var isExpanded = false

    init(
        track: Track,
        outputDevice: String = "Device",
        isShuffleMode: Bool = false,
        isAlbumPlayback: Bool = false,
        transcodingQuality: TranscodingQuality? = nil
    ) {
        self.track = track
        self.outputDevice = outputDevice
        self.isShuffleMode = isShuffleMode
        self.isAlbumPlayback = isAlbumPlayback
        self.transcodingQuality = transcodingQuality
    }

    private var signalPath: SignalPath {
        SignalPath.build(
            from: track,
            outputDevice: outputDevice,
            isShuffleMode: isShuffleMode,
            isAlbumPlayback: isAlbumPlayback,
            transcodingQuality: transcodingQuality
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with quality indicator
            signalPathHeader

            // Expanded signal path detail
            if isExpanded {
                signalPathDetail
                    .padding(.top, Spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.md)
        .background(Color.Background.surface)
        .cornerRadius(CornerRadius.md)
        .animation(.Navi.smooth, value: isExpanded)
    }

    private var signalPathHeader: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: Spacing.sm) {
                // Quality light indicator
                Circle()
                    .fill(signalPath.overallQuality.color)
                    .frame(width: 8, height: 8)
                    .shadow(color: signalPath.overallQuality.color.opacity(0.5), radius: 4)

                Text("Signal Path")
                    .font(.Navi.labelMedium)
                    .foregroundColor(Color.Text.primary)

                Text("•")
                    .foregroundColor(Color.Text.tertiary)

                Text(signalPath.overallQuality.label)
                    .font(.Navi.caption)
                    .foregroundColor(signalPath.overallQuality.color)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.Text.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    private var signalPathDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(signalPath.stages.enumerated()), id: \.element.id) { index, stage in
                HStack(alignment: .top, spacing: Spacing.md) {
                    // Quality indicator line
                    VStack(spacing: 0) {
                        if index > 0 {
                            Rectangle()
                                .fill(stage.quality.color.opacity(0.6))
                                .frame(width: 2, height: 8)
                        } else {
                            Color.clear.frame(width: 2, height: 8)
                        }

                        Circle()
                            .fill(stage.quality.color)
                            .frame(width: 10, height: 10)
                            .shadow(color: stage.quality.color.opacity(0.4), radius: 3)

                        if index < signalPath.stages.count - 1 {
                            Rectangle()
                                .fill(stage.quality.color.opacity(0.6))
                                .frame(width: 2, height: 20)
                        }
                    }
                    .frame(width: 16)

                    // Stage info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: stage.icon)
                                .font(.system(size: 11))
                                .foregroundColor(stage.quality.color)
                                .frame(width: 14)

                            Text(stage.name)
                                .font(.Navi.labelSmall)
                                .foregroundColor(Color.Text.primary)
                        }

                        Text(stage.detail)
                            .font(.Navi.monoSmall)
                            .foregroundColor(Color.Text.tertiary)

                        // Sample rate/bit depth if available
                        if let specs = stage.formattedSpecs {
                            Text(specs)
                                .font(.Navi.monoSmall)
                                .foregroundColor(Color.Text.tertiary.opacity(0.7))
                        }
                    }
                    .padding(.bottom, index < signalPath.stages.count - 1 ? Spacing.xs : 0)

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Legacy Signal Path Display (Horizontal)
struct SignalPathView: View {
    let track: Track
    let outputDevice: String

    init(track: Track, outputDevice: String = "Device") {
        self.track = track
        self.outputDevice = outputDevice
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Source
            SignalPathNode(
                icon: "waveform",
                title: "Source",
                detail: track.qualitySpecs
            )

            SignalPathArrow()

            // Replay Gain (if available)
            if let replayGain = track.replayGain?.effectiveGain {
                SignalPathNode(
                    icon: "slider.horizontal.3",
                    title: "Replay Gain",
                    detail: String(format: "%.1f dB", replayGain)
                )

                SignalPathArrow()
            }

            // Output
            SignalPathNode(
                icon: "hifispeaker",
                title: "Output",
                detail: outputDevice
            )
        }
        .padding(Spacing.md)
        .background(Color.Background.surface)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Signal Path Components
private struct SignalPathNode: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.Accent.cyan)

            Text(title)
                .font(.Navi.captionSmall)
                .foregroundColor(Color.Text.secondary)

            Text(detail)
                .font(.Navi.monoSmall)
                .foregroundColor(Color.Text.tertiary)
                .lineLimit(1)
        }
        .frame(minWidth: 60)
    }
}

private struct SignalPathArrow: View {
    var body: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 12))
            .foregroundColor(Color.Text.tertiary)
    }
}

// MARK: - Preview
#if DEBUG
struct QualityBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Hi-Res
            QualityBadge(
                track: .preview(suffix: "flac", sampleRate: 96000, bitDepth: 24),
                showSpecs: true
            )

            // Lossless
            QualityBadge(
                track: .preview(suffix: "flac", sampleRate: 44100, bitDepth: 16),
                showSpecs: true
            )

            // DSD
            QualityBadge(
                track: .preview(suffix: "dsf", sampleRate: 2822400, bitDepth: 1),
                showSpecs: true
            )

            // Lossy
            QualityBadge(
                track: .preview(suffix: "mp3", bitRate: 320),
                showSpecs: true
            )

            // Signal Path
            SignalPathView(
                track: .preview(suffix: "flac", sampleRate: 96000, bitDepth: 24),
                outputDevice: "AirPods Pro"
            )
        }
        .padding()
        .background(Color.Background.default)
        .preferredColorScheme(.dark)
    }
}

// Preview helper
extension Track {
    static func preview(
        suffix: String,
        sampleRate: Int? = nil,
        bitDepth: Int? = nil,
        bitRate: Int? = nil
    ) -> Track {
        Track(
            id: "preview",
            parent: nil,
            isDir: false,
            title: "Preview Track",
            album: "Preview Album",
            artist: "Preview Artist",
            track: 1,
            year: 2024,
            genre: "Electronic",
            coverArt: nil,
            size: nil,
            contentType: nil,
            suffix: suffix,
            duration: 240,
            bitRate: bitRate,
            path: nil,
            discNumber: 1,
            albumId: nil,
            artistId: nil,
            playCount: nil,
            starred: nil,
            userRating: nil,
            samplingRate: sampleRate,
            bitDepth: bitDepth,
            channelCount: 2,
            displayArtist: nil,
            displayComposer: nil,
            genres: nil,
            contributors: nil,
            replayGain: ReplayGain(trackGain: -3.2, albumGain: -2.8, trackPeak: 0.98, albumPeak: 0.99),
            musicBrainzId: nil,
            isrc: nil,
            lastfmListeners: 50000,
            lastfmPlaycount: 150000,
            bpm: nil,
            comment: nil,
            sortName: nil,
            mediaType: nil,
            played: nil,
            explicitStatus: nil
        )
    }
}
#endif
