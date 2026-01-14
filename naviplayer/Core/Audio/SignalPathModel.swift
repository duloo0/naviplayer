//
//  SignalPathModel.swift
//  naviplayer
//
//  Roon-style signal path model for audio chain visualization
//

import SwiftUI

// MARK: - Signal Quality
enum SignalQuality {
    case lossless       // Bit-perfect path
    case enhanced       // Better than source (upsampling)
    case highQuality    // Good quality processing
    case standard       // Lossy or unknown

    var color: Color {
        switch self {
        case .lossless: return Color.Quality.lossless
        case .enhanced: return Color(red: 0.608, green: 0.349, blue: 0.714) // Purple
        case .highQuality: return Color.Quality.hiRes
        case .standard: return Color.Quality.standard
        }
    }

    var label: String {
        switch self {
        case .lossless: return "Lossless"
        case .enhanced: return "Enhanced"
        case .highQuality: return "High Quality"
        case .standard: return "Standard"
        }
    }
}

// MARK: - Signal Stage Type
enum SignalPathStageType {
    case source         // Original file
    case transcode      // Server-side transcoding
    case decode         // Decoder (FLAC, AAC, etc.)
    case dsp            // Any DSP processing
    case replayGain     // Volume normalization
    case output         // Output device
}

// MARK: - Signal Stage
struct SignalPathStage: Identifiable {
    let id = UUID()
    let type: SignalPathStageType
    let name: String
    let detail: String
    let quality: SignalQuality
    let sampleRate: Int?
    let bitDepth: Int?
    let icon: String

    var formattedSpecs: String? {
        var parts: [String] = []
        if let sr = sampleRate {
            if sr >= 1000 {
                parts.append("\(sr / 1000)kHz")
            } else {
                parts.append("\(sr)Hz")
            }
        }
        if let bd = bitDepth {
            parts.append("\(bd)-bit")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }
}

// MARK: - Signal Path
struct SignalPath {
    let stages: [SignalPathStage]
    let overallQuality: SignalQuality

    /// Build signal path with full context for accurate ReplayGain display
    static func build(
        from track: Track,
        outputDevice: String,
        isShuffleMode: Bool = false,
        isAlbumPlayback: Bool = false,
        transcodingQuality: TranscodingQuality? = nil
    ) -> SignalPath {
        var stages: [SignalPathStage] = []
        var lowestQuality: SignalQuality = .lossless

        // Determine source quality
        let sourceQuality: SignalQuality = track.qualityTier == .lossy ? .standard : .lossless
        if sourceQuality == .standard { lowestQuality = .standard }

        // 1. Source stage
        stages.append(SignalPathStage(
            type: .source,
            name: track.suffix?.uppercased() ?? "Source",
            detail: track.qualitySpecs,
            quality: sourceQuality,
            sampleRate: track.samplingRate,
            bitDepth: track.bitDepth,
            icon: "doc.fill"
        ))

        // 2. Transcoding stage (if active)
        if let transcoding = transcodingQuality, transcoding != .original {
            // Transcoding always results in lossy output
            lowestQuality = .standard

            stages.append(SignalPathStage(
                type: .transcode,
                name: "Transcode",
                detail: transcoding.formatDisplayName,
                quality: .standard,
                sampleRate: nil,
                bitDepth: nil,
                icon: "arrow.triangle.2.circlepath"
            ))
        }

        // 3. Decode stage
        let decoderName = Self.decoderName(for: track)
        stages.append(SignalPathStage(
            type: .decode,
            name: "Decode",
            detail: decoderName,
            quality: sourceQuality,
            sampleRate: track.samplingRate,
            bitDepth: track.bitDepth,
            icon: "waveform"
        ))

        // 4. ReplayGain (only if normalization is enabled and track has RG data)
        let audioSettings = AudioSettings.shared
        if audioSettings.normalizationMode != .off,
           let _ = track.replayGain,
           let appliedGain = audioSettings.effectiveGain(
               for: track,
               isShuffleMode: isShuffleMode,
               isAlbumPlayback: isAlbumPlayback
           ) {
            // Determine mode label
            let modeLabel: String
            switch audioSettings.normalizationMode {
            case .smart:
                modeLabel = isShuffleMode ? "Track" : (isAlbumPlayback ? "Album" : "Track")
            case .trackGain:
                modeLabel = "Track"
            case .albumGain:
                modeLabel = "Album"
            case .off:
                modeLabel = ""
            }

            stages.append(SignalPathStage(
                type: .replayGain,
                name: "ReplayGain",
                detail: String(format: "%+.1f dB (%@)", appliedGain, modeLabel),
                quality: .lossless, // ReplayGain is lossless volume scaling
                sampleRate: track.samplingRate,
                bitDepth: track.bitDepth,
                icon: "slider.horizontal.3"
            ))
        }

        // 5. Output stage
        stages.append(SignalPathStage(
            type: .output,
            name: "Output",
            detail: outputDevice,
            quality: lowestQuality,
            sampleRate: nil,
            bitDepth: nil,
            icon: "hifispeaker.fill"
        ))

        return SignalPath(stages: stages, overallQuality: lowestQuality)
    }

    private static func decoderName(for track: Track) -> String {
        guard let suffix = track.suffix?.lowercased() else { return "Decoder" }

        switch suffix {
        case "flac":
            return "FLAC Decoder"
        case "alac", "m4a":
            return "Apple Lossless"
        case "wav", "aiff":
            return "PCM"
        case "mp3":
            return "MP3 Decoder"
        case "aac":
            return "AAC Decoder"
        case "ogg", "opus":
            return "Vorbis/Opus"
        case "dsf", "dff":
            return "DSD → PCM"
        case "wma":
            return "WMA Decoder"
        default:
            return "Audio Decoder"
        }
    }
}
