import Combine

/// Progress changes only invalidate the visible player, not library/artist/list views.
@MainActor
final class PlaybackClock: ObservableObject {
    @Published var position: Double = 0
}
