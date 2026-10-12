import SwiftUI

/// Short, event-driven feedback; the layout and the button's content shape stay fixed.
struct VisualPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.65 : 1)
            .contentShape(Rectangle())
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Animate a transform of the existing thumbnail, never its layout or blur.
struct PlaybackArtworkView: View {
    var reduceMotion: Bool
    var track: Track?
    var side: CGFloat
    var isPlaying: Bool
    var body: some View {
        ArtworkView(track: track).frame(width: side, height: side)
            .scaleEffect(reduceMotion || track == nil || isPlaying ? 1 : 0.9)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isPlaying)
            .frame(width: side, height: side)
    }
}
