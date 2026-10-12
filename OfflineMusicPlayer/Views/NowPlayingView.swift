import SwiftUI

struct MiniPlayer: View {
    @EnvironmentObject private var playback: PlaybackCoordinator
    @Binding var showingPlayer: Bool
    var body: some View {
        HStack(spacing: 8) {
            Button { showingPlayer = true } label: {
                HStack(spacing: 10) {
                    ArtworkView(track: playback.currentTrack).frame(width: 36, height: 36)
                    Text(playback.title ?? "").font(.subheadline).lineLimit(1).foregroundColor(.primary)
                    Spacer(minLength: 0)
                }.frame(minHeight: 52).contentShape(Rectangle())
            }.buttonStyle(VisualPressButtonStyle()).accessibilityLabel("Open Now Playing")
            Button { playback.toggle() } label: { Image(systemName: (playback.playbackRequested || playback.isPlaying) ? "pause.fill" : "play.fill").frame(width: 52, height: 52) }.accessibilityLabel((playback.playbackRequested || playback.isPlaying) ? "Pause" : "Play")
            Button { playback.next() } label: { Image(systemName: "forward.fill").frame(width: 52, height: 52) }.accessibilityLabel("Next song")
        }.buttonStyle(VisualPressButtonStyle()).padding(.horizontal, 12).background(.regularMaterial)
            .overlay(alignment: .top) { Divider() }
    }
}

enum PlayerDestination: Identifiable {
    case artist(String), album(String)
    var id: String { switch self { case .artist(let name): return "artist:" + name; case .album(let key): return "album:" + key } }
}

enum NowPlayingMode { case artwork, queue, lyrics }

struct NowPlayingView: View {
    @EnvironmentObject private var playback: PlaybackCoordinator
    var initialMode: NowPlayingMode = .artwork
    var body: some View { NowPlayingContent(clock: playback.clock, initialMode: initialMode) }
}

