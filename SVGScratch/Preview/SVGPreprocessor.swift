import Foundation

struct SVGParseError: Error, Equatable {
    let message: String
}

struct SVGPreprocessResult {
    let text: String
    let didStripScript: Bool
}

enum SVGPreprocessor {
    static func preprocess(_ raw: String) -> Result<SVGPreprocessResult, SVGParseError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .success(SVGPreprocessResult(text: "", didStripScript: false))
        }

        var text = stripPrologAndDoctype(raw)

        let beforeScriptStrip = text
        text = stripScripts(text)
        let didStripScript = text != beforeScriptStrip

        if !hasSVGRoot(text) {
            text = "<svg xmlns=\"http://www.w3.org/2000/svg\">\(text)</svg>"
        }

        if let error = firstParseError(in: text) {
            return .failure(error)
        }

        return .success(SVGPreprocessResult(text: text, didStripScript: didStripScript))
    }

    static func stripPrologAndDoctype(_ text: String) -> String {
        var result = text
        result = replacing(pattern: "<\\?xml[^>]*\\?>", in: result, with: "")
        result = replacing(pattern: "<!DOCTYPE[^>]*>", in: result, with: "", options: [.caseInsensitive])
        return result
    }

    private static func stripScripts(_ text: String) -> String {
        var result = text
        result = replacing(pattern: "<script\\b[^>]*>[\\s\\S]*?</script>", in: result, with: "", options: [.caseInsensitive])
        result = replacing(pattern: "<script\\b[^>]*/>", in: result, with: "", options: [.caseInsensitive])
        return result
    }

    private static func hasSVGRoot(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.range(of: "^<svg[\\s>/]", options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func replacing(pattern: String, in text: String, with replacement: String, options: NSRegularExpression.Options = []) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }

    private static func firstParseError(in text: String) -> SVGParseError? {
        let data = Data(text.utf8)
        let delegate = ParseErrorCollector()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.error
    }
}

private final class ParseErrorCollector: NSObject, XMLParserDelegate {
    var error: SVGParseError?

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        guard error == nil else { return }
        let nsError = parseError as NSError
        let description = nsError.localizedDescription
        error = SVGParseError(message: "\(description) (line \(parser.lineNumber), column \(parser.columnNumber))")
    }
}
