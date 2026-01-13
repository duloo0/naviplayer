//
//  FloatingBottomBar.swift
//  naviplayer
//
//  TIDAL-style floating bottom bar combining mini player and tab navigation
//

import SwiftUI

struct FloatingBottomBar: View {
    @ObservedObject var audioEngine: AudioEngine
    @Binding var selectedTab: ContentView.Tab
    var onPlayerTap: () -> Void

    private let barHeight: CGFloat = 72
    private let cornerRadius: CGFloat = 24

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at very top of bubble
            if audioEngine.currentTrack != nil {
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.Accent.cyan)
                        .frame(width: geo.size.width * audioEngine.progress, height: 3)
                }
                .frame(height: 3)
                .background(Color.white.opacity(0.1))
            }

            // Main content row
            HStack(spacing: 8) {
                // Mini player section (when playing)
                if let track = audioEngine.currentTrack {
                    // Artwork
                    AsyncImage(url: audioEngine.coverArtURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onTapGesture { onPlayerTap() }

                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(track.effectiveArtist)
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 90, alignment: .leading)
                    .onTapGesture { onPlayerTap() }

                    // Play/Pause
                    Button {
                        audioEngine.togglePlayPause()
                    } label: {
                        Image(systemName: audioEngine.playbackState == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)

                    // Next
                    Button {
                        Task { await audioEngine.next() }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.6))
                            .frame(width: 32, height: 40)
                    }
                    .buttonStyle(.plain)

                    // Vertical divider
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 32)
                        .padding(.horizontal, 4)
                }

                Spacer(minLength: 0)

                // Tab icons
                HStack(spacing: 0) {
                    tabButton(.library, icon: "music.note.house")
                    tabButton(.playlists, icon: "text.badge.plus")
                    tabButton(.radio, icon: "radio")
                    tabButton(.search, icon: "magnifyingglass")
                    tabButton(.settings, icon: "gearshape")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(height: audioEngine.currentTrack != nil ? barHeight : 60)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func tabButton(_ tab: ContentView.Tab, icon: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Image(systemName: selectedTab == tab ? filledIcon(icon) : icon)
                .font(.system(size: 20))
                .foregroundColor(selectedTab == tab ? Color.Accent.cyan : Color.white.opacity(0.5))
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }

    private func filledIcon(_ icon: String) -> String {
        switch icon {
        case "music.note.house": return "music.note.house.fill"
        case "radio": return "radio.fill"
        case "gearshape": return "gearshape.fill"
        default: return icon
        }
    }
}

#if DEBUG
struct FloatingBottomBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Spacer()
                FloatingBottomBar(
                    audioEngine: AudioEngine.shared,
                    selectedTab: .constant(.library),
                    onPlayerTap: {}
                )
            }
        }
    }
}
#endif
