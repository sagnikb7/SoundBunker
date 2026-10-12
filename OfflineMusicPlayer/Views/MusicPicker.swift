import SwiftUI
import UniformTypeIdentifiers

struct MusicPicker: UIViewControllerRepresentable {
    var folders: Bool
    var selected: ([URL]) -> Void
    var cancelled: () -> Void
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = folders ? [.folder] : [.audio, .mp3, .mpeg4Audio, .wav, .aiff, UTType(filenameExtension: "m3u") ?? .plainText, UTType(filenameExtension: "m3u8") ?? .plainText]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: false)
        picker.allowsMultipleSelection = !folders; picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: MusicPicker
        init(_ parent: MusicPicker) { self.parent = parent }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { parent.selected(urls) }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { parent.cancelled() }
    }
}
