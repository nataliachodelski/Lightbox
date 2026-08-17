import SwiftUI

struct ContentView: View {
    @Binding var document: SVGDocument
    @StateObject private var previewController = PreviewController()

    var body: some View {
        HSplitView {
            CodeEditor(text: $document.text)
                .frame(minWidth: 300)
                .onChange(of: document.text) { _, newValue in
                    previewController.textDidChange(newValue)
                }

            ZStack(alignment: .top) {
                PreviewCanvas(bridge: previewController.bridge)

                VStack(spacing: 0) {
                    if let message = previewController.errorMessage {
                        ErrorBanner(message: message, style: .error)
                    }
                    if let notice = previewController.scriptWarning {
                        ErrorBanner(message: notice, style: .notice) {
                            previewController.scriptWarning = nil
                        }
                    }
                }
            }
            .frame(minWidth: 300)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            previewController.textDidChange(document.text)
        }
    }
}
