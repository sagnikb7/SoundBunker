import Foundation
import Combine

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var tracks: [Track] = [] {
        didSet { trackLookup = Dictionary(uniqueKeysWithValues: tracks.map { ($0.id, $0) }); visibleCache = nil; sortedCache = nil; browseCache = nil }
    }
    @Published private(set) var sources: [MusicSource] = [] { didSet { visibleCache = nil; sortedCache = nil; browseCache = nil } }
    @Published private(set) var playbackHistory: [PlaybackHistoryEntry] = []
    @Published private(set) var playlists: [MusicPlaylist] = []
    @Published private(set) var scanning = false
    @Published private(set) var clearingArtwork = false
    var busy: Bool { scanning || clearingArtwork }
    @Published private(set) var scannedCount = 0
    @Published private(set) var scanStatus = ""
    @Published var errorMessage: String?
    @Published var pickerRequest: PickerRequest?
    let documents: URL
    let artworkDirectory: URL
    private(set) var database: LibraryDatabase?
    private let scanner = LibraryScanner()
    private var scanTask: Task<Void, Never>?
    private var trackLookup: [String: Track] = [:]
    private var visibleCache: [Track]?
    private var sortedCache: [Track]?
    private var browseCache: BrowseIndex?
    private var artworkNeedsTrim = false
    private var lastScan = Date.distantPast
    private var resolvedRoots: [UUID: URL] = [:]
    private enum FolderChange { case add(MusicSource, FolderAccess), remove(UUID) }
    private var folderChanges: [FolderChange] = []
    private var firstScanGrants: [UUID: FolderAccess] = [:]

    init(documents: URL? = nil, inMemory: Bool = false, databaseURL: URL? = nil) {
        let fm = FileManager.default
        #if targetEnvironment(macCatalyst)
        // Catalyst preview is app-specific even when launched with an ad-hoc signature without sandbox entitlements.
        let defaultDocuments = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("PocketMusic/Files", isDirectory: true)
        #else
        let defaultDocuments = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        #endif
        self.documents = documents ?? defaultDocuments
        artworkDirectory = documents.map { $0.appendingPathComponent(".artwork", isDirectory: true) } ?? fm.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("PocketMusicArtwork", isDirectory: true)
        do {
            try fm.createDirectory(at: self.documents, withIntermediateDirectories: true)
            // Files may hide an empty Documents container. A small useful guide makes it discoverable immediately.
            let guide = self.documents.appendingPathComponent("Cassette Guide.txt")
            if !fm.fileExists(atPath: guide.path) {
                try """
                Add music to Cassette

                On your iPod: Files → Browse → On My iPod → Cassette.
                Other apps can use the Files picker to copy audio into this folder.
                On your Mac: connect and unlock the iPod, trust this computer, open Finder,
                select the iPod → Files → Cassette, and drag your audio files into the app.
                Music is scanned when Cassette opens. Use Settings → Rescan Library for immediate discovery.
                Keep M3U playlists and LRC lyrics alongside the audio using their relative paths.
                Your playlists and favorites are stored privately; deleting this guide does not affect them.
                """.write(to: guide, atomically: true, encoding: .utf8)
            }
            try fm.createDirectory(at: artworkDirectory, withIntermediateDirectories: true)
            database = try LibraryDatabase(inMemory: inMemory, storeURL: databaseURL)
            tracks = try database!.all("track", as: Track.self)
            trackLookup = Dictionary(uniqueKeysWithValues: tracks.map { ($0.id, $0) })
            sources = try database!.all("source", as: MusicSource.self)
            playlists = try database!.all("playlist", as: MusicPlaylist.self)
            playbackHistory = try database!.all("history", as: PlaybackHistoryEntry.self).sorted { $0.playedAt > $1.playedAt }
            for index in sources.indices where sources[index].isOwned && sources[index].name != "Cassette" {
                sources[index].name = "Cassette"; try save(sources[index])
            }
            if !sources.contains(where: { $0.isOwned }) {
                let source = MusicSource(id: UUID(), name: "Cassette", isOwned: true)
                sources.insert(source, at: 0); try save(source)
            }
        } catch { errorMessage = "Couldn't open your library: \(error.localizedDescription)" }
    }

    var visibleTracks: [Track] {
        if let cached = visibleCache { return cached }
        let roots = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0) })
        let result = tracks.filter { track in track.locations.contains { roots[$0.sourceID]?.permits($0.relativePath) ?? false } }
        visibleCache = result; return result
    }
    var sortedTracks: [Track] {
        if let cached = sortedCache { return cached }
        let result = visibleTracks.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        sortedCache = result; return result
    }
    var historySongs: [PlayedSong] {
        let visible = Dictionary(uniqueKeysWithValues: visibleTracks.map { ($0.id, $0) })
        return playbackHistory.compactMap { entry in
            visible[entry.trackID].map { PlayedSong(entry: entry, track: $0) }
        }
    }
    var recentlyPlayed: [PlayedSong] { Array(historySongs.prefix(10)) }

    func recordPlayback(_ track: Track) {
        guard trackLookup[track.id] != nil, let database = database else { return }
        let entry = PlaybackHistoryEntry(trackID: track.id)
        do {
            try database.save(entry, key: "history:\(entry.id)", kind: "history")
            try database.commit()
            playbackHistory.insert(entry, at: 0)
        } catch { errorMessage = "Couldn't save listening history: \(error.localizedDescription)" }
    }

    func track(_ id: String) -> Track? { trackLookup[id] }
    func sourceURL(_ source: MusicSource) throws -> URL {
        if source.isOwned { return documents }
        if let cached = resolvedRoots[source.id] { return cached }
        guard let bookmark = source.bookmark else { throw CocoaError(.fileReadNoPermission) }
        var stale = false
        let url = try URL(resolvingBookmarkData: bookmark, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
        // Check readability only after the caller starts security-scoped access.
        resolvedRoots[source.id] = url
        return url
    }
    func addFolder(_ url: URL, reconnecting: UUID? = nil) {
        let grant = FolderAccess(url)
        do {
            try LocalFilePolicy.check(url)
            guard try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else { throw CocoaError(.fileReadInvalidFileName) }
            if let id = reconnecting, sources.first(where: { $0.id == id })?.isOwned != false {
                throw CocoaError(.fileReadNoPermission)
            }
            let canonical = url.resolvingSymlinksInPath().standardizedFileURL
            let queued = folderChanges.reversed().compactMap { change -> MusicSource? in
                if case .add(let source, let grant) = change, grant.url.resolvingSymlinksInPath().standardizedFileURL == canonical { return source }
                return nil
            }.first
            let duplicate = queued ?? sources.first { (try? sourceURL($0).resolvingSymlinksInPath().standardizedFileURL) == canonical }
            if duplicate?.isOwned == true { rescanIfNeeded(minimumInterval: 0); return }
            if let duplicate = duplicate, let id = reconnecting, duplicate.id != id {
                errorMessage = "This folder is already in your library."; return
            }
            let data = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            var source = MusicSource(id: reconnecting ?? duplicate?.id ?? UUID(), name: url.lastPathComponent, bookmark: data, isOwned: false)
            if let old = sources.first(where: { $0.id == source.id }) { source.enabled = old.enabled; source.excludedPaths = old.excludedPaths }
            queueFolderChange(.add(source, grant))
        } catch { errorMessage = "Couldn't add \(url.lastPathComponent): \(error.localizedDescription) Choose the folder again in Files. For cloud storage, download the audio first." }
    }
    private func queueFolderChange(_ change: FolderChange) {
        folderChanges.append(change)
        if scanning { scanStatus = "Updating music folders…"; scanTask?.cancel() }
        else if !clearingArtwork { applyFolderChanges() }
    }
    private func finishScan() {
        scanning = false; scanTask = nil
        for id in firstScanGrants.keys { resolvedRoots[id] = nil }
        firstScanGrants.removeAll()
        applyFolderChanges()
    }
    private func applyFolderChanges() {
        guard !busy, !folderChanges.isEmpty else { return }
        let changes = folderChanges; folderChanges.removeAll()
        var shouldScan = false
        for change in changes {
            do {
                switch change {
                case .add(let source, let grant):
                    try save(source)
                    if let index = sources.firstIndex(where: { $0.id == source.id }) { sources[index] = source }
                    else { sources.append(source) }
                    resolvedRoots[source.id] = grant.url
                    firstScanGrants[source.id] = grant
                    shouldScan = shouldScan || source.enabled
                case .remove(let id):
                    guard sources.contains(where: { $0.id == id && !$0.isOwned }) else { continue }
                    var updated = tracks
                    for index in updated.indices {
                        updated[index].locations.removeAll { $0.sourceID == id }
                        if updated[index] != tracks[index] { try database?.save(updated[index], key: "track:\(updated[index].id)", kind: "track") }
                    }
                    try database?.remove(key: "source:\(id)"); try database?.commit()
                    sources.removeAll { $0.id == id }
                    resolvedRoots[id] = nil; firstScanGrants[id] = nil
                    if updated != tracks { tracks = updated }
                }
            } catch { database?.container.viewContext.rollback(); errorMessage = "Couldn't update music folders: \(error.localizedDescription)" }
        }
        if shouldScan { rescan() }
        else {
            for id in firstScanGrants.keys { resolvedRoots[id] = nil }
            firstScanGrants.removeAll()
        }
    }

    func importFiles(_ urls: [URL]) {
        guard !busy else { errorMessage = "Wait for the current scan to finish before importing."; return }
        scanning = true; scannedCount = 0; scanStatus = "Importing files"
        scanTask = Task {
            let destination = documents
            let worker = Task.detached(priority: .userInitiated) {
                var errors: [String] = []
                for url in urls {
                    if Task.isCancelled { break }
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    do {
                        try LocalFilePolicy.check(url)
                        guard LibraryScanner.extensions.union(["m3u", "m3u8"]).contains(url.pathExtension.lowercased()) else { continue }
                        var target = destination.appendingPathComponent(url.lastPathComponent)
                        if target.standardizedFileURL == url.standardizedFileURL { continue }
                        if FileManager.default.fileExists(atPath: target.path) {
                            target = destination.appendingPathComponent(url.deletingPathExtension().lastPathComponent + "-" + UUID().uuidString.prefix(6) + "." + url.pathExtension)
                        }
                        var coordinationError: NSError?, copyError: Error?
                        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinationError) { source in
                            do { try FileManager.default.copyItem(at: source, to: target) } catch { copyError = error }
                        }
                        if let error = coordinationError ?? (copyError as NSError?) { throw error }
                        // Explicit file import also preserves an adjacent local lyric file when accessible.
                        let lrc = url.deletingPathExtension().appendingPathExtension("lrc")
                        if FileManager.default.fileExists(atPath: lrc.path), (try? LocalFilePolicy.check(lrc)) != nil {
                            try? FileManager.default.copyItem(at: lrc, to: target.deletingPathExtension().appendingPathExtension("lrc"))
                        }
                    } catch { errors.append("\(url.lastPathComponent): \(error.localizedDescription)") }
                }
                return errors
            }
            let result = await withTaskCancellationHandler(operation: { await worker.value }, onCancel: { worker.cancel() })
            let cancelled = Task.isCancelled
            if !result.isEmpty { errorMessage = result.prefix(5).joined(separator: "\n") }
            if cancelled { scanStatus = "Import cancelled" }
            finishScan()
            if !cancelled { rescan() }
        }
    }

    func rescanIfNeeded(minimumInterval: TimeInterval = 120) {
        guard !busy, Date().timeIntervalSince(lastScan) >= minimumInterval else { return }
        rescan()
    }
    var browse: BrowseIndex {
        if let cached = browseCache { return cached }
        let value = BrowseIndex(tracks: sortedTracks)
        browseCache = value; return value
    }
    func rescan(only id: UUID? = nil) {
        guard !busy, database != nil else { return }
        let selected = sources.filter { $0.enabled && (id == nil || $0.id == id) }
        scanning = true; scannedCount = 0; scanStatus = "Preparing scan…"
        if id == nil { lastScan = Date() }
        scanTask = Task {
            defer { finishScan() }
            for var source in selected {
                if Task.isCancelled { scanStatus = "Scan cancelled"; break }
                scanStatus = "Scanning \(source.name)"
                do {
                    let root = try sourceURL(source)
                    let access = root.startAccessingSecurityScopedResource()
                    defer { if access { root.stopAccessingSecurityScopedResource() } }
                    let snapshot = trackLookup
                    let completedCount = scannedCount
                    let result = try await scanner.scan(root: root, sourceID: source.id, existing: snapshot, cache: artworkDirectory, excluded: source.excludedPaths, checked: { count in
                        await self.updateScanCount(completedCount + count)
                    }, progress: { batch, count in
                        await self.receive(batch, count: completedCount + count)
                    })
                    try Task.checkCancellation()
                    var updated = tracks
                    var changed = false
                    for index in updated.indices {
                        guard !result.seen.contains(updated[index].id), updated[index].locations.contains(where: { $0.sourceID == source.id && $0.available }) else { continue }
                        for location in updated[index].locations.indices where updated[index].locations[location].sourceID == source.id { updated[index].locations[location].available = false }
                        changed = true
                        try database?.save(updated[index], key: "track:\(updated[index].id)", kind: "track")
                    }
                    if changed { tracks = updated }
                    try mergeImportedPlaylists(result.playlists, source: source)
                    source.needsReconnect = false; update(source); try save(source)
                    try database?.commit()
                    scanStatus = "\(scannedCount) files checked\(result.skipped > 0 ? "; \(result.skipped) unavailable" : "")"
                    if !result.issues.isEmpty { errorMessage = result.issues.prefix(5).joined(separator: "\n") }
                } catch is CancellationError { scanStatus = "Scan cancelled"; break }
                catch {
                    source.needsReconnect = !source.isOwned; update(source)
                    var updated = tracks
                    for index in updated.indices {
                        guard updated[index].locations.contains(where: { $0.sourceID == source.id && $0.available }) else { continue }
                        for location in updated[index].locations.indices where updated[index].locations[location].sourceID == source.id { updated[index].locations[location].available = false }
                        try? database?.save(updated[index], key: "track:\(updated[index].id)", kind: "track")
                    }
                    if updated != tracks { tracks = updated }
                    try? save(source); errorMessage = "\(source.name): \(error.localizedDescription)"
                }
            }
            if artworkNeedsTrim { await trimArtwork(); artworkNeedsTrim = false }
        }
    }
    private func mergeImportedPlaylists(_ manifests: [ScannedPlaylist], source: MusicSource) throws {
        guard !manifests.isEmpty else { return }
        var pathIndex: [String: String] = [:]
        for track in tracks {
            for location in track.locations where location.sourceID == source.id && location.available && source.permits(location.relativePath) {
                pathIndex[location.relativePath] = track.id
            }
        }
        var updated = playlists
        var changed = false
        for manifest in manifests {
            let index = updated.firstIndex { $0.importedSourceID == source.id && $0.importedPath == manifest.path }
            var playlist = index.map { updated[$0] } ?? MusicPlaylist(name: manifest.name)
            playlist.name = manifest.name; playlist.importedSourceID = source.id; playlist.importedPath = manifest.path
            playlist.trackIDs = manifest.entries.compactMap { pathIndex[$0] }
            playlist.unresolvedPaths = manifest.entries.filter { pathIndex[$0] == nil }
            if let index = index {
                if updated[index] == playlist { continue }
                updated[index] = playlist
            } else { updated.append(playlist) }
            try database?.save(playlist, key: "playlist:\(playlist.id)", kind: "playlist"); changed = true
        }
        if changed { try database?.commit(); playlists = updated }
    }
    private func updateScanCount(_ count: Int) { scannedCount = count }

    private func receive(_ batch: [Track], count: Int) {
        do {
            var updated = tracks
            var indices = Dictionary(uniqueKeysWithValues: updated.enumerated().map { ($0.element.id, $0.offset) })
            var changed = false
            for var track in batch {
                if track.artwork != nil && track.artwork != trackLookup[track.id]?.artwork { artworkNeedsTrim = true }
                if let index = indices[track.id] {
                    track.favorite = updated[index].favorite
                    if track == updated[index] { continue }
                    updated[index] = track
                } else { indices[track.id] = updated.count; updated.append(track) }
                changed = true
                try database?.save(track, key: "track:\(track.id)", kind: "track")
            }
            try database?.commit()
            if changed { tracks = updated }
            scannedCount = count
        } catch { errorMessage = "Couldn't save scan results: \(error.localizedDescription)"; scanTask?.cancel() }
    }
    func setEnabled(_ id: UUID, enabled: Bool) {
        guard !busy, var source = sources.first(where: { $0.id == id }) else { return }
        source.enabled = enabled; applyRestriction(source)
        if enabled { rescan(only: id) }
    }
    func excludeFolder(_ url: URL, from id: UUID) {
        guard !busy, var source = sources.first(where: { $0.id == id }) else { return }
        do {
            let root = try sourceURL(source).resolvingSymlinksInPath().standardizedFileURL
            let path = url.resolvingSymlinksInPath().standardizedFileURL.path
            if path == root.path { setEnabled(id, enabled: false); return }
            guard path.hasPrefix(root.path + "/") else { errorMessage = "Choose a subfolder inside \(source.name)."; return }
            let relative = String(path.dropFirst(root.path.count + 1))
            if !source.excludedPaths.contains(relative) { source.excludedPaths.append(relative) }
            applyRestriction(source); rescan(only: id)
        } catch { errorMessage = error.localizedDescription }
    }
    func includeFolder(_ id: UUID, path: String) {
        guard !busy, var source = sources.first(where: { $0.id == id }) else { return }
        source.excludedPaths.removeAll { $0 == path }; applyRestriction(source); rescan(only: id)
    }
    private func applyRestriction(_ source: MusicSource) {
        update(source)
        do {
            var updated = tracks
            for index in updated.indices {
                for loc in updated[index].locations.indices where updated[index].locations[loc].sourceID == source.id {
                    if !source.permits(updated[index].locations[loc].relativePath) { updated[index].locations[loc].available = false }
                }
                if updated[index] != tracks[index] { try database?.save(updated[index], key: "track:\(updated[index].id)", kind: "track") }
            }
            if updated != tracks { tracks = updated }
            try save(source)
        } catch { errorMessage = error.localizedDescription }
    }
    func cancelScan() { scanTask?.cancel() }
    func removeSource(_ source: MusicSource) {
        guard !source.isOwned else { errorMessage = "Cassette’s own folder cannot be removed. Turn off scanning instead."; return }
        queueFolderChange(.remove(source.id))
    }
    func favorite(_ track: Track) {
        guard let index = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        tracks[index].favorite.toggle()
        do { try database?.save(tracks[index], key: "track:\(track.id)", kind: "track"); try database?.commit() }
        catch { errorMessage = error.localizedDescription }
    }
    func createPlaylist(_ name: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let playlist = MusicPlaylist(name: name); playlists.append(playlist); savePlaylist(playlist)
    }
    /// All interactive add paths share this idempotent mutation; existing legacy duplicates are preserved.
    @discardableResult
    func addTrack(_ trackID: String, to playlistID: UUID) -> Bool {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }),
              track(trackID) != nil, !playlists[index].trackIDs.contains(trackID) else { return false }
        var updated = playlists[index]
        updated.trackIDs.append(trackID)
        guard let database = database else { errorMessage = "Your library is unavailable."; return false }
        do {
            try database.save(updated, key: "playlist:\(updated.id)", kind: "playlist"); try database.commit()
            playlists[index] = updated
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }
    /// Selection rows toggle membership; clearing selection removes any legacy duplicate occurrences too.
    @discardableResult
    func toggleTrack(_ trackID: String, in playlistID: UUID) -> Bool {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return false }
        if !playlists[index].trackIDs.contains(trackID) { return addTrack(trackID, to: playlistID) }
        var updated = playlists[index]
        updated.trackIDs.removeAll { $0 == trackID }
        guard let database = database else { errorMessage = "Your library is unavailable."; return false }
        do {
            try database.save(updated, key: "playlist:\(updated.id)", kind: "playlist"); try database.commit()
            playlists[index] = updated
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }
    func changePlaylist(_ playlist: MusicPlaylist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index] = playlist; savePlaylist(playlist)
    }
    func deletePlaylist(_ playlist: MusicPlaylist) {
        playlists.removeAll { $0.id == playlist.id }
        do { try database?.remove(key: "playlist:\(playlist.id)"); try database?.commit() } catch { errorMessage = error.localizedDescription }
    }
    private func savePlaylist(_ playlist: MusicPlaylist) {
        do { try database?.save(playlist, key: "playlist:\(playlist.id)", kind: "playlist"); try database?.commit() } catch { errorMessage = error.localizedDescription }
    }
    private func save(_ source: MusicSource) throws { try database?.save(source, key: "source:\(source.id)", kind: "source"); try database?.commit() }
    private func update(_ source: MusicSource) { if let index = sources.firstIndex(where: { $0.id == source.id }) { sources[index] = source } }
    func clearArtwork() async {
        guard !busy else { return }
        clearingArtwork = true
        defer { clearingArtwork = false; applyFolderChanges() }
        let directory = artworkDirectory
        let failure = await Task.detached(priority: .utility) { () -> String? in
            do {
                let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                for file in files { try FileManager.default.removeItem(at: file) }
                return nil
            } catch { return error.localizedDescription }
        }.value
        do {
            // Small main-actor database batches leave room for scrolling and preserve edits between batches.
            for start in stride(from: 0, to: tracks.count, by: 50) {
                var updated = tracks
                for index in start..<min(start + 50, updated.count) {
                    updated[index].artwork = nil; updated[index].fingerprint = ""
                    try database?.save(updated[index], key: "track:\(updated[index].id)", kind: "track")
                }
                try database?.commit(); tracks = updated
                await Task.yield()
            }
            if let failure = failure { errorMessage = "Some artwork could not be cleared: \(failure)" }
        } catch { errorMessage = "Couldn't update the artwork cache: \(error.localizedDescription)" }
    }
    private func trimArtwork() async {
        let directory = artworkDirectory
        let used = Set(tracks.compactMap(\.artwork))
        await Task.detached(priority: .utility) {
            let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
            var total = 0
            for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                if !used.contains(file.lastPathComponent) || total + size > 50_000_000 { try? FileManager.default.removeItem(at: file) }
                else { total += size }
            }
        }.value
    }
}
