import SwiftUI

struct AppReleaseNotes: Decodable {
    struct Section: Decodable { var title: String; var items: [String] }
    var version: String
    var sections: [Section]
    static let bundled: AppReleaseNotes? = {
        guard let url = Bundle.main.url(forResource: "ReleaseNotes", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }()
}

enum AppIdentity {
    static var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—" }
    static var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—" }
    static var versionLabel: String { "Version \(version) (\(build))" }
    static var icon: UIImage? {
        let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any]
        let primary = icons?["CFBundlePrimaryIcon"] as? [String: Any]
        let names = primary?["CFBundleIconFiles"] as? [String]
        return names?.last.flatMap { UIImage(named: $0) }
    }
}

struct SettingsRow: View {
    var title: String
    var symbol: String
    var tint: Color = .blue
    var value: String? = nil
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white).frame(width: 26, height: 26)
                .background(tint).cornerRadius(6).accessibilityHidden(true)
            Text(title).foregroundColor(.primary)
            Spacer(minLength: 4)
            if let value = value { Text(value).font(.subheadline).foregroundColor(.secondary).lineLimit(1) }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var library: LibraryStore
    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    if let image = AppIdentity.icon {
                        Image(uiImage: image).resizable().frame(width: 48, height: 48).cornerRadius(10).accessibilityHidden(true)
                    } else {
                        Image(systemName: "waveform").font(.title2).foregroundColor(.blue).frame(width: 48, height: 48)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("SoundBunker").font(.headline)
                        Text("Your music. Your pocket.").font(.footnote).foregroundColor(.secondary)
                        Text(AppIdentity.versionLabel).font(.caption).foregroundColor(.secondary)
                    }
                }.padding(.vertical, 4)
            }
            Section {
                NavigationLink { SourceSettingsView() } label: { SettingsRow(title: "Music Folders", symbol: "folder.fill", value: "\(library.sources.filter(\.enabled).count) enabled") }
                Button { library.pickerRequest = PickerRequest(folders: false) } label: { SettingsRow(title: "Import Audio Files", symbol: "square.and.arrow.down.fill") }.disabled(library.busy)
                Button { library.rescan() } label: { SettingsRow(title: "Rescan Library", symbol: "arrow.clockwise") }.disabled(library.busy)
                if library.scanning { ScanProgressView() }
            } header: { Text("Music Library") } footer: { Text(library.scanning ? library.scanStatus : "Enabled folders are checked when the app opens.") }
            Section("Preferences") {
                NavigationLink { PlaybackSettingsView() } label: { SettingsRow(title: "Playback", symbol: "play.fill", tint: .purple) }
                NavigationLink { AppearanceSettingsView() } label: { SettingsRow(title: "Appearance", symbol: "paintbrush.fill", tint: .indigo) }
            }
            Section("Storage & Library") {
                NavigationLink { LibraryStatisticsView() } label: { SettingsRow(title: "Library Statistics", symbol: "chart.bar.fill", tint: .green) }
                NavigationLink { ArtworkStorageView() } label: { SettingsRow(title: "Artwork Cache", symbol: "internaldrive.fill", tint: .orange) }
            }
            Section("About") {
                NavigationLink { WhatsNewView() } label: { SettingsRow(title: "What's New", symbol: "sparkles", tint: .pink) }
                NavigationLink { AboutView() } label: { SettingsRow(title: "About SoundBunker", symbol: "info.circle.fill", tint: .gray) }
            }
        }.listStyle(.insetGrouped).environment(\.defaultMinListRowHeight, 44)
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
    }
}

struct LabeledContentRow: View {
    var label: String; var value: String
    var body: some View { HStack { Text(label); Spacer(); Text(value).foregroundColor(.secondary) } }
}

