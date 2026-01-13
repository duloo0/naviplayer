//
//  TrackDetailsView.swift
//  naviplayer
//
//  Track details sheet showing comprehensive metadata
//

import SwiftUI

struct TrackDetailsView: View {
    let track: Track
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Background.default
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Artwork section
                        artworkSection

                        // Basic Info
                        infoSection(title: "Track Information") {
                            detailRow(label: "Title", value: track.title)
                            detailRow(label: "Artist", value: track.effectiveArtist)
                            detailRow(label: "Album", value: track.effectiveAlbum)
                            if let year = track.year {
                                detailRow(label: "Year", value: "\(year)")
                            }
                            if let genre = track.genre {
                                detailRow(label: "Genre", value: genre)
                            }
                            if let track = track.track {
                                detailRow(label: "Track Number", value: "\(track)")
                            }
                            if let discNumber = track.discNumber {
                                detailRow(label: "Disc Number", value: "\(discNumber)")
                            }
                            detailRow(label: "Duration", value: track.formattedDuration)
                        }

                        // Audio Quality
                        infoSection(title: "Audio Quality") {
                            detailRow(label: "Format", value: track.suffix?.uppercased() ?? "Unknown")
                            detailRow(label: "Quality Tier", value: track.qualityTier.displayName)
                            if let sampleRate = track.formattedSampleRate {
                                detailRow(label: "Sample Rate", value: sampleRate)
                            }
                            if let bitDepth = track.formattedBitDepth {
                                detailRow(label: "Bit Depth", value: bitDepth)
                            }
                            if let bitRate = track.formattedBitRate {
                                detailRow(label: "Bitrate", value: bitRate)
                            }
                            if let channels = track.channelCount {
                                detailRow(label: "Channels", value: "\(channels)")
                            }
                        }

                        // File Info
                        infoSection(title: "File Information") {
                            if let path = track.path {
                                detailRow(label: "Path", value: path, isPath: true)
                            }
                            if let size = track.size {
                                detailRow(label: "File Size", value: formatFileSize(size))
                            }
                            if let contentType = track.contentType {
                                detailRow(label: "Content Type", value: contentType)
                            }
                        }

                        // Popularity (Last.fm)
                        if track.lastfmListeners != nil || track.lastfmPlaycount != nil {
                            infoSection(title: "Popularity (Last.fm)") {
                                if let listeners = track.lastfmListeners {
                                    detailRow(label: "Listeners", value: formatNumber(listeners))
                                }
                                if let playcount = track.lastfmPlaycount {
                                    detailRow(label: "Playcount", value: formatNumber(playcount))
                                }
                            }
                        }

                        // User Data
                        infoSection(title: "User Data") {
                            if let playCount = track.playCount {
                                detailRow(label: "Play Count", value: "\(playCount)")
                            }
                            detailRow(label: "Rating", value: ratingDisplay)
                            detailRow(label: "Starred", value: track.isStarred ? "Yes" : "No")
                        }

                        // IDs (for debugging/advanced users)
                        infoSection(title: "Identifiers") {
                            detailRow(label: "Track ID", value: track.id, isPath: true)
                            if let albumId = track.albumId {
                                detailRow(label: "Album ID", value: albumId, isPath: true)
                            }
                            if let artistId = track.artistId {
                                detailRow(label: "Artist ID", value: artistId, isPath: true)
                            }
                            if let musicBrainzId = track.musicBrainzId {
                                detailRow(label: "MusicBrainz ID", value: musicBrainzId, isPath: true)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Track Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.Accent.cyan)
                }
            }
        }
    }

    // MARK: - Artwork Section

    private var artworkSection: some View {
        HStack {
            Spacer()
            AsyncArtwork(
                url: SubsonicClient.shared.coverArtURL(for: track.coverArt, size: 200),
                size: 160,
                cornerRadius: 12
            )
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Section Builder

    private func infoSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.Text.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.Background.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Detail Row

    private func detailRow(label: String, value: String, isPath: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.Text.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color.Text.primary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(isPath ? nil : 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private var ratingDisplay: String {
        let rating = track.userRating ?? 0
        if rating == 0 {
            return "Not rated"
        } else if rating == 1 {
            return "👎 Thumbs Down"
        } else if rating == 5 {
            return "👍 Thumbs Up"
        } else {
            return "\(rating) stars"
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatNumber(_ number: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

#if DEBUG
struct TrackDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        TrackDetailsView(track: Track(
            id: "1",
            parent: nil,
            isDir: false,
            title: "Test Track",
            album: "Test Album",
            artist: "Test Artist",
            track: 1,
            year: 2024,
            genre: "Rock",
            coverArt: nil,
            size: 10485760,
            contentType: "audio/flac",
            suffix: "flac",
            duration: 240,
            bitRate: 1411,
            path: "/music/artist/album/track.flac",
            discNumber: 1,
            albumId: "album-1",
            artistId: "artist-1",
            playCount: 42,
            starred: nil,
            userRating: 5,
            samplingRate: 96000,
            bitDepth: 24,
            channelCount: 2,
            displayArtist: nil,
            displayComposer: nil,
            genres: nil,
            contributors: nil,
            replayGain: nil,
            musicBrainzId: "abc-123",
            isrc: nil,
            lastfmListeners: 1234567,
            lastfmPlaycount: 9876543,
            bpm: nil,
            comment: nil,
            sortName: nil,
            mediaType: nil,
            played: nil,
            explicitStatus: nil
        ))
        .preferredColorScheme(.dark)
    }
}
#endif
