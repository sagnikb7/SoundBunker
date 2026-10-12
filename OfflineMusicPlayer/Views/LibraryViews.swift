import SwiftUI

@MainActor
final class ThumbnailLoader {
    static let shared = ThumbnailLoader()
    private let cache = NSCache<NSString, UIImage>()
    init() { cache.totalCostLimit = 12_000_000 }
    func image(_ path: String) -> UIImage? {
        if let image = cache.object(forKey: path as NSString) { return image }
        guard let image = UIImage(contentsOfFile: path) else { return nil }
        cache.setObject(image, forKey: path as NSString, cost: Int(image.size.width * image.size.height * 4))
        return image
    }
    func clear() { cache.removeAllObjects() }
}

struct ArtworkView: View {
    @EnvironmentObject private var library: LibraryStore
    var track: Track?
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let name = track?.artwork, let image = ThumbnailLoader.shared.image(library.artworkDirectory.appendingPathComponent(name).path) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    ZStack { Color(UIColor.secondarySystemBackground); Image(systemName: "music.note").font(.system(size: max(18, geometry.size.width * 0.35))).foregroundColor(.secondary) }
                }
            }.frame(width: geometry.size.width, height: geometry.size.height).clipped().cornerRadius(6)
        }.accessibilityHidden(true)
    }
}

struct SongRow: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var playback: PlaybackCoordinator
    var track: Track
    var play: () -> Void
    @State private var destination: PlayerDestination?
    var body: some View {
        HStack(spacing: 12) {
            Button(action: play) {
                HStack(spacing: 12) {
                    ArtworkView(track: track).frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title).font(.callout).foregroundColor(playback.currentTrack?.id == track.id ? .blue : .primary).lineLimit(1)
                        Text(track.available ? track.artist : "Unavailable · reconnect folder").font(.footnote).foregroundColor(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }.frame(minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(VisualPressButtonStyle())
            Menu {
                Button("Go to Artist", systemImage: "person.fill") { destination = .artist(track.artist) }
                Button("Go to Album", systemImage: "square.stack") { destination = .album(track.albumKey) }
                Button("Play Next", systemImage: "text.insert") { playback.playNext(track) }
                Button("Add to Queue", systemImage: "text.badge.plus") { playback.addToQueue(track) }
                Button(track.favorite ? "Remove Favorite" : "Add to Favorites", systemImage: track.favorite ? "heart.slash" : "heart") { library.favorite(track) }
                if !library.playlists.isEmpty {
                    Menu("Add to Playlist") {
                        ForEach(library.playlists) { playlist in
                            Button { library.addTrack(track.id, to: playlist.id) } label: {
                                Label(playlist.name, systemImage: playlist.trackIDs.contains(track.id) ? "checkmark" : "plus")
                            }.disabled(playlist.trackIDs.contains(track.id))
                        }
                    }
                }
            } label: { Image(systemName: "ellipsis").foregroundColor(.secondary).frame(width: 44, height: 44) }.accessibilityLabel("More options for \(track.title)")
        }.listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 8))
            .background {
                NavigationLink(isActive: Binding(get: { destination != nil }, set: { if !$0 { destination = nil } })) {
                    if let destination = destination { SongDestinationContent(destination: destination) }
                } label: { EmptyView() }.hidden()
            }
    }
}

struct SongListView: View {
    @EnvironmentObject private var playback: PlaybackCoordinator
    var title: String
    var tracks: [Track]
    @State private var query = ""
    @State private var sort = "Default"
    var body: some View {
        Group {
            if tracks.isEmpty { EmptyLibraryView(symbol: "music.note", title: "No songs yet", detail: "Add a music folder or import audio files from Library.") }
            else {
                List {
                    HStack {
                        Text("\(filtered.count) songs").font(.footnote).foregroundColor(.secondary)
                        Spacer()
                        Menu(sort) { Button("Default") { sort = "Default" }; Button("Title") { sort = "Title" }; Button("Artist") { sort = "Artist" } }.font(.footnote)
                    }
                    PlayButtons(tracks: filtered)
                    ForEach(filtered) { track in SongRow(track: track) { playback.play(filtered, startingAt: track) } }
                }.listStyle(.plain)
            }
        }.navigationTitle(title).searchable(text: $query, prompt: "Search songs")
    }
    private var filtered: [Track] {
        let result = tracks.filter { query.isEmpty || ($0.title + " " + $0.artist + " " + $0.album).localizedCaseInsensitiveContains(query) }
        if sort == "Title" { return result.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending } }
        if sort == "Artist" { return result.sorted { $0.artist.localizedStandardCompare($1.artist) == .orderedAscending } }
        return result
    }
}

