import Foundation

enum SVGCompletionContext: Equatable {
    case none
    case tagName
    case attributeName(element: String, existingAttributes: Set<String>)
    case attributeValue(element: String, attribute: String)
}

struct SVGCompletionQuery {
    let context: SVGCompletionContext
    let partialWord: String
    let replacementRange: NSRange
}

enum SVGCompletionAnalyzer {
    private static let lessThan: unichar = 60
    private static let greaterThan: unichar = 62
    private static let slash: unichar = 47
    private static let equals: unichar = 61
    private static let doubleQuote: unichar = 34
    private static let singleQuote: unichar = 39

    private static let identifierCharacters: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-:")
        return set
    }()

    static func analyze(text: NSString, cursorLocation: Int) -> SVGCompletionQuery {
        let loc = max(0, min(cursorLocation, text.length))
        let start = identifierRunStart(in: text, before: loc)
        let replacementRange = NSRange(location: start, length: loc - start)
        let partialWord = text.substring(with: replacementRange)

        var i = start
        while i > 0 {
            let c = text.character(at: i - 1)
            if c == greaterThan {
                return SVGCompletionQuery(context: .none, partialWord: partialWord, replacementRange: replacementRange)
            }
            if c == lessThan {
                let context = classify(text: text, tagStart: i - 1, cursor: start)
                return SVGCompletionQuery(context: context, partialWord: partialWord, replacementRange: replacementRange)
            }
            i -= 1
        }
        return SVGCompletionQuery(context: .none, partialWord: partialWord, replacementRange: replacementRange)
    }

    private static func identifierRunStart(in text: NSString, before loc: Int) -> Int {
        var start = loc
        while start > 0, let scalar = Unicode.Scalar(text.character(at: start - 1)), identifierCharacters.contains(scalar) {
            start -= 1
        }
        return start
    }

    private static func classify(text: NSString, tagStart: Int, cursor: Int) -> SVGCompletionContext {
        let tagContentRange = NSRange(location: tagStart + 1, length: max(0, cursor - (tagStart + 1)))
        let tagContent = text.substring(with: tagContentRange) as NSString

        if tagContent.rangeOfCharacter(from: .whitespacesAndNewlines).location == NSNotFound {
            return .tagName
        }

        let element = elementName(in: tagContent)
        let scan = scanTagContent(tagContent)

        if let openAttribute = scan.openAttributeName {
            return .attributeValue(element: element, attribute: openAttribute)
        }
        return .attributeName(element: element, existingAttributes: scan.completedAttributeNames)
    }

    private static func elementName(in tagContent: NSString) -> String {
        var offset = 0
        if tagContent.length > 0, tagContent.character(at: 0) == slash {
            offset = 1
        }
        var end = offset
        while end < tagContent.length, let scalar = Unicode.Scalar(tagContent.character(at: end)), identifierCharacters.contains(scalar) {
            end += 1
        }
        return tagContent.substring(with: NSRange(location: offset, length: end - offset))
    }

    private struct TagScanResult {
        let completedAttributeNames: Set<String>
        let openAttributeName: String?
    }

    private static func scanTagContent(_ tagContent: NSString) -> TagScanResult {
        let length = tagContent.length
        var i = 0
        var pendingName: String?
        var openQuote: unichar?
        var quoteAttrName: String?
        var completed = Set<String>()

        while i < length {
            let c = tagContent.character(at: i)

            if let quote = openQuote {
                if c == quote {
                    openQuote = nil
                    quoteAttrName = nil
                }
                i += 1
                continue
            }

            if c == doubleQuote || c == singleQuote {
                openQuote = c
                quoteAttrName = pendingName
                pendingName = nil
                i += 1
                continue
            }

            if c == equals {
                if let name = pendingName { completed.insert(name) }
                i += 1
                continue
            }

            if let scalar = Unicode.Scalar(c), identifierCharacters.contains(scalar) {
                var end = i
                while end < length, let s = Unicode.Scalar(tagContent.character(at: end)), identifierCharacters.contains(s) {
                    end += 1
                }
                pendingName = tagContent.substring(with: NSRange(location: i, length: end - i))
                i = end
                continue
            }

            i += 1
        }

        return TagScanResult(completedAttributeNames: completed, openAttributeName: openQuote != nil ? quoteAttrName : nil)
    }
}

enum SVGCompletionProvider {
    static func candidates(for query: SVGCompletionQuery) -> [String] {
        switch query.context {
        case .none:
            return []
        case .tagName:
            return SVGSchema.elementNames
                .filter { $0.hasPrefix(query.partialWord) }
                .sorted()
        case .attributeName(let element, let existing):
            return SVGSchema.attributes(for: element)
                .filter { $0.hasPrefix(query.partialWord) && !existing.contains($0) }
                .sorted()
        case .attributeValue(_, let attribute):
            return (SVGSchema.enumAttributeValues[attribute] ?? [])
                .filter { $0.hasPrefix(query.partialWord) }
                .sorted()
        }
    }
}
