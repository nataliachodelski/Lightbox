import AppKit

final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = 50
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView, let layoutManager = textView.layoutManager, let textContainer = textView.textContainer else { return }

        EditorTheme.gutterBackground.setFill()
        bounds.fill()

        let visibleRect = textView.visibleRect
        let content = textView.string as NSString
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        let font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: EditorTheme.lineNumber]

        var lineNumber = content.substring(to: charRange.location).components(separatedBy: "\n").count

        let insets = textView.textContainerInset
        var index = charRange.location
        let end = NSMaxRange(charRange)

        while index < end {
            let lineRange = content.lineRange(for: NSRange(location: index, length: 0))
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: lineRange.location)
            let lineFragmentRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)

            let numberString = "\(lineNumber)" as NSString
            let size = numberString.size(withAttributes: attributes)
            let y = lineFragmentRect.minY + insets.height - visibleRect.minY
            let x = ruleThickness - size.width - 8
            numberString.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)

            if lineRange.length == 0 { break }
            index = NSMaxRange(lineRange)
            lineNumber += 1
        }

        let extraLineFragmentRect = layoutManager.extraLineFragmentRect
        if !extraLineFragmentRect.isEmpty {
            let numberString = "\(lineNumber)" as NSString
            let size = numberString.size(withAttributes: attributes)
            let y = extraLineFragmentRect.minY + insets.height - visibleRect.minY
            let x = ruleThickness - size.width - 8
            numberString.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
        }
    }
}
