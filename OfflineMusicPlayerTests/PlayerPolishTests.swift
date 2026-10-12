import XCTest
import SwiftUI
import Combine
@testable import OfflineMusicPlayer

final class PlayerPolishTests: XCTestCase {
    @MainActor
    func testPlaylistAddIsIdempotentAndPersistsAcrossMultiplePlaylists() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TestTone", withExtension: "wav"))
        try FileManager.default.copyItem(at: fixture, to: root.appendingPathComponent("Song.wav"))
        let library = LibraryStore(documents: root, inMemory: true)
        library.rescan(); try await waitForScan(library)
        let track = try XCTUnwrap(library.tracks.first)
        library.createPlaylist("First"); library.createPlaylist("Second")
        let first = library.playlists[0].id, second = library.playlists[1].id
        XCTAssertTrue(library.addTrack(track.id, to: first))
        for _ in 0..<10 { XCTAssertFalse(library.addTrack(track.id, to: first)) }
        XCTAssertTrue(library.addTrack(track.id, to: second))
        XCTAssertFalse(library.addTrack("missing-track", to: second))
        XCTAssertFalse(library.addTrack(track.id, to: UUID()))
        XCTAssertEqual(library.playlists.map(\.trackIDs), [[track.id], [track.id]])
        let stored = try XCTUnwrap(library.database).all("playlist", as: MusicPlaylist.self)
        XCTAssertEqual(stored.count, 2)
        XCTAssertTrue(stored.allSatisfy { $0.trackIDs == [track.id] })
        // A second selection tap removes the accidental addition and only touches that playlist.
        XCTAssertTrue(library.toggleTrack(track.id, in: first))
        XCTAssertEqual(library.playlists.map(\.trackIDs), [[], [track.id]])
        XCTAssertTrue(library.toggleTrack(track.id, in: first))
        XCTAssertEqual(library.playlists[0].trackIDs, [track.id])
        XCTAssertTrue(library.toggleTrack(track.id, in: first))
        let updated = try XCTUnwrap(library.database).all("playlist", as: MusicPlaylist.self)
        XCTAssertEqual(updated.first { $0.id == first }?.trackIDs, [])
        XCTAssertFalse(library.toggleTrack(track.id, in: UUID()))
        // Old duplicate records become wholly unselected instead of retaining a hidden occurrence.
        var legacy = library.playlists[0]; legacy.trackIDs = [track.id, track.id]
        library.changePlaylist(legacy)
        XCTAssertTrue(library.toggleTrack(track.id, in: first))
        XCTAssertTrue(library.playlists[0].trackIDs.isEmpty)
    }

    @MainActor
    func testArtworkTintIsTinyAndReusesCachedImage() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let artwork = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 320), format: format).image { context in
            UIColor.red.setFill(); context.fill(CGRect(x: 0, y: 0, width: 320, height: 160))
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 160, width: 320, height: 160))
        }
        let url = root.appendingPathComponent("art.png")
        try XCTUnwrap(artwork.pngData()).write(to: url)
        let cache = ArtworkSurfaceCache()
        let rendered = await cache.image(at: url)
        let first = try XCTUnwrap(rendered)
        let reused = await cache.image(at: url)
        XCTAssertTrue(first === reused, "Repeated playback updates must not regenerate the blur")
        XCTAssertLessThanOrEqual(first.size.width, 64); XCTAssertLessThanOrEqual(first.size.height, 64)
        let missing = await cache.image(at: root.appendingPathComponent("missing.png"))
        XCTAssertNil(missing)
    }

    @MainActor
    func testUnchangedScanAndCacheClearPreserveUserOrganization() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TestTone", withExtension: "wav"))
        try FileManager.default.copyItem(at: fixture, to: root.appendingPathComponent("Song.wav"))
        let library = LibraryStore(documents: root, inMemory: true)
        library.rescan(); try await waitForScan(library)
        let track = try XCTUnwrap(library.sortedTracks.first)
        library.favorite(track); library.createPlaylist("Keep")
        let playlist = try XCTUnwrap(library.playlists.first)
        library.addTrack(track.id, to: playlist.id)
        XCTAssertTrue(try XCTUnwrap(library.track(track.id)).favorite)
        var publications = 0
        let subscription = library.$tracks.dropFirst().sink { _ in publications += 1 }
        library.rescan(); try await waitForScan(library)
        XCTAssertEqual(publications, 0, "Unchanged scans should not refresh every song row")
        await library.clearArtwork()
        XCTAssertFalse(library.busy)
        XCTAssertTrue(try XCTUnwrap(library.track(track.id)).favorite)
        XCTAssertEqual(library.sortedTracks.map(\.id), [track.id])
        XCTAssertEqual(library.playlists.first?.trackIDs, [track.id])
        subscription.cancel()
    }

    @MainActor
    func testCompactSettingsRenderForVisualInspection() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let library = LibraryStore(documents: root, inMemory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let player = PlaybackCoordinator(); player.connect(library)
        let host = UIHostingController(rootView: NavigationView { SettingsView() }
            .navigationViewStyle(.stack).environmentObject(library).environmentObject(player))
        host.overrideUserInterfaceStyle = .dark
        let bounds = CGRect(x: 0, y: 0, width: 320, height: 548)
        host.view.frame = bounds; host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 150_000_000)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in
            host.view.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/SoundBunker-settings-320x548.png"))
    }

    @MainActor
    func testCompactPlayerRenderForVisualInspection() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let library = LibraryStore(documents: root, inMemory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let player = PlaybackCoordinator(); player.connect(library)
        let host = UIHostingController(rootView: NowPlayingView().environmentObject(library).environmentObject(player))
        host.overrideUserInterfaceStyle = .dark
        let bounds = CGRect(x: 0, y: 0, width: 320, height: 548)
        host.view.frame = bounds
        host.view.setNeedsLayout(); host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 100_000_000)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in
            host.view.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        XCTAssertEqual(image.size.width, 320); XCTAssertEqual(image.size.height, 548)
        try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/SoundBunker-player-320x548.png"))
    }
}
