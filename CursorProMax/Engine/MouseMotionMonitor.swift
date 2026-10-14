import AppKit
import QuartzCore

final class MouseMotionMonitor: @unchecked Sendable {
    private static let observedEvents: [CGEventType] = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
    private static let fallbackEvents: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]

    private var onMotion: (@MainActor (MouseMotion) -> Void)?
    private var tap: CFMachPort?
    private var tapRunLoop: CFRunLoop?
    private var fallbackMonitors: [Any] = []

    @MainActor
    func start(onMotion: @escaping @MainActor (MouseMotion) -> Void) {
        guard self.onMotion == nil else { return }
        self.onMotion = onMotion
        if !(CGPreflightListenEventAccess() && startEventTap()) {
            startFallbackMonitors()
        }
    }

    @MainActor
    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let tapRunLoop {
            CFRunLoopStop(tapRunLoop)
        }
        tap = nil
        tapRunLoop = nil
        fallbackMonitors.forEach(NSEvent.removeMonitor)
        fallbackMonitors.removeAll()
        onMotion = nil
    }

    @MainActor
    private func startEventTap() -> Bool {
        let mask = Self.observedEvents.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                if let userInfo {
                    Unmanaged<MouseMotionMonitor>.fromOpaque(userInfo).takeUnretainedValue().handle(type: type, event: event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }
        self.tap = tap
        let port = MachPortReference(port: tap)
        let thread = Thread { [weak self] in
            let tap = port.port
            guard let source = CFMachPortCreateRunLoopSource(nil, tap, 0) else { return }
            let runLoop = CFRunLoopGetCurrent()
            self?.tapRunLoop = runLoop
            CFRunLoopAddSource(runLoop, source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
        thread.name = "dev.adrian.cursorpromax.mouse"
        thread.qualityOfService = .userInteractive
        thread.start()
        return true
    }

    @MainActor
    private func startFallbackMonitors() {
        let global = NSEvent.addGlobalMonitorForEvents(matching: Self.fallbackEvents) { [weak self] event in
            self?.deliver(Self.motion(from: event))
        }
        let local = NSEvent.addLocalMonitorForEvents(matching: Self.fallbackEvents) { [weak self] event in
            self?.deliver(Self.motion(from: event))
            return event
        }
        fallbackMonitors = [global, local].compactMap { $0 }
    }

    private func handle(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        let motion = MouseMotion(
            deltaX: Double(event.getIntegerValueField(.mouseEventDeltaX)),
            deltaY: Double(event.getIntegerValueField(.mouseEventDeltaY)),
            timestamp: Self.timestamp(of: event)
        )
        deliver(motion)
    }

    private func deliver(_ motion: MouseMotion) {
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated {
                self?.onMotion?(motion)
            }
        }
    }

    private static func timestamp(of event: CGEvent) -> TimeInterval {
        let now = CACurrentMediaTime()
        let seconds = Double(event.timestamp) / 1_000_000_000
        return abs(seconds - now) < 1 ? seconds : now
    }

    private static func motion(from event: NSEvent) -> MouseMotion {
        let now = CACurrentMediaTime()
        let timestamp = abs(event.timestamp - now) < 1 ? event.timestamp : now
        return MouseMotion(deltaX: event.deltaX, deltaY: event.deltaY, timestamp: timestamp)
    }
}

private struct MachPortReference: @unchecked Sendable {
    let port: CFMachPort
}
