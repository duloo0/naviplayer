//
//  ContentView.swift
//  naviplayer
//
//  Main tab bar view for the app
//

import SwiftUI

struct ContentView: View {
    @StateObject private var client = SubsonicClient.shared
    @StateObject private var audioEngine = AudioEngine.shared
    @State private var selectedTab: Tab = .library
    @State private var showNowPlaying = false

    enum Tab {
        case library
        case radio
        case search
        case settings
    }

    var body: some View {
        Group {
            if client.isConnected {
                mainTabView
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Verify saved connection is still valid on app launch
            await client.verifyConnection()
        }
    }

    // MARK: - Main Tab View
    private var mainTabView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // Library Tab
                NavigationStack {
                    LibraryView()
                }
                .tabItem {
                    Label("Library", systemImage: "music.note.house")
                }
                .tag(Tab.library)

                // Radio Tab
                NavigationStack {
                    RadioMenuView()
                }
                .tabItem {
                    Label("Radio", systemImage: "radio")
                }
                .tag(Tab.radio)

                // Search Tab
                NavigationStack {
                    SearchView()
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)

                // Settings Tab
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
            }
            .tint(Color.Accent.cyan)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Mini Player (above tab bar) - hidden when full player is showing
                if audioEngine.currentTrack != nil && !showNowPlaying {
                    MiniPlayer(audioEngine: audioEngine) {
                        showNowPlaying = true
                    }
                }
            }
        }
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
    }
}

// MARK: - Library View
struct LibraryView: View {
    @State private var selectedSection: LibrarySection = .albums
    @State private var albums: [Album] = []
    @State private var artists: [Artist] = []
    @State private var isLoading = false
    @State private var albumSortType: AlbumListType = .newest

    enum LibrarySection: String, CaseIterable {
        case albums = "Albums"
        case artists = "Artists"
    }

    var body: some View {
        ZStack {
            Color.Background.default
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Segment picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(LibrarySection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.Page.horizontal)
                .padding(.vertical, Spacing.sm)

                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.Accent.cyan))
                    Spacer()
                } else {
                    switch selectedSection {
                    case .albums:
                        albumsContent
                    case .artists:
                        artistsContent
                    }
                }
            }
        }
        .navigationTitle("Library")
        .toolbar {
            if selectedSection == .albums {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach([AlbumListType.newest, .recent, .frequent, .random, .alphabeticalByName], id: \.self) { type in
                            Button {
                                albumSortType = type
                                Task { await loadAlbums() }
                            } label: {
                                HStack {
                                    Text(sortTypeName(type))
                                    if albumSortType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(Color.Accent.cyan)
                    }
                }
            }
        }
        .task {
            await loadData()
        }
        .onChange(of: selectedSection) { _, _ in
            Task { await loadData() }
        }
    }

    private func sortTypeName(_ type: AlbumListType) -> String {
        switch type {
        case .newest: return "Recently Added"
        case .recent: return "Recently Played"
        case .frequent: return "Most Played"
        case .random: return "Random"
        case .alphabeticalByName: return "A-Z"
        default: return type.rawValue
        }
    }

    // MARK: - Albums Content
    private var albumsContent: some View {
        Group {
            if albums.isEmpty {
                emptyView(icon: "square.stack", message: "No albums yet")
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: Spacing.Card.gap),
                        GridItem(.flexible(), spacing: Spacing.Card.gap)
                    ], spacing: Spacing.Card.gap) {
                        ForEach(albums) { album in
                            NavigationLink {
                                AlbumDetailView(albumId: album.id)
                            } label: {
                                AlbumCard(album: album)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Spacing.Page.horizontal)
                    .padding(.bottom, 100) // Space for mini player
                }
            }
        }
    }

    // MARK: - Artists Content
    private var artistsContent: some View {
        Group {
            if artists.isEmpty {
                emptyView(icon: "person.2", message: "No artists yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(artists) { artist in
                            NavigationLink {
                                ArtistDetailView(artistId: artist.id)
                            } label: {
                                ArtistRow(artist: artist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
    }

    private func emptyView(icon: String, message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Color.Text.tertiary)

            Text(message)
                .font(.Navi.bodyMedium)
                .foregroundColor(Color.Text.secondary)
            Spacer()
        }
    }

    // MARK: - Data Loading
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        switch selectedSection {
        case .albums:
            await loadAlbums()
        case .artists:
            await loadArtists()
        }
    }

    private func loadAlbums() async {
        do {
            albums = try await SubsonicClient.shared.getAlbumList(type: albumSortType, size: 100)
        } catch {
            print("Failed to load albums: \(error)")
        }
    }

    private func loadArtists() async {
        do {
            artists = try await SubsonicClient.shared.getArtists()
        } catch {
            print("Failed to load artists: \(error)")
        }
    }
}

// MARK: - Album Card
struct AlbumCard: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Artwork
            AsyncArtwork(
                url: SubsonicClient.shared.coverArtURL(for: album.coverArt, size: 300),
                size: 160,
                cornerRadius: CornerRadius.md
            )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.Navi.titleSmall)
                    .foregroundColor(Color.Text.primary)
                    .lineLimit(1)

                Text(album.effectiveArtist)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Artist Row
