//
//  Album.swift
//  naviplayer
//
//  Album model based on Subsonic AlbumID3 response
//

import Foundation

// MARK: - Album Model
struct Album: Codable, Identifiable, Equatable, Hashable {
    // MARK: - Core Fields
    let id: String
    let name: String
    let artist: String?
    let artistId: String?
    let coverArt: String?
    let songCount: Int?
    let duration: Int?
    let playCount: Int64?
    let created: String?
    let year: Int?
    let genre: String?

    // MARK: - User Data
    let starred: String?
    let userRating: Int?

    // MARK: - OpenSubsonic Extensions
    let sortName: String?
    let musicBrainzId: String?
    let isCompilation: Bool?
    let displayArtist: String?
    let releaseDate: ReleaseDate?
    let originalReleaseDate: ReleaseDate?
    let releaseTypes: [String]?
    let moods: [String]?
    let genres: [ItemGenre]?
    let recordLabels: [RecordLabel]?
    let discTitles: [DiscTitle]?
    let explicitStatus: String?
    let version: String?

    // MARK: - Last.fm Popularity
    let lastfmListeners: Int64?
    let lastfmPlaycount: Int64?

    // MARK: - Songs (when fetched with getAlbum)
    let song: [Track]?

    // MARK: - Computed Properties

    /// Display name (prefers sortName for display)
    var displayName: String {
        name
    }

    /// Display artist (prefers displayArtist over artist)
    var effectiveArtist: String {
        displayArtist ?? artist ?? "Unknown Artist"
    }

    /// Formatted duration string
    var formattedDuration: String {
        guard let duration = duration else { return "" }
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }

    /// Whether the album is starred/loved
    var isStarred: Bool {
        starred != nil
    }

    /// Year string
    var yearString: String? {
        guard let year = year, year > 0 else { return nil }
        return String(year)
    }

    /// Song count string
    var songCountString: String {
        guard let count = songCount else { return "" }
        return count == 1 ? "1 song" : "\(count) songs"
    }

    /// Formatted play count
    var formattedPlayCount: String? {
        guard let count = playCount, count > 0 else { return nil }
        if count >= 1_000_000 {
            return String(format: "%.1fM plays", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK plays", Double(count) / 1_000)
        }
        return "\(count) plays"
    }

    /// Formatted Last.fm listeners
    var formattedListeners: String? {
        guard let listeners = lastfmListeners, listeners > 0 else { return nil }
        if listeners >= 1_000_000 {
            return String(format: "%.1fM listeners", Double(listeners) / 1_000_000)
        } else if listeners >= 1_000 {
            return String(format: "%.1fK listeners", Double(listeners) / 1_000)
        }
        return "\(listeners) listeners"
    }

    /// All tracks on this album
    var tracks: [Track] {
        song ?? []
    }
}

// MARK: - Supporting Types

struct ReleaseDate: Codable, Equatable, Hashable {
    let year: Int?
    let month: Int?
    let day: Int?

    var formatted: String? {
        guard let year = year else { return nil }

        if let month = month, let day = day {
            return String(format: "%04d-%02d-%02d", year, month, day)
        } else if let month = month {
            return String(format: "%04d-%02d", year, month)
        }
        return String(year)
    }
}

struct RecordLabel: Codable, Equatable, Hashable {
    let name: String
}

struct DiscTitle: Codable, Equatable, Hashable {
    let disc: Int
    let title: String
}

// MARK: - Album List Response
struct AlbumListResponse: Codable {
    let albumList2: AlbumList?

    struct AlbumList: Codable {
        let album: [Album]?
    }

    var albums: [Album] {
        albumList2?.album ?? []
    }
}

// MARK: - Single Album Response
struct AlbumResponse: Codable {
    let album: Album?
}

// MARK: - Album List Types
enum AlbumListType: String, CaseIterable {
    case newest
    case recent
    case frequent
    case random
    case alphabeticalByName
    case alphabeticalByArtist
    case starred
    case highest
    case byGenre
    case byYear
}
