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

    private(set) var scale = CursorGrowth.restingScale
    private(set) var phase = Phase.idle
    private(set) var isCoveringScreen = false

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let monitor = MouseMotionMonitor()
    @ObservationIgnored private let ticker = DisplayTicker()
    @ObservationIgnored private let overlay = CursorOverlay()
    @ObservationIgnored private let cursorVisibility = SystemCursorVisibility()
    @ObservationIgnored private var detector = ShakeDetector()
    @ObservationIgnored private var growth = CursorGrowth()
    @ObservationIgnored private var session: Session?
    @ObservationIgnored private var pinnedScale: Double?

    private struct Session {
        var artwork: CursorArtwork
        var baseScale: CGFloat
        var lastTimestamp: CFTimeInterval
    }

    init(settings: AppSettings) {
        self.settings = settings
    }

    func start() {
        monitor.start { [weak self] motion in
            self?.handle(motion)
        }
    }

    func stop() {
        monitor.stop()
        endSession()
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
        overlay.screensChanged()
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
        guard session == nil, let artwork = CursorArtwork.current() else { return }
        session = Session(artwork: artwork, baseScale: SystemCursorSize.current(), lastTimestamp: CACurrentMediaTime())
        overlay.present(artwork)
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

        let pointer = NSEvent.mouseLocation
        let screenFrame = Self.screen(containing: pointer)?.frame ?? .zero
        let coverageScale = ScreenCoverage.scaleToCover(
            screenFrame,
            from: pointer,
            interiorRadius: session.artwork.interiorRadius(baseScale: session.baseScale)
        )
        let maximumScale = settings.sizeLimit.maximumScale(screenCoverageScale: coverageScale)
        let isShaking = detector.isShaking(at: CACurrentMediaTime())

        if let pinnedScale {
            growth.pin(at: pinnedScale)
        } else {
            growth.advance(by: elapsed, isShaking: isShaking, maximumScale: maximumScale)
        }

        if growth.isResting && !isShaking && pinnedScale == nil {
            endSession()
            return
        }

        let placement = session.artwork.placement(baseScale: session.baseScale)
        overlay.place(cursorFrame: placement.frame(pointer: pointer, scale: growth.scale, coverageScale: coverageScale))
        cursorVisibility.hide()
        publish(isShaking: isShaking || pinnedScale != nil, maximumScale: maximumScale, coverageScale: coverageScale)
    }

    private func publish(isShaking: Bool, maximumScale: Double, coverageScale: Double) {
        let atMaximum = growth.scale >= maximumScale * 0.999
        let nextPhase: Phase = isShaking ? (atMaximum ? .atMaximum : .growing) : .shrinking
        if phase != nextPhase { phase = nextPhase }
        let covering = growth.scale >= coverageScale * 0.999
        if isCoveringScreen != covering { isCoveringScreen = covering }
        if abs(scale - growth.scale) >= 0.01 || growth.scale == maximumScale { scale = growth.scale }
    }

    private func endSession() {
        ticker.stop()
        overlay.dismiss()
        cursorVisibility.show()
        detector.reset()
        growth.reset()
        session = nil
        scale = CursorGrowth.restingScale
        phase = .idle
        isCoveringScreen = false
    }

    private static func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
    }
}
