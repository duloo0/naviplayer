//
//  SubsonicClient.swift
//  naviplayer
//
//  Main Subsonic API client
//

import Foundation
import Combine

// MARK: - API Errors
enum SubsonicAPIError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(SubsonicError)
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Server not configured"
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let error):
            return error.message
        case .unexpectedResponse:
            return "Unexpected server response"
        }
    }
}

// MARK: - Subsonic Client
@MainActor
final class SubsonicClient: ObservableObject {
    // MARK: - Properties
    @Published private(set) var configuration: ServerConfiguration?
    @Published private(set) var isConnected = false

    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: - Singleton
    static let shared = SubsonicClient()

    // MARK: - Initialization
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Load saved configuration
        if let saved = ServerConfiguration.load() {
            self.configuration = saved
            self.isConnected = true
        }
    }

    /// Verify saved connection is still valid (call on app launch)
    func verifyConnection() async {
        guard configuration != nil else { return }

        do {
            try await ping()
            isConnected = true
        } catch {
            // Connection failed - user will need to re-login
            print("Saved connection failed verification: \(error)")
            isConnected = false
        }
    }

    // MARK: - Configuration
    func configure(url: URL, username: String, password: String) async throws {
        let config = ServerConfiguration.create(url: url, username: username, password: password)

        // Test connection
        let tempConfig = configuration
        configuration = config

        do {
            try await ping()
            try config.save()
            isConnected = true
        } catch {
            configuration = tempConfig
            throw error
        }
    }

    func disconnect() {
        ServerConfiguration.clear()
        configuration = nil
        isConnected = false
    }

    // MARK: - Generic Request
    private func request<T: Codable>(
        endpoint: String,
        parameters: [String: String] = [:]
    ) async throws -> T {
        guard let config = configuration else {
            throw SubsonicAPIError.notConfigured
        }

        guard let url = config.buildURL(endpoint: endpoint, parameters: parameters) else {
            throw SubsonicAPIError.invalidURL
        }

        do {
            let (data, _) = try await session.data(from: url)

            // Debug: Print raw response
            #if DEBUG
            if let json = String(data: data, encoding: .utf8) {
                print("[\(endpoint)] Response: \(json.prefix(500))")
            }
            #endif

            let response = try decoder.decode(SubsonicResponse<T>.self, from: data)

            if let error = response.subsonicResponse.error {
                throw SubsonicAPIError.serverError(error)
            }

            guard let data = response.subsonicResponse.data else {
                // For endpoints that return no data (like ping), return empty
                if T.self == EmptyResponse.self {
                    return EmptyResponse() as! T
                }
                throw SubsonicAPIError.unexpectedResponse
            }

            return data
        } catch let error as SubsonicAPIError {
            throw error
        } catch let error as DecodingError {
            throw SubsonicAPIError.decodingError(error)
        } catch {
            throw SubsonicAPIError.networkError(error)
        }
    }

    // MARK: - Request with multiple ID parameters
    private func requestWithIds<T: Codable>(
        endpoint: String,
        ids: [String],
        parameters: [String: String] = [:]
    ) async throws -> T {
        guard let config = configuration else {
            throw SubsonicAPIError.notConfigured
        }

        guard var components = URLComponents(
            url: config.url.appendingPathComponent("rest/\(endpoint)"),
            resolvingAgainstBaseURL: true
        ) else {
            throw SubsonicAPIError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "u", value: config.username),
            URLQueryItem(name: "t", value: config.token),
            URLQueryItem(name: "s", value: config.salt),
            URLQueryItem(name: "v", value: ServerConfiguration.apiVersion),
            URLQueryItem(name: "c", value: ServerConfiguration.clientName),
            URLQueryItem(name: "f", value: "json")
        ]

        // Add multiple id parameters
        for id in ids {
            queryItems.append(URLQueryItem(name: "id", value: id))
        }

        // Add other parameters
        for (key, value) in parameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw SubsonicAPIError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(SubsonicResponse<T>.self, from: data)

        if let error = response.subsonicResponse.error {
            throw SubsonicAPIError.serverError(error)
        }

        guard let data = response.subsonicResponse.data else {
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            throw SubsonicAPIError.unexpectedResponse
        }

        return data
    }

    // MARK: - System Endpoints

    /// Test connection to server
    func ping() async throws {
        let _: EmptyResponse = try await request(endpoint: "ping")
    }

    // MARK: - Library Radio

    /// Get smart weighted radio songs
    func getLibraryRadio(
        count: Int = 50,
        genre: String? = nil,
        fromYear: Int? = nil,
        toYear: Int? = nil
    ) async throws -> [Track] {
        var params: [String: String] = ["count": String(count)]
        if let genre = genre { params["genre"] = genre }
        if let fromYear = fromYear { params["fromYear"] = String(fromYear) }
        if let toYear = toYear { params["toYear"] = String(toYear) }

        let response: SongsResponse = try await request(endpoint: "getLibraryRadio", parameters: params)
        return response.songs
    }

    // MARK: - Rating

    /// Set rating for a song/album/artist (1-5, or 0 to remove)
    func setRating(id: String, rating: Int) async throws {
        let _: EmptyResponse = try await request(
            endpoint: "setRating",
            parameters: ["id": id, "rating": String(rating)]
        )
    }

    /// Star an item (song/album/artist)
    func star(id: String) async throws {
        let _: EmptyResponse = try await request(endpoint: "star", parameters: ["id": id])
    }

    /// Unstar an item
    func unstar(id: String) async throws {
        let _: EmptyResponse = try await request(endpoint: "unstar", parameters: ["id": id])
    }

    // MARK: - Albums

    /// Get album list
    func getAlbumList(
        type: AlbumListType,
        size: Int = 20,
        offset: Int = 0,
        genre: String? = nil,
        fromYear: Int? = nil,
        toYear: Int? = nil
    ) async throws -> [Album] {
        var params: [String: String] = [
            "type": type.rawValue,
            "size": String(size),
            "offset": String(offset)
        ]
        if let genre = genre { params["genre"] = genre }
        if let fromYear = fromYear { params["fromYear"] = String(fromYear) }
        if let toYear = toYear { params["toYear"] = String(toYear) }

        let response: AlbumListResponse = try await request(endpoint: "getAlbumList2", parameters: params)
        return response.albums
    }

    /// Get single album with tracks
    func getAlbum(id: String) async throws -> Album {
        let response: AlbumResponse = try await request(endpoint: "getAlbum", parameters: ["id": id])
        guard let album = response.album else {
            throw SubsonicAPIError.unexpectedResponse
        }
        return album
    }

    // MARK: - Artists

    /// Get all artists
    func getArtists() async throws -> [Artist] {
        let response: ArtistsResponse = try await request(endpoint: "getArtists")
        return response.allArtists
    }

    /// Get single artist with albums
    func getArtist(id: String) async throws -> Artist {
        let response: ArtistResponse = try await request(endpoint: "getArtist", parameters: ["id": id])
        guard let artist = response.artist else {
            throw SubsonicAPIError.unexpectedResponse
        }
        return artist
    }

    /// Get artist info (biography, similar artists)
    func getArtistInfo(id: String, count: Int = 10) async throws -> ArtistInfo {
        let response: ArtistInfoResponse = try await request(
            endpoint: "getArtistInfo2",
            parameters: ["id": id, "count": String(count)]
        )
        guard let info = response.artistInfo2 else {
            throw SubsonicAPIError.unexpectedResponse
        }
        return info
    }

    // MARK: - Songs

    /// Get single song
    func getSong(id: String) async throws -> Track {
        let response: SongsResponse = try await request(endpoint: "getSong", parameters: ["id": id])
        guard let song = response.song else {
            throw SubsonicAPIError.unexpectedResponse
        }
        return song
    }

    /// Get random songs
    func getRandomSongs(
        count: Int = 50,
        genre: String? = nil,
        fromYear: Int? = nil,
        toYear: Int? = nil
    ) async throws -> [Track] {
        var params: [String: String] = ["size": String(count)]
        if let genre = genre { params["genre"] = genre }
        if let fromYear = fromYear { params["fromYear"] = String(fromYear) }
        if let toYear = toYear { params["toYear"] = String(toYear) }

        let response: SongsResponse = try await request(endpoint: "getRandomSongs", parameters: params)
        return response.songs
    }

    // MARK: - Lyrics

    /// Get synced lyrics by song ID
    func getLyrics(songId: String) async throws -> StructuredLyrics? {
        let response: LyricsResponse = try await request(
            endpoint: "getLyricsBySongId",
            parameters: ["id": songId]
        )
        return response.bestLyrics
    }

    // MARK: - Search

    /// Search for artists, albums, and songs
    func search(_ params: SearchParameters) async throws -> SearchResult {
        let response: SearchResponse = try await request(endpoint: "search3", parameters: params.parameters)
        return response.result
    }

    /// Quick search convenience method
    func search(query: String) async throws -> SearchResult {
        try await search(SearchParameters(query: query))
    }

    // MARK: - Play Queue

    /// Get saved play queue
    func getPlayQueue() async throws -> PlayQueue? {
        let response: PlayQueueResponse = try await request(endpoint: "getPlayQueue")
        return response.playQueue
    }

    /// Save play queue
    func savePlayQueue(trackIds: [String], currentId: String? = nil, position: TimeInterval? = nil) async throws {
        var params: [String: String] = [:]
        if let currentId = currentId {
            params["current"] = currentId
        }
        if let position = position {
            params["position"] = String(Int64(position * 1000))
        }

        let _: EmptyResponse = try await requestWithIds(endpoint: "savePlayQueue", ids: trackIds, parameters: params)
    }

    // MARK: - Scrobbling

    /// Scrobble a song (submit play event)
    func scrobble(id: String, time: Date? = nil, submission: Bool = true) async throws {
        var params: [String: String] = ["id": id, "submission": String(submission)]
        if let time = time {
            params["time"] = String(Int64(time.timeIntervalSince1970 * 1000))
        }

        let _: EmptyResponse = try await request(endpoint: "scrobble", parameters: params)
    }

    // MARK: - URL Helpers

    /// Get stream URL for a track
    func streamURL(for track: Track, maxBitRate: Int? = nil, format: String? = nil) -> URL? {
        configuration?.streamURL(id: track.id, maxBitRate: maxBitRate, format: format)
    }

    /// Get cover art URL
    func coverArtURL(for id: String?, size: Int? = nil) -> URL? {
        guard let id = id else { return nil }
        return configuration?.coverArtURL(id: id, size: size)
    }
}
