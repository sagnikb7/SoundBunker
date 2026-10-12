import SwiftUI

@main
struct OfflineMusicPlayerApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var playback = PlaybackCoordinator()
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(library).environmentObject(playback)
        }
    }
}
