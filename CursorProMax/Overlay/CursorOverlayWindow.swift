import AppKit
import QuartzCore

final class CursorOverlayWindow: NSPanel {
    let cursorLayer = CALayer()
    let screenFrame: CGRect

    init(screen: NSScreen) {
        screenFrame = screen.frame
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configureWindow()
        installHostView(backingScale: screen.backingScaleFactor)
        setFrame(screen.frame, display: false)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func place(cursorFrame globalFrame: CGRect) {
        cursorLayer.frame = globalFrame.offsetBy(dx: -screenFrame.minX, dy: -screenFrame.minY)
    }

    private func configureWindow() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        animationBehavior = .none
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.cursorWindow)))
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    private func installHostView(backingScale: CGFloat) {
        let hostView = NSView(frame: CGRect(origin: .zero, size: screenFrame.size))
        hostView.wantsLayer = true
        cursorLayer.contentsGravity = .resize
        cursorLayer.contentsScale = backingScale
        cursorLayer.magnificationFilter = .linear
        cursorLayer.minificationFilter = .trilinear
        cursorLayer.actions = ["position": NSNull(), "bounds": NSNull(), "contents": NSNull(), "hidden": NSNull()]
        hostView.layer?.addSublayer(cursorLayer)
        contentView = hostView
    }
}
