import AppKit

enum EditorTheme {
    static let plainText = NSColor.labelColor
    static let tagName = dynamic(
        light: NSColor(red: 0.16, green: 0.32, blue: 0.75, alpha: 1),
        dark: NSColor(red: 0.45, green: 0.62, blue: 1.0, alpha: 1)
    )
    static let attributeName = dynamic(
        light: NSColor(red: 0.55, green: 0.1, blue: 0.5, alpha: 1),
        dark: NSColor(red: 0.85, green: 0.55, blue: 0.95, alpha: 1)
    )
    static let attributeValue = dynamic(
        light: NSColor(red: 0.65, green: 0.1, blue: 0.1, alpha: 1),
        dark: NSColor(red: 0.98, green: 0.55, blue: 0.5, alpha: 1)
    )
    static let comment = dynamic(
        light: NSColor(red: 0.35, green: 0.45, blue: 0.35, alpha: 1),
        dark: NSColor(red: 0.5, green: 0.65, blue: 0.5, alpha: 1)
    )
    static let cdata = dynamic(
        light: NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1),
        dark: NSColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1)
    )
    static let entity = dynamic(
        light: NSColor(red: 0.7, green: 0.4, blue: 0.0, alpha: 1),
        dark: NSColor(red: 0.95, green: 0.65, blue: 0.3, alpha: 1)
    )

    static let lineNumber = NSColor.tertiaryLabelColor
    static let gutterBackground = NSColor.controlBackgroundColor

    private static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }
}
