import Foundation

/// Retains the picker grant across cancellation of an existing scan and the first new scan.
/// The bookmarked URL is resolved afresh after that scan; start/stop remain balanced.
final class FolderAccess {
    let url: URL
    private let started: Bool
    init(_ url: URL) { self.url = url; started = url.startAccessingSecurityScopedResource() }
    deinit { if started { url.stopAccessingSecurityScopedResource() } }
}
