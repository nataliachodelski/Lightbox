import AppKit

final class CodeTextView: NSTextView {
    private lazy var completionPopup: CompletionPopup = {
        let popup = CompletionPopup()
        popup.onAccept = { [weak self] word in self?.acceptCompletion(word) }
        return popup
    }()

    private var currentCompletionContext: SVGCompletionContext = .none
    private var currentReplacementRange = NSRange(location: 0, length: 0)

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

    // MARK: - Completion

    override func didChangeText() {
        super.didChangeText()
        updateCompletionState()
    }

    private func updateCompletionState() {
        let nsString = self.string as NSString
        let query = SVGCompletionAnalyzer.analyze(text: nsString, cursorLocation: selectedRange().location)
        currentCompletionContext = query.context
        currentReplacementRange = query.replacementRange

        let candidates = SVGCompletionProvider.candidates(for: query)
        guard query.context != .none, !candidates.isEmpty, let window else {
            completionPopup.hide()
            return
        }

        if completionPopup.isVisible {
            completionPopup.updateItems(candidates)
        } else if let screenPoint = screenPointBelowCaret() {
            completionPopup.show(items: candidates, at: screenPoint, parent: window)
        }
    }

    private func screenPointBelowCaret() -> NSPoint? {
        guard let window, let layoutManager else { return nil }
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: selectedRange().location)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        let glyphLocation = layoutManager.location(forGlyphAt: glyphIndex)
        let insets = textContainerInset
        let pointInView = NSPoint(x: glyphLocation.x + insets.width, y: lineRect.maxY + insets.height)
        let pointInWindow = convert(pointInView, to: nil)
        return window.convertPoint(toScreen: pointInWindow)
    }

    private func acceptCompletion(_ word: String) {
        let range = currentReplacementRange
        if case .attributeName = currentCompletionContext {
            let insertion = "\(word)=\"\""
            insertText(insertion, replacementRange: range)
            let caretLocation = range.location + (insertion as NSString).length - 1
            setSelectedRange(NSRange(location: caretLocation, length: 0))
        } else {
            insertText(word, replacementRange: range)
        }
        completionPopup.hide()
    }

    override func moveUp(_ sender: Any?) {
        if completionPopup.isVisible {
            completionPopup.moveSelection(by: -1)
            return
        }
        super.moveUp(sender)
    }

    override func moveDown(_ sender: Any?) {
        if completionPopup.isVisible {
            completionPopup.moveSelection(by: 1)
            return
        }
        super.moveDown(sender)
    }

    override func cancelOperation(_ sender: Any?) {
        if completionPopup.isVisible {
            completionPopup.hide()
            return
        }
        super.cancelOperation(sender)
    }

    override func mouseDown(with event: NSEvent) {
        completionPopup.hide()
        super.mouseDown(with: event)
    }

    override func resignFirstResponder() -> Bool {
        completionPopup.hide()
        return super.resignFirstResponder()
    }

    // MARK: - Editing

    override func insertTab(_ sender: Any?) {
        if completionPopup.isVisible, let selected = completionPopup.selectedItem {
            acceptCompletion(selected)
            return
        }

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
        completionPopup.hide()

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
