import Combine
import Foundation

final class ReferenceController: ObservableObject {
    @Published var reference: ReferenceImage?
    @Published var isInspectorVisible = false
    @Published var relinkNeeded = false

    private let bridge: CanvasBridge
    private var documentURL: URL?
    private var dataURI: String?
    private var isReady = false
    private var hasLoadedInitialState = false
    private var cancellables = Set<AnyCancellable>()

    init(bridge: CanvasBridge) {
        self.bridge = bridge

        bridge.events
            .receive(on: RunLoop.main)
            .sink { [weak self] event in self?.handle(event) }
            .store(in: &cancellables)
    }

    func loadForDocument(at url: URL?) {
        guard !hasLoadedInitialState else { return }
        hasLoadedInitialState = true
        documentURL = url

        guard let url, let stored = ReferenceStore.shared.reference(for: url) else { return }

        reference = stored
        if let result = ReferenceImporter.reimport(fromBookmark: stored.imageBookmark) {
            dataURI = result.dataURI
        } else {
            relinkNeeded = true
        }
        pushToCanvas()
    }

    func documentURLDidChange(_ newURL: URL?) {
        guard let newURL, newURL != documentURL else { return }
        let previousURL = documentURL
        documentURL = newURL
        if let previousURL, previousURL != newURL {
            ReferenceStore.shared.setReference(nil, for: previousURL)
        }
        persist()
    }

    func importImage(from url: URL) {
        guard let result = ReferenceImporter.importImage(at: url) else { return }
        applyImportedReference(result)
    }

    func applyImportedReference(_ result: ReferenceImporter.ImportResult) {
        let previousBookmark = reference?.imageBookmark

        var newReference = ReferenceImage(imageBookmark: result.bookmark)
        newReference.pixelWidth = result.pixelWidth
        newReference.pixelHeight = result.pixelHeight
        reference = newReference
        dataURI = result.dataURI
        relinkNeeded = false
        persist()
        pushToCanvas()

        if let previousBookmark {
            ReferenceImporter.deleteStoredCopy(bookmark: previousBookmark)
        }
    }

    func relink(to url: URL) {
        guard let result = ReferenceImporter.importImage(at: url) else { return }
        let previousBookmark = reference?.imageBookmark

        dataURI = result.dataURI
        relinkNeeded = false
        update { current in
            current.imageBookmark = result.bookmark
            current.pixelWidth = result.pixelWidth
            current.pixelHeight = result.pixelHeight
        }

        if let previousBookmark {
            ReferenceImporter.deleteStoredCopy(bookmark: previousBookmark)
        }
    }

    func removeReference() {
        let previousBookmark = reference?.imageBookmark
        reference = nil
        dataURI = nil
        relinkNeeded = false
        persist()
        pushToCanvas()

        if let previousBookmark {
            ReferenceImporter.deleteStoredCopy(bookmark: previousBookmark)
        }
    }

    func update(_ mutate: (inout ReferenceImage) -> Void) {
        guard var current = reference else { return }
        mutate(&current)
        reference = current
        persist()
        pushToCanvas()
    }

    func toggleVisibility() {
        update { $0.isVisible.toggle() }
    }

    func nudge(dx: Double, dy: Double) {
        update {
            $0.offsetX += dx
            $0.offsetY += dy
        }
    }

    func fitToViewBox() {
        update { $0.scale = 1 }
    }

    private func handle(_ event: CanvasEvent) {
        switch event {
        case .ready:
            isReady = true
            pushToCanvas()
        case .referenceMoved(let x, let y):
            reference?.offsetX = x
            reference?.offsetY = y
            persist()
        default:
            break
        }
    }

    private func persist() {
        guard let documentURL else { return }
        ReferenceStore.shared.setReference(reference, for: documentURL)
    }

    private func pushToCanvas() {
        guard isReady else { return }
        bridge.setReference(reference, dataURI: dataURI)
    }
}
