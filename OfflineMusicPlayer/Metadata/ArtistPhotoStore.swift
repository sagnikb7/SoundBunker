import Foundation
import CryptoKit
import ImageIO
import UIKit

struct ArtistPhoto: Codable {
    var filename: String
    var creator: String
    var license: String
    var licenseURL: URL
    var sourceURL: URL
    var fileURL: URL
}

/// On-demand Wikimedia-only lookups; persistent positive/negative cache and bounded thumbnails.
actor ArtistPhotoStore {
    static let shared = ArtistPhotoStore()
    struct CacheEntry: Codable { var photo: ArtistPhoto?; var checked: Date; var retryAfter: Date? = nil }
    private let directory: URL
    private let session: URLSession
    private let preferences: UserDefaults
    private var completedDownloads = 0
    private var networkFailures: Set<String> = []
    private var jobs: [String: Task<ArtistPhoto?, Never>] = [:]
    private var lastRequest = Date.distantPast
    private var requesting = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    init(directory: URL? = nil, session: URLSession? = nil, preferences: UserDefaults = .standard) {
        self.preferences = preferences
        self.directory = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("SoundBunkerArtists")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10; configuration.timeoutIntervalForResource = 15
        configuration.waitsForConnectivity = false; configuration.httpMaximumConnectionsPerHost = 2
        self.session = session ?? URLSession(configuration: configuration, delegate: WikimediaRedirectPolicy(), delegateQueue: nil)
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }
    func photo(for artist: String) async -> ArtistPhoto? {
        guard artist != "Unknown Artist", !artist.isEmpty, artist.count <= 150 else { return nil }
        let key = SHA256.hash(data: Data(artist.lowercased().utf8)).map { String(format: "%02x", $0) }.joined()
        let recordURL = directory.appendingPathComponent(key + ".json")
        if let data = try? Data(contentsOf: recordURL), let entry = try? JSONDecoder().decode(CacheEntry.self, from: data) {
            if var photo = entry.photo {
                photo.fileURL = directory.appendingPathComponent(key + ".jpg")
                if FileManager.default.fileExists(atPath: photo.fileURL.path) { return photo }
            }
            if entry.photo == nil, Date() < (entry.retryAfter ?? entry.checked.addingTimeInterval(86_400)) { return nil }
        }
        guard preferences.object(forKey: "artistPhotosEnabled") as? Bool ?? true else { return nil }
        if let job = jobs[key] { return await job.value }
        let job = Task { await self.lookup(artist, key: key) }
        jobs[key] = job
        let photo = await withTaskCancellationHandler(operation: { await job.value }, onCancel: { job.cancel() })
        jobs[key] = nil
        // Failures/no match are cached to avoid a new network request on every row appearance.
        let failed = networkFailures.remove(key) != nil
        if !job.isCancelled, let data = try? JSONEncoder().encode(CacheEntry(photo: photo, checked: Date(), retryAfter: Date().addingTimeInterval(failed ? 300 : 86_400))) { try? data.write(to: recordURL, options: .atomic) }
        return photo
    }
    private func request(_ url: URL, maximumBytes: Int = 1_000_000) async throws -> Data {
        try Task.checkCancellation()
        guard preferences.object(forKey: "artistPhotosEnabled") as? Bool ?? true else { throw CancellationError() }
        guard url.scheme == "https", ["en.wikipedia.org", "upload.wikimedia.org", "thumb.wikimedia.org"].contains(url.host ?? "") else { throw URLError(.badURL) }
        await acquireRequest()
        defer { releaseRequest() }
        try Task.checkCancellation()
        let delay = max(0, 1 - Date().timeIntervalSince(lastRequest))
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        try Task.checkCancellation()
        guard preferences.object(forKey: "artistPhotosEnabled") as? Bool ?? true else { throw CancellationError() }
        lastRequest = Date()
        var request = URLRequest(url: url)
        request.setValue("Cassette/\(AppIdentity.version) (\(AppIdentity.projectURL.absoluteString))", forHTTPHeaderField: "User-Agent")
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              response.url?.scheme == "https", ["en.wikipedia.org", "upload.wikimedia.org", "thumb.wikimedia.org"].contains(response.url?.host ?? "") else { throw URLError(.badServerResponse) }
        var data = Data()
        for try await byte in bytes {
            guard data.count < maximumBytes else { throw URLError(.dataLengthExceedsMaximum) }
            data.append(byte)
        }
        return data
    }
    private func acquireRequest() async {
        if requesting { await withCheckedContinuation { waiters.append($0) } }
        else { requesting = true }
    }
    private func releaseRequest() {
        if waiters.isEmpty { requesting = false }
        else { waiters.removeFirst().resume() }
    }
    static func apiURL(_ parameters: [String: String]) -> URL {
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")!
        components.queryItems = parameters.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }
    static func match(_ pages: [[String: Any]], artist: String) -> [String: Any]? {
        let normalize: (String) -> String = { $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX")).trimmingCharacters(in: .whitespaces) }
        let matches = pages.filter { page in
            let title = (page["title"] as? String ?? "").components(separatedBy: " (")[0]
            let description = (page["description"] as? String ?? "").lowercased()
            let qualifier = (page["title"] as? String ?? "").components(separatedBy: " (").dropFirst().joined().lowercased()
            guard !["film", "album", "song)", "discography", "tour", "soundtrack", "book", "episode"].contains(where: { qualifier.contains($0) }) else { return false }
            let musical = ["singer", "musician", "band", "rapper", "songwriter", "composer", "recording artist", "disc jockey", "dj", "duo", "trio", "pianist", "guitarist", "orchestra"].contains { description.contains($0) }
            let musicGroup = description.contains("group") && ["music", "rock", "pop", "jazz", "folk", "electronic", "metal", "hip hop"].contains { description.contains($0) }
            return normalize(title) == normalize(artist) && (musical || musicGroup)
        }
        return matches.count == 1 ? matches.first : nil
    }
    static func plain(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: "&quot;", with: "\"")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private func lookup(_ artist: String, key: String) async -> ArtistPhoto? {
        do {
            let searchURL = Self.apiURL(["action":"query", "generator":"search", "gsrsearch":artist, "gsrlimit":"3", "gsrnamespace":"0", "prop":"pageimages|description", "piprop":"name", "pilicense":"free", "format":"json", "formatversion":"2"])
            let search = try JSONSerialization.jsonObject(with: await request(searchURL)) as? [String: Any]
            guard let query = search?["query"] as? [String: Any], let pages = query["pages"] as? [[String: Any]],
                  let page = Self.match(pages, artist: artist), let filename = page["pageimage"] as? String else { return nil }
            let infoURL = Self.apiURL(["action":"query", "titles":"File:" + filename, "prop":"imageinfo", "iiprop":"url|extmetadata", "iiurlwidth":"160", "format":"json", "formatversion":"2"])
            let info = try JSONSerialization.jsonObject(with: await request(infoURL)) as? [String: Any]
            let imageQuery = info?["query"] as? [String: Any]
            let imagePages = imageQuery?["pages"] as? [[String: Any]]
            guard let imageInfo = (imagePages?.first?["imageinfo"] as? [[String: Any]])?.first,
                  let thumbnail = imageInfo["thumburl"] as? String, let imageURL = URL(string: thumbnail), ["upload.wikimedia.org", "thumb.wikimedia.org"].contains(imageURL.host ?? ""),
                  let descriptionURL = imageInfo["descriptionurl"] as? String, let sourceURL = URL(string: descriptionURL),
                  sourceURL.scheme == "https", ["commons.wikimedia.org", "en.wikipedia.org"].contains(sourceURL.host ?? ""),
                  let metadata = imageInfo["extmetadata"] as? [String: Any],
                  let creator = (metadata["Artist"] as? [String: Any])?["value"] as? String,
                  let license = (metadata["LicenseShortName"] as? [String: Any])?["value"] as? String else { return nil }
            var licenseComponents = URLComponents(string: ((metadata["LicenseUrl"] as? [String: Any])?["value"] as? String) ?? sourceURL.absoluteString)
            if licenseComponents?.scheme == "http" { licenseComponents?.scheme = "https" }
            let licenseURL = licenseComponents?.url ?? sourceURL
            guard licenseURL.scheme == "https" else { return nil }
            let data = try await request(imageURL, maximumBytes: 2_000_000)
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
                  let thumbnailImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 160, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary),
                  let jpeg = UIImage(cgImage: thumbnailImage).jpegData(compressionQuality: 0.8) else { return nil }
            let fileURL = directory.appendingPathComponent(key + ".jpg")
            try jpeg.write(to: fileURL, options: .atomic)
            completedDownloads += 1
            if completedDownloads.isMultiple(of: 20) { trimCache() }
            return ArtistPhoto(filename: filename, creator: Self.plain(creator), license: Self.plain(license), licenseURL: licenseURL, sourceURL: sourceURL, fileURL: fileURL)
        } catch { networkFailures.insert(key); return nil }
    }
    private func trimCache() {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey])) ?? []
        var bytes = 0
        for file in files.sorted(by: { ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) > ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) }) {
            bytes += (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            if bytes > 10_000_000 { try? FileManager.default.removeItem(at: file) }
        }
    }

}

private final class WikimediaRedirectPolicy: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        let allowed = request.url?.scheme == "https" && ["en.wikipedia.org", "upload.wikimedia.org", "thumb.wikimedia.org"].contains(request.url?.host ?? "")
        completionHandler(allowed ? request : nil)
    }
}
