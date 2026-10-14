import Foundation

struct ShakeDetector: Sendable {
    struct Configuration: Sendable, Equatable {
        var minimumStrokeDistance: Double
        var minimumStrokeSpeed: Double
        var reversalsToBeginShake: Int
        var reversalWindow: TimeInterval
        var quietTimeout: TimeInterval
        var reversalTolerance: Double
        var maximumVerticalRatio: Double

        init(sensitivity: ShakeSensitivity) {
            minimumStrokeDistance = sensitivity.interpolated(from: 90, to: 20)
            minimumStrokeSpeed = sensitivity.interpolated(from: 1800, to: 450)
            reversalsToBeginShake = Int((4 - 2 * sensitivity.value).rounded())
            reversalWindow = 1.0
            quietTimeout = 0.4
            reversalTolerance = 6
            maximumVerticalRatio = 1.2
        }
    }

    private struct Stroke: Sendable {
        var direction: Double
        var startX: Double
        var startTime: TimeInterval
        var extremeX: Double
        var extremeTime: TimeInterval
        var verticalTravel: Double

        var distance: Double { abs(extremeX - startX) }

        var speed: Double {
            distance / max(extremeTime - startTime, 0.001)
        }

        func hasReversed(at position: Double, tolerance: Double) -> Bool {
            (extremeX - position) * direction > tolerance
        }

        func extends(to position: Double) -> Bool {
            (position - extremeX) * direction > 0
        }
    }

    var sensitivity: ShakeSensitivity {
        didSet { configuration = Configuration(sensitivity: sensitivity) }
    }
    private(set) var configuration: Configuration
    private var horizontalPosition: Double = 0
    private var previousTimestamp: TimeInterval?
    private var stroke: Stroke?
    private var recentReversals: [TimeInterval] = []
    private var lastQualifyingReversal: TimeInterval?
    private var isEngaged = false

    init(sensitivity: ShakeSensitivity = .standard) {
        self.sensitivity = sensitivity
        configuration = Configuration(sensitivity: sensitivity)
    }

    func isShaking(at time: TimeInterval) -> Bool {
        guard isEngaged, let lastQualifyingReversal else { return false }
        return time - lastQualifyingReversal <= configuration.quietTimeout
    }

    mutating func register(_ motion: MouseMotion) {
        disengageIfQuiet(at: motion.timestamp)
        let strokeStartTime = previousTimestamp ?? motion.timestamp
        previousTimestamp = motion.timestamp
        horizontalPosition += motion.deltaX
        let verticalStep = abs(motion.deltaY)

        guard var current = stroke else {
            beginFirstStroke(motion: motion, startTime: strokeStartTime)
            return
        }

        current.verticalTravel += verticalStep
        if current.extends(to: horizontalPosition) {
            current.extremeX = horizontalPosition
            current.extremeTime = motion.timestamp
            stroke = current
        } else if current.hasReversed(at: horizontalPosition, tolerance: configuration.reversalTolerance) {
            if qualifies(current) {
                recordReversal(at: motion.timestamp)
            }
            stroke = Stroke(
                direction: -current.direction,
                startX: current.extremeX,
                startTime: current.extremeTime,
                extremeX: horizontalPosition,
                extremeTime: motion.timestamp,
                verticalTravel: verticalStep
            )
        } else {
            stroke = current
        }
    }

    mutating func reset() {
        self = ShakeDetector(sensitivity: sensitivity)
    }

    private mutating func beginFirstStroke(motion: MouseMotion, startTime: TimeInterval) {
        guard motion.deltaX != 0 else { return }
        stroke = Stroke(
            direction: motion.deltaX > 0 ? 1 : -1,
            startX: horizontalPosition - motion.deltaX,
            startTime: startTime,
            extremeX: horizontalPosition,
            extremeTime: motion.timestamp,
            verticalTravel: abs(motion.deltaY)
        )
    }

    private func qualifies(_ stroke: Stroke) -> Bool {
        stroke.distance >= configuration.minimumStrokeDistance
            && stroke.speed >= configuration.minimumStrokeSpeed
            && stroke.verticalTravel <= stroke.distance * configuration.maximumVerticalRatio
    }

    private mutating func recordReversal(at time: TimeInterval) {
        recentReversals.append(time)
        recentReversals.removeAll { time - $0 > configuration.reversalWindow }
        lastQualifyingReversal = time
        if recentReversals.count >= configuration.reversalsToBeginShake {
            isEngaged = true
        }
    }

    private mutating func disengageIfQuiet(at time: TimeInterval) {
        guard isEngaged, !isShaking(at: time) else { return }
        isEngaged = false
        recentReversals.removeAll()
    }
}
