import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Binding var document: SVGDocument
    let fileURL: URL?
    @StateObject private var previewController: PreviewController
    @StateObject private var referenceController: ReferenceController
    @State private var zoomFieldText = "100"

    init(document: Binding<SVGDocument>, fileURL: URL?) {
        self._document = document
        self.fileURL = fileURL
        let preview = PreviewController()
        _previewController = StateObject(wrappedValue: preview)
        _referenceController = StateObject(wrappedValue: ReferenceController(bridge: preview.bridge))
    }

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
            .onDrop(of: [.image], isTargeted: nil, perform: handleDrop)

            if referenceController.isInspectorVisible {
                ReferenceInspector(controller: referenceController)
                    .frame(minWidth: 240, idealWidth: 260, maxWidth: 320)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            previewController.textDidChange(document.text)
            referenceController.loadForDocument(at: fileURL)
        }
        .onChange(of: fileURL) { _, newURL in
            referenceController.documentURLDidChange(newURL)
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

                Button {
                    referenceController.toggleVisibility()
                } label: {
                    Image(systemName: referenceController.reference?.isVisible == true ? "eye" : "eye.slash")
                }
                .help("Toggle Reference Visibility")
                .disabled(referenceController.reference == nil)

                Button {
                    referenceController.isInspectorVisible.toggle()
                } label: {
                    Image(systemName: "sidebar.right")
                }
                .help("Toggle Inspector")
            }
        }
        .focusedSceneValue(\.previewController, previewController)
        .focusedSceneValue(\.referenceController, referenceController)
    }

    private func backgroundColor(_ background: CanvasBackground) -> Color {
        switch background {
        case .checkerboard: return .white
        case .white: return .white
        case .black: return .black
        case .custom(let color): return Color(color)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
            let result: ReferenceImporter.ImportResult?
            if let url = item as? URL {
                result = ReferenceImporter.importImage(at: url)
            } else if let data = item as? Data {
                result = ReferenceImporter.importImage(data: data)
            } else {
                result = nil
            }
            guard let result else { return }
            DispatchQueue.main.async {
                referenceController.applyImportedReference(result)
            }
        }
        return true
    }
}
