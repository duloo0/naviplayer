//
//  AsyncArtwork.swift
//  naviplayer
//
//  Async artwork loading with placeholder and blur effects
//

import SwiftUI

// MARK: - Async Artwork
struct AsyncArtwork: View {
    let url: URL?
    var size: CGFloat = 300
    var cornerRadius: CGFloat = CornerRadius.lg

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ArtworkPlaceholder(size: size)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            case .failure:
                ArtworkPlaceholder(size: size)
            @unknown default:
                ArtworkPlaceholder(size: size)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
    }
}

// MARK: - Artwork Placeholder
struct ArtworkPlaceholder: View {
    var size: CGFloat = 300

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.Background.elevated)

            Image(systemName: "music.note")
                .font(.system(size: size * 0.3, weight: .light))
                .foregroundColor(Color.Text.tertiary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Blurred Background
struct BlurredArtworkBackground: View {
    let url: URL?
    var blurRadius: CGFloat = 60
    var opacity: Double = 0.5

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: blurRadius)
                    .opacity(opacity)
            default:
                Color.Background.default
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Gradient Overlay
struct GradientOverlay: View {
    var topColor: Color = Color.black.opacity(0.3)
    var bottomColor: Color = Color.black.opacity(0.8)

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [topColor, Color.black.opacity(0.1), bottomColor]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Mini Artwork (for lists, mini player)
struct MiniArtwork: View {
    let url: URL?
    var size: CGFloat = 48
    var cornerRadius: CGFloat = CornerRadius.sm

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            default:
                ZStack {
                    Color.Background.elevated
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(Color.Text.tertiary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Preview
#if DEBUG
struct AsyncArtwork_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Large artwork
            AsyncArtwork(url: nil)

            // Mini artwork
            HStack(spacing: 12) {
                MiniArtwork(url: nil, size: 48)
                MiniArtwork(url: nil, size: 64)
            }

            // Placeholder
            ArtworkPlaceholder(size: 200)
        }
        .padding()
        .background(Color.Background.default)
        .preferredColorScheme(.dark)
    }
}
#endif
