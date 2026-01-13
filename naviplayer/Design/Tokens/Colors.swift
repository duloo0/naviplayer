//
//  Colors.swift
//  naviplayer
//
//  Design tokens based on Navidrome's Tidal/Roon theme
//

import SwiftUI

// MARK: - Background Colors
extension Color {
    enum Background {
        /// Main app background - #121212
        static let `default` = Color(hex: 0x121212)
        /// Elevated surfaces like cards - #1E1E1E
        static let paper = Color(hex: 0x1E1E1E)
        /// Higher elevation (modals, dropdowns) - #282828
        static let elevated = Color(hex: 0x282828)
        /// Hover/active states - #333333
        static let overlay = Color(hex: 0x333333)
        /// Alternative surface - #242424
        static let surface = Color(hex: 0x242424)
    }
}

// MARK: - Text Colors
extension Color {
    enum Text {
        /// Primary text - pure white
        static let primary = Color.white
        /// Secondary text - 75% opacity
        static let secondary = Color.white.opacity(0.75)
        /// Tertiary text - 55% opacity
        static let tertiary = Color.white.opacity(0.55)
        /// Disabled text - 38% opacity
        static let disabled = Color.white.opacity(0.38)
        /// Hint text - 50% opacity
        static let hint = Color.white.opacity(0.50)
    }
}

// MARK: - Accent Colors
extension Color {
    enum Accent {
        /// Primary accent - white
        static let primary = Color.white
        /// Roon/Tidal signature cyan - #00FFFF
        static let cyan = Color(hex: 0x00FFFF)
        /// Success green - #00FF88
        static let success = Color(hex: 0x00FF88)
        /// Warning amber - #FFB800
        static let warning = Color(hex: 0xFFB800)
        /// Error red - #FF4757
        static let error = Color(hex: 0xFF4757)
        /// Info blue - #00BFFF
        static let info = Color(hex: 0x00BFFF)
        /// Purple accent - #9B59B6
        static let purple = Color(hex: 0x9B59B6)
    }
}

// MARK: - Quality Badge Colors
extension Color {
    enum Quality {
        /// Hi-Res gold - #FFD700
        static let hiRes = Color(hex: 0xFFD700)
        /// Lossless green - #00FF88
        static let lossless = Color(hex: 0x00FF88)
        /// DSD purple - #9B59B6
        static let dsd = Color(hex: 0x9B59B6)
        /// MQA pink - #FF6B9C
        static let mqa = Color(hex: 0xFF6B9C)
        /// Standard/lossy gray - #888888
        static let standard = Color(hex: 0x888888)
    }
}

// MARK: - Interactive State Colors
extension Color {
    enum Interactive {
        /// Hover state - 12% white
        static let hover = Color.white.opacity(0.12)
        /// Active/pressed state - 18% white
        static let active = Color.white.opacity(0.18)
        /// Focus ring - 30% cyan
        static let focus = Color.Accent.cyan.opacity(0.30)
        /// Selected state - 22% white
        static let selected = Color.white.opacity(0.22)
    }
}

// MARK: - Border Colors
extension Color {
    enum Border {
        /// Subtle border - 12% white
        static let subtle = Color.white.opacity(0.12)
        /// Default border - 16% white
        static let `default` = Color.white.opacity(0.16)
        /// Light border - 20% white
        static let light = Color.white.opacity(0.20)
        /// Strong border - 32% white
        static let strong = Color.white.opacity(0.32)
    }
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(hex: UInt(int))
    }
}

// MARK: - Semantic Colors
extension Color {
    /// Love/heart button active color
    static let loved = Color.Accent.error

    /// Thumb up active color
    static let thumbUp = Color.Accent.success

    /// Thumb down active color
    static let thumbDown = Color.Accent.error

    /// Now playing accent
    static let nowPlayingAccent = Color.Accent.cyan
}
