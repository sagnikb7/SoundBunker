import XCTest
import SwiftUI
@testable import OfflineMusicPlayer

final class ArtistPhotoTests: XCTestCase {
    @MainActor
    func testPhotoLookupCachesPixelsAndAttributionAndOptOutStopsRequests() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let suite = UUID().uuidString
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        preferences.set(true, forKey: "artistPhotosEnabled")
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let jpeg = try XCTUnwrap(UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400), format: format).image { context in UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 400, height: 400)) }.jpegData(compressionQuality: 0.8))
        ArtistProtocol.configure(image: jpeg)
        let configuration = URLSessionConfiguration.ephemeral; configuration.protocolClasses = [ArtistProtocol.self]
        let service = ArtistPhotoStore(directory: root, session: URLSession(configuration: configuration), preferences: preferences)
        let result = await service.photo(for: "Test Singer")
        let photo = try XCTUnwrap(result)
        XCTAssertEqual(photo.creator, "Test Creator")
        XCTAssertEqual(photo.license, "CC BY 4.0")
        XCTAssertEqual(photo.sourceURL.host, "commons.wikimedia.org")
        XCTAssertLessThanOrEqual(try XCTUnwrap(UIImage(contentsOfFile: photo.fileURL.path)).size.width, 160)
        XCTAssertEqual(ArtistProtocol.count, 3)
        _ = await service.photo(for: "Test Singer")
        XCTAssertEqual(ArtistProtocol.count, 3)
        preferences.set(false, forKey: "artistPhotosEnabled")
        let cached = await service.photo(for: "Test Singer")
        XCTAssertNotNil(cached)
        let other = await service.photo(for: "Other Singer")
        XCTAssertNil(other)
        XCTAssertEqual(ArtistProtocol.count, 3)
    }
    @MainActor
    func testNoMatchAndOfflineFailureAreNegativelyCached() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let suite = UUID().uuidString
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        ArtistProtocol.configure(image: Data(), offline: true)
        let configuration = URLSessionConfiguration.ephemeral; configuration.protocolClasses = [ArtistProtocol.self]
        let service = ArtistPhotoStore(directory: root, session: URLSession(configuration: configuration), preferences: preferences)
        let first = await service.photo(for: "Test Singer")
        let second = await service.photo(for: "Test Singer")
        XCTAssertNil(first); XCTAssertNil(second)
        XCTAssertEqual(ArtistProtocol.count, 1)
    }
}

private final class ArtistProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var image = Data()
    private static var requests = 0
    private static var offline = false
    static var count: Int { lock.lock(); defer { lock.unlock() }; return requests }
    static func configure(image: Data, offline: Bool = false) {
        lock.lock(); defer { lock.unlock() }
        Self.image = image; Self.offline = offline; requests = 0
    }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock(); Self.requests += 1; let offline = Self.offline; let image = Self.image; Self.lock.unlock()
        if offline { client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)); return }
        let url = request.url!
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let data: Data
        if url.host == "thumb.wikimedia.org" { data = image }
        else if query.contains(where: { $0.name == "generator" }) {
            data = Data(#"{"query":{"pages":[{"title":"Test Singer","description":"British singer","pageimage":"Photo.jpg"}]}}"#.utf8)
        } else {
            data = Data(#"{"query":{"pages":[{"imageinfo":[{"thumburl":"https://thumb.wikimedia.org/test.jpg","descriptionurl":"https://commons.wikimedia.org/wiki/File:Photo.jpg","extmetadata":{"ExtraProviderField":{"value":42},"Artist":{"value":"<b>Test Creator</b>"},"LicenseShortName":{"value":"CC BY 4.0"},"LicenseUrl":{"value":"https://creativecommons.org/licenses/by/4.0"}}}]}]}}"#.utf8)
        }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":url.host == "thumb.wikimedia.org" ? "image/jpeg" : "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
