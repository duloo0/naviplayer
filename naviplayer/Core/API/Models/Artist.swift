//
//  Artist.swift
//  naviplayer
//
//  Artist model based on Subsonic ArtistID3 response
//

import Foundation

// MARK: - Artist Model
struct Artist: Codable, Identifiable, Equatable, Hashable {
    // MARK: - Core Fields
    let id: String
    let name: String
    let coverArt: String?
    let albumCount: Int?
    let artistImageUrl: String?

    // MARK: - User Data
    let starred: String?
    let userRating: Int?

    // MARK: - OpenSubsonic Extensions
    let sortName: String?
    let musicBrainzId: String?
    let roles: [String]?

    // MARK: - Last.fm Popularity
    let lastfmListeners: Int64?
    let lastfmPlaycount: Int64?

    // MARK: - Albums (when fetched with getArtist)
    let album: [Album]?

    // MARK: - Computed Properties

    /// Display name
    var displayName: String {
        name
    }

    /// Whether the artist is starred/loved
    var isStarred: Bool {
        starred != nil
    }

    /// Album count string
    var albumCountString: String {
        guard let count = albumCount else { return "" }
        return count == 1 ? "1 album" : "\(count) albums"
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

    /// All albums by this artist
    var albums: [Album] {
        album ?? []
    }

    /// Best image URL (prefers artistImageUrl, falls back to coverArt)
    var imageURL: String? {
        artistImageUrl ?? coverArt
    }
}

// MARK: - Artist Info (from getArtistInfo2)
struct ArtistInfo: Codable, Equatable {
    let biography: String?
    let musicBrainzId: String?
    let lastFmUrl: String?
    let smallImageUrl: String?
    let mediumImageUrl: String?
    let largeImageUrl: String?
    let similarArtist: [Artist]?

    /// Best available image URL
    var bestImageURL: String? {
        largeImageUrl ?? mediumImageUrl ?? smallImageUrl
    }

    /// Similar artists list
    var similarArtists: [Artist] {
        similarArtist ?? []
    }

    /// Cleaned biography (removes HTML tags)
    var cleanBiography: String? {
        guard let bio = biography else { return nil }
        // Basic HTML tag removal
        return bio
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Artists Response (from getArtists)
struct ArtistsResponse: Codable {
    let artists: ArtistsIndex?

    struct ArtistsIndex: Codable {
        let index: [ArtistIndex]?
        let ignoredArticles: String?
    }

    var allArtists: [Artist] {
        artists?.index?.flatMap { $0.artist ?? [] } ?? []
    }
}

struct ArtistIndex: Codable {
    let name: String // Index letter (A, B, C, etc.)
    let artist: [Artist]?
}

// MARK: - Single Artist Response
struct ArtistResponse: Codable {
    let artist: Artist?
}

// MARK: - Artist Info Response
struct ArtistInfoResponse: Codable {
    let artistInfo2: ArtistInfo?
}
