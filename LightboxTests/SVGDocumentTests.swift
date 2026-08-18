import XCTest
@testable import Lightbox

final class SVGDocumentTests: XCTestCase {
    func testDefaultContentIsNonEmpty() {
        let document = SVGDocument()
        XCTAssertFalse(document.text.isEmpty)
    }

    func testSavedDocumentNeverContainsReferenceImageData() throws {
        let document = SVGDocument(text: "<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>")

        let savedData = Data(document.text.utf8)
        let savedText = String(decoding: savedData, as: UTF8.self)

        XCTAssertEqual(savedText, document.text)
        XCTAssertFalse(savedText.contains("data:image"))
    }
}