private struct NowPlayingContent: View {
    @ObservedObject var clock: PlaybackClock
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var playback: PlaybackCoordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mode: NowPlayingMode
    init(clock: PlaybackClock, initialMode: NowPlayingMode) { self.clock = clock; _mode = State(initialValue: initialMode) }
    @State private var scrubPosition: Double = 0
    @State private var isScrubbing = false
    @State private var playlistTrack: Track?
    @State private var destination: PlayerDestination?
    @State private var lyricLines: [LyricLine] = []
    var body: some View {
        ZStack {
            ArtworkSurface(artworkURL: currentTrack?.artwork.map { library.artworkDirectory.appendingPathComponent($0) })
            VStack(spacing: 0) {
                header
                GeometryReader { geometry in
                    if mode == .artwork {
                        ScrollView {
                            let side = max(0, min(240, geometry.size.width, geometry.size.height - 16))
                            PlaybackArtworkView(reduceMotion: reduceMotion, track: currentTrack, side: side, isPlaying: playback.playbackRequested || playback.isPlaying)
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .contentShape(Rectangle())
                                .simultaneousGesture(DragGesture(minimumDistance: 24, coordinateSpace: .global).onEnded { value in
                                    guard value.startLocation.x > 32, abs(value.translation.width) > 50,
                                          abs(value.translation.width) > abs(value.translation.height) * 1.4 else { return }
                                    if value.translation.width < 0 { playback.next() } else { playback.previousTrack() }
                                })
                        }
                    } else if mode == .queue { queueView }
                    else { lyricsView }
                }.frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
                // This dock is outside every ScrollView. Artwork/lyrics yield space first.
                controlDock
            }.padding(.horizontal, 24)
        }
        .buttonStyle(VisualPressButtonStyle())
        .background(BackGestureSupport(rootBack: { dismiss() }))
        .onAppear { playback.setPlayerVisible(true); playback.setLyricsTracking(mode == .lyrics && !lyricLines.isEmpty) }
        .onChange(of: mode) { playback.setLyricsTracking($0 == .lyrics && !lyricLines.isEmpty) }
        .onChange(of: lyricLines) { playback.setLyricsTracking(mode == .lyrics && !$0.isEmpty) }
        .onDisappear { playback.setPlayerVisible(false) }
        .task(id: lyricFingerprint) {
            lyricLines = []
            let text = currentTrack?.lyrics ?? ""
            let parsed = await Task.detached(priority: .utility) { LRCParser.parse(text) }.value
            if !Task.isCancelled { lyricLines = parsed }
        }
        .fullScreenCover(item: $destination) { route in
            NavigationView {
                Group {
                    switch route {
                    case .artist(let name): SongListView(title: name, tracks: library.browse.artists[name] ?? [])
                    case .album(let key):
                        if let album = library.browse.albums.first(where: { $0.id == key }) { AlbumDetailView(album: album) }
                        else { Text("Album is unavailable") }
                    }
                }.toolbar { ToolbarItem(placement: .cancellationAction) { Button("Back to Player") { destination = nil } } }
                    .background(BackGestureSupport(rootBack: { destination = nil }))
            }.navigationViewStyle(.stack)
        }
        .sheet(item: $playlistTrack) { track in
            AddToPlaylistView(track: track).environmentObject(library)
        }
    }
    private var header: some View {
        ZStack {
            VStack(spacing: 2) {
                Text("NOW PLAYING").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                if let album = currentTrack?.album, !album.isEmpty {
                    Text(album).font(.footnote).lineLimit(1)
                }
            }.multilineTextAlignment(.center).frame(maxWidth: .infinity)
                .padding(.horizontal, 52)
            HStack(spacing: 0) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.down").frame(width: 52, height: 52, alignment: .leading).contentShape(Rectangle())
                }.accessibilityLabel("Dismiss Now Playing")
                Spacer(minLength: 0)
            }
        }.frame(minHeight: 52)
    }

    private var metadata: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(playback.title ?? "Nothing playing").font(.title3.weight(.semibold)).lineLimit(2)
                if let artist = currentTrack?.artist { Text(artist).foregroundColor(.secondary).lineLimit(1) }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Menu {
                if let track = currentTrack {
                    Button("Go to Artist", systemImage: "person.fill") { destination = .artist(track.artist) }
                    Button("Go to Album", systemImage: "square.stack") { destination = .album(track.albumKey) }
                    Button(isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: isFavorite ? "heart.slash" : "heart") { if let current = library.track(track.id) { library.favorite(current) } }
                    Button("Play Next", systemImage: "text.insert") { playback.playNext(track) }
                    Button("Add to Queue", systemImage: "text.badge.plus") { playback.addToQueue(track) }
                }
                Button("Add to Playlist", systemImage: "text.badge.plus") { playlistTrack = currentTrack }
                    .disabled(currentTrack == nil)
            } label: {
                Image(systemName: "ellipsis").font(.title3)
                    .frame(width: 52, height: 52, alignment: .trailing).contentShape(Rectangle())
            }.accessibilityLabel("Song options")
        }.frame(minHeight: 52)
    }
    private var currentTrack: Track? { playback.currentTrack.flatMap { library.track($0.id) } ?? playback.currentTrack }
    private var lyricFingerprint: String? { currentTrack.map { $0.id + ":" + $0.fingerprint } }
    private var isFavorite: Bool { currentTrack.flatMap { library.track($0.id) }?.favorite ?? false }
    private var controlDock: some View {
        VStack(spacing: 4) {
            metadata
            VStack(spacing: 0) {
                Slider(value: Binding(get: { isScrubbing ? scrubPosition : playback.position }, set: { scrubPosition = $0 }), in: 0...max(playback.duration, 0.01), onEditingChanged: { editing in
                    if editing { scrubPosition = playback.position }; isScrubbing = editing
                    if !editing { playback.seek(to: scrubPosition) }
                }).frame(minHeight: 44).accessibilityLabel("Playback position")
                HStack { Text(time(isScrubbing ? scrubPosition : playback.position)); Spacer(); Text("−" + time(max(0, playback.duration - playback.position))) }.font(.caption.monospacedDigit()).foregroundColor(.secondary)
            }
            HStack(spacing: 0) {
                Button { playback.previous() } label: { Image(systemName: "backward.fill").font(.title2).frame(maxWidth: .infinity, minHeight: 72).contentShape(Rectangle()) }.accessibilityLabel("Previous song")
                Button { playback.toggle() } label: { Image(systemName: (playback.playbackRequested || playback.isPlaying) ? "pause.fill" : "play.fill").font(.system(size: 38)).frame(maxWidth: .infinity, minHeight: 72).contentShape(Rectangle()) }.accessibilityLabel((playback.playbackRequested || playback.isPlaying) ? "Pause" : "Play")
                Button { playback.next() } label: { Image(systemName: "forward.fill").font(.title2).frame(maxWidth: .infinity, minHeight: 72).contentShape(Rectangle()) }.accessibilityLabel("Next song")
            }.foregroundColor(.primary)
            HStack(spacing: 0) {
                Button { mode = mode == .lyrics ? .artwork : .lyrics } label: {
                    Image(systemName: "quote.bubble").font(.title3).foregroundColor(mode == .lyrics ? .blue : .secondary)
                        .padding(10).background(mode == .lyrics ? Color.blue.opacity(0.12) : Color.clear).cornerRadius(10)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: mode)
                        .frame(maxWidth: .infinity, minHeight: 56).contentShape(Rectangle())
                }.accessibilityLabel(mode == .lyrics ? "Hide lyrics" : "Show lyrics").accessibilityValue(mode == .lyrics ? "Selected" : "")
                Button {
                    if let current = currentTrack, let track = library.track(current.id) { library.favorite(track) }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart").font(.title3).foregroundColor(isFavorite ? .blue : .secondary)
                        .scaleEffect(isFavorite && !reduceMotion ? 1.08 : 1)
                        .padding(10).background(isFavorite ? Color.blue.opacity(0.12) : Color.clear).cornerRadius(10)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isFavorite)
                        .frame(maxWidth: .infinity, minHeight: 56).contentShape(Rectangle())
                }.disabled(currentTrack == nil).accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
                Button { mode = mode == .queue ? .artwork : .queue } label: {
                    Image(systemName: "list.bullet").font(.title3).foregroundColor(mode == .queue ? .blue : .secondary)
                        .padding(10).background(mode == .queue ? Color.blue.opacity(0.12) : Color.clear).cornerRadius(10)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: mode)
                        .frame(maxWidth: .infinity, minHeight: 56).contentShape(Rectangle())
                }.accessibilityLabel(mode == .queue ? "Hide playing queue" : "Show playing queue").accessibilityValue(mode == .queue ? "Selected" : "")
            }
        }.buttonStyle(VisualPressButtonStyle()).fixedSize(horizontal: false, vertical: true).padding(.top, 4).padding(.bottom, 8)
    }
    private var queueView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                Text("Playing Next").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                Button { playback.toggleShuffle() } label: {
                    Image(systemName: "shuffle").frame(width: 52, height: 52).contentShape(Rectangle()).foregroundColor(playback.shuffle ? .blue : .secondary)
                }.accessibilityLabel(playback.shuffle ? "Turn shuffle off" : "Turn shuffle on").accessibilityValue(playback.shuffle ? "On" : "Off")
                Button { playback.cycleRepeat() } label: {
                    Image(systemName: playback.repeatMode == .one ? "repeat.1" : "repeat").frame(width: 52, height: 52).contentShape(Rectangle()).foregroundColor(playback.repeatMode == .off ? .secondary : .blue)
                }.accessibilityLabel("Repeat \(playback.repeatMode.rawValue)")
            }.buttonStyle(VisualPressButtonStyle())
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(playback.queue.enumerated()).filter { $0.offset > playback.queueIndex }, id: \.offset) { entry in
                        if let track = library.track(entry.element) {
                            Button { playback.jump(to: entry.offset) } label: {
                                HStack(spacing: 10) {
                                    ArtworkView(track: track).frame(width: 36, height: 36)
                                    Text(track.title).foregroundColor(.primary).lineLimit(1)
                                    Spacer(minLength: 0)
                                }.frame(maxWidth: .infinity, minHeight: 52).contentShape(Rectangle())
                            }.buttonStyle(VisualPressButtonStyle())
                        }
                    }
                    if playback.queueIndex + 1 >= playback.queue.count { Text("Nothing queued").foregroundColor(.secondary).padding(.vertical, 8) }
                }
            }
        }
    }
    @ViewBuilder private var lyricsView: some View {
        if let lyrics = currentTrack?.lyrics, !lyrics.isEmpty {
            if lyricLines.isEmpty { ScrollView { Text(lyrics).frame(maxWidth: .infinity, alignment: .leading).font(.body).textSelection(.enabled) } }
            else { SyncedLyricsView(lines: lyricLines, position: playback.position, seek: playback.seek).id(lyricFingerprint) }
        } else {
            ScrollView {
                VStack(spacing: 8) {
                    Image(systemName: "quote.bubble").font(.title2).foregroundColor(.secondary)
                    Text("No local lyrics").font(.headline)
                    Text("Embedded lyrics or a matching .lrc file will appear here.").font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity).padding(.vertical, 8)
            }
        }
    }
    private func time(_ seconds: Double) -> String { let value = Int(max(0, seconds.isFinite ? seconds : 0)); return String(format: "%d:%02d", value / 60, value % 60) }
}
