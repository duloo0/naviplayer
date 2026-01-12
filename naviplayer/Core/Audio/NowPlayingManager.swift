//
//  NowPlayingManager.swift
//  naviplayer
//
//  Manages Now Playing info for lock screen and Control Center
//

import MediaPlayer
import UIKit

final class NowPlayingManager {
    private let infoCenter = MPNowPlayingInfoCenter.default()

    // MARK: - Update Now Playing

    func update(
        track: Track,
        artwork: UIImage?,
        duration: TimeInterval,
        currentTime: TimeInterval,
        isPlaying: Bool
    ) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.effectiveArtist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue
        ]

        // Album
        if let album = track.album {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        }

        // Track number
        if let trackNumber = track.track {
            nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber] = trackNumber
        }

        // Artwork
        if let image = artwork {
            let mpArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = mpArtwork
        }

        infoCenter.nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Update Progress

    func updateProgress(currentTime: TimeInterval, duration: TimeInterval) {
        guard var info = infoCenter.nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration
        infoCenter.nowPlayingInfo = info
    }

    // MARK: - Update Playback State

    func updatePlaybackState(isPlaying: Bool) {
        guard var info = infoCenter.nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        infoCenter.nowPlayingInfo = info
    }

    // MARK: - Clear

    func clear() {
        infoCenter.nowPlayingInfo = nil
    }
}
