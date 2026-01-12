//
//  PlayQueue.swift
//  naviplayer
//
//  Play queue model for queue persistence
//

import Foundation

// MARK: - Play Queue
struct PlayQueue: Codable, Equatable {
    let entry: [Track]?
    let current: String? // ID of current track
    let position: Int64? // Position in current track (ms)
    let username: String?
    let changed: String?
    let changedBy: String?

    /// All tracks in the queue
    var tracks: [Track] {
        entry ?? []
    }

    /// Current track index
    var currentIndex: Int? {
        guard let currentId = current else { return nil }
        return tracks.firstIndex { $0.id == currentId }
    }

    /// Current track
    var currentTrack: Track? {
        guard let index = currentIndex else { return nil }
        return tracks[index]
    }

    /// Position in current track as TimeInterval
    var currentPosition: TimeInterval? {
        guard let pos = position else { return nil }
        return TimeInterval(pos) / 1000.0
    }
}

// MARK: - Play Queue Response
struct PlayQueueResponse: Codable {
    let playQueue: PlayQueue?
}

// MARK: - Save Queue Parameters
struct SaveQueueParameters {
    let trackIds: [String]
    let currentId: String?
    let position: Int64?

    init(trackIds: [String], currentId: String? = nil, position: TimeInterval? = nil) {
        self.trackIds = trackIds
        self.currentId = currentId
        self.position = position.map { Int64($0 * 1000) }
    }

    /// Convert to API parameters
    var parameters: [String: String] {
        var params: [String: String] = [:]

        // Add all track IDs (Subsonic uses multiple 'id' params)
        // Note: This needs special handling in the API client
        if let currentId = currentId {
            params["current"] = currentId
        }
        if let position = position {
            params["position"] = String(position)
        }

        return params
    }

    /// Track IDs for the request (needs to be added as multiple 'id' params)
    var idParameters: [(String, String)] {
        trackIds.map { ("id", $0) }
    }
}
