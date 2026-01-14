//
//  Lyrics.swift
//  naviplayer
//
//  Lyrics model based on Subsonic getLyricsBySongId response
//

import Foundation

// MARK: - Structured Lyrics
struct StructuredLyrics: Codable, Equatable {
    let displayArtist: String?
    let displayTitle: String?
    let lang: String?
    let synced: Bool
    let offset: Int?
    let line: [LyricLine]?

    /// All lyric lines
    var lines: [LyricLine] {
        line ?? []
    }

    /// Whether these are synced (timed) lyrics
    var isSynced: Bool {
        synced && lines.contains { $0.start != nil }
    }

    /// Plain text version of lyrics
    var plainText: String {
        lines.map { $0.value }.joined(separator: "\n")
    }
}

// MARK: - Lyric Line
struct LyricLine: Codable, Equatable, Identifiable {
    let start: Int64? // Timestamp in milliseconds
    let value: String

    var id: String {
        "\(start ?? 0):\(value)"
    }

    /// Start time as TimeInterval (seconds)
    var startTime: TimeInterval? {
        guard let start = start else { return nil }
        return TimeInterval(start) / 1000.0
    }

    /// Whether this line is empty/instrumental
    var isInstrumental: Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        value.lowercased().contains("[instrumental]") ||
        value.lowercased().contains("♪")
    }
}

// MARK: - Lyrics Response
struct LyricsResponse: Codable {
    let lyricsList: LyricsList?

    struct LyricsList: Codable {
        let structuredLyrics: [StructuredLyrics]?
    }

    /// All available lyrics
    var lyrics: [StructuredLyrics] {
        lyricsList?.structuredLyrics ?? []
    }

    /// Best available lyrics (prefer synced over unsynced)
    var bestLyrics: StructuredLyrics? {
        // Prefer synced lyrics
        if let synced = lyrics.first(where: { $0.isSynced }) {
            return synced
        }
        // Fall back to any lyrics
        return lyrics.first
    }
}

// MARK: - Legacy Lyrics Response (from getLyrics)
struct LegacyLyricsResponse: Codable {
    let lyrics: LegacyLyrics?

    struct LegacyLyrics: Codable {
        let artist: String?
        let title: String?
        let value: String?
    }
}

// MARK: - Lyrics Display Helper
struct LyricsDisplay {
    let lyrics: StructuredLyrics
    let currentTime: TimeInterval

    /// Index of the currently active line
    var activeLineIndex: Int? {
        guard lyrics.isSynced else { return nil }

        for (index, line) in lyrics.lines.enumerated().reversed() {
            if let startTime = line.startTime, currentTime >= startTime {
                return index
            }
        }
        return nil
    }

    /// The currently active line
    var activeLine: LyricLine? {
        guard let index = activeLineIndex else { return nil }
        return lyrics.lines[index]
    }

    /// Check if a line is active at current time
    func isLineActive(_ line: LyricLine) -> Bool {
        guard line.startTime != nil else { return false }
        guard let activeIndex = activeLineIndex else { return false }
        guard let lineIndex = lyrics.lines.firstIndex(where: { $0.id == line.id }) else { return false }
        return lineIndex == activeIndex
    }


    /// Check if a line has already passed
    func isLinePassed(_ line: LyricLine) -> Bool {
        guard let lineStart = line.startTime else { return false }
        return currentTime > lineStart && !isLineActive(line)
    }
}
