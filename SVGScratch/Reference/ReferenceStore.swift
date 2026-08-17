import Foundation

final class ReferenceStore {
    static let shared = ReferenceStore()

    private struct Entry: Codable {
        var documentBookmark: Data
        var reference: ReferenceImage
    }

    private let fileURL: URL
    private var entries: [Entry] = []

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("SVGScratch", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("references.json")
        load()
    }

    func reference(for documentURL: URL) -> ReferenceImage? {
        entries.first { matches($0, documentURL) }?.reference
    }

    func setReference(_ reference: ReferenceImage?, for documentURL: URL) {
        entries.removeAll { matches($0, documentURL) }

        if let reference, let bookmark = try? documentURL.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) {
            entries.append(Entry(documentBookmark: bookmark, reference: reference))
        }

        save()
    }

    private func matches(_ entry: Entry, _ documentURL: URL) -> Bool {
        var isStale = false
        guard let resolved = try? URL(
            resolvingBookmarkData: entry.documentBookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return false
        }
        return resolved.standardizedFileURL.path == documentURL.standardizedFileURL.path
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        entries = (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
