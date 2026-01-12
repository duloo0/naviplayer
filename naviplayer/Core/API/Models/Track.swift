//
//  Track.swift
//  naviplayer
//
//  Track/Song model based on Subsonic Child response
//

import Foundation

// MARK: - Track Model
struct Track: Codable, Identifiable, Equatable, Hashable {
    // MARK: - Core Fields
    let id: String
    let parent: String?
    let isDir: Bool?
    let title: String
    let album: String?
    let artist: String?
    let track: Int?
    let year: Int?
    let genre: String?
    let coverArt: String?
    let size: Int64?
    let contentType: String?
    let suffix: String?
    let duration: Int?
    let bitRate: Int?
    let path: String?
    let discNumber: Int?
    let albumId: String?
    let artistId: String?

    // MARK: - User Data
    let playCount: Int64?
    let starred: String?
    let userRating: Int?

    // MARK: - OpenSubsonic Extensions (Quality)
    let samplingRate: Int?
    let bitDepth: Int?
    let channelCount: Int?

    // MARK: - OpenSubsonic Extensions (Metadata)
    let displayArtist: String?
    let displayComposer: String?
    let genres: [ItemGenre]?
    let contributors: [Contributor]?
    let replayGain: ReplayGain?
    let musicBrainzId: String?
    let isrc: String?

    // MARK: - Last.fm Popularity
    let lastfmListeners: Int64?
    let lastfmPlaycount: Int64?

    // MARK: - Additional Fields
    let bpm: Int?
    let comment: String?
    let sortName: String?
    let mediaType: String?
    let played: String?
    let explicitStatus: String?

    // MARK: - Computed Properties

    /// Formatted duration string (mm:ss or hh:mm:ss)
    var formattedDuration: String {
        guard let duration = duration else { return "--:--" }
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Duration in seconds as TimeInterval
    var durationInterval: TimeInterval {
        TimeInterval(duration ?? 0)
    }

    /// Display artist (prefers displayArtist over artist)
    var effectiveArtist: String {
        displayArtist ?? artist ?? "Unknown Artist"
    }

    /// Display album
    var effectiveAlbum: String {
        album ?? "Unknown Album"
    }

    /// Whether the track is starred/loved
    var isStarred: Bool {
        starred != nil
    }

    /// User rating (1-5, 0 if unrated)
    var rating: Int {
        userRating ?? 0
    }

    /// Whether this is a thumb-up rated track (5 stars)
    var isThumbUp: Bool {
        rating == 5
    }

    /// Whether this is a thumb-down rated track (1 star)
    var isThumbDown: Bool {
        rating == 1
    }
}

// MARK: - Supporting Types

struct ItemGenre: Codable, Equatable, Hashable {
    let name: String
}

struct Contributor: Codable, Equatable, Hashable {
    let role: String
    let subRole: String?
    let artist: ContributorArtist
}

struct ContributorArtist: Codable, Equatable, Hashable {
    let id: String
    let name: String
}

struct ReplayGain: Codable, Equatable, Hashable {
    let trackGain: Double?
    let albumGain: Double?
    let trackPeak: Double?
    let albumPeak: Double?

    /// Effective gain value (prefers track, falls back to album)
    var effectiveGain: Double? {
        trackGain ?? albumGain
    }
}

// MARK: - Quality Tier
extension Track {
    enum QualityTier {
        case hiRes
        case lossless
        case dsd
        case lossy

        var displayName: String {
            switch self {
            case .hiRes: return "Hi-Res"
            case .lossless: return "Lossless"
            case .dsd: return "DSD"
            case .lossy: return "Audio"
            }
        }

        func displayName(withSuffix suffix: String?) -> String {
            switch self {
            case .lossy: return suffix?.uppercased() ?? "Audio"
            default: return displayName
            }
        }
    }

    private static let losslessFormats = ["flac", "alac", "wav", "aiff", "ape", "wv", "tta"]
    private static let dsdFormats = ["dsf", "dff", "dsd"]
    private static let lossyFormats = ["mp3", "aac", "m4a", "ogg", "opus", "wma"]

    /// Determine quality tier
    var qualityTier: QualityTier {
        let ext = suffix?.lowercased() ?? ""

        if Self.dsdFormats.contains(ext) {
            return .dsd
        }

        let isHiRes = (samplingRate ?? 0) > 44100 || (bitDepth ?? 0) > 16
        let isLossless = Self.losslessFormats.contains(ext)

        if isHiRes {
            return .hiRes
        } else if isLossless {
            return .lossless
        } else {
            return .lossy
        }
    }

    /// Whether this is a hi-res track
    var isHiRes: Bool {
        qualityTier == .hiRes
    }

    /// Whether this is a lossless track
    var isLossless: Bool {
        qualityTier == .lossless || qualityTier == .hiRes
    }

    /// Formatted sample rate string (e.g., "96kHz")
    var formattedSampleRate: String? {
        guard let rate = samplingRate, rate > 0 else { return nil }
        if rate >= 1000 {
            let khz = Double(rate) / 1000.0
            if khz.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(khz))kHz"
            } else {
                return String(format: "%.1fkHz", khz)
            }
        }
        return "\(rate)Hz"
    }

    /// Formatted bit depth string (e.g., "24-bit")
    var formattedBitDepth: String? {
        guard let depth = bitDepth, depth > 0 else { return nil }
        return "\(depth)-bit"
    }

    /// Formatted bitrate string (e.g., "320kbps")
    var formattedBitRate: String? {
        guard let rate = bitRate, rate > 0 else { return nil }
        if rate >= 1000 {
            return "\(rate / 1000)kbps"
        }
        return "\(rate)bps"
    }

    /// Full quality specs string (e.g., "FLAC 96kHz / 24-bit")
    var qualitySpecs: String {
        var parts: [String] = []

        if let suffix = suffix?.uppercased() {
            parts.append(suffix)
        }

        if let sampleRate = formattedSampleRate {
            parts.append(sampleRate)
        }

        if let bitDepth = formattedBitDepth {
            parts.append(bitDepth)
        }

        // Show bitrate only for lossy formats
        if qualityTier == .lossy, let bitRate = formattedBitRate {
            parts.append(bitRate)
        }

        return parts.joined(separator: " / ")
    }
}

// MARK: - Songs Response (for getRandomSongs, getLibraryRadio, etc.)
struct SongsResponse: Codable {
    let randomSongs: SongList?
    let song: Track?

    struct SongList: Codable {
        let song: [Track]?
    }

    var songs: [Track] {
        randomSongs?.song ?? []
    }
}
