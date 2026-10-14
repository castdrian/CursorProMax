import AppKit
import QuartzCore

@MainActor
final class MouseMotionMonitor {
    private static let observedEvents: NSEvent.EventTypeMask = [
        .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
    ]

    private var monitors: [Any] = []

    func start(onMotion: @escaping @MainActor (MouseMotion) -> Void) {
        guard monitors.isEmpty else { return }
        let global = NSEvent.addGlobalMonitorForEvents(matching: Self.observedEvents) { event in
            let motion = Self.motion(from: event)
            MainActor.assumeIsolated { onMotion(motion) }
        }
        let local = NSEvent.addLocalMonitorForEvents(matching: Self.observedEvents) { event in
            let motion = Self.motion(from: event)
            MainActor.assumeIsolated { onMotion(motion) }
            return event
        }
        monitors = [global, local].compactMap { $0 }
    }

    func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
    }

    private nonisolated static func motion(from event: NSEvent) -> MouseMotion {
        MouseMotion(deltaX: event.deltaX, deltaY: event.deltaY, timestamp: CACurrentMediaTime())
    }
}
