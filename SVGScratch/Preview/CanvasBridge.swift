import AppKit
import Combine
import WebKit

enum CanvasEvent {
    case ready
    case rendered(width: Double, height: Double)
    case error(String)
    case zoomChanged(percent: Int)
}

enum CanvasBackground: Equatable {
    case checkerboard
    case white
    case black
    case custom(NSColor)
}

final class CanvasBridge: NSObject, WKScriptMessageHandler {
    let events = PassthroughSubject<CanvasEvent, Never>()

    private weak var webView: WKWebView?

    func attach(to webView: WKWebView) {
        self.webView = webView
    }

    func setSource(_ svgText: String) {
        guard let webView else { return }
        webView.evaluateJavaScript("window.setSource(\(jsString(svgText)));")
    }

    func zoomIn() {
        webView?.evaluateJavaScript("window.zoomIn();")
    }

    func zoomOut() {
        webView?.evaluateJavaScript("window.zoomOut();")
    }

    func zoomActualSize() {
        webView?.evaluateJavaScript("window.zoomActualSize();")
    }

    func zoomToFit() {
        webView?.evaluateJavaScript("window.zoomToFit();")
    }

    func setZoomPercent(_ percent: Int) {
        webView?.evaluateJavaScript("window.setZoomPercent(\(percent));")
    }

    func setBackground(_ background: CanvasBackground) {
        let mode: String
        switch background {
        case .checkerboard: mode = "checkerboard"
        case .white: mode = "white"
        case .black: mode = "black"
        case .custom(let color): mode = cssColor(color)
        }
        webView?.evaluateJavaScript("window.setBackground(\(jsString(mode)));")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "canvas", let body = message.body as? [String: Any], let type = body["type"] as? String else { return }

        switch type {
        case "rendered":
            let width = body["width"] as? Double ?? 0
            let height = body["height"] as? Double ?? 0
            events.send(.rendered(width: width, height: height))
        case "error":
            events.send(.error(body["message"] as? String ?? "Unknown render error"))
        case "zoomChanged":
            events.send(.zoomChanged(percent: body["percent"] as? Int ?? 100))
        default:
            break
        }
    }

    private func jsString(_ text: String) -> String {
        guard let data = try? JSONEncoder().encode(text), let json = String(data: data, encoding: .utf8) else {
            return "\"\""
        }
        return json
    }

    private func cssColor(_ color: NSColor) -> String {
        guard let rgb = color.usingColorSpace(.deviceRGB) else { return "#ffffff" }
        return String(
            format: "rgba(%d, %d, %d, %.3f)",
            Int(rgb.redComponent * 255),
            Int(rgb.greenComponent * 255),
            Int(rgb.blueComponent * 255),
            rgb.alphaComponent
        )
    }
}

extension CanvasBridge: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        events.send(.ready)
    }
}
