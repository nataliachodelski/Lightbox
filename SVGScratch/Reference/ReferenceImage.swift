import Foundation

struct ReferenceImage: Codable, Equatable {
    var imageBookmark: Data
    var opacity: Double = 0.5
    var offsetX: Double = 0
    var offsetY: Double = 0
    var scale: Double = 1
    var rotation: Double = 0
    var isVisible: Bool = true
    var isOnTop: Bool = false
    var isLocked: Bool = false
    var pixelWidth: Double = 0
    var pixelHeight: Double = 0
}
