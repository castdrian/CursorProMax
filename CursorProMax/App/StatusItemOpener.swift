import AppKit

@MainActor
enum StatusItemOpener {
    private static let statusItemSelector = NSSelectorFromString("_statusItem")
    private static let expandSelector = NSSelectorFromString("_requestExpandedInterfaceSession")

    static func openMenuBarExtra() {
        guard let button = NSApp.windows.lazy.compactMap({ $0.contentView.flatMap(statusBarButton(in:)) }).first else { return }
        guard button.responds(to: statusItemSelector),
              let statusItem = button.perform(statusItemSelector)?.takeUnretainedValue() as? NSStatusItem,
              statusItem.responds(to: expandSelector)
        else {
            button.performClick(nil)
            return
        }
        statusItem.perform(expandSelector)
    }

    private static func statusBarButton(in view: NSView) -> NSStatusBarButton? {
        if let button = view as? NSStatusBarButton {
            return button
        }
        return view.subviews.lazy.compactMap(statusBarButton(in:)).first
    }
}
