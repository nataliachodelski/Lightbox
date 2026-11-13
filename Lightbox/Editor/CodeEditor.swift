import SwiftUI
import AppKit

struct CodeEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false // No longer needed when wrapping
        scrollView.autohidesScrollers = true
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
    
        let textView = CodeTextView(frame: .zero)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false // Lock width to the scroll view
        textView.autoresizingMask = [.width]
    
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true // Wrap text at the view's width
            textContainer.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        }

        textView.delegate = context.coordinator
        textView.textStorage?.delegate = context.coordinator.highlighter
        textView.string = text

        scrollView.documentView = textView

        let ruler = LineNumberRulerView(textView: textView)
        scrollView.verticalRulerView = ruler
        context.coordinator.rulerView = ruler

        if let textStorage = textView.textStorage {
            context.coordinator.highlighter.highlightAll(textStorage)
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
            if let textStorage = textView.textStorage {
                context.coordinator.highlighter.highlightAll(textStorage)
            }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        let highlighter = XMLHighlighter()
        weak var rulerView: LineNumberRulerView?
        private let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
            rulerView?.needsDisplay = true
        }
    }
}
