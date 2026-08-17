import SwiftUI

struct ContentView: View {
    @Binding var document: SVGDocument
    @StateObject private var previewController = PreviewController()
    @State private var zoomFieldText = "100"

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
        .onChange(of: previewController.zoomPercent) { _, newValue in
            zoomFieldText = String(newValue)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    previewController.zoomOut()
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .help("Zoom Out")

                TextField("Zoom", text: $zoomFieldText, onCommit: {
                    if let value = Int(zoomFieldText) {
                        previewController.setZoom(percent: value)
                    } else {
                        zoomFieldText = String(previewController.zoomPercent)
                    }
                })
                .frame(width: 48)
                .multilineTextAlignment(.trailing)

                Text("%")

                Button {
                    previewController.zoomIn()
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .help("Zoom In")

                Button("Fit") {
                    previewController.zoomToFit()
                }
                .help("Zoom to Fit")

                Menu {
                    Button("Checkerboard") { previewController.setBackground(.checkerboard) }
                    Button("White") { previewController.setBackground(.white) }
                    Button("Black") { previewController.setBackground(.black) }
                    ColorPicker(
                        "Custom…",
                        selection: Binding(
                            get: { backgroundColor(previewController.background) },
                            set: { previewController.setBackground(.custom(NSColor($0))) }
                        )
                    )
                } label: {
                    Image(systemName: "circle.lefthalf.filled")
                }
                .help("Canvas Background")
            }
        }
        .focusedSceneValue(\.previewController, previewController)
    }

    private func backgroundColor(_ background: CanvasBackground) -> Color {
        switch background {
        case .checkerboard: return .white
        case .white: return .white
        case .black: return .black
        case .custom(let color): return Color(color)
        }
    }
}
