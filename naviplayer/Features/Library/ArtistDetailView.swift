//
//  ArtistDetailView.swift
//  naviplayer
//
//  Artist detail view with Roon-style hero header, bio, and albums
//

import SwiftUI
import Combine

struct ArtistDetailView: View {
    let artistId: String
    @StateObject private var viewModel: ArtistDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(artistId: String) {
        self.artistId = artistId
        self._viewModel = StateObject(wrappedValue: ArtistDetailViewModel(artistId: artistId))
    }

    var body: some View {
        ZStack {
            Color.Background.default
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.artist == nil {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.Accent.cyan))
            } else if let artist = viewModel.artist {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {

                        // Hero header
                        artistHero(artist)

                        // Play controls
                        playControls
                            .padding(.top, Spacing.lg)
                            .padding(.horizontal, Spacing.Page.horizontal)

                        // Stats row
                        statsRow(artist)
                            .padding(.top, Spacing.lg)

                        // Biography
                        if let bio = viewModel.artistInfo?.cleanBiography, !bio.isEmpty {
                            biographySection(bio)
                                .padding(.top, Spacing.xl)
                        }

                        // Albums
                        if !artist.albums.isEmpty {
                            albumsSection(artist.albums)
                                .padding(.top, Spacing.xl)
                        }

                        // Similar artists
                        if let similar = viewModel.artistInfo?.similarArtists, !similar.isEmpty {
                            similarArtistsSection(similar)
                                .padding(.top, Spacing.xl)
                        }

                        // External links
                        if viewModel.artistInfo?.lastFmUrl != nil {
                            externalLinksSection
                                .padding(.top, Spacing.xl)
                        }

                        Spacer(minLength: Spacing.xl3 + 80)
                    }
                }
            } else {
                errorView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Artist Hero (Roon-style)
    private func artistHero(_ artist: Artist) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background image with blur
                if let imageUrl = viewModel.artistInfo?.bestImageURL ?? artist.imageURL {
                    AsyncImage(url: SubsonicClient.shared.coverArtURL(for: imageUrl, size: 800)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: 320)
                                .blur(radius: 40)
                                .opacity(0.6)
                        default:
                            Color.Background.elevated
                        }
                    }
                } else {
                    Color.Background.elevated
                }

                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.1),
                        Color.Background.default
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Content
                VStack(spacing: Spacing.md) {
                    // Artist image
                    if let imageUrl = viewModel.artistInfo?.bestImageURL ?? artist.imageURL {
                        AsyncImage(url: SubsonicClient.shared.coverArtURL(for: imageUrl, size: 400)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 160, height: 160)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
                            default:
                                artistPlaceholder
                            }
                        }
                    } else {
                        artistPlaceholder
                    }

                    // Label
                    Text("ARTIST")
                        .font(.Navi.captionSmall)
                        .foregroundColor(Color.Text.tertiary)
                        .tracking(2)

                    // Name
                    Text(artist.name)
                        .font(.Navi.displaySmall)
                        .foregroundColor(Color.Text.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.bottom, Spacing.xl)
            }
            .frame(height: 320)
        }
        .frame(height: 320)
    }

    private var artistPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.Background.elevated)
                .frame(width: 160, height: 160)

            Image(systemName: "person.fill")
                .font(.system(size: 64))
                .foregroundColor(Color.Text.tertiary)
        }
    }

    // MARK: - Play Controls
    private var playControls: some View {
        HStack(spacing: Spacing.md) {
            // Play all
            Button {
                Task {
                    await viewModel.playAll()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Play")
                        .font(.Navi.labelLarge)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.white)
                .cornerRadius(CornerRadius.md)
            }

            // Shuffle all
            Button {
                Task {
                    await viewModel.shuffleAll()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Shuffle")
                        .font(.Navi.labelLarge)
                }
                .foregroundColor(Color.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.Background.elevated)
                .cornerRadius(CornerRadius.md)
            }

            // Radio
            Button {
                Task {
                    await viewModel.startRadio()
                }
            } label: {
                Image(systemName: "radio")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.Text.primary)
                    .frame(width: 44, height: 44)
                    .background(Color.Background.elevated)
                    .cornerRadius(CornerRadius.md)
            }
        }
    }

    // MARK: - Stats Row
    private func statsRow(_ artist: Artist) -> some View {
        HStack(spacing: Spacing.xl) {
            if let count = artist.albumCount, count > 0 {
                statItem(value: "\(count)", label: count == 1 ? "Album" : "Albums")
            }

            if let listeners = artist.lastfmListeners, listeners > 0 {
                statItem(value: formatNumber(listeners), label: "Listeners")
            }

            if let plays = artist.lastfmPlaycount, plays > 0 {
                statItem(value: formatNumber(plays), label: "Plays")
            }
        }
        .padding(.horizontal, Spacing.Page.horizontal)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.Navi.headlineSmall)
                .foregroundColor(Color.Text.primary)

            Text(label)
                .font(.Navi.caption)
                .foregroundColor(Color.Text.tertiary)
        }
    }

    private func formatNumber(_ num: Int64) -> String {
        if num >= 1_000_000 {
            return String(format: "%.1fM", Double(num) / 1_000_000)
        } else if num >= 1_000 {
            return String(format: "%.1fK", Double(num) / 1_000)
        }
        return "\(num)"
    }

    // MARK: - Biography Section
    private func biographySection(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("BIOGRAPHY")
                .font(.Navi.captionSmall)
                .foregroundColor(Color.Text.tertiary)
                .tracking(1)

            ExpandableText(text: bio, lineLimit: 4)
        }
        .padding(.horizontal, Spacing.Page.horizontal)
    }

    // MARK: - Albums Section
    private func albumsSection(_ albums: [Album]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("ALBUMS")
                    .font(.Navi.captionSmall)
                    .foregroundColor(Color.Text.tertiary)
                    .tracking(1)

                Spacer()

                Text("\(albums.count)")
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.tertiary)
            }
            .padding(.horizontal, Spacing.Page.horizontal)

            // Albums grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.Card.gap),
                GridItem(.flexible(), spacing: Spacing.Card.gap)
            ], spacing: Spacing.Card.gap) {
                ForEach(albums) { album in
                    NavigationLink {
                        AlbumDetailView(albumId: album.id)
                    } label: {
                        artistAlbumCard(album)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.Page.horizontal)
        }
    }

    private func artistAlbumCard(_ album: Album) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            AsyncArtwork(
                url: SubsonicClient.shared.coverArtURL(for: album.coverArt, size: 300),
                size: 160,
                cornerRadius: CornerRadius.md
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.Navi.titleSmall)
                    .foregroundColor(Color.Text.primary)
                    .lineLimit(1)

                if let year = album.yearString {
                    Text(year)
                        .font(.Navi.caption)
                        .foregroundColor(Color.Text.tertiary)
                }
            }
        }
    }

    // MARK: - Similar Artists Section
    private func similarArtistsSection(_ artists: [Artist]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("SIMILAR ARTISTS")
                .font(.Navi.captionSmall)
                .foregroundColor(Color.Text.tertiary)
                .tracking(1)
                .padding(.horizontal, Spacing.Page.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(artists) { artist in
                        NavigationLink {
                            ArtistDetailView(artistId: artist.id)
                        } label: {
                            similarArtistCard(artist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.Page.horizontal)
            }
        }
    }

    private func similarArtistCard(_ artist: Artist) -> some View {
        VStack(spacing: Spacing.sm) {
            if let imageUrl = artist.imageURL {
                AsyncImage(url: SubsonicClient.shared.coverArtURL(for: imageUrl, size: 200)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    default:
                        Circle()
                            .fill(Color.Background.elevated)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.Text.tertiary)
                            )
                    }
                }
            } else {
                Circle()
                    .fill(Color.Background.elevated)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color.Text.tertiary)
                    )
            }

            Text(artist.name)
                .font(.Navi.caption)
                .foregroundColor(Color.Text.primary)
                .lineLimit(1)
        }
        .frame(width: 100)
    }

    // MARK: - External Links Section
    private var externalLinksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("LINKS")
                .font(.Navi.captionSmall)
                .foregroundColor(Color.Text.tertiary)
                .tracking(1)

            HStack(spacing: Spacing.md) {
                if let lastFmUrl = viewModel.artistInfo?.lastFmUrl,
                   let url = URL(string: lastFmUrl) {
                    Link(destination: url) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "link")
                                .font(.system(size: 14))
                            Text("Last.fm")
                                .font(.Navi.labelMedium)
                        }
                        .foregroundColor(Color.Accent.cyan)
                    }
                }

                if let mbid = viewModel.artistInfo?.musicBrainzId,
                   let url = URL(string: "https://musicbrainz.org/artist/\(mbid)") {
                    Link(destination: url) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "link")
                                .font(.system(size: 14))
                            Text("MusicBrainz")
                                .font(.Navi.labelMedium)
                        }
                        .foregroundColor(Color.Accent.cyan)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.Page.horizontal)
    }

    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Color.Text.tertiary)

            Text("Failed to load artist")
                .font(.Navi.bodyMedium)
                .foregroundColor(Color.Text.secondary)

            Button("Try Again") {
                Task {
                    await viewModel.load()
                }
            }
            .font(.Navi.labelLarge)
            .foregroundColor(Color.Accent.cyan)
        }
    }
}

