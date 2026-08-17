import Combine
import WebKit

enum CanvasEvent {
    case ready
    case rendered(width: Double, height: Double)
    case error(String)
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

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "canvas", let body = message.body as? [String: Any], let type = body["type"] as? String else { return }

        switch type {
        case "rendered":
            let width = body["width"] as? Double ?? 0
            let height = body["height"] as? Double ?? 0
            events.send(.rendered(width: width, height: height))
        case "error":
            events.send(.error(body["message"] as? String ?? "Unknown render error"))
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
}

extension CanvasBridge: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        events.send(.ready)
    }
}
