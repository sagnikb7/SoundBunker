import SwiftUI

struct SyncedLyricsView: View {
    var lines: [LyricLine]
    var position: Double
    var seek: (Double) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var following = true
    private var current: Int? { LRCParser.activeLine(in: lines, at: position) }
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(lines) { line in
                        Button { seek(line.time) } label: {
                            Text(line.text.isEmpty ? "♪" : line.text).font(.body.weight(.semibold))
                                .foregroundColor(.primary).opacity(line.id == current ? 1 : 0.45)
                                .padding(.vertical, 4).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(VisualPressButtonStyle()).id(line.id)
                    }
                }.animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: current)
            }
            .simultaneousGesture(DragGesture(minimumDistance: 10).onChanged { _ in following = false })
            .overlay(alignment: .topTrailing) {
                if !following {
                    Button("Follow") { following = true; follow(proxy) }.font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12).frame(minHeight: 44).background(.regularMaterial).cornerRadius(10)
                        .accessibilityLabel("Follow current lyric")
                }
            }
            .task(id: current) {
                // Wait for this lazy row's scroll anchor to be laid out before following it.
                await Task.yield()
                if following && !Task.isCancelled { follow(proxy) }
            }
            .onChange(of: lines) { _ in following = true; follow(proxy) }
        }
    }
    private func follow(_ proxy: ScrollViewProxy) {
        guard let current = current else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { proxy.scrollTo(current, anchor: UnitPoint(x: 0.5, y: 0.3)) }
    }
}
