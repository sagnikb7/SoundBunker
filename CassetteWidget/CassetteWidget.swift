import SwiftUI
import WidgetKit
import UIKit

struct CassetteEntry: TimelineEntry {
    var date: Date
    var snapshot: WidgetSnapshot
    var artwork: UIImage?
}
struct CassetteProvider: TimelineProvider {
    func placeholder(in context: Context) -> CassetteEntry { CassetteEntry(date: Date(), snapshot: .empty, artwork: nil) }
    func getSnapshot(in context: Context, completion: @escaping (CassetteEntry) -> Void) { completion(entry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CassetteEntry>) -> Void) {
        // Last-played state changes discretely. The app requests a reload only after a changed snapshot write.
        completion(Timeline(entries: [entry()], policy: .never))
    }
    private func entry() -> CassetteEntry {
        let directory = CassetteWidgetConfiguration.directory
        let snapshot = CassetteWidgetConfiguration.read(from: directory)
        let image = snapshot.artworkName.flatMap { name in directory.flatMap { UIImage(contentsOfFile: $0.appendingPathComponent(name).path) } }
        return CassetteEntry(date: Date(), snapshot: snapshot, artwork: image)
    }
}
struct CassetteEntryView: View {
    var entry: CassetteEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        CassetteWidgetCard(snapshot: entry.snapshot, artwork: entry.artwork, square: family == .systemSmall)
            .widgetURL(entry.snapshot.hasTrack ? CassetteWidgetConfiguration.playerURL : CassetteWidgetConfiguration.libraryURL)
    }
}
@main
struct CassetteWidget: Widget {
    var body: some WidgetConfiguration { configuration.contentMarginsDisabled() }
    private var configuration: some WidgetConfiguration {
        StaticConfiguration(kind: CassetteWidgetConfiguration.kind, provider: CassetteProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                CassetteEntryView(entry: entry).containerBackground(for: .widget) { Color(red: 0.08, green: 0.09, blue: 0.11) }
            } else { CassetteEntryView(entry: entry) }
        }.configurationDisplayName("Cassette")
            .description("Your last-played music, one tap away.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}
