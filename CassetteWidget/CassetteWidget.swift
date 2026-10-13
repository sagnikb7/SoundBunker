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
        // Recovery opportunity if a reload was missed or storage was temporarily inaccessible.
        // WidgetKit owns actual scheduling; this is not a background polling timer.
        let current = entry()
        completion(Timeline(entries: [current], policy: .after(CassetteWidgetConfiguration.retryDate(after: current.date))))
    }
    private func entry() -> CassetteEntry {
        let directory = CassetteWidgetConfiguration.directory
        let snapshot = CassetteWidgetConfiguration.read(from: directory)
        let image = CassetteWidgetConfiguration.artwork(for: snapshot, in: directory)
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
