import SwiftUI

struct WidgetPreviewView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var playback: PlaybackCoordinator
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your music, at a glance.").font(.headline)
                Text("Both sizes open the player when tapped. iOS 15 widgets do not play or pause music without opening the app.").font(.subheadline).foregroundColor(.secondary)
                Text("Square").font(.footnote.weight(.semibold))
                CassetteWidgetCard(snapshot: snapshot, artwork: image, square: true).frame(width: 141, height: 141).cornerRadius(22)
                Text("Horizontal").font(.footnote.weight(.semibold))
                CassetteWidgetCard(snapshot: snapshot, artwork: image, square: false).frame(maxWidth: 329).frame(height: 141).cornerRadius(22)
                Text("Add a widget").font(.headline)
                Text("Touch and hold the Home Screen, tap +, find Cassette, then choose the square or horizontal size.").font(.subheadline)
                Text("Artwork and track details need both the app and widget signed with the same App Group. A preview here does not confirm widget installation or signing.").font(.footnote).foregroundColor(.secondary)
            }.padding(16)
        }.navigationTitle("Widgets").navigationBarTitleDisplayMode(.inline)
    }
    private var snapshot: WidgetSnapshot { WidgetSnapshot(title: playback.currentTrack?.title ?? "", artist: playback.currentTrack?.artist ?? "", artworkName: nil) }
    private var image: UIImage? { playback.currentTrack?.artwork.flatMap { ThumbnailLoader.shared.image(library.artworkDirectory.appendingPathComponent($0).path) } }
}
