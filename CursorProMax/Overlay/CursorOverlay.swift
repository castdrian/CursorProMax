import AppKit
import QuartzCore

@MainActor
final class CursorOverlay {
    private var windows: [CursorOverlayWindow] = []
    private var isPresented = false

    func present(_ artwork: CursorArtwork) {
        if windows.isEmpty {
            rebuildWindows()
        }
        withoutAnimation {
            windows.forEach { $0.cursorLayer.contents = artwork.image }
        }
        windows.forEach { $0.orderFrontRegardless() }
        isPresented = true
    }

    func place(cursorFrame: CGRect) {
        guard isPresented else { return }
        withoutAnimation {
            windows.forEach { $0.place(cursorFrame: cursorFrame) }
        }
    }

    func dismiss() {
        windows.forEach { $0.orderOut(nil) }
        isPresented = false
    }

    func screensChanged() {
        dismiss()
        windows.forEach { $0.close() }
        windows.removeAll()
    }

    private func rebuildWindows() {
        windows = NSScreen.screens.map(CursorOverlayWindow.init(screen:))
    }

    private func withoutAnimation(_ changes: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        changes()
        CATransaction.commit()
    }
}