struct ArtistRow: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Artist image
            if let imageUrl = artist.imageURL {
                AsyncImage(url: SubsonicClient.shared.coverArtURL(for: imageUrl, size: 100)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    default:
                        artistPlaceholder
                    }
                }
            } else {
                artistPlaceholder
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(.Navi.titleSmall)
                    .foregroundColor(Color.Text.primary)
                    .lineLimit(1)

                Text(artist.albumCountString)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color.Text.tertiary)
        }
        .padding(.horizontal, Spacing.Page.horizontal)
        .padding(.vertical, Spacing.sm)
    }

    private var artistPlaceholder: some View {
        Circle()
            .fill(Color.Background.elevated)
            .frame(width: 56, height: 56)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.Text.tertiary)
            )
    }
}

// MARK: - Search View
struct SearchView: View {
    @State private var query = ""
    @State private var result: SearchResult?
    @State private var isSearching = false
    @StateObject private var audioEngine = AudioEngine.shared

    var body: some View {
        ZStack {
            Color.Background.default
                .ignoresSafeArea()

            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.Text.tertiary)

                    TextField("Search songs, albums, artists...", text: $query)
                        .font(.Navi.bodyLarge)
                        .foregroundColor(Color.Text.primary)
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            Task { await search() }
                        }

                    if !query.isEmpty {
                        Button {
                            query = ""
                            result = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.Text.tertiary)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.Background.elevated)
                .cornerRadius(CornerRadius.md)
                .padding(.horizontal, Spacing.Page.horizontal)

