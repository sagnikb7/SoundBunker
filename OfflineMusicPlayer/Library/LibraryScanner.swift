import AVFoundation
import UIKit

struct ScanResult {
    var tracks: [Track]
    var seen: Set<String>
    var skipped: Int
    var issues: [String]
}

enum LocalFilePolicy {
    static func musicFile(_ relativePath: String, in root: URL) throws -> URL {
        let canonicalRoot = root.resolvingSymlinksInPath().standardizedFileURL
        let file = canonicalRoot.appendingPathComponent(relativePath).standardizedFileURL
        let resolved = file.resolvingSymlinksInPath().standardizedFileURL
        guard !relativePath.hasPrefix("/"), resolved.path.hasPrefix(canonicalRoot.path + "/") else {
            throw CocoaError(.fileReadNoPermission)
        }
        try check(file)
        return file
    }

    static func check(_ url: URL) throws {
        guard url.isFileURL else { throw CocoaError(.fileReadUnsupportedScheme) }
        let values = try url.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey, .isSymbolicLinkKey])
        guard values.isSymbolicLink != true else { throw CocoaError(.fileReadNoPermission) }
        if values.isUbiquitousItem == true && values.ubiquitousItemDownloadingStatus != .current && values.ubiquitousItemDownloadingStatus != .downloaded {
            throw NSError(domain: "PocketMusic", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cloud-only file skipped. Download it in Files before adding it."])
        }
        // Do not ask external File Provider extensions to materialize files.
        if url.path.contains("File Provider Storage") || url.path.contains("FileProviderStorage") {
            throw NSError(domain: "PocketMusic", code: 2, userInfo: [NSLocalizedDescriptionKey: "Provider storage cannot be verified offline. Move these files to On My iPod → SoundBunker first."])
        }
    }
}