struct PlayButtons: View {
    @EnvironmentObject private var playback: PlaybackCoordinator
    var tracks: [Track]
    var body: some View {
        HStack(spacing: 12) {
            Button { playback.play(tracks) } label: { Label("Play", systemImage: "play.fill").frame(maxWidth: .infinity, minHeight: 36) }
            Button { playback.play(tracks, shuffled: true) } label: { Label("Shuffle", systemImage: "shuffle").frame(maxWidth: .infinity, minHeight: 36) }
        }.buttonStyle(.bordered).disabled(!tracks.contains(where: \.available))
    }
}

struct AlbumGroup: Identifiable {
    var id: String
    var title: String
    var artist: String
    var tracks: [Track]
    var added: Date { tracks.map(\.added).max() ?? .distantPast }
    static func make(_ tracks: [Track]) -> [AlbumGroup] {
        Dictionary(grouping: tracks, by: \.albumKey).map { key, tracks in
            AlbumGroup(id: key, title: tracks[0].album, artist: tracks[0].albumArtist,
                       tracks: tracks.sorted { ($0.discNumber, $0.trackNumber, $0.title) < ($1.discNumber, $1.trackNumber, $1.title) })
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}
struct AlbumTile: View {
    var album: AlbumGroup
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ArtworkView(track: album.tracks.first).aspectRatio(1, contentMode: .fit)
            Text(album.title).font(.subheadline.weight(.semibold)).lineLimit(1).foregroundColor(.primary)
            Text(album.artist).font(.footnote).lineLimit(1).foregroundColor(.secondary)
        }
    }
}
struct AlbumsView: View {
    @EnvironmentObject private var library: LibraryStore
    var body: some View {
        ScrollView { LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 16) {
            ForEach(library.browse.albums) { album in NavigationLink { AlbumDetailView(album: album) } label: { AlbumTile(album: album) }.buttonStyle(.plain) }
        }.padding(16) }.navigationTitle("Albums")
    }
}
struct AlbumDetailView: View {
    @EnvironmentObject private var playback: PlaybackCoordinator
    var album: AlbumGroup
    var body: some View {
        List {
            VStack(spacing: 12) {
                ArtworkView(track: album.tracks.first).frame(width: 148, height: 148)
                Text(album.title).font(.title2.bold()).multilineTextAlignment(.center)
                Text(album.artist).foregroundColor(.blue)
                Text("\(album.tracks.count) songs").font(.caption).foregroundColor(.secondary)
            }.frame(maxWidth: .infinity).padding(.vertical, 12).listRowSeparator(.hidden)
            PlayButtons(tracks: album.tracks)
            ForEach(album.tracks) { track in SongRow(track: track) { playback.play(album.tracks, startingAt: track) } }
        }.listStyle(.plain).navigationTitle(album.title).navigationBarTitleDisplayMode(.inline)
    }
}
struct GroupsView: View {
    enum Kind { case artist, genre }
    @EnvironmentObject private var library: LibraryStore
    var kind: Kind
    var body: some View {
        List(groups, id: \.self) { group in
            let tracks = (kind == .artist ? library.browse.artists[group] : library.browse.genres[group]) ?? []
            NavigationLink { SongListView(title: group, tracks: tracks) } label: {
                if kind == .artist { ArtistGroupRow(artist: group, count: tracks.count) }
                else {
                    HStack { Image(systemName: "waveform").foregroundColor(.blue).frame(width: 32)
                        VStack(alignment: .leading) { Text(group); Text("\(tracks.count) songs").font(.footnote).foregroundColor(.secondary) }
                    }.frame(minHeight: 44)
                }
            }
        }.listStyle(.plain).navigationTitle(kind == .artist ? "Artists" : "Genres")
    }
    private var groups: [String] { kind == .artist ? library.browse.artistNames : library.browse.genreNames }
}

