import SwiftUI

@main
struct SVGScratchApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: SVGDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
