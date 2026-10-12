import Foundation

struct ScannedPlaylist {
    var path: String
    var name: String
    var entries: [String]
}

struct M3UParseResult {
    var entries: [String]
    var issues: [String]
}

enum M3UParser {
    /// Resolve the nearest existing parent too: missing entries must survive /var → /private/var aliases.
    private static func canonical(_ url: URL) -> URL {
        var parent = url.standardizedFileURL
        var missing: [String] = []
        while !FileManager.default.fileExists(atPath: parent.path), parent.path != "/" {
            missing.append(parent.lastPathComponent); parent.deleteLastPathComponent()
        }
        var resolved = parent.resolvingSymlinksInPath()
        for component in missing.reversed() { resolved.appendPathComponent(component) }
        return resolved.standardizedFileURL
    }
    static func parse(_ data: Data, playlist: URL, root: URL) throws -> M3UParseResult {
        guard data.count <= 2_000_000 else { throw CocoaError(.fileReadTooLarge) }
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1252) else { throw CocoaError(.fileReadInapplicableStringEncoding) }
        let base = canonical(root)
        var entries: [String] = [], issues: [String] = []
        for raw in text.replacingOccurrences(of: "\u{feff}", with: "").components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let path = line.replacingOccurrences(of: "\\", with: "/")
            let candidate: URL
            if let url = URL(string: path), let scheme = url.scheme {
                guard scheme.lowercased() == "file", url.host == nil || url.host == "" || url.host == "localhost" else { if issues.count < 20 { issues.append("\(playlist.lastPathComponent): remote or unsupported entry skipped") }; continue }
                candidate = url
            } else if path.hasPrefix("/") { candidate = URL(fileURLWithPath: path) }
            else { candidate = playlist.deletingLastPathComponent().appendingPathComponent(path).standardizedFileURL }
            let resolved = canonical(candidate)
            guard resolved.path.hasPrefix(base.path + "/") else {
                if issues.count < 20 { issues.append("\(playlist.lastPathComponent): entry outside selected folder skipped") }
                continue
            }
            entries.append(String(resolved.path.dropFirst(base.path.count + 1)))
        }
        return M3UParseResult(entries: entries, issues: issues)
    }
}
