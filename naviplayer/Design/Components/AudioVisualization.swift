//
//  AudioVisualization.swift
//  naviplayer
//
//  Simple animated waveform visualization for the Now Playing screen
//

import SwiftUI

// MARK: - Audio Waveform Visualization
struct AudioWaveform: View {
    let isPlaying: Bool
    let color: Color
    let barCount: Int
    let barWidth: CGFloat
    let barSpacing: CGFloat
    let maxHeight: CGFloat

    @State private var animatingBars: [CGFloat]

    init(
        isPlaying: Bool,
        color: Color = Color.Accent.cyan,
        barCount: Int = 5,
        barWidth: CGFloat = 3,
        barSpacing: CGFloat = 2,
        maxHeight: CGFloat = 20
    ) {
        self.isPlaying = isPlaying
        self.color = color
        self.barCount = barCount
        self.barWidth = barWidth
        self.barSpacing = barSpacing
        self.maxHeight = maxHeight
        self._animatingBars = State(initialValue: Array(repeating: 0.3, count: barCount))
    }

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(color)
                    .frame(width: barWidth, height: barHeight(for: index))
            }
        }
        .frame(height: maxHeight)
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        if isPlaying {
            return animatingBars[index] * maxHeight
        } else {
            return maxHeight * 0.3
        }
    }

    private func startAnimation() {
        // Animate each bar with a slightly different timing
        for index in 0..<barCount {
            animateBar(at: index)
        }
    }

    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            animatingBars = Array(repeating: 0.3, count: barCount)
        }
    }

    private func animateBar(at index: Int) {
        guard isPlaying else { return }

        let delay = Double(index) * 0.1
        let duration = Double.random(in: 0.3...0.5)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: duration)) {
                if isPlaying {
                    animatingBars[index] = CGFloat.random(in: 0.3...1.0)
                }
            }

            // Continue animation
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                animateBar(at: index)
            }
        }
    }
}

// MARK: - Mini Waveform (for mini player/queue)
struct MiniWaveform: View {
    let isPlaying: Bool

    var body: some View {
        AudioWaveform(
            isPlaying: isPlaying,
            color: Color.Accent.cyan,
            barCount: 3,
            barWidth: 2,
            barSpacing: 1,
            maxHeight: 12
        )
    }
}

// MARK: - Now Playing Waveform (larger)
struct NowPlayingWaveform: View {
    let isPlaying: Bool
    let color: Color

    init(isPlaying: Bool, color: Color = Color.Accent.cyan) {
        self.isPlaying = isPlaying
        self.color = color
    }

    var body: some View {
        AudioWaveform(
            isPlaying: isPlaying,
            color: color,
            barCount: 7,
            barWidth: 4,
            barSpacing: 3,
            maxHeight: 24
        )
    }
}

// MARK: - Pulsing Circle (alternative visualization)
struct PulsingCircle: View {
    let isPlaying: Bool
    let color: Color

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.5

    var body: some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .onAppear {
                if isPlaying {
                    startPulsing()
                }
            }
            .onChange(of: isPlaying) { _, newValue in
                if newValue {
                    startPulsing()
                } else {
                    stopPulsing()
                }
            }
    }

    private func startPulsing() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            scale = 1.3
            opacity = 0.8
        }
    }

    private func stopPulsing() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 1.0
            opacity = 0.5
        }
    }
}

// MARK: - Preview
#if DEBUG
struct AudioVisualization_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            VStack {
                Text("Playing")
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
                AudioWaveform(isPlaying: true)
            }

            VStack {
                Text("Paused")
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
                AudioWaveform(isPlaying: false)
            }

            VStack {
                Text("Mini Waveform")
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
                MiniWaveform(isPlaying: true)
            }

            VStack {
                Text("Now Playing Waveform")
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
                NowPlayingWaveform(isPlaying: true, color: Color.Quality.hiRes)
            }

            VStack {
                Text("Pulsing Circle")
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
                PulsingCircle(isPlaying: true, color: Color.Accent.cyan)
            }
        }
        .padding()
        .background(Color.Background.default)
        .preferredColorScheme(.dark)
    }
}
#endif
