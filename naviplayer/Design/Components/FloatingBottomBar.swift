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

    @State private var isPlayerPressed = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at top (only when playing)
            if audioEngine.currentTrack != nil {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                        Rectangle()
                            .fill(Color.Accent.cyan)
                            .frame(width: geo.size.width * audioEngine.progress)
                    }
                }
                .frame(height: 3)
                .clipShape(RoundedRectangle(cornerRadius: 1.5))
            }

            // Main content
            HStack(spacing: 0) {
                // Mini player section (left side)
                if let track = audioEngine.currentTrack {
                    miniPlayerSection(track: track)
                        .contentShape(Rectangle())
                        .onTapGesture { onPlayerTap() }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in isPlayerPressed = true }
                                .onEnded { _ in isPlayerPressed = false }
                        )
                        .scaleEffect(isPlayerPressed ? 0.98 : 1.0)
                        .animation(.easeOut(duration: 0.1), value: isPlayerPressed)

                    // Divider between player and tabs
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 40)
                        .padding(.horizontal, 12)
                }

                // Tab icons section (right side)
                tabIconsSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, audioEngine.currentTrack != nil ? 10 : 14)
        }
        .background(Color.Background.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Mini Player Section

    private func miniPlayerSection(track: Track) -> some View {
        HStack(spacing: 12) {
            // Artwork
            MiniArtwork(
                url: audioEngine.coverArtURL,
                size: 44,
                cornerRadius: 8
            )

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.Text.primary)
                    .lineLimit(1)

                Text(track.effectiveArtist)
                    .font(.system(size: 12))
                    .foregroundColor(Color.Text.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: 120, alignment: .leading)

            Spacer(minLength: 8)

            // Play/Pause button
            Button {
                audioEngine.togglePlayPause()
            } label: {
                Image(systemName: audioEngine.playbackState == .playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.Text.primary)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            // Next button
            Button {
                Task { await audioEngine.next() }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.Text.secondary)
                    .frame(width: 36, height: 40)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Tab Icons Section

    private var tabIconsSection: some View {
        HStack(spacing: 4) {
            TabIconButton(
                icon: "music.note.house",
                isSelected: selectedTab == .library
            ) { selectedTab = .library }

            TabIconButton(
                icon: "music.note.list",
                isSelected: selectedTab == .playlists
            ) { selectedTab = .playlists }

            TabIconButton(
                icon: "radio",
                isSelected: selectedTab == .radio
            ) { selectedTab = .radio }

            TabIconButton(
                icon: "magnifyingglass",
                isSelected: selectedTab == .search
            ) { selectedTab = .search }

            TabIconButton(
                icon: "gearshape",
                isSelected: selectedTab == .settings
            ) { selectedTab = .settings }
        }
    }
}

// MARK: - Tab Icon Button

struct TabIconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? filledIcon : icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.Accent.cyan : Color.Text.tertiary)
                    .frame(width: 44, height: 32)
            }
        }
        .buttonStyle(TabButtonStyle())
    }

    private var filledIcon: String {
        switch icon {
        case "music.note.house": return "music.note.house.fill"
        case "music.note.list": return "music.note.list"
        case "radio": return "radio.fill"
        case "magnifyingglass": return "magnifyingglass"
        case "gearshape": return "gearshape.fill"
        default: return icon
        }
    }
}

// MARK: - Tab Button Style

struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct FloatingBottomBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.Background.default
                .ignoresSafeArea()

            VStack {
                Spacer()
                FloatingBottomBar(
                    audioEngine: AudioEngine.shared,
                    selectedTab: .constant(.library),
                    onPlayerTap: {}
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
