import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var svg: UTType {
        UTType(importedAs: "public.svg-image")
    }
}

struct SVGDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.svg] }
    static var writableContentTypes: [UTType] { [.svg] }

    var text: String

    init(text: String = DocumentTemplate.defaultContent) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
