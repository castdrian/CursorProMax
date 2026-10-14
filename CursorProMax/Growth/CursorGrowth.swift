import Foundation

struct CursorGrowth: Sendable, Equatable {
    static let restingScale = 1.0

    var doublingTime: TimeInterval = 0.5
    var settleRate: Double = 8
    var settleThreshold: Double = 0.002
    private(set) var scale = restingScale

    var isResting: Bool { scale == Self.restingScale }

    mutating func advance(by elapsed: TimeInterval, isShaking: Bool, maximumScale: Double) {
        guard elapsed > 0 else { return }
        let ceiling = max(maximumScale, Self.restingScale)
        if isShaking && scale < ceiling {
            grow(for: elapsed, upTo: ceiling)
        } else {
            settle(toward: isShaking ? ceiling : Self.restingScale, for: elapsed)
        }
    }

    mutating func pin(at pinnedScale: Double) {
        scale = max(pinnedScale, Self.restingScale)
    }

    mutating func reset() {
        scale = Self.restingScale
    }

    private mutating func grow(for elapsed: TimeInterval, upTo ceiling: Double) {
        let growthFactor = exp(log(2) / doublingTime * elapsed)
        scale = min(ceiling, scale * growthFactor)
    }

    private mutating func settle(toward target: Double, for elapsed: TimeInterval) {
        let remainingDistance = log(scale / target) * exp(-settleRate * elapsed)
        scale = abs(remainingDistance) < settleThreshold ? target : target * exp(remainingDistance)
    }
}
