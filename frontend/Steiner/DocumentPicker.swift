import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileURL: URL?
    var onPick: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.item]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        let onPick: (URL?) -> Void

        init(_ parent: DocumentPicker, onPick: @escaping (URL?) -> Void) {
            self.parent = parent
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let url = urls.first
            parent.fileURL = url
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(nil)
        }
    }
}
#elseif os(macOS)
import AppKit

struct DocumentPicker: NSViewControllerRepresentable {
    @Binding var fileURL: URL?
    var onPick: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onPick: onPick)
    }

    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NSViewController()
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.item]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK {
                let url = panel.url
                fileURL = url
                onPick(url)
            } else {
                onPick(nil)
            }
        }
        return controller
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}

    class Coordinator: NSObject {
        let parent: DocumentPicker
        let onPick: (URL?) -> Void

        init(_ parent: DocumentPicker, onPick: @escaping (URL?) -> Void) {
            self.parent = parent
            self.onPick = onPick
        }
    }
}
#endif
