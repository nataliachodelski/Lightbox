import XCTest
@testable import SVGScratch

final class SVGDocumentTests: XCTestCase {
    func testDefaultContentIsNonEmpty() {
        let document = SVGDocument()
        XCTAssertFalse(document.text.isEmpty)
    }
}
