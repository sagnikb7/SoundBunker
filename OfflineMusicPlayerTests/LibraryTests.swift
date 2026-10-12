import XCTest
@testable import OfflineMusicPlayer

final class LibraryTests: XCTestCase {
    func testTimedLyricsOffsetsMultipleTimestampsAndMalformedInput() {
        let result = LRCParser.parse("[ar:Artist]\n[offset:-500]\n[00:01.25][00:03.00]Hello\n[bad]skip\n[00:99.00]invalid")
        XCTAssertEqual(result.map(\.text), ["Hello", "Hello"])
        XCTAssertEqual(result.map(\.time), [0.75, 2.5])
        XCTAssertTrue(LRCParser.parse("Plain lyrics").isEmpty)
    }
    func testSourceExclusionUsesPathBoundariesAndOldRecordsDecode() throws {
        var source = MusicSource(id: UUID(), name: "Music", isOwned: true)
        source.excludedPaths = ["Podcasts"]
        XCTAssertFalse(source.permits("Podcasts/file.mp3"))
        XCTAssertTrue(source.permits("Podcasts Plus/file.mp3"))
        XCTAssertTrue(source.permits("Albums/file.mp3"))
        source.enabled = false; XCTAssertFalse(source.permits("Albums/file.mp3"))
        let legacy = "{\"id\":\"\(source.id)\",\"name\":\"Music\",\"isOwned\":true}"
        let decoded = try JSONDecoder().decode(MusicSource.self, from: Data(legacy.utf8))
        XCTAssertTrue(decoded.enabled); XCTAssertTrue(decoded.excludedPaths.isEmpty)
    }
    @MainActor
    func testLocalLibraryExclusionsFavoritesPlaylistsAndRemovalAreNonDestructive() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let blocked = root.appendingPathComponent("Podcasts")
        try FileManager.default.createDirectory(at: blocked, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TestTone", withExtension: "wav"))
        try FileManager.default.copyItem(at: fixture, to: root.appendingPathComponent("Song.wav"))
        try FileManager.default.copyItem(at: fixture, to: blocked.appendingPathComponent("Talk.wav"))
        let library = LibraryStore(documents: root, inMemory: true)
        library.rescan(); try await waitForScan(library)
        XCTAssertEqual(library.tracks.count, 2)
        let song = try XCTUnwrap(library.tracks.first { $0.title == "Song" })
        XCTAssertEqual(song.artist, "Unknown Artist")
        library.favorite(song); library.createPlaylist("Road trip")
        var playlist = try XCTUnwrap(library.playlists.first); playlist.trackIDs = [song.id, song.id]
        library.changePlaylist(playlist)
        XCTAssertEqual(try library.database?.all("playlist", as: MusicPlaylist.self).first?.trackIDs.count, 2)
        let owned = try XCTUnwrap(library.sources.first)
        library.excludeFolder(blocked, from: owned.id); try await waitForScan(library)
        XCTAssertEqual(library.visibleTracks.count, 1)
        XCTAssertEqual(library.tracks.count, 2, "Exclusion preserves persistent track identities")
        XCTAssertTrue(library.track(song.id)?.favorite ?? false)
        library.includeFolder(owned.id, path: "Podcasts"); try await waitForScan(library)
        XCTAssertEqual(library.visibleTracks.count, 2)
        library.addFolder(blocked); try await waitForScan(library)
        let external = try XCTUnwrap(library.sources.first { !$0.isOwned })
        XCTAssertEqual(library.tracks.first { $0.title == "Talk" }?.locations.count, 2)
        library.removeSource(external)
        XCTAssertEqual(library.tracks.first { $0.title == "Talk" }?.locations.count, 1)
        XCTAssertEqual(library.visibleTracks.count, 2)
        library.setEnabled(owned.id, enabled: false); XCTAssertTrue(library.visibleTracks.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: blocked.appendingPathComponent("Talk.wav").path))
        library.deletePlaylist(playlist); XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent("Song.wav").path))
    }
    func testOverlappingRootsDeduplicateIdentityButSeparateCopiesRemainDistinct() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let child = root.appendingPathComponent("Album")
        let cache = root.appendingPathComponent(".cache")
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TestTone", withExtension: "wav"))
        try FileManager.default.copyItem(at: fixture, to: child.appendingPathComponent("Song.wav"))
        try FileManager.default.copyItem(at: fixture, to: child.appendingPathComponent("Copy.wav"))
        let scanner = LibraryScanner()
        let first = try await scanner.scan(root: root, sourceID: UUID(), existing: [:], cache: cache) { _, _ in }
        let second = try await scanner.scan(root: child, sourceID: UUID(), existing: Dictionary(uniqueKeysWithValues: first.tracks.map { ($0.id, $0) }), cache: cache) { _, _ in }
        XCTAssertEqual(first.tracks.count, 2)
        XCTAssertEqual(Set(first.tracks.map(\.id)), Set(second.tracks.map(\.id)))
        XCTAssertEqual(second.tracks[0].locations.count, 2)
        let cancelled = Task { try await scanner.scan(root: root, sourceID: UUID(), existing: [:], cache: cache) { _, _ in } }
        cancelled.cancel()
        do { _ = try await cancelled.value; XCTFail("Cancelled scan completed") } catch is CancellationError { }
    }
    func testPlaybackFilePolicyRejectsEscapesAndReplacedSymlinks() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let music = root.appendingPathComponent("Music")
        try FileManager.default.createDirectory(at: music, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let outside = root.appendingPathComponent("Outside.wav")
        try Data([0]).write(to: outside)
        let local = music.appendingPathComponent("Song.wav")
        try Data([0]).write(to: local)
        XCTAssertEqual(try LocalFilePolicy.musicFile("Song.wav", in: music), local)
        XCTAssertThrowsError(try LocalFilePolicy.musicFile("../Outside.wav", in: music))
        XCTAssertThrowsError(try LocalFilePolicy.musicFile(outside.path, in: music))
        try FileManager.default.removeItem(at: local)
        try FileManager.default.createSymbolicLink(at: local, withDestinationURL: outside)
        XCTAssertThrowsError(try LocalFilePolicy.musicFile("Song.wav", in: music))
        XCTAssertThrowsError(try LocalFilePolicy.check(local))
    }

    @MainActor
    func testDiskPersistenceAcrossStoreInstances() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("library.sqlite")
        var first: LibraryDatabase? = try LibraryDatabase(storeURL: url)
        try first?.save(MusicPlaylist(name: "Persisted"), key: "playlist:one", kind: "playlist")
        try first?.commit()
        if let first = first {
            first.container.viewContext.reset()
            for store in first.container.persistentStoreCoordinator.persistentStores { try first.container.persistentStoreCoordinator.remove(store) }
        }
        first = nil
        let reopened = try LibraryDatabase(storeURL: url)
        defer {
            reopened.container.viewContext.reset()
            for store in reopened.container.persistentStoreCoordinator.persistentStores { try? reopened.container.persistentStoreCoordinator.remove(store) }
        }
        XCTAssertEqual(try reopened.all("playlist", as: MusicPlaylist.self).first?.name, "Persisted")
    }
    @MainActor
    func testDatabaseRecordRoundTripAndDeletion() throws {
        // An isolated in-memory store verifies round-trip serialization without touching production data.
        let db = try LibraryDatabase(inMemory: true)
        let playlist = MusicPlaylist(name: "Unicode ♪ हिंदी")
        try db.save(playlist, key: "playlist:test", kind: "playlist"); try db.commit()
        XCTAssertEqual(try db.all("playlist", as: MusicPlaylist.self).first?.name, playlist.name)
        try db.remove(key: "playlist:test"); try db.commit()
        XCTAssertTrue(try db.all("playlist", as: MusicPlaylist.self).isEmpty)
    }
}
