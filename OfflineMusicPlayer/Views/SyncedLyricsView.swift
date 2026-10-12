import SwiftUI

struct SyncedLyricsView: View {
    var lines: [LyricLine]
    var position: Double
    var seek: (Double) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var current: Int? { LRCParser.activeLine(in: lines, at: position) }
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(lines) { line in
                        Button { seek(line.time) } label: {
                            Text(line.text.isEmpty ? "♪" : line.text).font(.body.weight(.semibold))
                                .foregroundColor(.primary).opacity(line.id == current ? 1 : 0.45)
                                .padding(.vertical, 3).frame(maxWidth: .infinity, minHeight: 32, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(VisualPressButtonStyle()).id(line.id)
                    }
                }.animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: current)
            }
            .task(id: current) {
                // Wait for this lazy row's scroll anchor to be laid out before following it.
                await Task.yield()
                if !Task.isCancelled { follow(proxy) }
            }
            .onChange(of: lines) { _ in follow(proxy) }
        }
    }
    private func follow(_ proxy: ScrollViewProxy) {
        guard let current = current else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { proxy.scrollTo(current, anchor: UnitPoint(x: 0.5, y: 0.3)) }
    }
}
