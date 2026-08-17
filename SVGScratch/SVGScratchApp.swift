import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct SVGScratchApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: SVGDocument()) { file in
            ContentView(document: file.$document, fileURL: file.fileURL)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Divider()
                ImportReferenceCommand()
            }

            CommandGroup(after: .textEditing) {
                Divider()

                Button("Find…") {
                    NSApp.sendAction(
                        #selector(NSTextView.performFindPanelAction(_:)),
                        to: nil,
                        from: MenuActionSender(tag: NSTextFinder.Action.showFindInterface.rawValue)
                    )
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Toggle Comment") {
                    NSApp.sendAction(#selector(CodeTextView.toggleComment(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("/", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                ZoomCommands()
                Divider()
                ReferenceCommands()
            }
        }
    }
}

private struct ZoomCommands: View {
    @FocusedValue(\.previewController) var previewController

    var body: some View {
        Group {
            Button("Zoom In") { previewController?.zoomIn() }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(previewController == nil)

            Button("Zoom Out") { previewController?.zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(previewController == nil)

            Button("Actual Size") { previewController?.zoomActualSize() }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(previewController == nil)

            Button("Zoom to Fit") { previewController?.zoomToFit() }
                .keyboardShortcut("9", modifiers: .command)
                .disabled(previewController == nil)
        }
    }
}

private struct ImportReferenceCommand: View {
    @FocusedValue(\.referenceController) var referenceController

    var body: some View {
        Button("Import Reference…") {
            guard let referenceController else { return }
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.image]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK, let url = panel.url {
                referenceController.importImage(from: url)
            }
        }
        .keyboardShortcut("i", modifiers: [.command, .shift])
        .disabled(referenceController == nil)
    }
}

private struct ReferenceCommands: View {
    @FocusedValue(\.referenceController) var referenceController

    var body: some View {
        if let referenceController {
            ReferenceCommandButtons(controller: referenceController)
        } else {
            Group {
                Button("Toggle Reference Visibility") {}
                    .keyboardShortcut("h", modifiers: [.command, .shift])
                    .disabled(true)
                Button("Show Inspector") {}
                    .keyboardShortcut("i", modifiers: [.command, .option])
                    .disabled(true)
            }
        }
    }
}

private struct ReferenceCommandButtons: View {
    @ObservedObject var controller: ReferenceController

    var body: some View {
        Group {
            Button("Toggle Reference Visibility") { controller.toggleVisibility() }
                .keyboardShortcut("h", modifiers: [.command, .shift])
                .disabled(controller.reference == nil)

            Button(controller.isInspectorVisible ? "Hide Inspector" : "Show Inspector") {
                controller.isInspectorVisible.toggle()
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
        }
    }
}

private final class MenuActionSender: NSObject, NSValidatedUserInterfaceItem {
    let tag: Int
    var action: Selector?

    init(tag: Int) {
        self.tag = tag
    }
}