// MARK: - Expandable Text
struct ExpandableText: View {
    let text: String
    let lineLimit: Int

    @State private var isExpanded = false
    @State private var isTruncated = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(text)
                .font(.Navi.bodySmall)
                .foregroundColor(Color.Text.secondary)
                .lineLimit(isExpanded ? nil : lineLimit)
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            // Check if text is truncated
                            let totalHeight = text.boundingRect(
                                with: CGSize(width: geometry.size.width, height: .infinity),
                                options: .usesLineFragmentOrigin,
                                attributes: [.font: UIFont.systemFont(ofSize: 14)],
                                context: nil
                            ).height

                            let lineHeight = UIFont.systemFont(ofSize: 14).lineHeight
                            isTruncated = totalHeight > lineHeight * CGFloat(lineLimit)
                        }
                    }
                )

            if isTruncated {
                Button {
                    withAnimation(.Navi.smooth) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show less" : "Read more")
                        .font(.Navi.labelMedium)
                        .foregroundColor(Color.Accent.cyan)
                }
            }
        }
    }
}

// MARK: - Artist Detail ViewModel
@MainActor
final class ArtistDetailViewModel: ObservableObject {
    @Published var artist: Artist?
    @Published var artistInfo: ArtistInfo?
    @Published var isLoading = false

