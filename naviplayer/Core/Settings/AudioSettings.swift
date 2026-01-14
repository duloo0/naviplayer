//
//  AudioSettings.swift
//  naviplayer
//
//  Audio settings manager for normalization and playback preferences
//

import Foundation
import Combine

// MARK: - Normalization Mode
enum NormalizationMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case smart = "Smart"
    case trackGain = "Track Gain"
    case albumGain = "Album Gain"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .off:
            return "No volume normalization applied"
        case .smart:
            return "Uses track gain when shuffling, album gain when playing albums"
        case .trackGain:
            return "Always use track gain for consistent loudness"
        case .albumGain:
            return "Always use album gain to preserve album dynamics"
        }
    }
}

// MARK: - Transcoding Quality
enum TranscodingQuality: String, CaseIterable, Identifiable, Codable {
    case original = "Original"
    case high = "High Quality"
    case balanced = "Balanced"
    case dataSaver = "Data Saver"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .original:
            return "Stream original files (WiFi recommended)"
        case .high:
            return "AAC 256 kbps (excellent quality, smaller)"
        case .balanced:
            return "Opus 128 kbps (good quality, data efficient)"
        case .dataSaver:
            return "Opus 96 kbps (saves bandwidth)"
        }
    }

    var maxBitRate: Int? {
        switch self {
        case .original:
            return nil
        case .high:
            return 256
        case .balanced:
            return 128
        case .dataSaver:
            return 96
        }
    }

    var format: String? {
        switch self {
        case .original:
            return nil
        case .high:
            return "aac"
        case .balanced:
            return "opus"
        case .dataSaver:
            return "opus"
        }
    }

    var formatDisplayName: String {
        switch self {
        case .original:
            return "Original"
        case .high:
            return "AAC 256"
        case .balanced:
            return "Opus 128"
        case .dataSaver:
            return "Opus 96"
        }
    }
}

// MARK: - Audio Settings
@MainActor
final class AudioSettings: ObservableObject {
    // MARK: - Singleton
    static let shared = AudioSettings()

    // MARK: - Published Properties
    @Published var normalizationMode: NormalizationMode {
        didSet { saveSettings() }
    }

    @Published var preampGain: Double {
        didSet { saveSettings() }
    }

    @Published var preventClipping: Bool {
        didSet { saveSettings() }
    }

    @Published var transcodingQuality: TranscodingQuality {
        didSet { saveSettings() }
    }

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let normalizationMode = "NaviPlayer.Audio.NormalizationMode"
        static let preampGain = "NaviPlayer.Audio.PreampGain"
        static let preventClipping = "NaviPlayer.Audio.PreventClipping"
        static let transcodingQuality = "NaviPlayer.Audio.TranscodingQuality"
    }

    // MARK: - Initialization
    private init() {
        // Load saved settings or use defaults
        if let modeString = UserDefaults.standard.string(forKey: Keys.normalizationMode),
           let mode = NormalizationMode(rawValue: modeString) {
            self.normalizationMode = mode
        } else {
            self.normalizationMode = .smart // Default to smart mode
        }

        self.preampGain = UserDefaults.standard.object(forKey: Keys.preampGain) as? Double ?? 0.0
        self.preventClipping = UserDefaults.standard.object(forKey: Keys.preventClipping) as? Bool ?? true

        if let qualityString = UserDefaults.standard.string(forKey: Keys.transcodingQuality),
           let quality = TranscodingQuality(rawValue: qualityString) {
            self.transcodingQuality = quality
        } else {
            self.transcodingQuality = .original // Default to original quality
        }
    }

    // MARK: - Persistence
    private func saveSettings() {
        UserDefaults.standard.set(normalizationMode.rawValue, forKey: Keys.normalizationMode)
        UserDefaults.standard.set(preampGain, forKey: Keys.preampGain)
        UserDefaults.standard.set(preventClipping, forKey: Keys.preventClipping)
        UserDefaults.standard.set(transcodingQuality.rawValue, forKey: Keys.transcodingQuality)
    }

    // MARK: - Gain Calculation

    /// Calculate the effective gain to apply for a track based on current settings and playback context
    /// - Parameters:
    ///   - track: The track to calculate gain for
    ///   - isShuffleMode: Whether shuffle is enabled
    ///   - isAlbumPlayback: Whether playing from an album context
    /// - Returns: The gain in dB to apply, or nil if no normalization should be applied
    func effectiveGain(for track: Track, isShuffleMode: Bool, isAlbumPlayback: Bool) -> Double? {
        guard normalizationMode != .off else { return nil }
        guard let replayGain = track.replayGain else { return nil }

        let baseGain: Double?

        switch normalizationMode {
        case .off:
            return nil

        case .smart:
            // Use track gain when shuffling (mixed content), album gain when playing albums
            if isShuffleMode {
                baseGain = replayGain.trackGain ?? replayGain.albumGain
            } else if isAlbumPlayback {
                baseGain = replayGain.albumGain ?? replayGain.trackGain
            } else {
                // Default to track gain for playlists or other contexts
                baseGain = replayGain.trackGain ?? replayGain.albumGain
            }

        case .trackGain:
            baseGain = replayGain.trackGain ?? replayGain.albumGain

        case .albumGain:
            baseGain = replayGain.albumGain ?? replayGain.trackGain
        }

        guard let gain = baseGain else { return nil }

        // Apply preamp adjustment
        return gain + preampGain
    }

    /// Calculate the linear volume multiplier from dB gain with optional peak limiting
    /// - Parameters:
    ///   - gainDB: The gain in decibels
    ///   - peak: Optional peak value for clipping prevention
    /// - Returns: Linear volume multiplier (0.0 to ~2.0 typically)
    func linearGain(fromDB gainDB: Double, peak: Double?) -> Float {
        // Convert dB to linear: 10^(dB/20)
        var linear = pow(10.0, gainDB / 20.0)

        // Apply peak limiting to prevent clipping
        if preventClipping, let peak = peak, peak > 0 {
            let maxGain = 1.0 / peak
            linear = min(linear, maxGain)
        }

        // Clamp to reasonable range (prevent extreme values)
        linear = max(0.0, min(linear, 4.0))

        return Float(linear)
    }
}
