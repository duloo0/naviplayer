//
//  ProgressSlider.swift
//  naviplayer
//
//  Custom progress slider for Now Playing screen
//

import SwiftUI

// MARK: - Progress Slider
struct ProgressSlider: View {
    @Binding var progress: Double // 0.0 to 1.0
    let duration: TimeInterval
    var currentTime: TimeInterval { progress * duration }
    var onSeek: ((TimeInterval) -> Void)?

    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Slider
            GeometryReader { geometry in
                let width = geometry.size.width
                let displayProgress = isDragging ? dragProgress : progress

                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: max(0, width * displayProgress), height: 4)

                    // Knob (visible when dragging)
                    if isDragging {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .offset(x: max(0, width * displayProgress - 6))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            withAnimation(.Navi.fast) {
                                isDragging = true
                            }
                            dragProgress = min(max(0, value.location.x / width), 1)
                        }
                        .onEnded { value in
                            let finalProgress = min(max(0, value.location.x / width), 1)
                            onSeek?(finalProgress * duration)
                            withAnimation(.Navi.fast) {
                                isDragging = false
                            }
                        }
                )
            }
            .frame(height: 20)

            // Time labels
            HStack {
                Text(formatTime(currentTime))
                    .font(.Navi.time)
                    .foregroundColor(Color.Text.tertiary)

                Spacer()

                Text(formatTime(duration))
                    .font(.Navi.time)
                    .foregroundColor(Color.Text.tertiary)
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Simple Progress Bar (non-interactive)
struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 3)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: max(0, geometry.size.width * progress), height: 3)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Preview
#if DEBUG
struct ProgressSlider_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State var progress: Double = 0.35

        var body: some View {
            VStack(spacing: 40) {
                ProgressSlider(
                    progress: $progress,
                    duration: 240,
                    onSeek: { time in
                        print("Seek to: \(time)")
                    }
                )

                ProgressBar(progress: 0.5)
            }
            .padding()
            .background(Color.Background.default)
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .preferredColorScheme(.dark)
    }
}
#endif
