import SwiftUI

@main
struct OfflineMusicPlayerApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var playback = PlaybackCoordinator()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(library).environmentObject(playback)
        }
    }
}
