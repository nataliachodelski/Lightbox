import XCTest
import AppKit
@testable import Lightbox

final class XMLHighlighterTests: XCTestCase {
    private func highlight(_ source: String) -> NSTextStorage {
        let textStorage = NSTextStorage(string: source)
        let highlighter = XMLHighlighter()
        highlighter.highlightAll(textStorage)
        return textStorage
    }

    private func color(at index: Int, in textStorage: NSTextStorage) -> NSColor? {
        textStorage.attribute(.foregroundColor, at: index, effectiveRange: nil) as? NSColor
    }

    func testTagNameIsColored() {
        let source = "<svg><circle r=\"1\"/></svg>"
        let textStorage = highlight(source)
        let circleIndex = (source as NSString).range(of: "circle").location
        XCTAssertEqual(color(at: circleIndex, in: textStorage), EditorTheme.tagName)
    }

    func testAttributeNameAndValueAreColored() {
        let source = "<circle id=\"1\"/>"
        let textStorage = highlight(source)
        let nameIndex = (source as NSString).range(of: "id=").location
        let valueIndex = (source as NSString).range(of: "\"1\"").location
        XCTAssertEqual(color(at: nameIndex, in: textStorage), EditorTheme.attributeName)
        XCTAssertEqual(color(at: valueIndex, in: textStorage), EditorTheme.attributeValue)
    }

    func testCommentIsColored() {
        let source = "<svg><!-- a comment --></svg>"
        let textStorage = highlight(source)
        let commentIndex = (source as NSString).range(of: "a comment").location
        XCTAssertEqual(color(at: commentIndex, in: textStorage), EditorTheme.comment)
    }

    func testCDATAIsColored() {
        let source = "<svg><![CDATA[ raw <not-a-tag> text ]]></svg>"
        let textStorage = highlight(source)
        let cdataIndex = (source as NSString).range(of: "raw").location
        XCTAssertEqual(color(at: cdataIndex, in: textStorage), EditorTheme.cdata)
    }

    func testEntityIsColored() {
        let source = "<text>Fish &amp; Chips</text>"
        let textStorage = highlight(source)
        let entityIndex = (source as NSString).range(of: "&amp;").location
        XCTAssertEqual(color(at: entityIndex, in: textStorage), EditorTheme.entity)
    }

    func testUnterminatedTagDoesNotCrash() {
        let source = "<svg><circle r=\"1\""
        _ = highlight(source)
    }

    func testUnterminatedCommentDoesNotCrash() {
        let source = "<svg><!-- never closed"
        _ = highlight(source)
    }

    func testUnterminatedCDATADoesNotCrash() {
        let source = "<svg><![CDATA[ never closed"
        _ = highlight(source)
    }

    func testEmptyDocumentDoesNotCrash() {
        _ = highlight("")
    }

    func testIncrementalReHighlightAfterEdit() {
        let textStorage = NSTextStorage(string: "<svg>\n<circle r=\"1\"/>\n</svg>")
        let highlighter = XMLHighlighter()
        textStorage.delegate = highlighter
        highlighter.highlightAll(textStorage)

        textStorage.replaceCharacters(in: NSRange(location: 6, length: 0), with: "<rect/>\n")

        let rectIndex = (textStorage.string as NSString).range(of: "rect").location
        XCTAssertEqual(color(at: rectIndex, in: textStorage), EditorTheme.tagName)
    }
}
