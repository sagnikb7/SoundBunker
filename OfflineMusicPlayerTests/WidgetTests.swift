import XCTest
import SwiftUI
@testable import OfflineMusicPlayer

final class WidgetTests: XCTestCase {
    func testWidgetSnapshotRoundTripSuppressesUnchangedWritesAndRejectsUnsafePaths() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = WidgetSnapshotStore(directory: directory)
        let first = try await store.publish(title: "Track", artist: "Artist", artwork: nil)
        XCTAssertTrue(first)
        XCTAssertEqual(CassetteWidgetConfiguration.read(from: directory), WidgetSnapshot(title: "Track", artist: "Artist", artworkName: nil))
        let file = directory.appendingPathComponent("snapshot.json")
        let before = try Data(contentsOf: file)
        let unchanged = try await store.publish(title: "Track", artist: "Artist", artwork: nil)
        XCTAssertFalse(unchanged); XCTAssertEqual(try Data(contentsOf: file), before)
        let unsafe = WidgetSnapshot(title: "Track", artist: "Artist", artworkName: "cover-../../private.jpg")
        try JSONEncoder().encode(unsafe).write(to: file)
        XCTAssertEqual(CassetteWidgetConfiguration.read(from: directory), .empty)
        try Data(repeating: 0, count: 65_000).write(to: file)
        XCTAssertEqual(CassetteWidgetConfiguration.read(from: directory), .empty)
    }
    func testWidgetSnapshotSharesOnlyBoundedCoversAndLimitsStorage() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appendingPathComponent("Shared")
        let store = WidgetSnapshotStore(directory: directory)
        for index in 0..<4 {
            let cover = root.appendingPathComponent("Art\(index).jpg")
            try Data([1, 2, UInt8(index)]).write(to: cover)
            _ = try await store.publish(title: "Track \(index)", artist: "Artist", artwork: cover)
        }
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.filter { $0.pathExtension == "jpg" }.count, 2)
        XCTAssertEqual(files.filter { $0.pathExtension == "json" }.count, 1)
        let restored = CassetteWidgetConfiguration.read(from: directory)
        XCTAssertEqual(restored.title, "Track 3")
        XCTAssertNotNil(restored.artworkName)
        let oversized = root.appendingPathComponent("Huge.jpg")
        try Data(repeating: 0, count: 2_000_001).write(to: oversized)
        _ = try await store.publish(title: "Track 4", artist: "Artist", artwork: oversized)
        XCTAssertNil(CassetteWidgetConfiguration.read(from: directory).artworkName)
        let unavailable = try await WidgetSnapshotStore(directory: nil).publish(title: "Unavailable", artist: "Artist", artwork: nil)
        XCTAssertFalse(unavailable)
    }
    func testWidgetLinksOnlyOpenKnownDestinationsWithoutAutoplayCommands() {
        XCTAssertTrue(CassetteWidgetConfiguration.opensPlayer(CassetteWidgetConfiguration.playerURL))
        XCTAssertTrue(CassetteWidgetConfiguration.opensLibrary(CassetteWidgetConfiguration.libraryURL))
        for value in ["https://example.com/player", "cassette://player?play=true", "cassette://player/private", "cassette://user@player", "cassette://player:99", "cassette://player#file", "file:///private/music.mp3"] {
            let url = URL(string: value)!
            XCTAssertFalse(CassetteWidgetConfiguration.opensPlayer(url))
            XCTAssertFalse(CassetteWidgetConfiguration.opensLibrary(url))
        }
    }
    @MainActor
    func testNativeWidgetSizesAndEmptyStateRender() async throws {
        let snapshot = WidgetSnapshot(title: "Night Drive", artist: "Mira Vale", artworkName: nil)
        for (name, square, width, content) in [("square", true, 141.0, snapshot), ("horizontal", false, 292.0, snapshot), ("empty", true, 141.0, WidgetSnapshot.empty)] {
            let view = CassetteWidgetCard(snapshot: content, artwork: nil, square: square).frame(width: width, height: 141).cornerRadius(22).ignoresSafeArea()
            let host = UIHostingController(rootView: view)
            let bounds = CGRect(x: 0, y: 0, width: width, height: 141)
            host.view.frame = bounds; host.view.layoutIfNeeded()
            try await Task.sleep(nanoseconds: 100_000_000)
            let format = UIGraphicsImageRendererFormat(); format.scale = 2
            let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in host.view.drawHierarchy(in: bounds, afterScreenUpdates: true) }
            XCTAssertEqual(image.size, bounds.size)
            try XCTUnwrap(image.pngData()).write(to: URL(fileURLWithPath: "/tmp/Cassette-widget-\(name).png"))
        }
    }
}