actor LibraryScanner {
    static let extensions: Set<String> = ["mp3", "m4a", "aac", "alac", "wav", "aiff", "aif", "flac", "ogg", "opus"]
    func scan(root: URL, sourceID: UUID, existing: [String: Track], cache: URL, excluded: [String] = [],
              progress: @escaping @Sendable ([Track], Int) async -> Void) async throws -> ScanResult {
        let scanRoot = root.resolvingSymlinksInPath().standardizedFileURL
        try LocalFilePolicy.check(scanRoot)
        guard FileManager.default.isReadableFile(atPath: scanRoot.path) else { throw CocoaError(.fileReadNoPermission) }
        var issues: [String] = []
        guard let enumerator = FileManager.default.enumerator(at: scanRoot,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileResourceIdentifierKey, .volumeIdentifierKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants], errorHandler: { url, error in
                issues.append("\(url.lastPathComponent): \(error.localizedDescription)"); return true
            }) else { throw CocoaError(.fileReadUnknown) }
        var tracks: [Track] = [], batch: [Track] = [], seen = Set<String>(), skipped = 0, count = 0
        while let file = enumerator.nextObject() as? URL {
            try Task.checkCancellation()
            do {
                let relativePath = String(file.resolvingSymlinksInPath().path.dropFirst(scanRoot.path.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if excluded.contains(where: { relativePath == $0 || relativePath.hasPrefix($0 + "/") }) { enumerator.skipDescendants(); continue }
                let attributes = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileResourceIdentifierKey, .volumeIdentifierKey, .fileSizeKey, .contentModificationDateKey])
                if attributes.isSymbolicLink == true { enumerator.skipDescendants(); continue }
                guard attributes.isRegularFile == true, Self.extensions.contains(file.pathExtension.lowercased()) else { continue }
                count += 1
                try LocalFilePolicy.check(file)
                let relative = String(file.resolvingSymlinksInPath().path.dropFirst(scanRoot.path.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                let identity: String
                if let fid = attributes.fileResourceIdentifier, let volume = attributes.volumeIdentifier {
                    identity = "\(volume):\(fid)"
                } else { identity = file.standardizedFileURL.path }
                let fingerprint = "\(attributes.fileSize ?? 0):\(attributes.contentModificationDate?.timeIntervalSince1970 ?? 0)"
                var track: Track
                if let previous = existing[identity], previous.fingerprint == fingerprint { track = previous }
                else {
                    track = try await metadata(file, id: identity, fingerprint: fingerprint, cache: cache)
                    if let previous = existing[identity] { track.added = previous.added; track.favorite = previous.favorite; track.locations = previous.locations }
                }
                let location = TrackLocation(sourceID: sourceID, relativePath: relative, available: true)
                if let index = track.locations.firstIndex(where: { $0.sourceID == sourceID }) { track.locations[index] = location }
                else { track.locations.append(location) }
                seen.insert(identity)
                tracks.append(track); batch.append(track)
                if batch.count == 25 { await progress(batch, count); batch.removeAll() }
            } catch is CancellationError { throw CancellationError() }
            catch { skipped += 1; if issues.count < 20 { issues.append("\(file.lastPathComponent): \(error.localizedDescription)") } }
        }
        if !batch.isEmpty { await progress(batch, count) }
        return ScanResult(tracks: tracks, seen: seen, skipped: skipped, issues: issues)
    }

    private func metadata(_ url: URL, id: String, fingerprint: String, cache: URL) async throws -> Track {
        var readError: NSError?
        var asset: AVURLAsset?
        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &readError) { coordinatedURL in
            asset = AVURLAsset(url: coordinatedURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        }
        if let error = readError { throw error }
        guard let asset = asset else { throw CocoaError(.fileReadUnknown) }
        var duration = (try? await asset.load(.duration).seconds) ?? 0
        let items = (try? await asset.load(.metadata)) ?? []
        if !duration.isFinite || duration <= 0, let audio = try? AVAudioFile(forReading: url) {
            duration = Double(audio.length) / audio.processingFormat.sampleRate
        }
        func value(_ key: AVMetadataKey) -> String? {
            items.first { $0.commonKey == key }?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        func tag(_ fragments: [String]) -> String? {
            items.first { item in fragments.contains { (item.identifier?.rawValue ?? String(describing: item.key)).localizedCaseInsensitiveContains($0) } }?.stringValue
        }
        let title = value(.commonKeyTitle).flatMap { $0.isEmpty ? nil : $0 } ?? url.deletingPathExtension().lastPathComponent
        let artist = value(.commonKeyArtist) ?? "Unknown Artist"
        let album = value(.commonKeyAlbumName) ?? "Unknown Album"
        var artwork: String?
        if let data = items.first(where: { $0.commonKey == .commonKeyArtwork })?.dataValue,
           data.count < 15_000_000, let image = UIImage(data: data) {
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let thumbnail = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 320), format: format).image { _ in
                let factor = max(320 / image.size.width, 320 / image.size.height)
                let size = CGSize(width: image.size.width * factor, height: image.size.height * factor)
                image.draw(in: CGRect(x: (320 - size.width) / 2, y: (320 - size.height) / 2, width: size.width, height: size.height))
            }
            let name = UUID().uuidString + ".jpg"
            if let jpg = thumbnail.jpegData(compressionQuality: 0.8) { try jpg.write(to: cache.appendingPathComponent(name), options: .atomic); artwork = name }
        }
        var lyrics = tag(["USLT", "lyrics"])
        let lrc = url.deletingPathExtension().appendingPathExtension("lrc")
        if FileManager.default.fileExists(atPath: lrc.path) {
            try LocalFilePolicy.check(lrc)
            let size = try lrc.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            if size < 1_000_000 { lyrics = try? String(contentsOf: lrc, encoding: .utf8) }
        }
        return Track(id: id, title: title, artist: artist, albumArtist: tag(["albumArtist", "TPE2", "aART"]) ?? artist,
                     album: album, genre: tag(["genre", "TCON"]) ?? "Unknown Genre", duration: duration.isFinite ? duration : 0,
                     trackNumber: Int((tag(["trackNumber", "TRCK"]) ?? "0").components(separatedBy: "/")[0]) ?? 0,
                     discNumber: Int((tag(["discNumber", "TPOS"]) ?? "0").components(separatedBy: "/")[0]) ?? 0,
                     fingerprint: fingerprint, artwork: artwork, lyrics: lyrics, locations: [], added: Date())
    }
}
