import AppKit

final class CompletionPopup: NSObject {
    private let panel: NSPanel
    private let scrollView: NSScrollView
    private let tableView: NSTableView
    private var items: [String] = []

    var onAccept: ((String) -> Void)?

    var isVisible: Bool { panel.isVisible }

    override init() {
        tableView = NSTableView()
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        column.width = 200
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.rowHeight = 20
        tableView.backgroundColor = .clear
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.style = .plain
        tableView.usesAutomaticRowHeights = false

        scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 140),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false

        let effectView = NSVisualEffectView()
        effectView.material = .popover
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 6
        effectView.layer?.masksToBounds = true
        panel.contentView = effectView

        super.init()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.action = #selector(rowClicked)

        effectView.addSubview(scrollView)
    }

    func show(items: [String], at screenTopLeft: NSPoint, parent: NSWindow) {
        self.items = items
        tableView.reloadData()
        selectFirstRow()

        resizePanel()
        panel.setFrameTopLeftPoint(screenTopLeft)

        if panel.parent !== parent {
            parent.addChildWindow(panel, ordered: .above)
        }
        panel.orderFront(nil)
    }

    func updateItems(_ items: [String]) {
        self.items = items
        tableView.reloadData()
        selectFirstRow()

        let topLeft = NSPoint(x: panel.frame.minX, y: panel.frame.maxY)
        resizePanel()
        panel.setFrameTopLeftPoint(topLeft)
    }

    func hide() {
        guard panel.isVisible else { return }
        panel.parent?.removeChildWindow(panel)
        panel.orderOut(nil)
    }

    func moveSelection(by delta: Int) {
        guard !items.isEmpty else { return }
        let current = tableView.selectedRow == -1 ? 0 : tableView.selectedRow
        let next = max(0, min(items.count - 1, current + delta))
        tableView.selectRowIndexes(IndexSet(integer: next), byExtendingSelection: false)
        tableView.scrollRowToVisible(next)
    }

    var selectedItem: String? {
        if tableView.selectedRow >= 0, tableView.selectedRow < items.count {
            return items[tableView.selectedRow]
        }
        return items.first
    }

    private func selectFirstRow() {
        guard !items.isEmpty else { return }
        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }

    private func resizePanel() {
        let rowCount = min(max(items.count, 1), 8)
        let height = CGFloat(rowCount) * tableView.rowHeight + 8
        panel.setContentSize(NSSize(width: 220, height: height))
        scrollView.frame = panel.contentView?.bounds ?? .zero
    }

    @objc private func rowClicked() {
        guard tableView.clickedRow >= 0, tableView.clickedRow < items.count else { return }
        onAccept?(items[tableView.clickedRow])
    }
}

extension CompletionPopup: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("cell")
        let cell: NSTextField
        if let reused = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTextField {
            cell = reused
        } else {
            cell = NSTextField(labelWithString: "")
            cell.identifier = identifier
            cell.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        }
        cell.stringValue = items[row]
        return cell
    }
}