struct PlaybackSettingsView: View {
    @EnvironmentObject private var playback: PlaybackCoordinator
    @AppStorage("rememberPlaybackPosition") private var rememberPosition = true
    var body: some View {
        Form {
            Section {
                Toggle("Remember Playback Position", isOn: $rememberPosition)
            } footer: { Text("On the next launch, restore your last song position. Playback always waits for you to press Play.") }
            Section("Current Queue") {
                Toggle("Shuffle", isOn: Binding(get: { playback.shuffle }, set: { if $0 != playback.shuffle { playback.toggleShuffle() } })).disabled(playback.queue.isEmpty)
                Picker("Repeat", selection: Binding(get: { playback.repeatMode }, set: playback.setRepeatMode)) {
                    Text("Off").tag(RepeatMode.off); Text("All Songs").tag(RepeatMode.all); Text("One Song").tag(RepeatMode.one)
                }
            }
        }.navigationTitle("Playback").navigationBarTitleDisplayMode(.inline)
    }
}
struct AppearanceSettingsView: View {
    @AppStorage("appearance") private var appearance = "system"
    var body: some View {
        List {
            Section {
                ForEach([("system", "Use Device Setting"), ("light", "Light"), ("dark", "Dark")], id: \.0) { value, label in
                    Button { appearance = value } label: {
                        HStack { Text(label).foregroundColor(.primary); Spacer(); if appearance == value { Image(systemName: "checkmark").foregroundColor(.blue) } }.frame(minHeight: 32)
                    }.accessibilityValue(appearance == value ? "Selected" : "")
                }
            } footer: { Text("Use Device Setting follows your iPod's appearance automatically.") }
        }.listStyle(.insetGrouped).navigationTitle("Appearance").navigationBarTitleDisplayMode(.inline)
    }
}
struct LibraryStatisticsView: View {
    @EnvironmentObject private var library: LibraryStore
    var body: some View {
        List {
            Section("Music") {
                LabeledContentRow(label: "Songs", value: "\(library.visibleTracks.count)")
                LabeledContentRow(label: "Available", value: "\(library.visibleTracks.filter(\.available).count)")
                LabeledContentRow(label: "Albums", value: "\(AlbumGroup.make(library.visibleTracks).count)")
                LabeledContentRow(label: "Artists", value: "\(Set(library.visibleTracks.map(\.artist)).count)")
                LabeledContentRow(label: "Listening Time", value: listeningTime)
            }
            Section("Your Library") {
                LabeledContentRow(label: "Favorites", value: "\(library.visibleTracks.filter(\.favorite).count)")
                LabeledContentRow(label: "Playlists", value: "\(library.playlists.count)")
                LabeledContentRow(label: "Enabled Folders", value: "\(library.sources.filter(\.enabled).count)")
            }
        }.listStyle(.insetGrouped).navigationTitle("Library Statistics").navigationBarTitleDisplayMode(.inline)
    }
    private var listeningTime: String {
        let formatter = DateComponentsFormatter(); formatter.allowedUnits = [.hour, .minute]; formatter.unitsStyle = .abbreviated
        return formatter.string(from: library.visibleTracks.reduce(0) { $0 + max(0, $1.duration) }) ?? "0 min"
    }
}
struct ArtworkStorageView: View {
    @EnvironmentObject private var library: LibraryStore
    @State private var bytes: Int?
    @State private var confirming = false
    var body: some View {
        List {
            Section {
                LabeledContentRow(label: "Artwork Cache", value: bytes.map { ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file) } ?? "Calculating…")
                LabeledContentRow(label: "Cache Limit", value: "50 MB")
                if library.clearingArtwork { ProgressView("Clearing artwork…") }
                Button("Clear Artwork Cache", role: .destructive) { confirming = true }.disabled(library.busy || bytes == 0 || bytes == nil)
            } footer: { Text("Only generated covers are cleared. Your songs, playlists and favorites stay intact. Covers return during the next scan.") }
        }.listStyle(.insetGrouped).navigationTitle("Artwork Cache").navigationBarTitleDisplayMode(.inline)
            .task { await refreshSize() }
            .confirmationDialog("Clear artwork cache?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Clear Cache", role: .destructive) { Task { ThumbnailLoader.shared.clear(); await library.clearArtwork(); await refreshSize() } }
                Button("Cancel", role: .cancel) {}
            }
    }
    private func refreshSize() async {
        let directory = library.artworkDirectory
        bytes = await Task.detached(priority: .utility) {
            let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
            return files.reduce(0) { $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
        }.value
    }
}
struct WhatsNewView: View {
    var body: some View {
        List {
            if let notes = AppReleaseNotes.bundled {
                Section { Text("SoundBunker \(notes.version)").font(.headline) }
                ForEach(notes.sections.indices, id: \.self) { index in
                    Section(notes.sections[index].title) { ForEach(notes.sections[index].items, id: \.self) { Text($0).font(.subheadline) } }
                }
            } else { Text("Release notes are unavailable for this build.").foregroundColor(.secondary) }
        }.listStyle(.insetGrouped).navigationTitle("What's New").navigationBarTitleDisplayMode(.inline)
    }
}
struct AboutView: View {
    var body: some View {
        List {
            Section { Text("SoundBunker").font(.title3.bold()); Text(AppIdentity.versionLabel).foregroundColor(.secondary); Text("Native, offline music for your iPod.").font(.subheadline) }
            Section("Privacy") { Label("No accounts or tracking", systemImage: "checkmark.shield"); Text("Your library stays on your device. No music, artwork or lyrics are downloaded by SoundBunker.").font(.subheadline).foregroundColor(.secondary) }
            Section("Audio Formats") { Text("Native playback for local audio files. Availability depends on your iOS decoder and file encoding.").font(.subheadline); Text("MP3, M4A/AAC, ALAC, WAV and AIFF are native candidates. FLAC, Ogg and Opus may be unavailable.").font(.subheadline).foregroundColor(.secondary) }
            Section("File Access") { Text("SoundBunker scans its own Files folder and folders you choose. iOS does not allow unrestricted access to every folder on the device.").font(.subheadline).foregroundColor(.secondary) }
        }.listStyle(.insetGrouped).navigationTitle("About").navigationBarTitleDisplayMode(.inline)
    }
}
