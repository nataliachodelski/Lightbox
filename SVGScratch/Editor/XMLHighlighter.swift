import AppKit

final class XMLHighlighter: NSObject, NSTextStorageDelegate {
    private static let tokenPattern: NSRegularExpression = {
        let alternatives = [
            #"(?<comment><!--[\s\S]*?-->)"#,
            #"(?<cdata><!\[CDATA\[[\s\S]*?\]\]>)"#,
            #"(?<tag></?[A-Za-z_][-\w:.]*)"#,
            #"(?<attrValue>"[^"]*"|'[^']*')"#,
            #"(?<attrName>[A-Za-z_][-\w:.]*)(?=\s*=)"#,
            #"(?<entity>&(?:#\d+|#x[0-9A-Fa-f]+|[A-Za-z][A-Za-z0-9]*);)"#,
        ]
        let pattern = alternatives.joined(separator: "|")
        return try! NSRegularExpression(pattern: pattern)
    }()

    private static let groupColors: [(name: String, color: NSColor)] = [
        ("comment", EditorTheme.comment),
        ("cdata", EditorTheme.cdata),
        ("tag", EditorTheme.tagName),
        ("attrValue", EditorTheme.attributeValue),
        ("attrName", EditorTheme.attributeName),
        ("entity", EditorTheme.entity),
    ]

    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else { return }
        let fullString = textStorage.string as NSString
        guard fullString.length > 0 else { return }
        let paragraphRange = fullString.paragraphRange(for: editedRange)
        let highlightRange = expanded(paragraphRange, in: fullString, marginLines: 3)
        highlight(textStorage, in: highlightRange)
    }

    func highlightAll(_ textStorage: NSTextStorage) {
        highlight(textStorage, in: NSRange(location: 0, length: textStorage.length))
    }

    private func expanded(_ range: NSRange, in string: NSString, marginLines: Int) -> NSRange {
        var start = range.location
        var end = range.location + range.length

        for _ in 0..<marginLines where start > 0 {
            let previousLine = string.lineRange(for: NSRange(location: start - 1, length: 0))
            start = previousLine.location
        }

        for _ in 0..<marginLines where end < string.length {
            let nextLine = string.lineRange(for: NSRange(location: end, length: 0))
            end = NSMaxRange(nextLine)
        }

        return NSRange(location: start, length: end - start)
    }

    private func highlight(_ textStorage: NSTextStorage, in range: NSRange) {
        guard range.length > 0, NSMaxRange(range) <= textStorage.length else { return }

        textStorage.beginEditing()
        textStorage.removeAttribute(.obliqueness, range: range)
        textStorage.addAttribute(.foregroundColor, value: EditorTheme.plainText, range: range)

        let text = textStorage.string as String
        Self.tokenPattern.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            guard let match else { return }
            apply(match: match, to: textStorage)
        }

        textStorage.endEditing()
    }

    private func apply(match: NSTextCheckingResult, to textStorage: NSTextStorage) {
        for (name, color) in Self.groupColors {
            let groupRange = match.range(withName: name)
            guard groupRange.location != NSNotFound else { continue }
            textStorage.addAttribute(.foregroundColor, value: color, range: groupRange)
            if name == "comment" {
                textStorage.addAttribute(.obliqueness, value: 0.1, range: groupRange)
            }
            return
        }
    }
}
