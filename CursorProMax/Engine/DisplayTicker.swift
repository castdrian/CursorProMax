import AppKit
import QuartzCore

@MainActor
final class DisplayTicker: NSObject {
    private var displayLink: CADisplayLink?
    private var onTick: (@MainActor (CFTimeInterval) -> Void)?

    var isRunning: Bool { displayLink != nil }

    func start(on screen: NSScreen?, onTick: @escaping @MainActor (CFTimeInterval) -> Void) {
        stop()
        guard let screen = screen ?? NSScreen.main else { return }
        self.onTick = onTick
        let link = screen.displayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        onTick = nil
    }

    @objc private func step(_ link: CADisplayLink) {
        onTick?(link.targetTimestamp)
    }
}
