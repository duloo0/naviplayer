//
//  DecadeRadioPickerView.swift
//  naviplayer
//
//  Decade selection view for decade-filtered radio
//

import SwiftUI

struct DecadeRadioPickerView: View {
    var body: some View {
        ZStack {
            Color.Background.default
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Compact header row
                HStack {
                    Text("Decade Radio")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, Spacing.Page.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.md) {
                        // Header description
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "calendar")
                                .font(.system(size: 40))
                                .foregroundColor(Color.Accent.purple)

                            Text("Radio filtered by decade")
                                .font(.Navi.bodyMedium)
                                .foregroundColor(Color.Text.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, Spacing.md)

                        // Decade options
                        ForEach(DecadePreset.presets) { preset in
                            NavigationLink {
                                LibraryRadioView(
                                    fromYear: preset.fromYear,
                                    toYear: preset.toYear,
                                    radioLabel: "\(preset.label) Radio"
                                )
                            } label: {
                                DecadeRow(preset: preset)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer(minLength: Spacing.xl3 + 80) // Space for mini player
                    }
                    .padding(.horizontal, Spacing.Page.horizontal)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Decade Row
struct DecadeRow: View {
    let preset: DecadePreset

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.Accent.purple.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: preset.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.Accent.purple)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.label)
                    .font(.Navi.bodyMedium)
                    .foregroundColor(Color.Text.primary)

                Text(yearRangeText)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.Text.tertiary)
        }
        .padding(Spacing.md)
        .background(Color.Background.paper)
        .cornerRadius(CornerRadius.md)
    }

    private var yearRangeText: String {
        if preset.toYear >= 2029 {
            return "\(preset.fromYear) - Present"
        } else if preset.fromYear == 1900 {
            return "Before 1970"
        } else {
            return "\(preset.fromYear) - \(preset.toYear)"
        }
    }
}

// MARK: - Preview
#if DEBUG
struct DecadeRadioPickerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DecadeRadioPickerView()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