                if isSearching {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.Accent.cyan))
                    Spacer()
                } else if let result = result {
                    searchResults(result)
                } else {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(Color.Text.tertiary)
                    Text("Search your library")
                        .font(.Navi.bodyMedium)
                        .foregroundColor(Color.Text.secondary)
                    Spacer()
                }
            }
        }
        .navigationTitle("Search")
    }

    private func searchResults(_ result: SearchResult) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                // Artists
                if !result.artists.isEmpty {
                    sectionHeader("Artists")
                    ForEach(result.artists) { artist in
                        NavigationLink {
                            ArtistDetailView(artistId: artist.id)
                        } label: {
                            searchArtistRow(artist: artist)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Albums
                if !result.albums.isEmpty {
                    sectionHeader("Albums")
                    ForEach(result.albums) { album in
                        NavigationLink {
                            AlbumDetailView(albumId: album.id)
                        } label: {
                            searchAlbumRow(album: album)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Songs
                if !result.songs.isEmpty {
                    sectionHeader("Songs")
                    ForEach(Array(result.songs.enumerated()), id: \.element.id) { index, song in
                        Button {
                            Task {
                                await playSong(song, from: result.songs, at: index)
                            }
                        } label: {
                            searchSongRow(song: song)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Spacing.Page.horizontal)
            .padding(.bottom, 100) // Space for mini player
        }
    }

    // MARK: - Row Components

    private func searchArtistRow(artist: Artist) -> some View {
        HStack(spacing: Spacing.md) {
            // Artist image
            if let imageUrl = artist.imageURL {
                AsyncImage(url: SubsonicClient.shared.coverArtURL(for: imageUrl, size: 100)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    default:
                        artistPlaceholder(size: 48)
                    }
                }
            } else {
                artistPlaceholder(size: 48)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(.Navi.bodyMedium)
                    .foregroundColor(Color.Text.primary)
                    .lineLimit(1)

                Text(artist.albumCountString)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color.Text.tertiary)
        }
        .padding(.vertical, Spacing.xs)
    }

    private func searchAlbumRow(album: Album) -> some View {
        HStack(spacing: Spacing.md) {
            MiniArtwork(
                url: SubsonicClient.shared.coverArtURL(for: album.coverArt, size: 100),
                size: 48
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.Navi.bodyMedium)
                    .foregroundColor(Color.Text.primary)
                    .lineLimit(1)

                Text(album.effectiveArtist)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let year = album.yearString {
                Text(year)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.tertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color.Text.tertiary)
        }
        .padding(.vertical, Spacing.xs)
    }

    private func searchSongRow(song: Track) -> some View {
        let isPlaying = audioEngine.currentTrack?.id == song.id

        return HStack(spacing: Spacing.md) {
            // Playing indicator or artwork
            ZStack {
                MiniArtwork(
                    url: SubsonicClient.shared.coverArtURL(for: song.coverArt, size: 100),
                    size: 44
                )

                if isPlaying {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 44, height: 44)
                        .cornerRadius(CornerRadius.sm)

                    Image(systemName: "waveform")
                        .font(.system(size: 14))
                        .foregroundColor(Color.Accent.cyan)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.Navi.bodyMedium)
                    .foregroundColor(isPlaying ? Color.Accent.cyan : Color.Text.primary)
                    .lineLimit(1)

                Text(song.effectiveArtist)
                    .font(.Navi.caption)
                    .foregroundColor(Color.Text.secondary)
                    .lineLimit(1)
            }

            Spacer()

            QualityTierBadge(track: song)

            Text(song.formattedDuration)
                .font(.Navi.caption)
                .foregroundColor(Color.Text.tertiary)
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }

    private func artistPlaceholder(size: CGFloat) -> some View {
        Circle()
            .fill(Color.Background.elevated)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(Color.Text.tertiary)
            )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.Navi.captionSmall)
            .foregroundColor(Color.Text.tertiary)
            .tracking(1)
            .padding(.top, Spacing.sm)
    }

    // MARK: - Actions

    private func search() async {
        guard !query.isEmpty else { return }
        isSearching = true
        defer { isSearching = false }

        do {
            result = try await SubsonicClient.shared.search(query: query)
        } catch {
            print("Search failed: \(error)")
        }
    }

    private func playSong(_ song: Track, from songs: [Track], at index: Int) async {
        await audioEngine.setQueue(songs, startIndex: index)
        audioEngine.play()
    }
}

// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        ZStack {
            Color.Background.default
                .ignoresSafeArea()

            List {
                Section {
                    HStack {
                        Text("Server")
                        Spacer()
                        Text(SubsonicClient.shared.configuration?.url.host ?? "Not connected")
                            .foregroundColor(Color.Text.secondary)
                    }

                    HStack {
                        Text("Username")
                        Spacer()
                        Text(SubsonicClient.shared.configuration?.username ?? "")
                            .foregroundColor(Color.Text.secondary)
                    }
                } header: {
                    Text("Connection")
                }

                Section {
                    Button("Disconnect", role: .destructive) {
                        SubsonicClient.shared.disconnect()
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
