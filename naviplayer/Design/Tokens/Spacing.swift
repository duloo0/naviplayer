//
//  Spacing.swift
//  naviplayer
//
//  Spacing system based on 4px grid
//

import SwiftUI

// MARK: - Spacing Scale
enum Spacing {
    /// 2px - Minimal spacing
    static let xxs: CGFloat = 2
    /// 4px - Extra small
    static let xs: CGFloat = 4
    /// 8px - Small
    static let sm: CGFloat = 8
    /// 12px - Small-medium
    static let md: CGFloat = 12
    /// 16px - Medium (base)
    static let base: CGFloat = 16
    /// 20px - Medium-large
    static let lg: CGFloat = 20
    /// 24px - Large
    static let xl: CGFloat = 24
    /// 32px - Extra large
    static let xl2: CGFloat = 32
    /// 48px - 2x extra large
    static let xl3: CGFloat = 48
    /// 64px - 3x extra large
    static let xl4: CGFloat = 64
    /// 96px - 4x extra large
    static let xl5: CGFloat = 96
}

// MARK: - Component-Specific Spacing
extension Spacing {
    enum Page {
        /// Horizontal page padding
        static let horizontal: CGFloat = 20
        /// Vertical page padding
        static let vertical: CGFloat = 16
        /// Safe area bottom padding
        static let bottomSafe: CGFloat = 34
    }

    enum Card {
        /// Card internal padding
        static let padding: CGFloat = 16
        /// Gap between cards in grid
        static let gap: CGFloat = 12
        /// Card corner radius
        static let cornerRadius: CGFloat = 12
    }

    enum List {
        /// Vertical spacing between list items
        static let itemSpacing: CGFloat = 8
        /// Horizontal padding for list items
        static let itemPadding: CGFloat = 16
        /// Section header spacing
        static let sectionSpacing: CGFloat = 24
    }

    enum Player {
        /// Artwork size (Now Playing)
        static let artworkSize: CGFloat = 300
        /// Mini player artwork size
        static let miniArtworkSize: CGFloat = 48
        /// Control button size
        static let controlSize: CGFloat = 56
        /// Control button spacing
        static let controlSpacing: CGFloat = 32
        /// Progress bar height
        static let progressHeight: CGFloat = 4
    }

    enum Button {
        /// Standard button height
        static let height: CGFloat = 44
        /// Small button height
        static let heightSmall: CGFloat = 32
        /// Icon button size
        static let iconSize: CGFloat = 44
        /// Button corner radius
        static let cornerRadius: CGFloat = 8
    }
}

// MARK: - Corner Radius
enum CornerRadius {
    /// 4px - Small elements
    static let sm: CGFloat = 4
    /// 8px - Default
    static let md: CGFloat = 8
    /// 12px - Cards
    static let lg: CGFloat = 12
    /// 16px - Modals
    static let xl: CGFloat = 16
    /// Full circle
    static let full: CGFloat = 9999
}

// MARK: - View Extensions
extension View {
    /// Standard card styling with background and corner radius
    func cardStyle() -> some View {
        self
            .padding(Spacing.Card.padding)
            .background(Color.Background.paper)
            .cornerRadius(CornerRadius.lg)
    }

    /// Elevated card with shadow
    func elevatedCardStyle() -> some View {
        self
            .padding(Spacing.Card.padding)
            .background(Color.Background.elevated)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}
