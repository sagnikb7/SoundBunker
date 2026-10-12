import SwiftUI

struct PickerRequest: Identifiable {
    let id = UUID()
    var folders: Bool
    var reconnecting: UUID? = nil
    var excludeFrom: UUID? = nil
}

struct RootView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var playback: PlaybackCoordinator
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingPlayer = false
    @State private var launched = false
    @State private var keyboardVisible = false
    @AppStorage("appearance") private var appearance = "system"
    var body: some View {
        content.preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
            .fullScreenCover(isPresented: $showingPlayer) {
                NowPlayingView().environmentObject(library).environmentObject(playback)
            }
            .sheet(item: $library.pickerRequest) { request in
                MusicPicker(folders: request.folders, selected: { urls in
                    library.pickerRequest = nil
                    if request.folders { if let url = urls.first {
                        if let source = request.excludeFrom { library.excludeFolder(url, from: source) }
                        else { library.addFolder(url, reconnecting: request.reconnecting) }
                    } }
                    else { library.importFiles(urls) }
                }, cancelled: { library.pickerRequest = nil })
            }
            .alert("SoundBunker", isPresented: Binding(get: { library.errorMessage != nil || playback.errorMessage != nil }, set: { if !$0 { library.errorMessage = nil; playback.errorMessage = nil } })) {
                Button("OK", role: .cancel) { library.errorMessage = nil; playback.errorMessage = nil }
            } message: { Text(playback.errorMessage ?? library.errorMessage ?? "") }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                // Keyboard-safe-area avoidance moves the overlay; only the hidden tab-bar offset must go.
                keyboardVisible = frame.minY < UIScreen.main.bounds.maxY && frame.height > 0
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardVisible = false }
            .onAppear {
                if !launched { launched = true; playback.connect(library); library.rescanIfNeeded(minimumInterval: 0) }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active && launched { library.rescanIfNeeded() }
                else if phase == .background { playback.persist() }
            }
    }
    @ViewBuilder private var content: some View {
        #if targetEnvironment(macCatalyst)
        tabs.safeAreaInset(edge: .bottom, spacing: 0) { miniPlayer }
        #else
        tabs.overlay(alignment: .bottom) { miniPlayer.padding(.bottom, keyboardVisible ? 0 : 49) }
        #endif
    }
    private var tabs: some View {
        TabView {
            navigation { LibraryHomeView() }.tabItem { Label("Library", systemImage: "music.note") }
            navigation { PlaylistsView() }.tabItem { Label("Playlists", systemImage: "music.note.list") }
            navigation { SearchView() }.tabItem { Label("Search", systemImage: "magnifyingglass") }
            navigation { SettingsView() }.tabItem { Label("Settings", systemImage: "gearshape") }
        }.accentColor(.blue)
    }
    private func navigation<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationView { content().background(BackGestureSupport()).safeAreaInset(edge: .bottom) {
            #if !targetEnvironment(macCatalyst)
            Color.clear.frame(height: playback.currentTrack == nil ? 0 : 56)
            #endif
        } }.navigationViewStyle(.stack)
    }
    @ViewBuilder private var miniPlayer: some View {
        if playback.currentTrack != nil { MiniPlayer(showingPlayer: $showingPlayer) }
    }
}

struct LibraryHomeView: View {
    @EnvironmentObject private var library: LibraryStore
    var body: some View {
        Group {
            if library.visibleTracks.isEmpty {
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note").font(.system(size: 56)).foregroundColor(.blue).padding(.top, 36)
                        Text("Your music. Your pocket.").font(.title2.bold()).multilineTextAlignment(.center)
                        Text("Add a folder from On My iPod, or import audio files. SoundBunker finds the songs inside and keeps them ready offline.")
                            .foregroundColor(.secondary).multilineTextAlignment(.center)
                        Button { library.pickerRequest = PickerRequest(folders: true) } label: { Label("Add Music Folder", systemImage: "folder.badge.plus").frame(minHeight: 44) }
                            .buttonStyle(.borderedProminent).accessibilityIdentifier("addMusicFolder")
                        Button("Import Audio Files") { library.pickerRequest = PickerRequest(folders: false) }.frame(minHeight: 44)
                        Label("Your music stays on your device.", systemImage: "checkmark.shield").font(.footnote).foregroundColor(.secondary)
                        if library.scanning { ScanProgressView() }
                    }.padding(24)
                }
            } else {
                List {
                    NavigationLink { SongListView(title: "Songs", tracks: library.sortedTracks) } label: { Label("Songs", systemImage: "music.note") }
                    NavigationLink { AlbumsView() } label: { Label("Albums", systemImage: "square.stack") }
                    NavigationLink { GroupsView(kind: .artist) } label: { Label("Artists", systemImage: "music.mic") }
                    NavigationLink { GroupsView(kind: .genre) } label: { Label("Genres", systemImage: "waveform") }
                    NavigationLink { FoldersView() } label: { Label("Folders", systemImage: "folder") }
                    NavigationLink { SongListView(title: "Recently Added", tracks: library.browse.recentTracks) } label: { Label("Recently Added", systemImage: "clock") }
                    Section("Recently Added") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(recentAlbums, id: \.id) { album in
                                    NavigationLink { AlbumDetailView(album: album) } label: { AlbumTile(album: album).frame(width: 112) }.buttonStyle(.plain)
                                }
                            }.padding(.vertical, 6)
                        }
                    }
                    if library.scanning { ScanProgressView() }
                }.listStyle(.plain)
            }
        }.navigationTitle("Library")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Menu {
                Button("Add Music Folder") { library.pickerRequest = PickerRequest(folders: true) }
                Button("Import Audio Files") { library.pickerRequest = PickerRequest(folders: false) }
                Button("Rescan Library") { library.rescan() }
            } label: { Image(systemName: "plus").frame(width: 44, height: 44) }.accessibilityLabel("Add music") } }
    }
    private var recentAlbums: [AlbumGroup] { library.browse.recentAlbums }
}

struct ScanProgressView: View {
    @EnvironmentObject private var library: LibraryStore
    var body: some View {
        HStack {
            ProgressView()
            VStack(alignment: .leading) {
                Text(library.scanStatus).font(.subheadline)
                Text("\(library.scannedCount) audio files checked").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button("Cancel") { library.cancelScan() }
        }.padding(.vertical, 8)
    }
}

struct EmptyLibraryView: View {
    let symbol: String
    let title: String
    let detail: String
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol).font(.system(size: 44)).foregroundColor(.blue).accessibilityHidden(true)
            Text(title).font(.title2.bold())
            Text(detail).foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
