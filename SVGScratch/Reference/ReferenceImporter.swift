import AppKit
import ImageIO
import UniformTypeIdentifiers

enum ReferenceImporter {
    struct ImportResult {
        let dataURI: String
        let pixelWidth: Double
        let pixelHeight: Double
        let bookmark: Data
    }

    static func importImage(at url: URL) -> ImportResult? {
        guard let cgImage = loadDownsampledImage(source: CGImageSourceCreateWithURL(url as CFURL, nil)) else {
            return nil
        }
        return finishImport(cgImage)
    }

    static func importImage(data: Data) -> ImportResult? {
        guard let cgImage = loadDownsampledImage(source: CGImageSourceCreateWithData(data as CFData, nil)) else {
            return nil
        }
        return finishImport(cgImage)
    }

    static func reimport(fromBookmark bookmark: Data) -> ImportResult? {
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            return nil
        }
        guard let pngData = try? Data(contentsOf: url) else { return nil }
        guard let source = CGImageSourceCreateWithData(pngData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else {
            return nil
        }

        let dataURI = "data:image/png;base64,\(pngData.base64EncodedString())"
        return ImportResult(dataURI: dataURI, pixelWidth: Double(width), pixelHeight: Double(height), bookmark: bookmark)
    }

    static func deleteStoredCopy(bookmark: Data) {
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            return
        }
        try? FileManager.default.removeItem(at: url)
    }

    private static func loadDownsampledImage(source: CGImageSource?) -> CGImage? {
        guard let source else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }

        let originalWidth = (properties[kCGImagePropertyPixelWidth] as? Int) ?? 0
        let originalHeight = (properties[kCGImagePropertyPixelHeight] as? Int) ?? 0
        let longestEdge = max(originalWidth, originalHeight)
        guard longestEdge > 0 else { return nil }

        let maxDimension = 4096
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: min(longestEdge, maxDimension),
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]

        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    private static func finishImport(_ cgImage: CGImage) -> ImportResult? {
        guard let pngData = encodePNG(cgImage) else { return nil }
        guard let storedURL = try? storeCopy(of: pngData) else { return nil }
        guard let bookmark = try? storedURL.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) else {
            return nil
        }

        let dataURI = "data:image/png;base64,\(pngData.base64EncodedString())"
        return ImportResult(
            dataURI: dataURI,
            pixelWidth: Double(cgImage.width),
            pixelHeight: Double(cgImage.height),
            bookmark: bookmark
        )
    }

    private static func storeCopy(of data: Data) throws -> URL {
        let directory = try referenceImagesDirectory()
        let fileURL = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private static func referenceImagesDirectory() throws -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("SVGScratch/ReferenceImages", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func encodePNG(_ cgImage: CGImage) -> Data? {
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}
