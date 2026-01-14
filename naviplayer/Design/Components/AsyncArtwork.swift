//
//  AsyncArtwork.swift
//  naviplayer
//
//  Async artwork loading with placeholder, caching, and blur effects
//

import SwiftUI
import Foundation
import CryptoKit

// MARK: - Image Cache
actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxDiskBytes: Int64 = 1_000_000_000
    private let maxMemoryCount = 200
    private let maxMemoryBytes = 100 * 1024 * 1024

    init() {
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("com.naviplayer.artwork", isDirectory: true)

        memoryCache.countLimit = maxMemoryCount
        memoryCache.totalCostLimit = maxMemoryBytes

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        Task { await pruneIfNeeded() }
    }

    func image(for url: URL) -> UIImage? {
        let key = url as NSURL
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        let fileURL = cacheFileURL(for: url)
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        memoryCache.setObject(image, forKey: key, cost: data.count)
        touchFile(fileURL)
        return image
    }

    func setImage(_ image: UIImage, for url: URL) {
        let key = url as NSURL
        if let data = image.jpegData(compressionQuality: 0.9) {
            memoryCache.setObject(image, forKey: key, cost: data.count)
            let fileURL = cacheFileURL(for: url)
            try? data.write(to: fileURL, options: .atomic)
            touchFile(fileURL)
            Task { await pruneIfNeeded() }
        } else {
            memoryCache.setObject(image, forKey: key, cost: 0)
        }
    }

    private func cacheFileURL(for url: URL) -> URL {
        cacheDirectory
            .appendingPathComponent(cacheKey(for: url))
            .appendingPathExtension("jpg")
    }

    private func cacheKey(for url: URL) -> String {
        let data = Data(url.absoluteString.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func touchFile(_ url: URL) {
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
    }

    private func pruneIfNeeded() async {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return
        }

        var entries: [(url: URL, size: Int64, date: Date)] = []
        var totalSize: Int64 = 0

        for fileURL in files {
            let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            let size = Int64(values?.fileSize ?? 0)
            let date = values?.contentModificationDate ?? .distantPast
            totalSize += size
            entries.append((fileURL, size, date))
        }

        guard totalSize > maxDiskBytes else { return }

        entries.sort { $0.date < $1.date }
        var currentSize = totalSize

        for entry in entries {
            try? fileManager.removeItem(at: entry.url)
            currentSize -= entry.size
            if currentSize <= maxDiskBytes {
                break
            }
        }
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
