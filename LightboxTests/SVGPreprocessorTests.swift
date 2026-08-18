import XCTest
@testable import Lightbox

final class SVGPreprocessorTests: XCTestCase {
    func testEmptyDocumentProducesNoError() throws {
        let result = SVGPreprocessor.preprocess("")
        let value = try result.get()
        XCTAssertEqual(value.text, "")
    }

    func testWellFormedSVGPassesThrough() throws {
        let source = "<svg xmlns=\"http://www.w3.org/2000/svg\"><circle cx=\"1\" cy=\"1\" r=\"1\"/></svg>"
        let result = SVGPreprocessor.preprocess(source)
        let value = try result.get()
        XCTAssertTrue(value.text.contains("<circle"))
    }

    func testPrologAndDoctypeAreStrippedForInjectionOnly() {
        let original = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>"
        let stripped = SVGPreprocessor.stripPrologAndDoctype(original)
        XCTAssertFalse(stripped.contains("<?xml"))
        XCTAssertFalse(stripped.contains("<!DOCTYPE"))
        XCTAssertTrue(stripped.contains("<svg"))

        XCTAssertTrue(original.contains("<?xml"))
        XCTAssertTrue(original.contains("<!DOCTYPE"))
    }

    func testFragmentWithoutRootSVGIsWrapped() throws {
        let fragment = "<circle cx=\"1\" cy=\"1\" r=\"1\"/>"
        let result = SVGPreprocessor.preprocess(fragment)
        let value = try result.get()
        XCTAssertTrue(value.text.hasPrefix("<svg"))
        XCTAssertTrue(value.text.contains(fragment))
    }

    func testScriptElementsAreStripped() throws {
        let source = "<svg xmlns=\"http://www.w3.org/2000/svg\"><script>alert('x')</script><circle cx=\"1\" cy=\"1\" r=\"1\"/></svg>"
        let result = SVGPreprocessor.preprocess(source)
        let value = try result.get()
        XCTAssertFalse(value.text.contains("<script"))
        XCTAssertTrue(value.didStripScript)
    }

    func testMalformedXMLProducesError() {
        let broken = "<svg xmlns=\"http://www.w3.org/2000/svg\"><circle cx=\"1\" cy=\"1\" r=\"1\"/>"
        let result = SVGPreprocessor.preprocess(broken)
        switch result {
        case .success:
            XCTFail("Expected a parse error for unclosed root element")
        case .failure(let error):
            XCTAssertFalse(error.message.isEmpty)
        }
    }
}
