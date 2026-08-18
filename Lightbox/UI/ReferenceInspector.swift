import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ReferenceInspector: View {
    @ObservedObject var controller: ReferenceController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if controller.reference == nil {
                emptyState
            } else {
                content
            }
        }
        .padding(12)
        .frame(minWidth: 240, idealWidth: 260, maxWidth: 300)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No reference image")
                .foregroundStyle(.secondary)
            Button("Import Reference…", action: importViaPanel)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    @ViewBuilder
    private var content: some View {
        if controller.relinkNeeded {
            relinkBanner
        }

        Toggle("Visible", isOn: Binding(
            get: { controller.reference?.isVisible ?? true },
            set: { newValue in controller.update { $0.isVisible = newValue } }
        ))

        VStack(alignment: .leading) {
            Text("Opacity")
            Slider(
                value: Binding(
                    get: { controller.reference?.opacity ?? 0.5 },
                    set: { newValue in controller.update { $0.opacity = newValue } }
                ),
                in: 0...1
            )
        }

        VStack(alignment: .leading) {
            Text("Stacking")
            Picker("Stacking", selection: Binding(
                get: { controller.reference?.isOnTop ?? false },
                set: { newValue in controller.update { $0.isOnTop = newValue } }
            )) {
                Text("Behind").tag(false)
                Text("In Front").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }

        VStack(alignment: .leading) {
            Text("Position")
            HStack {
                TextField("X", value: Binding(
                    get: { controller.reference?.offsetX ?? 0 },
                    set: { newValue in controller.update { $0.offsetX = newValue } }
                ), format: .number)
                TextField("Y", value: Binding(
                    get: { controller.reference?.offsetY ?? 0 },
                    set: { newValue in controller.update { $0.offsetY = newValue } }
                ), format: .number)
            }
            .textFieldStyle(.roundedBorder)
        }

        VStack(alignment: .leading) {
            Text("Scale")
            HStack {
                TextField("Scale %", value: Binding(
                    get: { (controller.reference?.scale ?? 1) * 100 },
                    set: { newValue in controller.update { $0.scale = newValue / 100 } }
                ), format: .number)
                .textFieldStyle(.roundedBorder)
                Button("Fit to viewBox") {
                    controller.fitToViewBox()
                }
            }
        }

        VStack(alignment: .leading) {
            Text("Rotation")
            TextField("Degrees", value: Binding(
                get: { controller.reference?.rotation ?? 0 },
                set: { newValue in controller.update { $0.rotation = newValue } }
            ), format: .number)
            .textFieldStyle(.roundedBorder)
        }

        Toggle("Locked", isOn: Binding(
            get: { controller.reference?.isLocked ?? false },
            set: { newValue in controller.update { $0.isLocked = newValue } }
        ))

        Spacer()

        Button("Remove Reference", role: .destructive) {
            controller.removeReference()
        }
    }

    private var relinkBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reference image not found")
                .font(.callout.bold())
            Button("Relink…", action: relinkViaPanel)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
    }

    private func importViaPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            controller.importImage(from: url)
        }
    }

    private func relinkViaPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            controller.relink(to: url)
        }
    }
}
