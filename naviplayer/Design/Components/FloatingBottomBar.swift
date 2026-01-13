//
//  FloatingBottomBar.swift
//  naviplayer
//
//  TIDAL-style floating bottom bar combining mini player and tab navigation
//  Two-row vertical layout: mini player on top, tab icons below
//

import SwiftUI

struct FloatingBottomBar: View {
    @ObservedObject var audioEngine: AudioEngine
    @Binding var selectedTab: ContentView.Tab
    var onPlayerTap: () -> Void

    private let cornerRadius: CGFloat = 24

    var body: some View {
        VStack(spacing: 0) {
            // Row 1: Mini player (only when playing)
            if let track = audioEngine.currentTrack {
                miniPlayerRow(track: track)
            }

            // Row 2: Tab navigation
            tabRow
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.85))
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.6), radius: 24, x: 0, y: 10)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Mini Player Row

    private func miniPlayerRow(track: Track) -> some View {
        HStack(spacing: 10) {
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

            // Track info - takes remaining space
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(track.effectiveArtist)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture { onPlayerTap() }

            // Play/Pause button (circle style like TIDAL)
            Button {
                audioEngine.togglePlayPause()
            } label: {
                Image(systemName: audioEngine.playbackState == .playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

            // Next button
            Button {
                Task { await audioEngine.next() }
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.5))
                    .frame(width: 36, height: 42)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Tab Row

    private var tabRow: some View {
        HStack(spacing: 0) {
            tabButton(.library, icon: "music.note")
            tabButton(.playlists, icon: "text.badge.plus")
            tabButton(.radio, icon: "antenna.radiowaves.left.and.right")
            tabButton(.search, icon: "magnifyingglass")
            tabButton(.settings, icon: "line.3.horizontal")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func tabButton(_ tab: ContentView.Tab, icon: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                .foregroundColor(selectedTab == tab ? .white : Color.white.opacity(0.4))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    Group {
                        if selectedTab == tab {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                        }
                    }
                )
        }
        .buttonStyle(.plain)
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
