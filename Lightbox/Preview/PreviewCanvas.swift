import SwiftUI
import WebKit

struct PreviewCanvas: NSViewRepresentable {
    let bridge: CanvasBridge

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(bridge, name: "canvas")
        configuration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = bridge
        bridge.attach(to: webView)

        if let htmlURL = Bundle.main.url(forResource: "canvas", withExtension: "html") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
    }
}
