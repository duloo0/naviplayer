# NaviPlayer

NaviPlayer is a SwiftUI iOS client for Navidrome/Subsonic music servers. It focuses on a premium playback experience with smart radio, gapless playback, and quality-focused audio controls.

## Features

- **Navidrome/Subsonic support** with token-based authentication (API v1.16.1).
- **Library browsing** for albums and artists with rich artwork views.
- **Smart Library Radio** that requests weighted radio mixes from the server.
- **Decade Radio** presets for era-based listening.
- **Full-screen Now Playing** with queue access, rating controls, and track details.
- **Gapless playback** via `AVQueuePlayer` with adaptive preloading.
- **ReplayGain normalization** with smart, track, and album gain modes.
- **Streaming quality controls** (Original, High, Balanced, Data Saver).
- **Lyrics support** via `getLyricsBySongId`.
- **Signal path visualization** and quality badges (lossless/hi-res/standard).
- **Lock screen and Control Center** integration.

## Requirements

- Xcode (latest stable recommended).
- iOS deployment target configured in `naviplayer.xcodeproj` (currently `26.2`).
- A running Navidrome or Subsonic-compatible server with the required endpoints enabled.

## Getting Started

1. Open `naviplayer.xcodeproj` in Xcode.
2. Select a simulator or device.
3. Configure signing if running on a physical device.
4. Build and run the app.

On first launch, enter your server URL, username, and password. The app stores the server configuration in `UserDefaults` and verifies connectivity on startup.

## Server Compatibility

NaviPlayer targets the Subsonic API and uses token + salt authentication.

Supported endpoints (high-level):

- Library: `getAlbumList2`, `getAlbum`, `getArtists`, `getArtist`
- Playback: `stream`, `getPlayQueue`, `savePlayQueue`
- Radio: `getLibraryRadio`, `getRandomSongs`
- Ratings/Love: `setRating`, `star`, `unstar`
- Lyrics: `getLyricsBySongId`
- Search: `search3`
- Playlists: `getPlaylists`, `getPlaylist`, `createPlaylist`, `updatePlaylist`, `deletePlaylist`

## App Navigation

- **Library**: Albums and artists with quick navigation to detail views.
- **Playlists**: Manage and play server-side playlists.
- **Radio**: Smart library radio and decade filters.
- **Search**: Unified search for songs, albums, and artists.
- **Settings**: Connection details, ReplayGain normalization, and streaming quality.

## Audio & Playback Details

- Uses `AVQueuePlayer` for gapless playback.
- Adaptive preloading based on network conditions and track duration.
- ReplayGain processing uses track/album metadata with optional clipping protection.
- Background audio is enabled via `UIBackgroundModes` (audio/fetch/processing).

## Project Structure

- `naviplayer/ContentView.swift`: Main tab shell and routing.
- `naviplayer/Core/API`: Subsonic client, auth, and API models.
- `naviplayer/Core/Audio`: Playback engine, Now Playing manager, signal path modeling.
- `naviplayer/Core/Settings`: Audio settings persistence.
- `naviplayer/Features`: Feature-level views (Library, Radio, Now Playing, Search, Playlists, Settings).

## Running Tests

- Unit tests: `naviplayerTests`.
- UI tests: `naviplayerUITests`.

From Xcode, select **Product > Test**. If you prefer CLI:

```bash
xcodebuild test -scheme naviplayer -destination "platform=iOS Simulator,name=iPhone 15"
```

## Notes

- Streaming quality settings map to server-side transcoding (`mp3` 320/192/128 kbps) or original quality.
- The app assumes the server supports the Navidrome library radio endpoint.

## License

See the project license for distribution terms.
