//
//  Playlist.swift
//  naviplayer
//
//  Playlist model based on Subsonic/Navidrome API response
//

import Foundation

// MARK: - Playlist Model
struct Playlist: Codable, Identifiable, Equatable, Hashable {
    // MARK: - Core Fields
    let id: String
    let name: String
    let songCount: Int?
    let duration: Int?
    let created: String?
    let changed: String?
    let coverArt: String?
    let owner: String?
    let comment: String?

    // "public" is a Swift keyword, so use coding key
    private let `public`: Bool?

    // MARK: - Navidrome Smart Playlist Extensions
    let rules: SmartPlaylistRules?

    // MARK: - Tracks (when fetched with getPlaylist)
    let entry: [Track]?

    // MARK: - Computed Properties

    /// Whether this is a smart/dynamic playlist
    var isSmart: Bool {
        rules != nil
    }

    /// Whether the playlist is public
    var isPublic: Bool {
        `public` ?? false
    }

    /// All tracks in the playlist
    var tracks: [Track] {
        entry ?? []
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

    /// Track count display
    var trackCountDisplay: String {
        guard let count = songCount else { return "" }
        return count == 1 ? "1 track" : "\(count) tracks"
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, name, songCount, duration, created, changed
        case coverArt, owner, comment
        case `public` = "public"
        case rules, entry
    }
}

// MARK: - Smart Playlist Rules (Navidrome Extension)
struct SmartPlaylistRules: Codable, Equatable, Hashable {
    let limit: Int?
    let order: String?

    // Rule groups (AND/OR logic)
    let all: [PlaylistRule]?
    let any: [PlaylistRule]?

    var hasRules: Bool {
        (all?.isEmpty == false) || (any?.isEmpty == false)
    }

    var ruleCount: Int {
        (all?.count ?? 0) + (any?.count ?? 0)
    }
}

// MARK: - Individual Playlist Rule
struct PlaylistRule: Codable, Equatable, Hashable {
    let field: String
    let `operator`: String?
    let value: String?

    // Nested rules for complex conditions
    let all: [PlaylistRule]?
    let any: [PlaylistRule]?

    enum CodingKeys: String, CodingKey {
        case field
        case `operator` = "operator"
        case value
        case all, any
    }

    /// Human-readable description of the rule
    var description: String {
        let op = `operator` ?? "is"
        let val = value ?? ""

        switch field.lowercased() {
        case "genre":
            return "Genre \(op) \(val)"
        case "year":
            return "Year \(op) \(val)"
        case "rating":
            return "Rating \(op) \(val)"
        case "playcount":
            return "Play count \(op) \(val)"
        case "lastplayed":
            return "Last played \(op) \(val)"
        case "dateadded":
            return "Date added \(op) \(val)"
        case "loved":
            return "Loved tracks"
        default:
            return "\(field) \(op) \(val)"
        }
    }
}

// MARK: - API Response Types

struct PlaylistsResponse: Codable {
    let playlists: PlaylistsContainer?

    struct PlaylistsContainer: Codable {
        let playlist: [Playlist]?
    }

    var allPlaylists: [Playlist] {
        playlists?.playlist ?? []
    }
}

struct PlaylistResponse: Codable {
    let playlist: Playlist?
}
