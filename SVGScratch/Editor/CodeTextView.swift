import AppKit

final class CodeTextView: NSTextView {
    override convenience init(frame frameRect: NSRect) {
        let textContainer = NSTextContainer(containerSize: NSSize(width: frameRect.width, height: .greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        self.init(frame: frameRect, textContainer: textContainer)
    }

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isRichText = true
        isEditable = true
        isSelectable = true
        textColor = EditorTheme.plainText
        font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isAutomaticDataDetectionEnabled = false
        isAutomaticLinkDetectionEnabled = false
        isContinuousSpellCheckingEnabled = false
        isGrammarCheckingEnabled = false
        usesFindBar = true
        isIncrementalSearchingEnabled = true
        allowsUndo = true
    }

    override func insertTab(_ sender: Any?) {
        let range = selectedRange()
        let selectedText = (string as NSString).substring(with: range)
        if selectedText.contains("\n") {
            indentSelectedLines(by: 1)
        } else {
            insertText("  ", replacementRange: range)
        }
    }

    override func insertBacktab(_ sender: Any?) {
        indentSelectedLines(by: -1)
    }

    override func insertNewline(_ sender: Any?) {
        let nsString = string as NSString
        let lineRange = nsString.lineRange(for: NSRange(location: selectedRange().location, length: 0))
        let currentLine = nsString.substring(with: lineRange)
        let leadingWhitespace = currentLine.prefix { $0 == " " || $0 == "\t" }

        super.insertNewline(sender)

        if !leadingWhitespace.isEmpty {
            insertText(String(leadingWhitespace), replacementRange: selectedRange())
        }
    }

    @objc func toggleComment(_ sender: Any?) {
        let nsString = string as NSString
        var range = selectedRange()
        if range.length == 0 {
            range = nsString.lineRange(for: range)
            if range.length > 0 && nsString.substring(with: range).hasSuffix("\n") {
                range.length -= 1
            }
        }

        let selectedText = nsString.substring(with: range)
        let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)

        var newText = selectedText
        if trimmed.hasPrefix("<!--") && trimmed.hasSuffix("-->"),
           let closeRange = selectedText.range(of: "-->", options: .backwards),
           let openRange = selectedText.range(of: "<!--") {
            newText.removeSubrange(closeRange)
            newText.removeSubrange(openRange)
        } else {
            newText = "<!--\(selectedText)-->"
        }

        insertText(newText, replacementRange: range)
        setSelectedRange(NSRange(location: range.location, length: (newText as NSString).length))
    }

    private func indentSelectedLines(by direction: Int) {
        let nsString = string as NSString
        let lineRange = nsString.lineRange(for: selectedRange())
        var lines = nsString.substring(with: lineRange).components(separatedBy: "\n")
        let hasTrailingEmpty = lines.last == ""
        if hasTrailingEmpty { lines.removeLast() }

        let indented = lines.map { line -> String in
            if direction > 0 {
                return "  " + line
            } else if line.hasPrefix("  ") {
                return String(line.dropFirst(2))
            } else if line.hasPrefix(" ") || line.hasPrefix("\t") {
                return String(line.dropFirst(1))
            } else {
                return line
            }
        }

        var newText = indented.joined(separator: "\n")
        if hasTrailingEmpty { newText += "\n" }

        insertText(newText, replacementRange: lineRange)
        setSelectedRange(NSRange(location: lineRange.location, length: (newText as NSString).length))
    }
}
