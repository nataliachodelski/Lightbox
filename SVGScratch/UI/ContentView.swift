import SwiftUI

struct ContentView: View {
    @Binding var document: SVGDocument

    var body: some View {
        HSplitView {
            TextEditor(text: $document.text)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 300)

            Color.gray.opacity(0.2)
                .frame(minWidth: 300)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