    let artistId: String
    private let client = SubsonicClient.shared
    private let audioEngine = AudioEngine.shared

    init(artistId: String) {
        self.artistId = artistId
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let artistTask = client.getArtist(id: artistId)
            async let infoTask = client.getArtistInfo(id: artistId)

            let (loadedArtist, loadedInfo) = try await (artistTask, infoTask)
            artist = loadedArtist
            artistInfo = loadedInfo
        } catch {
            print("Failed to load artist: \(error)")
        }
    }

    func playAll() async {
        guard let artist = artist else { return }

        // Collect all tracks from all albums
        var allTracks: [Track] = []
        for album in artist.albums {
            do {
                let fullAlbum = try await client.getAlbum(id: album.id)
                allTracks.append(contentsOf: fullAlbum.tracks)
            } catch {
                print("Failed to load album \(album.id)")
            }
        }

        if !allTracks.isEmpty {
            await audioEngine.setQueue(allTracks)
            audioEngine.play()
        }
    }

    func shuffleAll() async {
        guard let artist = artist else { return }

        var allTracks: [Track] = []
        for album in artist.albums {
            do {
                let fullAlbum = try await client.getAlbum(id: album.id)
                allTracks.append(contentsOf: fullAlbum.tracks)
            } catch {
                print("Failed to load album \(album.id)")
            }
        }

        if !allTracks.isEmpty {
            allTracks.shuffle()
            await audioEngine.setQueue(allTracks)
            audioEngine.play()
        }
    }

    func startRadio() async {
        // Could use getSimilarSongs2 or getTopSongs
        guard artist != nil else { return }

        do {
            // Get top songs for artist as radio seed
            let songs = try await client.getLibraryRadio(count: 50)
            // Filter to artist or similar
            if !songs.isEmpty {
                await audioEngine.setQueue(songs)
                audioEngine.play()
            }
        } catch {
            print("Failed to start radio")
        }
    }

}

// MARK: - Preview
#if DEBUG
struct ArtistDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ArtistDetailView(artistId: "preview")
        }
    }
}
#endif
