//
//  Typography.swift
//  naviplayer
//
//  Typography system based on Tidal/Roon aesthetic
//

import SwiftUI

// MARK: - Font Sizes
enum FontSize {
    static let xs: CGFloat = 10
    static let sm: CGFloat = 12
    static let md: CGFloat = 14
    static let base: CGFloat = 16
    static let lg: CGFloat = 18
    static let xl: CGFloat = 20
    static let xl2: CGFloat = 24
    static let xl3: CGFloat = 28
    static let xl4: CGFloat = 32
    static let xl5: CGFloat = 40
    static let xl6: CGFloat = 48
}

// MARK: - Font Weights
extension Font.Weight {
    static let light: Font.Weight = .light
    static let regular: Font.Weight = .regular
    static let medium: Font.Weight = .medium
    static let semibold: Font.Weight = .semibold
    static let bold: Font.Weight = .bold
}

// MARK: - Typography Styles
extension Font {
    enum Navi {
        // MARK: - Display
        /// Large display - 48pt bold (album titles, hero text)
        static let displayLarge = Font.system(size: FontSize.xl6, weight: .bold, design: .default)
        /// Medium display - 40pt bold
        static let displayMedium = Font.system(size: FontSize.xl5, weight: .bold, design: .default)
        /// Small display - 32pt semibold
        static let displaySmall = Font.system(size: FontSize.xl4, weight: .semibold, design: .default)

        // MARK: - Headlines
        /// Large headline - 28pt bold
        static let headlineLarge = Font.system(size: FontSize.xl3, weight: .bold, design: .default)
        /// Medium headline - 24pt semibold
        static let headlineMedium = Font.system(size: FontSize.xl2, weight: .semibold, design: .default)
        /// Small headline - 20pt semibold
        static let headlineSmall = Font.system(size: FontSize.xl, weight: .semibold, design: .default)

        // MARK: - Titles
        /// Large title - 18pt semibold (track titles)
        static let titleLarge = Font.system(size: FontSize.lg, weight: .semibold, design: .default)
        /// Medium title - 16pt medium
        static let titleMedium = Font.system(size: FontSize.base, weight: .medium, design: .default)
        /// Small title - 14pt medium
        static let titleSmall = Font.system(size: FontSize.md, weight: .medium, design: .default)

        // MARK: - Body
        /// Large body - 16pt regular
        static let bodyLarge = Font.system(size: FontSize.base, weight: .regular, design: .default)
        /// Medium body - 14pt regular (default text)
        static let bodyMedium = Font.system(size: FontSize.md, weight: .regular, design: .default)
        /// Small body - 12pt regular
        static let bodySmall = Font.system(size: FontSize.sm, weight: .regular, design: .default)

        // MARK: - Labels
        /// Large label - 14pt medium (buttons)
        static let labelLarge = Font.system(size: FontSize.md, weight: .medium, design: .default)
        /// Medium label - 12pt medium
        static let labelMedium = Font.system(size: FontSize.sm, weight: .medium, design: .default)
        /// Small label - 10pt medium (badges)
        static let labelSmall = Font.system(size: FontSize.xs, weight: .medium, design: .default)

        // MARK: - Captions
        /// Caption - 12pt regular (secondary info)
        static let caption = Font.system(size: FontSize.sm, weight: .regular, design: .default)
        /// Caption small - 10pt regular
        static let captionSmall = Font.system(size: FontSize.xs, weight: .regular, design: .default)

        // MARK: - Mono (for quality specs)
        /// Monospace - 12pt regular (sample rate, bit depth)
        static let mono = Font.system(size: FontSize.sm, weight: .regular, design: .monospaced)
        /// Monospace small - 10pt regular
        static let monoSmall = Font.system(size: FontSize.xs, weight: .regular, design: .monospaced)

        // MARK: - Special
        /// Quality badge - 10pt semibold uppercase
        static let badge = Font.system(size: FontSize.xs, weight: .semibold, design: .default)
        /// Time display - 12pt mono
        static let time = Font.system(size: FontSize.sm, weight: .regular, design: .monospaced)
    }
}

// MARK: - Text Styles
extension View {
    /// Apply primary text styling
    func textPrimary() -> some View {
        self.foregroundColor(Color.Text.primary)
    }

    /// Apply secondary text styling
    func textSecondary() -> some View {
        self.foregroundColor(Color.Text.secondary)
    }

    /// Apply tertiary text styling
    func textTertiary() -> some View {
        self.foregroundColor(Color.Text.tertiary)
    }
}

// MARK: - Letter Spacing
extension View {
    /// Apply uppercase with letter spacing (for badges, labels)
    func uppercaseSpaced(_ spacing: CGFloat = 0.5) -> some View {
        self
            .textCase(.uppercase)
            .tracking(spacing)
    }
}
