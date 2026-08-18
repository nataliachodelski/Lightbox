import XCTest
@testable import Lightbox

final class ReferenceStoreTests: XCTestCase {
    func testSaveAndLoadRoundTrip() throws {
        let documentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReferenceStoreTests-\(UUID().uuidString).svg")
        try "<svg></svg>".write(to: documentURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: documentURL) }

        let reference = ReferenceImage(
            imageBookmark: Data([1, 2, 3, 4]),
            opacity: 0.75,
            offsetX: 12,
            offsetY: -8,
            scale: 1.5,
            rotation: 45,
            isVisible: true,
            isOnTop: true,
            isLocked: false,
            pixelWidth: 800,
            pixelHeight: 600
        )

        ReferenceStore.shared.setReference(reference, for: documentURL)
        defer { ReferenceStore.shared.setReference(nil, for: documentURL) }

        let loaded = ReferenceStore.shared.reference(for: documentURL)
        XCTAssertEqual(loaded, reference)
    }

    func testRemovingReferenceClearsIt() throws {
        let documentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReferenceStoreTests-\(UUID().uuidString).svg")
        try "<svg></svg>".write(to: documentURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: documentURL) }

        let reference = ReferenceImage(imageBookmark: Data([1, 2, 3]))
        ReferenceStore.shared.setReference(reference, for: documentURL)
        ReferenceStore.shared.setReference(nil, for: documentURL)

        XCTAssertNil(ReferenceStore.shared.reference(for: documentURL))
    }

    func testUnknownDocumentHasNoReference() {
        let documentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("never-saved-\(UUID().uuidString).svg")
        XCTAssertNil(ReferenceStore.shared.reference(for: documentURL))
    }
}
