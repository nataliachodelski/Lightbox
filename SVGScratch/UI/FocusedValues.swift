import SwiftUI

private struct PreviewControllerKey: FocusedValueKey {
    typealias Value = PreviewController
}

extension FocusedValues {
    var previewController: PreviewController? {
        get { self[PreviewControllerKey.self] }
        set { self[PreviewControllerKey.self] = newValue }
    }
}
