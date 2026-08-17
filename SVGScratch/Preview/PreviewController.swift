import Combine
import Foundation

final class PreviewController: ObservableObject {
    @Published var errorMessage: String?
    @Published var scriptWarning: String?
    @Published var zoomPercent: Int = 100
    @Published var background: CanvasBackground = .checkerboard

    let bridge = CanvasBridge()

    private let textSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var isReady = false
    private var latestText: String = ""
    private var hasWarnedAboutScript = false

    init() {
        textSubject
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] text in self?.render(text) }
            .store(in: &cancellables)

        bridge.events
            .receive(on: RunLoop.main)
            .sink { [weak self] event in self?.handle(event) }
            .store(in: &cancellables)
    }

    func textDidChange(_ text: String) {
        latestText = text
        textSubject.send(text)
    }

    func zoomIn() {
        bridge.zoomIn()
    }

    func zoomOut() {
        bridge.zoomOut()
    }

    func zoomActualSize() {
        bridge.zoomActualSize()
    }

    func zoomToFit() {
        bridge.zoomToFit()
    }

    func setZoom(percent: Int) {
        bridge.setZoomPercent(percent)
    }

    func setBackground(_ newBackground: CanvasBackground) {
        background = newBackground
        bridge.setBackground(newBackground)
    }

    private func handle(_ event: CanvasEvent) {
        switch event {
        case .ready:
            isReady = true
            bridge.setBackground(background)
            render(latestText)
        case .rendered:
            errorMessage = nil
        case .error(let message):
            errorMessage = message
        case .zoomChanged(let percent):
            zoomPercent = percent
        case .referenceMoved:
            break
        }
    }

    private func render(_ text: String) {
        guard isReady else { return }

        switch SVGPreprocessor.preprocess(text) {
        case .success(let result):
            bridge.setSource(result.text)
            if result.didStripScript && !hasWarnedAboutScript {
                hasWarnedAboutScript = true
                scriptWarning = "This SVG contained <script> elements, which were removed for safety."
            }
        case .failure(let error):
            errorMessage = error.message
        }
    }
}
