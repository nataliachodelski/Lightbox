import SwiftUI

private struct PreviewControllerKey: FocusedValueKey {
    typealias Value = PreviewController
}

private struct ReferenceControllerKey: FocusedValueKey {
    typealias Value = ReferenceController
}

extension FocusedValues {
    var previewController: PreviewController? {
        get { self[PreviewControllerKey.self] }
        set { self[PreviewControllerKey.self] = newValue }
    }

    var referenceController: ReferenceController? {
        get { self[ReferenceControllerKey.self] }
        set { self[ReferenceControllerKey.self] = newValue }
    }
}
