import XCTest
import SwiftUI
import Combine
@testable import OfflineMusicPlayer

final class PlayerPolishTests: XCTestCase {
    @MainActor
    func testRecentlyPlayedAndHistoryRenderAtCompactWidth() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let library = LibraryStore(documents: root, inMemory: true)
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TestTone", withExtension: "wav"))
        for name in ["A Song With A Long Title", "Another Song", "Final Song"] {
            try FileManager.default.copyItem(at: fixture, to: root.appendingPathComponent(name + ".wav"))
        }
        library.rescan(); try await waitForScan(library)
        for track in library.sortedTracks { library.recordPlayback(track) }
        let playback = PlaybackCoordinator(); playback.connect(library)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let parent = try XCTUnwrap(scene.windows.first { $0.isKeyWindow }?.rootViewController)
        for (name, content) in [("library", AnyView(LibraryHomeView())), ("history", AnyView(ListeningHistoryView()))] {
            let host = UIHostingController(rootView: NavigationView { content }.navigationViewStyle(.stack).environmentObject(library).environmentObject(playback))
            parent.addChild(host); parent.view.addSubview(host.view); host.didMove(toParent: parent)
            host.overrideUserInterfaceStyle = .light
            let bounds = CGRect(x: 0, y: 0, width: 320, height: 548)
            host.view.frame = bounds
            host.beginAppearanceTransition(true, animated: false); host.endAppearanceTransition()
            host.view.layoutIfNeeded()
            try await Task.sleep(nanoseconds: 250_000_000)
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in host.view.drawHierarchy(in: bounds, afterScreenUpdates: true) }
            try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/Cassette-recent-\(name)-320x548.png"))
            if name == "library" {
                // Catalyst hosts the List in a native scroll surface. A taller capture
                // shows its below-the-fold section while keeping the iPod's 320-point width.
                let expanded = CGRect(x: 0, y: 0, width: 320, height: 820)
                host.view.frame = expanded; host.view.layoutIfNeeded()
                try await Task.sleep(nanoseconds: 250_000_000)
                let fullLibrary = UIGraphicsImageRenderer(bounds: expanded, format: format).image { _ in host.view.drawHierarchy(in: expanded, afterScreenUpdates: true) }
                try XCTUnwrap(fullLibrary.pngData()).write(to: URL(fileURLWithPath: "/tmp/Cassette-recent-library-320x820.png"))
            }
            host.willMove(toParent: nil); host.view.removeFromSuperview(); host.removeFromParent()
        }
    }

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
    func testCompactSleepTimerRenderForVisualInspection() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let library = LibraryStore(documents: root, inMemory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TestTone", withExtension: "wav"))
        try FileManager.default.copyItem(at: fixture, to: root.appendingPathComponent("Song.wav"))
        library.rescan(); try await waitForScan(library)
        let player = PlaybackCoordinator(); player.connect(library)
        player.play(library.sortedTracks); try await waitForPlayback(player); player.pause()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let parent = try XCTUnwrap(scene.windows.first { $0.isKeyWindow }?.rootViewController)
        let host = UIHostingController(rootView: SleepTimerView(clock: player.clock).environmentObject(player))
        parent.addChild(host); parent.view.addSubview(host.view); host.didMove(toParent: parent)
        defer { host.willMove(toParent: nil); host.view.removeFromSuperview(); host.removeFromParent() }
        host.overrideUserInterfaceStyle = .light
        let bounds = CGRect(x: 0, y: 0, width: 320, height: 820)
        host.view.frame = bounds
        host.beginAppearanceTransition(true, animated: false); host.endAppearanceTransition()
        host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 250_000_000)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in host.view.drawHierarchy(in: bounds, afterScreenUpdates: true) }
        try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/Cassette-sleep-timer-320x820.png"))
    }

    @MainActor
    func testFullSettingsAndAboutRenderForDuplicateLinkAudit() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let library = LibraryStore(documents: root, inMemory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let player = PlaybackCoordinator(); player.connect(library)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let parent = try XCTUnwrap(scene.windows.first { $0.isKeyWindow }?.rootViewController)
        for (name, content) in [("settings", AnyView(SettingsView())), ("about", AnyView(AboutView()))] {
            let host = UIHostingController(rootView: NavigationView { content }.navigationViewStyle(.stack).environmentObject(library).environmentObject(player))
            parent.addChild(host); parent.view.addSubview(host.view); host.didMove(toParent: parent)
            host.overrideUserInterfaceStyle = .light
            let bounds = CGRect(x: 0, y: 0, width: 320, height: 1800)
            host.view.frame = bounds
            host.beginAppearanceTransition(true, animated: false); host.endAppearanceTransition()
            host.view.layoutIfNeeded()
            try await Task.sleep(nanoseconds: 250_000_000)
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in host.view.drawHierarchy(in: bounds, afterScreenUpdates: true) }
            try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/Cassette-audit-\(name)-320x1800.png"))
            host.willMove(toParent: nil); host.view.removeFromSuperview(); host.removeFromParent()
        }
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
        try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/Cassette-settings-320x548.png"))
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
        try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/Cassette-player-320x548.png"))

        // Also inspect the two-line header and wrapped metadata without starting playback.
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TestTone", withExtension: "wav"))
        try FileManager.default.copyItem(at: fixture, to: root.appendingPathComponent("A Song With A Longer Display Title.wav"))
        for name in ["B Next Song", "C Last Song"] { try FileManager.default.copyItem(at: fixture, to: root.appendingPathComponent(name + ".wav")) }
        library.rescan(); try await waitForScan(library)
        try library.database?.save(PlaybackSnapshot(queue: library.sortedTracks.map(\.id), index: 0, position: 0, repeatMode: .off, shuffle: false), key: "playback", kind: "playback")
        try library.database?.commit()
        let restored = PlaybackCoordinator(); restored.connect(library)
        XCTAssertFalse(restored.isPlaying)
        for mode in [NowPlayingMode.artwork, .queue, .lyrics] {
            let populatedHost = UIHostingController(rootView: NowPlayingView(initialMode: mode).environmentObject(library).environmentObject(restored))
            populatedHost.overrideUserInterfaceStyle = .dark
            populatedHost.view.frame = bounds; populatedHost.view.layoutIfNeeded()
            try await Task.sleep(nanoseconds: 100_000_000)
            let populated = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in
                populatedHost.view.drawHierarchy(in: bounds, afterScreenUpdates: true)
            }
            let name = mode == .artwork ? "populated" : mode == .queue ? "queue" : "lyrics"
            try XCTUnwrap(populated.pngData()).write(to: URL(fileURLWithPath: "/tmp/Cassette-player-\(name)-320x548.png"))
        }

        defer { restored.pause() }
        for (name, playing) in [("playing", true), ("paused", false)] {
            if playing { restored.play(); try await waitForPlayback(restored); XCTAssertTrue(restored.isPlaying) } else { restored.pause(); XCTAssertFalse(restored.isPlaying) }
            let motionHost = UIHostingController(rootView: NowPlayingView().environmentObject(library).environmentObject(restored))
            motionHost.overrideUserInterfaceStyle = .dark
            motionHost.view.frame = bounds; motionHost.view.layoutIfNeeded()
            try await Task.sleep(nanoseconds: 350_000_000)
            let rendered = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in
                motionHost.view.drawHierarchy(in: bounds, afterScreenUpdates: true)
            }
            try XCTUnwrap(rendered.pngData()).write(to: URL(fileURLWithPath: "/tmp/Cassette-player-\(name)-320x548.png"))
        }

        // The system accessibility environment is read-only; render the same artwork policy directly.
        var reducedImages: [Data] = []
        for playing in [false, true] {
            let reducedHost = UIHostingController(rootView: PlaybackArtworkView(reduceMotion: true, track: restored.currentTrack, side: 200, isPlaying: playing)
                .frame(width: 240, height: 240).background(Color(UIColor.systemBackground)).ignoresSafeArea().environmentObject(library))
            reducedHost.overrideUserInterfaceStyle = .dark
            let reducedBounds = CGRect(x: 0, y: 0, width: 240, height: 240)
            reducedHost.view.frame = reducedBounds; reducedHost.view.layoutIfNeeded()
            try await Task.sleep(nanoseconds: 100_000_000)
            let rendered = UIGraphicsImageRenderer(bounds: reducedBounds, format: format).image { _ in
                reducedHost.view.drawHierarchy(in: reducedBounds, afterScreenUpdates: true)
            }
            reducedImages.append(try XCTUnwrap(rendered.pngData()))
        }
        XCTAssertEqual(reducedImages[0], reducedImages[1], "Reduce Motion must keep artwork geometry identical on play/pause")
        try reducedImages[0].write(to: URL(fileURLWithPath: "/tmp/Cassette-player-reduced-motion.png"))
    }
}
