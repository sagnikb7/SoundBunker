import Foundation
import WidgetKit
import CryptoKit

struct WidgetSnapshot: Codable, Equatable {
    var title: String
    var artist: String
    var artworkName: String?
    static let empty = WidgetSnapshot(title: "", artist: "", artworkName: nil)
    var hasTrack: Bool { !title.isEmpty }
}

enum CassetteWidgetConfiguration {
    static let kind = "CassetteLastPlayed"
    static let appGroup = "group.com.local.offlinemusicplayer"
    static let playerURL = URL(string: "cassette://player")!
    static let libraryURL = URL(string: "cassette://library")!
    static func opensPlayer(_ url: URL) -> Bool {
        validRoute(url, host: "player")
    }
    static func opensLibrary(_ url: URL) -> Bool { validRoute(url, host: "library") }
    private static func validRoute(_ url: URL, host: String) -> Bool {
        url.scheme?.lowercased() == "cassette" && url.host == host && url.path.isEmpty && url.query == nil && url.fragment == nil && url.user == nil && url.password == nil && url.port == nil
    }
    static var directory: URL? {
        #if targetEnvironment(macCatalyst)
        return nil // Desktop previews/tests inject a private directory; no group entitlement is needed.
        #else
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?.appendingPathComponent("Widget", isDirectory: true)
        #endif
    }
    static func read(from directory: URL?) -> WidgetSnapshot {
        guard let directory = directory else { return .empty }
        let file = directory.appendingPathComponent("snapshot.json")
        guard let size = try? file.resourceValues(forKeys: [.fileSizeKey, .isSymbolicLinkKey]), size.isSymbolicLink != true, (size.fileSize ?? 64_001) <= 64_000,
              let data = try? Data(contentsOf: file), data.count <= 64_000,
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
              snapshot.title.count <= 1000, snapshot.artist.count <= 1000,
              snapshot.artworkName.map({ $0.hasPrefix("cover-") && $0.hasSuffix(".jpg") && !$0.contains("/") && !$0.contains("..") }) ?? true else { return .empty }
        return snapshot
    }
}

/// Publishes only when visible metadata/artwork changes, never on progress ticks or Play/Pause.
actor WidgetSnapshotStore {
    static let shared = WidgetSnapshotStore(directory: CassetteWidgetConfiguration.directory)
    private let directory: URL?
    init(directory: URL?) { self.directory = directory }
    @discardableResult
    func publish(title: String, artist: String, artwork: URL?) throws -> Bool {
        try Task.checkCancellation()
        guard let directory = directory else { return false }
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        var snapshot = WidgetSnapshot(title: String(title.prefix(1000)), artist: String(artist.prefix(1000)), artworkName: nil)
        if let artwork = artwork, let attributes = try? artwork.resourceValues(forKeys: [.fileSizeKey, .isSymbolicLinkKey]), attributes.isSymbolicLink != true,
           let size = attributes.fileSize, size > 0, size <= 2_000_000 {
            // Only the already-downsampled cover is shared, never audio, bookmarks or the library database.
            let name = "cover-" + SHA256.hash(data: Data(artwork.lastPathComponent.utf8)).prefix(12).map { String(format: "%02x", $0) }.joined() + ".jpg"
            let destination = directory.appendingPathComponent(name)
            if !fm.fileExists(atPath: destination.path) { try Data(contentsOf: artwork).write(to: destination, options: .atomic) }
            snapshot.artworkName = name
        }
        guard CassetteWidgetConfiguration.read(from: directory) != snapshot else { return false }
        try JSONEncoder().encode(snapshot).write(to: directory.appendingPathComponent("snapshot.json"), options: .atomic)
        // Bound storage. Keep one prior cover so a currently rendered old entry can still load it.
        let covers = (try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        let obsolete = covers.filter { $0.lastPathComponent.hasPrefix("cover-") && $0.lastPathComponent != snapshot.artworkName }
            .sorted { ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) > ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) }
        for old in obsolete.dropFirst() { try? fm.removeItem(at: old) }
        return true
    }
}
