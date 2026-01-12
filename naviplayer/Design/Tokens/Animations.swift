//
//  Animations.swift
//  naviplayer
//
//  Animation tokens for consistent motion design
//

import SwiftUI

// MARK: - Durations
enum AnimationDuration {
    /// Fast interactions - 150ms
    static let fast: Double = 0.15
    /// Standard animations - 250ms
    static let normal: Double = 0.25
    /// Slow reveals - 400ms
    static let slow: Double = 0.4
    /// Extra slow - 600ms
    static let extraSlow: Double = 0.6
}

// MARK: - Animation Presets
extension Animation {
    enum Navi {
        /// Fast interaction feedback
        static let fast = Animation.easeOut(duration: AnimationDuration.fast)

        /// Standard UI animation
        static let standard = Animation.easeInOut(duration: AnimationDuration.normal)

        /// Smooth easing for reveals
        static let smooth = Animation.easeOut(duration: AnimationDuration.slow)

        /// Spring animation for playful interactions
        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)

        /// Bouncy spring for buttons
        static let bounce = Animation.spring(response: 0.3, dampingFraction: 0.6)

        /// Gentle spring for modals
        static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8)

        /// Progress bar animation
        static let progress = Animation.linear(duration: 0.1)

        /// Fade in animation
        static let fadeIn = Animation.easeIn(duration: AnimationDuration.normal)

        /// Slide up animation
        static let slideUp = Animation.easeOut(duration: AnimationDuration.slow)
    }
}

// MARK: - Transition Presets
extension AnyTransition {
    /// Fade with slight scale
    static let fadeScale = AnyTransition.opacity
        .combined(with: .scale(scale: 0.95))

    /// Slide from bottom with fade
    static let slideFromBottom = AnyTransition.move(edge: .bottom)
        .combined(with: .opacity)

    /// Slide from right with fade
    static let slideFromRight = AnyTransition.move(edge: .trailing)
        .combined(with: .opacity)

    /// Quick fade for overlays
    static let quickFade = AnyTransition.opacity
        .animation(.easeOut(duration: AnimationDuration.fast))
}

// MARK: - View Extensions
extension View {
    /// Apply standard appear animation
    func appearAnimation(delay: Double = 0) -> some View {
        self
            .opacity(1)
            .animation(Animation.Navi.smooth.delay(delay), value: true)
    }

    /// Press effect for buttons
    func pressEffect(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(Animation.Navi.fast, value: isPressed)
    }

    /// Hover effect for interactive elements
    func hoverEffect(isHovered: Bool) -> some View {
        self
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(Animation.Navi.fast, value: isHovered)
    }
}
