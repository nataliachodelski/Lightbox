import SwiftUI
import AppKit

@main
struct SVGScratchApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: SVGDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
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

private final class MenuActionSender: NSObject, NSValidatedUserInterfaceItem {
    let tag: Int
    var action: Selector?

    init(tag: Int) {
        self.tag = tag
    }
}
