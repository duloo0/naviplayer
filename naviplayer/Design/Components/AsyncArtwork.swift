//
//  AsyncArtwork.swift
//  naviplayer
//
//  Async artwork loading with placeholder, caching, and blur effects
//

import SwiftUI

// MARK: - Image Cache
actor ImageCache {
    static let shared = ImageCache()

    private var cache: [URL: UIImage] = [:]
    private let maxCacheSize = 100

    func image(for url: URL) -> UIImage? {
        cache[url]
    }

    func setImage(_ image: UIImage, for url: URL) {
        // Evict oldest if at capacity
        if cache.count >= maxCacheSize {
            cache.removeValue(forKey: cache.keys.first!)
        }
        cache[url] = image
    }
}

// MARK: - Cached Image View
struct CachedAsyncImage: View {
    let url: URL?
    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.Background.elevated

            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.Text.tertiary))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(Color.Text.tertiary)
                }
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else {
            image = nil
            return
        }

        // Check cache first
        if let cached = await ImageCache.shared.image(for: url) {
            image = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let loadedImage = UIImage(data: data) {
                await ImageCache.shared.setImage(loadedImage, for: url)
                image = loadedImage
            }
        } catch {
            image = nil
        }
    }
}

// MARK: - Async Artwork
struct AsyncArtwork: View {
    let url: URL?
    var size: CGFloat = 300
    var cornerRadius: CGFloat = CornerRadius.lg

    var body: some View {
        CachedAsyncImage(url: url)
            .aspectRatio(1, contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.Background.default

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: blurRadius)
                    .opacity(opacity)
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else {
            image = nil
            return
        }

        // Check cache first
        if let cached = await ImageCache.shared.image(for: url) {
            image = cached
            return
        }

        // Load from network
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let loadedImage = UIImage(data: data) {
                await ImageCache.shared.setImage(loadedImage, for: url)
                image = loadedImage
            }
        } catch {
            image = nil
        }
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
        CachedAsyncImage(url: url)
            .aspectRatio(1, contentMode: .fill)
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