struct FoldersView: View {
    @EnvironmentObject private var library: LibraryStore
    var body: some View {
        List {
            ForEach(library.sources) { source in
                NavigationLink { FolderContentsView(source: source, path: "") } label: {
                    HStack { Image(systemName: "folder.fill").foregroundColor(.blue).frame(width: 32)
                        VStack(alignment: .leading) { Text(source.name); Text(source.needsReconnect ? "Reconnect required" : "\(library.tracks.filter { $0.locations.contains { $0.sourceID == source.id } }.count) songs").font(.footnote).foregroundColor(.secondary) }
                    }.frame(minHeight: 44)
                }
            }
            Button("Add Music Folder…") { library.pickerRequest = PickerRequest(folders: true) }
        }.navigationTitle("Folders")
    }
}
struct FolderContentsView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var playback: PlaybackCoordinator
    var source: MusicSource
    var path: String
    private var entries: [(Track, String)] { library.sortedTracks.compactMap { track in
        guard let location = track.locations.first(where: { $0.sourceID == source.id }), location.relativePath.hasPrefix(path) else { return nil }
        return (track, String(location.relativePath.dropFirst(path.count)))
    } }
    private var folders: [String] { Set(entries.compactMap { $0.1.contains("/") ? $0.1.components(separatedBy: "/").first : nil }).sorted() }
    private var songs: [Track] { entries.filter { !$0.1.contains("/") }.map { $0.0 } }
    var body: some View {
        List {
            ForEach(folders, id: \.self) { folder in NavigationLink { FolderContentsView(source: source, path: path + folder + "/") } label: { Label(folder, systemImage: "folder") } }
            if !songs.isEmpty { PlayButtons(tracks: songs) }
            ForEach(songs) { track in SongRow(track: track) { playback.play(songs, startingAt: track) } }
            if entries.isEmpty { Text("No indexed audio in this folder.").foregroundColor(.secondary) }
        }.listStyle(.plain).navigationTitle(path.isEmpty ? source.name : String(path.dropLast()).components(separatedBy: "/").last ?? source.name).navigationBarTitleDisplayMode(.inline)
    }
}

/// Shared destinations keep song menus consistent across albums, playlists, search and the player.
struct SongDestinationContent: View {
    @EnvironmentObject private var library: LibraryStore
    var destination: PlayerDestination
    @ViewBuilder var body: some View {
        switch destination {
        case .artist(let name): SongListView(title: name, tracks: library.browse.artists[name] ?? [])
        case .album(let key):
            if let album = library.browse.albums.first(where: { $0.id == key }) { AlbumDetailView(album: album) }
            else { Text("Album is unavailable") }
        }
    }
}


struct RecentlyPlayedTile: View {
    @EnvironmentObject private var playback: PlaybackCoordinator
    var track: Track
    var body: some View {
        Button { playback.play([track]) } label: {
            VStack(alignment: .leading, spacing: 5) {
                ArtworkView(track: track).aspectRatio(1, contentMode: .fit)
                Text(track.title).font(.subheadline.weight(.semibold)).foregroundColor(.primary).lineLimit(1)
                Text(track.artist).font(.footnote).foregroundColor(.secondary).lineLimit(1)
            }
        }.buttonStyle(.plain).accessibilityLabel("Play \(track.title) by \(track.artist)")
    }
}

struct ListeningHistoryView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var playback: PlaybackCoordinator
    var body: some View {
        Group {
            if library.historySongs.isEmpty {
                EmptyLibraryView(symbol: "clock", title: "No listening history yet", detail: "Songs you play will appear here, with the most recent first.")
            } else {
                List {
                    ForEach(library.historySongs) { song in
                        VStack(alignment: .leading, spacing: 2) {
                            SongRow(track: song.track) { playback.play([song.track]) }
                            Text(song.entry.playedAt, style: .date) + Text(" · ") + Text(song.entry.playedAt, style: .time)
                        }.font(.caption).foregroundColor(.secondary)
                    }
                }.listStyle(.plain)
            }
        }.navigationTitle("Listening History").navigationBarTitleDisplayMode(.inline)
    }
}
