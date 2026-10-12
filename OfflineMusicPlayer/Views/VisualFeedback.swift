import SwiftUI
import UIKit

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
            .shadow(color: .black.opacity(track != nil && (isPlaying || reduceMotion) ? 0.28 : 0), radius: 12, x: 0, y: 6)
            .scaleEffect(reduceMotion || track == nil || isPlaying ? 1 : 0.9)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isPlaying)
            .frame(width: side, height: side)
    }
}


/// Native gesture arbitration prevents a released hold from also skipping a song.
struct SeekTransportButton: UIViewRepresentable {
    var symbol: String
    var label: String
    var tap: () -> Void
    var seek: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24)), for: .normal)
        button.tintColor = .label
        button.accessibilityLabel = label
        button.accessibilityHint = "Touch and hold to seek"
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        let hold = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.held(_:)))
        hold.minimumPressDuration = 0.4
        button.addGestureRecognizer(hold)
        button.accessibilityCustomActions = [UIAccessibilityCustomAction(name: symbol == "forward.fill" ? "Seek forward" : "Seek backward", target: context.coordinator, selector: #selector(Coordinator.accessibleSeek))]
        return button
    }
    func updateUIView(_ button: UIButton, context: Context) { context.coordinator.parent = self }
    static func dismantleUIView(_ button: UIButton, coordinator: Coordinator) { coordinator.stop() }

    final class Coordinator: NSObject {
        var parent: SeekTransportButton
        private var timer: Timer?
        init(_ parent: SeekTransportButton) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(stop), name: UIApplication.willResignActiveNotification, object: nil)
        }
        @objc func tapped() { parent.tap() }
        @objc func accessibleSeek() -> Bool { parent.seek(); return true }
        @objc func held(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                beginSeeking()
            } else if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
                stop()
            }
        }
        func beginSeeking() {
            stop()
            parent.seek()
            let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in self?.parent.seek() }
            self.timer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
        @objc func stop() { timer?.invalidate(); timer = nil }
        deinit { timer?.invalidate(); NotificationCenter.default.removeObserver(self) }
    }
}
