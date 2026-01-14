//
//  SubsonicAuth.swift
//  naviplayer
//
//  Subsonic API authentication using MD5 token + salt
//

import Foundation
import CryptoKit

// MARK: - Server Configuration
struct ServerConfiguration: Codable, Equatable {
    let url: URL
    let username: String
    let token: String
    let salt: String

    /// API version to use
    static let apiVersion = "1.16.1"
    /// Client identifier
    static let clientName = "NaviPlayer"

    /// Create configuration from password (generates token and salt)
    static func create(url: URL, username: String, password: String) -> ServerConfiguration {
        let salt = generateSalt()
        let token = generateToken(password: password, salt: salt)
        return ServerConfiguration(url: url, username: username, token: token, salt: salt)
    }

    /// Generate a random salt string
    private static func generateSalt() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<12).map { _ in characters.randomElement()! })
    }

    /// Generate MD5 token from password + salt
    private static func generateToken(password: String, salt: String) -> String {
        let data = Data((password + salt).utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Request Builder
extension ServerConfiguration {
    /// Build authenticated URL for API endpoint
    func buildURL(endpoint: String, parameters: [String: String] = [:]) -> URL? {
        guard var components = URLComponents(url: url.appendingPathComponent("rest/\(endpoint)"), resolvingAgainstBaseURL: true) else {
            return nil
        }

        var queryItems = [
            URLQueryItem(name: "u", value: username),
            URLQueryItem(name: "t", value: token),
            URLQueryItem(name: "s", value: salt),
            URLQueryItem(name: "v", value: Self.apiVersion),
            URLQueryItem(name: "c", value: Self.clientName),
            URLQueryItem(name: "f", value: "json")
        ]

        for (key, value) in parameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        components.queryItems = queryItems
        return components.url
    }

    /// Build stream URL for media playback
    func streamURL(id: String, maxBitRate: Int? = nil, format: String? = nil) -> URL? {
        var params: [String: String] = ["id": id]
        if let maxBitRate = maxBitRate {
            params["maxBitRate"] = String(maxBitRate)
        }
        if let format = format {
            params["format"] = format
        }
        // Add estimateContentLength when transcoding - required for iOS AVPlayer
        // Without Content-Length, AVPlayer fails with "Cannot Open" errors
        if maxBitRate != nil || format != nil {
            params["estimateContentLength"] = "true"
        }
        return buildURL(endpoint: "stream", parameters: params)
    }

    /// Build cover art URL
    func coverArtURL(id: String, size: Int? = nil) -> URL? {
        var params: [String: String] = ["id": id]
        if let size = size {
            params["size"] = String(size)
        }
        return buildURL(endpoint: "getCoverArt", parameters: params)
    }
}

// MARK: - Persistence
extension ServerConfiguration {
    private static let storageKey = "NaviPlayer.ServerConfiguration"

    /// Save configuration to UserDefaults
    func save() throws {
        let data = try JSONEncoder().encode(self)
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    /// Load configuration from UserDefaults
    static func load() -> ServerConfiguration? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }
        return try? JSONDecoder().decode(ServerConfiguration.self, from: data)
    }

    /// Clear saved configuration
    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
