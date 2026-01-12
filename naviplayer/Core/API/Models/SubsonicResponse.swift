//
//  SubsonicResponse.swift
//  naviplayer
//
//  Base Subsonic API response wrapper
//

import Foundation

// MARK: - Response Wrapper
struct SubsonicResponse<T: Codable>: Codable {
    let subsonicResponse: SubsonicResponseBody<T>

    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

struct SubsonicResponseBody<T: Codable>: Codable {
    let status: String
    let version: String
    let type: String?
    let serverVersion: String?
    let openSubsonic: Bool?
    let error: SubsonicError?

    // Generic data payload (different for each endpoint)
    let data: T?

    var isOk: Bool { status == "ok" }

    // Known keys to exclude when looking for data payload
    private static var knownKeys: Set<String> {
        ["status", "version", "type", "serverVersion", "openSubsonic", "error"]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        status = try container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "status")!)
        version = try container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "version")!)
        type = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "type")!)
        serverVersion = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "serverVersion")!)
        openSubsonic = try container.decodeIfPresent(Bool.self, forKey: DynamicCodingKeys(stringValue: "openSubsonic")!)
        error = try container.decodeIfPresent(SubsonicError.self, forKey: DynamicCodingKeys(stringValue: "error")!)

        // Decode data payload - T expects to decode from the same level
        // Use a new decoder call to let T decode its own keys
        do {
            data = try T(from: decoder)
        } catch {
            #if DEBUG
            print("SubsonicResponseBody: Failed to decode data payload (\(T.self)): \(error)")
            #endif
            data = nil
        }
    }
}

// MARK: - Dynamic Coding Keys
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - Error Response
struct SubsonicError: Codable, Error {
    let code: Int
    let message: String

    var localizedDescription: String { message }
}

// MARK: - Error Codes
extension SubsonicError {
    static let genericError = 0
    static let requiredParameterMissing = 10
    static let incompatibleVersion = 20
    static let incompatibleServerVersion = 30
    static let wrongCredentials = 40
    static let tokenAuthNotSupported = 41
    static let userNotAuthorized = 50
    static let trialExpired = 60
    static let notFound = 70
}

// MARK: - Empty Response (for endpoints that return no data)
struct EmptyResponse: Codable {}

// MARK: - Ping Response
struct PingResponse: Codable {
    // Ping has no additional data beyond the base response
}
