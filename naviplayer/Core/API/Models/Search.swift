//
//  Search.swift
//  naviplayer
//
//  Search model based on Subsonic search3 response
//

import Foundation

// MARK: - Search Result
struct SearchResult: Codable, Equatable {
    let artist: [Artist]?
    let album: [Album]?
    let song: [Track]?

    /// All found artists
    var artists: [Artist] {
        artist ?? []
    }

    /// All found albums
    var albums: [Album] {
        album ?? []
    }

    /// All found songs
    var songs: [Track] {
        song ?? []
    }

    /// Whether the search returned any results
    var isEmpty: Bool {
        artists.isEmpty && albums.isEmpty && songs.isEmpty
    }

    /// Total result count
    var totalCount: Int {
        artists.count + albums.count + songs.count
    }
}

// MARK: - Search Response
struct SearchResponse: Codable {
    let searchResult3: SearchResult?

    var result: SearchResult {
        searchResult3 ?? SearchResult(artist: nil, album: nil, song: nil)
    }
}

// MARK: - Search Parameters
struct SearchParameters {
    let query: String
    let artistCount: Int
    let albumCount: Int
    let songCount: Int
    let artistOffset: Int
    let albumOffset: Int
    let songOffset: Int
    let musicFolderId: String?

    init(
        query: String,
        artistCount: Int = 20,
        albumCount: Int = 20,
        songCount: Int = 20,
        artistOffset: Int = 0,
        albumOffset: Int = 0,
        songOffset: Int = 0,
        musicFolderId: String? = nil
    ) {
        self.query = query
        self.artistCount = artistCount
        self.albumCount = albumCount
        self.songCount = songCount
        self.artistOffset = artistOffset
        self.albumOffset = albumOffset
        self.songOffset = songOffset
        self.musicFolderId = musicFolderId
    }

    /// Convert to API parameters dictionary
    var parameters: [String: String] {
        var params: [String: String] = [
            "query": query,
            "artistCount": String(artistCount),
            "albumCount": String(albumCount),
            "songCount": String(songCount)
        ]

        if artistOffset > 0 {
            params["artistOffset"] = String(artistOffset)
        }
        if albumOffset > 0 {
            params["albumOffset"] = String(albumOffset)
        }
        if songOffset > 0 {
            params["songOffset"] = String(songOffset)
        }
        if let folderId = musicFolderId {
            params["musicFolderId"] = folderId
        }

        return params
    }
}
