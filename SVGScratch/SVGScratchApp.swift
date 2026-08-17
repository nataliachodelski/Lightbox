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
