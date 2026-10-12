import XCTest
import AVFoundation
@testable import OfflineMusicPlayer

final class PlaybackTests: XCTestCase {
    @MainActor
    func testNativeFixtureAdvancesAndPauses() async throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TestTone", withExtension: "wav"))
        let engine = NativeAudioEngine()
        try engine.load(url)
        XCTAssertEqual(engine.duration, 12, accuracy: 0.01)
        try AVAudioSession.sharedInstance().setCategory(.playback)
        try AVAudioSession.sharedInstance().setActive(true)
        try engine.play()
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertTrue(engine.isPlaying); XCTAssertGreaterThan(engine.currentTime, 0)
        engine.pause(); let paused = engine.currentTime
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(engine.currentTime, paused, accuracy: 0.02)
        engine.seek(to: -.infinity); XCTAssertEqual(engine.currentTime, paused, accuracy: 0.02)
        engine.seek(to: -1); XCTAssertEqual(engine.currentTime, 0)
        var completed = false
        engine.onCompletion = { completed = true }
        engine.seek(to: 11.85); try engine.play()
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertTrue(completed, "Native end-of-track callback must arrive")
        engine.stop()
    }
    @MainActor
    func testPlaybackSettingsPersistAndPositionPreferenceDoesNotAutoplay() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TestTone", withExtension: "wav"))
        try FileManager.default.copyItem(at: fixture, to: root.appendingPathComponent("Song.wav"))
        let library = LibraryStore(documents: root, inMemory: true)
        library.rescan(); try await waitForScan(library)
        let suite = UUID().uuidString
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let player = PlaybackCoordinator(engine: StubEngine(), preferences: preferences)
        player.connect(library); player.setRepeatMode(.all)
        let emptyRestored = PlaybackCoordinator(engine: StubEngine(), preferences: preferences)
        emptyRestored.connect(library)
        XCTAssertEqual(emptyRestored.repeatMode, .all)
        player.play(library.sortedTracks); player.seek(to: 5); player.pause()
        preferences.set(false, forKey: "rememberPlaybackPosition")
        let restored = PlaybackCoordinator(engine: StubEngine(), preferences: preferences)
        restored.connect(library)
        XCTAssertEqual(restored.currentTrack?.id, player.currentTrack?.id)
        XCTAssertEqual(restored.position, 0)
        XCTAssertFalse(restored.isPlaying)
        XCTAssertEqual(restored.repeatMode, .all)
        preferences.set(true, forKey: "rememberPlaybackPosition")
        let remembered = PlaybackCoordinator(engine: StubEngine(), preferences: preferences)
        remembered.connect(library)
        XCTAssertEqual(remembered.position, 5)
        XCTAssertFalse(remembered.isPlaying)
    }
    @MainActor
    func testRejectsRemoteURL() {
        XCTAssertThrowsError(try NativeAudioEngine().load(URL(string: "https://example.invalid/song.mp3")!))
    }
    @MainActor
    func testQueueRepeatRestorationAndUnavailableRecovery() async throws {
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TestTone", withExtension: "wav"))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for name in ["A", "B", "C"] { try FileManager.default.copyItem(at: fixture, to: root.appendingPathComponent(name + ".wav")) }
        let library = LibraryStore(documents: root, inMemory: true)
        library.rescan(); try await waitForScan(library)
        XCTAssertEqual(library.tracks.count, 3)
        let songs = library.sortedTracks
        guard songs.count == 3 else { XCTFail(library.errorMessage ?? "Missing indexed fixture tracks"); return }
        let engine = StubEngine()
        let player = PlaybackCoordinator(engine: engine); player.connect(library)
        XCTAssertNil(player.currentTrack); XCTAssertFalse(player.isPlaying)
        player.play(songs); XCTAssertEqual(player.currentTrack?.title, "A")
        engine.onCompletion?(); XCTAssertEqual(player.currentTrack?.title, "B")
        player.cycleRepeat(); player.cycleRepeat(); XCTAssertEqual(player.repeatMode, .one)
        engine.onCompletion?(); XCTAssertEqual(player.currentTrack?.title, "B")
        player.cycleRepeat(); player.seek(to: 5); player.pause()
        let restored = PlaybackCoordinator(engine: StubEngine()); restored.connect(library)
        XCTAssertEqual(restored.currentTrack?.title, "B"); XCTAssertEqual(restored.position, 5); XCTAssertFalse(restored.isPlaying)
        try FileManager.default.removeItem(at: root.appendingPathComponent("B.wav"))
        library.rescan(); try await waitForScan(library)
        player.play(songs, startingAt: songs[1]); XCTAssertEqual(player.currentTrack?.title, "C")
        player.pause()
    }
}

@MainActor
private final class StubEngine: AudioEngine {
    var duration: TimeInterval = 0
    var currentTime: TimeInterval = 0
    var isPlaying = false
    var onCompletion: (() -> Void)?
    var onFailure: ((Error) -> Void)?
    func load(_ url: URL) throws { guard FileManager.default.fileExists(atPath: url.path) else { throw CocoaError(.fileReadNoSuchFile) }; duration = 12; currentTime = 0 }
    func play() throws { isPlaying = true }
    func pause() { isPlaying = false }
    func seek(to time: TimeInterval) { currentTime = min(max(0, time), duration) }
    func stop() { isPlaying = false; duration = 0 }
}

@MainActor
func waitForScan(_ library: LibraryStore) async throws {
    for _ in 0..<200 {
        if !library.scanning { return }
        try await Task.sleep(nanoseconds: 50_000_000)
    }
    XCTFail("Scan did not finish within 10 seconds"); library.cancelScan()
}
