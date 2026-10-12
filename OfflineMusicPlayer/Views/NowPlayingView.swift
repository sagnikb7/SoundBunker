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
            }.buttonStyle(.plain).accessibilityLabel("Open Now Playing")
            Button { playback.toggle() } label: { Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill").frame(width: 44, height: 44) }.accessibilityLabel(playback.isPlaying ? "Pause" : "Play")
            Button { playback.next() } label: { Image(systemName: "forward.fill").frame(width: 44, height: 44) }.accessibilityLabel("Next song")
        }.padding(.horizontal, 12).background(.regularMaterial)
            .overlay(alignment: .top) { Divider() }
    }
}

struct NowPlayingView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var playback: PlaybackCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var mode = "artwork"
    @State private var scrubPosition: Double = 0
    @State private var isScrubbing = false
    @State private var playlistTrack: Track?
    @State private var lyricLines: [LyricLine] = []
    var body: some View {
        ZStack {
            ArtworkSurface(artworkURL: playback.currentTrack?.artwork.map { library.artworkDirectory.appendingPathComponent($0) })
            VStack(spacing: 0) {
                header
                GeometryReader { geometry in
                    if mode == "artwork" {
                        ScrollView {
                            VStack(spacing: 12) {
                                let side = max(0, min(240, geometry.size.width - 48, geometry.size.height - 88))
                                ArtworkView(track: playback.currentTrack).frame(width: side, height: side)
                                metadata
                            }.frame(maxWidth: .infinity).padding(.vertical, 8)
                        }
                    } else {
                        VStack(spacing: 8) {
                            metadata
                            if mode == "queue" { queueView } else { lyricsView }
                        }.padding(.top, 8)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                // This dock is outside every ScrollView. Artwork/lyrics yield space first.
                controlDock
            }.padding(.horizontal, 24)
        }
        .task(id: playback.currentTrack?.id) {
            let text = playback.currentTrack?.lyrics ?? ""
            let parsed = await Task.detached(priority: .utility) { LRCParser.parse(text) }.value
            if !Task.isCancelled { lyricLines = parsed }
        }
        .sheet(item: $playlistTrack) { track in
            AddToPlaylistView(track: track).environmentObject(library)
        }
    }
    private var header: some View {
        HStack {
            Button { dismiss() } label: { Image(systemName: "chevron.down").frame(width: 44, height: 44) }.accessibilityLabel("Dismiss Now Playing")
            Spacer(minLength: 4)
            VStack(spacing: 2) {
                Text("NOW PLAYING").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                Text(playback.currentTrack?.album ?? "").font(.footnote).lineLimit(1)
            }
            Spacer(minLength: 4)
            Menu {
                Button("Add to Playlist", systemImage: "text.badge.plus") { playlistTrack = playback.currentTrack }
                    .disabled(playback.currentTrack == nil)
                Button(mode == "queue" ? "Show Artwork" : "Up Next", systemImage: "list.bullet") { mode = mode == "queue" ? "artwork" : "queue" }
            } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }.accessibilityLabel("Now Playing options")
        }.frame(minHeight: 44)
    }
    private var metadata: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(playback.title ?? "Nothing playing").font(.title3.weight(.semibold)).lineLimit(2)
                Text(playback.currentTrack?.artist ?? "").foregroundColor(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            Button { if let current = playback.currentTrack, let track = library.track(current.id) { library.favorite(track) } } label: {
                Image(systemName: (playback.currentTrack.flatMap { library.track($0.id) }?.favorite ?? false) ? "heart.fill" : "heart").frame(width: 44, height: 44)
            }.accessibilityLabel("Toggle favorite")
        }
    }
    private var controlDock: some View {
        VStack(spacing: 4) {
            VStack(spacing: 0) {
                Slider(value: Binding(get: { isScrubbing ? scrubPosition : playback.position }, set: { scrubPosition = $0 }), in: 0...max(playback.duration, 0.01), onEditingChanged: { editing in
                    if editing { scrubPosition = playback.position }; isScrubbing = editing
                    if !editing { playback.seek(to: scrubPosition) }
                }).accessibilityLabel("Playback position")
                HStack { Text(time(isScrubbing ? scrubPosition : playback.position)); Spacer(); Text("−" + time(max(0, playback.duration - playback.position))) }.font(.caption.monospacedDigit()).foregroundColor(.secondary)
            }
            HStack(spacing: 36) {
                Button { playback.previous() } label: { Image(systemName: "backward.fill").font(.title2).frame(width: 44, height: 44) }.accessibilityLabel("Previous song")
                Button { playback.toggle() } label: { Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 38)).frame(width: 64, height: 60) }.accessibilityLabel(playback.isPlaying ? "Pause" : "Play")
                Button { playback.next() } label: { Image(systemName: "forward.fill").font(.title2).frame(width: 44, height: 44) }.accessibilityLabel("Next song")
            }.foregroundColor(.primary)
            HStack(spacing: 30) {
                Button { playback.toggleShuffle() } label: { Image(systemName: "shuffle").frame(width: 44, height: 44).foregroundColor(playback.shuffle ? .blue : .secondary) }.accessibilityLabel(playback.shuffle ? "Turn shuffle off" : "Turn shuffle on")
                Button { playback.cycleRepeat() } label: { Image(systemName: playback.repeatMode == .one ? "repeat.1" : "repeat").frame(width: 44, height: 44).foregroundColor(playback.repeatMode == .off ? .secondary : .blue) }.accessibilityLabel("Repeat \(playback.repeatMode.rawValue)")
                Button { mode = mode == "lyrics" ? "artwork" : "lyrics" } label: { Image(systemName: "quote.bubble").frame(width: 44, height: 44).foregroundColor(mode == "lyrics" ? .blue : .secondary) }.accessibilityLabel("Lyrics")
            }
        }.fixedSize(horizontal: false, vertical: true).padding(.top, 4).padding(.bottom, 8)
    }
    private var queueView: some View {
        ScrollView { VStack(alignment: .leading, spacing: 12) {
            Text("Up Next").font(.title3.bold())
            ForEach(Array(playback.queue.enumerated()).filter { $0.offset > playback.queueIndex }, id: \.offset) { entry in
                if let track = library.track(entry.element) { Button { playback.jump(to: entry.offset) } label: { HStack { ArtworkView(track: track).frame(width: 36, height: 36); Text(track.title).foregroundColor(.primary).lineLimit(1); Spacer() }.frame(minHeight: 44) } }
            }
            if playback.queueIndex + 1 >= playback.queue.count { Text("Nothing queued").foregroundColor(.secondary) }
        } }
    }
    @ViewBuilder private var lyricsView: some View {
        if let lyrics = playback.currentTrack?.lyrics, !lyrics.isEmpty {
            let lines = lyricLines
            ScrollView {
                if lines.isEmpty { Text(lyrics).frame(maxWidth: .infinity, alignment: .leading).font(.body).textSelection(.enabled) }
                else {
                    let current = lines.last(where: { $0.time <= playback.position })?.id
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(lines) { line in Button { playback.seek(to: line.time) } label: { Text(line.text.isEmpty ? "♪" : line.text).font(.title3.bold()).foregroundColor(line.id == current ? .primary : .secondary).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading) } }
                    }
                }
            }
        } else { EmptyLibraryView(symbol: "quote.bubble", title: "No local lyrics", detail: "Embedded lyrics or a matching .lrc file beside the song will appear here.") }
    }
    private func time(_ seconds: Double) -> String { let value = Int(max(0, seconds.isFinite ? seconds : 0)); return String(format: "%d:%02d", value / 60, value % 60) }
}
