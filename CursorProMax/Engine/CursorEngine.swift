import AppKit
import Observation
import QuartzCore

@Observable
@MainActor
final class CursorEngine {
    enum Phase: Sendable, Equatable {
        case idle
        case growing
        case atMaximum
        case shrinking
    }

    static let largestCursorScale = WindowServer.cursorScaleRange.upperBound
    static let settleRate = 8.0
    static let reducedMotionSettleRate = 40.0

    private(set) var scale = CursorGrowth.restingScale
    private(set) var phase = Phase.idle
    private(set) var largestGrowth = CursorGrowth.restingScale

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let monitor = MouseMotionMonitor()
    @ObservationIgnored private let ticker = DisplayTicker()
    @ObservationIgnored private let presenter = CursorPresenter()
    @ObservationIgnored private let safety = CursorSafetyNet()
    @ObservationIgnored private let upgrader = SystemCursorUpgrader()
    @ObservationIgnored private var detector = ShakeDetector()
    @ObservationIgnored private var growth = CursorGrowth()
    @ObservationIgnored private var session: Session?
    @ObservationIgnored private var pinnedScale: Double?

    private struct Session {
        let baseScale: Double
        var lastTimestamp: CFTimeInterval
    }

    init(settings: AppSettings) {
        self.settings = settings
    }

    func start() {
        safety.recoverFromPreviousRun()
        safety.suppressShakeToLocate()
        upgrader.upgrade()
        refreshLargestGrowth()
        monitor.start { [weak self] motion in
            self?.handle(motion)
        }
    }

    func stop() {
        monitor.stop()
        endSession(synchronously: true)
        upgrader.restore()
        NSCursor.arrow.set()
        safety.restoreShakeToLocate()
    }

    func pin(scale: Double) {
        pinnedScale = max(scale, CursorGrowth.restingScale)
        beginSessionIfNeeded()
    }

    func restoreSystemCursor() {
        pinnedScale = nil
        endSession()
    }

    func screensChanged() {
        let wasPinned = pinnedScale
        endSession()
        if let wasPinned {
            pin(scale: wasPinned)
        }
    }

    private func handle(_ motion: MouseMotion) {
        if detector.sensitivity != settings.shakeSensitivity {
            detector.sensitivity = settings.shakeSensitivity
        }
        detector.register(motion)
        if detector.isShaking(at: motion.timestamp) {
            beginSessionIfNeeded()
        }
    }

    private func beginSessionIfNeeded() {
        guard session == nil, let baseScale = WindowServer.cursorScale() else { return }
        session = Session(baseScale: baseScale, lastTimestamp: CACurrentMediaTime())
        if !settings.hasSeenWelcome {
            settings.hasSeenWelcome = true
        }
        upgrader.refresh()
        largestGrowth = Self.largestCursorScale / baseScale
        safety.sessionBegan(baseScale: baseScale)
        ticker.start(on: Self.screen(containing: NSEvent.mouseLocation)) { [weak self] timestamp in
            self?.tick(at: timestamp)
        }
        tick(at: CACurrentMediaTime())
    }

    private func tick(at timestamp: CFTimeInterval) {
        guard var session else { return }
        let elapsed = min(max(timestamp - session.lastTimestamp, 0), 1.0 / 20)
        session.lastTimestamp = timestamp
        self.session = session
        let isShaking = detector.isShaking(at: CACurrentMediaTime())
        let maximumGrowth = settings.sizeLimit.maximumScale(largestGrowth: largestGrowth)
        growth.doublingTime = settings.growthSpeed.doublingTime
        growth.settleRate = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? Self.reducedMotionSettleRate : Self.settleRate

        if let pinnedScale {
            growth.pin(at: min(pinnedScale, maximumGrowth))
        } else {
            growth.advance(by: elapsed, isShaking: isShaking, maximumScale: maximumGrowth)
        }

        if growth.isResting && !isShaking && pinnedScale == nil {
            endSession()
            return
        }

        presenter.present(scale: session.baseScale * growth.scale)
        publish(isShaking: isShaking || pinnedScale != nil, maximumGrowth: maximumGrowth)
    }

    private func publish(isShaking: Bool, maximumGrowth: Double) {
        let atMaximum = growth.scale >= maximumGrowth * 0.999
        let nextPhase: Phase = isShaking ? (atMaximum ? .atMaximum : .growing) : .shrinking
        if phase != nextPhase { phase = nextPhase }
        if abs(scale - growth.scale) >= 0.01 || growth.scale == maximumGrowth { scale = growth.scale }
    }

    private func refreshLargestGrowth() {
        if let baseScale = WindowServer.cursorScale() {
            largestGrowth = Self.largestCursorScale / baseScale
        }
    }

    private func endSession(synchronously: Bool = false) {
        ticker.stop()
        if let session {
            presenter.restore(scale: session.baseScale, synchronously: synchronously)
            safety.sessionEnded()
        }
        detector.reset()
        growth.reset()
        session = nil
        scale = CursorGrowth.restingScale
        phase = .idle
    }

    private static func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
    }
}
