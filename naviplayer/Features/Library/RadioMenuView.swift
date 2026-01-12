//
//  RadioMenuView.swift
//  naviplayer
//
//  Radio menu showing available radio options
//

import SwiftUI

struct RadioMenuView: View {
    var body: some View {
        ZStack {
            Color.Background.default
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "radio")
                            .font(.system(size: 48))
                            .foregroundColor(Color.Accent.cyan)
                            .padding(.top, Spacing.xl2)

                        Text("Radio")
                            .font(.Navi.headlineMedium)
                            .foregroundColor(Color.Text.primary)

                        Text("Smart radio stations based on your library")
                            .font(.Navi.bodyMedium)
                            .foregroundColor(Color.Text.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Spacing.Page.horizontal)
                    .padding(.bottom, Spacing.lg)

                    // Radio Options
                    VStack(spacing: Spacing.md) {
                        // Library Radio
                        NavigationLink {
                            LibraryRadioView()
                        } label: {
                            RadioOptionCard(
                                icon: "waveform.path",
                                title: "Library Radio",
                                description: "Smart mix weighted by popularity, your ratings, and play history",
                                accentColor: Color.Accent.cyan
                            )
                        }
                        .buttonStyle(.plain)

                        // More radio options can be added here in the future
                        // For example: Genre Radio, Artist Radio, Decade Radio, etc.

                        RadioOptionCard(
                            icon: "music.note.list",
                            title: "Genre Radio",
                            description: "Coming soon - Radio based on your favorite genres",
                            accentColor: Color.Text.tertiary,
                            isDisabled: true
                        )

                        RadioOptionCard(
                            icon: "person.2",
                            title: "Artist Radio",
                            description: "Coming soon - Radio based on similar artists",
                            accentColor: Color.Text.tertiary,
                            isDisabled: true
                        )
                    }
                    .padding(.horizontal, Spacing.Page.horizontal)

                    Spacer(minLength: Spacing.xl3 + 80) // Space for mini player
                }
            }
        }
        .navigationTitle("Radio")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Radio Option Card
struct RadioOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    var isDisabled: Bool = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
            }

            // Text
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.Navi.titleSmall)
                    .foregroundColor(isDisabled ? Color.Text.tertiary : Color.Text.primary)

                Text(description)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if !isDisabled {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.Text.tertiary)
            }
        }
        .padding(Spacing.md)
        .background(Color.Background.paper)
        .cornerRadius(CornerRadius.md)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

// MARK: - Preview
#if DEBUG
struct RadioMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RadioMenuView()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
