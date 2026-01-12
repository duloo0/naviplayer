//
//  ColorExtractor.swift
//  naviplayer
//
//  Extracts dominant colors from album artwork for dynamic theming
//

import SwiftUI
import UIKit
import CoreImage

@MainActor
final class ColorExtractor: ObservableObject {
    // MARK: - Singleton
    static let shared = ColorExtractor()

    // MARK: - Cache
    private var colorCache: [String: ExtractedColors] = [:]
    private let maxCacheSize = 50

    // MARK: - Types
    struct ExtractedColors: Equatable {
        let dominant: Color
        let secondary: Color
        let isDark: Bool

        static let `default` = ExtractedColors(
            dominant: Color.Accent.cyan,
            secondary: Color.Background.elevated,
            isDark: true
        )
    }

    // MARK: - Public Methods

    /// Extract colors from an image URL
    func extractColors(from url: URL?) async -> ExtractedColors {
        guard let url = url else { return .default }

        // Check cache
        let cacheKey = url.absoluteString
        if let cached = colorCache[cacheKey] {
            return cached
        }

        // Load image
        guard let uiImage = await loadImage(from: url) else {
            return .default
        }

        // Extract colors
        let colors = extractColorsFromImage(uiImage)

        // Cache result
        if colorCache.count >= maxCacheSize {
            colorCache.removeAll()
        }
        colorCache[cacheKey] = colors

        return colors
    }

    /// Extract colors synchronously from a cached UIImage
    func extractColors(from image: UIImage?) -> ExtractedColors {
        guard let image = image else { return .default }
        return extractColorsFromImage(image)
    }

    // MARK: - Private Methods

    private func loadImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    private func extractColorsFromImage(_ image: UIImage) -> ExtractedColors {
        // Resize image for faster processing
        let targetSize = CGSize(width: 50, height: 50)
        guard let resized = image.resized(to: targetSize),
              let cgImage = resized.cgImage else {
            return .default
        }

        // Get pixel data
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return .default
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Collect color samples
        var colorCounts: [ColorBucket: Int] = [:]

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0

                // Skip very dark or very light colors
                let brightness = (r + g + b) / 3.0
                guard brightness > 0.1 && brightness < 0.9 else { continue }

                // Skip grayscale
                let saturation = max(r, g, b) - min(r, g, b)
                guard saturation > 0.15 else { continue }

                let bucket = ColorBucket(r: r, g: g, b: b)
                colorCounts[bucket, default: 0] += 1
            }
        }

        // Find dominant color
        let sortedColors = colorCounts.sorted { $0.value > $1.value }

        guard let dominant = sortedColors.first else {
            return .default
        }

        // Find secondary color (different enough from dominant)
        var secondary = dominant.key
        for (bucket, _) in sortedColors.dropFirst() {
            if bucket.isDifferentEnough(from: dominant.key) {
                secondary = bucket
                break
            }
        }

        let dominantColor = Color(
            red: dominant.key.r,
            green: dominant.key.g,
            blue: dominant.key.b
        )

        let secondaryColor = Color(
            red: secondary.r,
            green: secondary.g,
            blue: secondary.b
        )

        // Determine if dominant is dark
        let isDark = (dominant.key.r + dominant.key.g + dominant.key.b) / 3.0 < 0.5

        return ExtractedColors(
            dominant: dominantColor,
            secondary: secondaryColor,
            isDark: isDark
        )
    }
}

// MARK: - Color Bucket for quantization
private struct ColorBucket: Hashable {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat

    init(r: CGFloat, g: CGFloat, b: CGFloat) {
        // Quantize to reduce unique colors
        let bucketSize: CGFloat = 0.1
        self.r = (r / bucketSize).rounded() * bucketSize
        self.g = (g / bucketSize).rounded() * bucketSize
        self.b = (b / bucketSize).rounded() * bucketSize
    }

    func isDifferentEnough(from other: ColorBucket) -> Bool {
        let diff = abs(r - other.r) + abs(g - other.g) + abs(b - other.b)
        return diff > 0.3
    }
}

// MARK: - UIImage Extension
private extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
