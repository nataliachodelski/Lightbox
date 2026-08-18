import XCTest
@testable import SVGScratch

final class SVGCompletionTests: XCTestCase {
    private func query(_ text: String) -> SVGCompletionQuery {
        let nsString = text as NSString
        return SVGCompletionAnalyzer.analyze(text: nsString, cursorLocation: nsString.length)
    }

    func testTagNameContext() {
        let result = query("<cir")
        XCTAssertEqual(result.context, .tagName)
        XCTAssertEqual(result.partialWord, "cir")

        let candidates = SVGCompletionProvider.candidates(for: result)
        XCTAssertTrue(candidates.contains("circle"))
    }

    func testTagNameContextAtBareLessThan() {
        let result = query("<")
        XCTAssertEqual(result.context, .tagName)
        XCTAssertEqual(result.partialWord, "")
        XCTAssertFalse(SVGCompletionProvider.candidates(for: result).isEmpty)
    }

    func testAttributeNameContextWithNoneTyped() {
        let result = query("<svg><circle ")
        XCTAssertEqual(result.context, .attributeName(element: "circle", existingAttributes: []))

        let candidates = SVGCompletionProvider.candidates(for: result)
        XCTAssertTrue(candidates.contains("cx"))
        XCTAssertTrue(candidates.contains("fill"))
    }

    func testAttributeNameContextExcludesAlreadyTyped() {
        let result = query("<circle cx=\"1\" cy=\"2\" c")
        guard case .attributeName(let element, let existing) = result.context else {
            return XCTFail("expected attributeName context")
        }
        XCTAssertEqual(element, "circle")
        XCTAssertEqual(existing, ["cx", "cy"])
        XCTAssertEqual(result.partialWord, "c")

        let candidates = SVGCompletionProvider.candidates(for: result)
        XCTAssertFalse(candidates.contains("cx"))
        XCTAssertFalse(candidates.contains("cy"))
        XCTAssertTrue(candidates.contains("class"))
    }

    func testAttributeValueContextWithEnum() {
        let result = query("<circle fill-rule=\"non")
        XCTAssertEqual(result.context, .attributeValue(element: "circle", attribute: "fill-rule"))
        XCTAssertEqual(result.partialWord, "non")
        XCTAssertEqual(SVGCompletionProvider.candidates(for: result), ["nonzero"])
    }

    func testAttributeValueContextWithNonEnumAttribute() {
        let result = query("<circle fill=\"")
        XCTAssertEqual(result.context, .attributeValue(element: "circle", attribute: "fill"))
        XCTAssertTrue(SVGCompletionProvider.candidates(for: result).isEmpty)
    }

    func testNoCompletionInPlainTextContent() {
        let result = query("<svg>Hello wor")
        XCTAssertEqual(result.context, .none)
        XCTAssertTrue(SVGCompletionProvider.candidates(for: result).isEmpty)
    }

    func testNoCompletionAtDocumentStart() {
        let result = query("Hello")
        XCTAssertEqual(result.context, .none)
    }

    func testClosingTagNameContext() {
        let result = query("<svg></cir")
        XCTAssertEqual(result.context, .tagName)
        XCTAssertEqual(result.partialWord, "cir")

        let candidates = SVGCompletionProvider.candidates(for: result)
        XCTAssertTrue(candidates.contains("circle"))
    }
}
