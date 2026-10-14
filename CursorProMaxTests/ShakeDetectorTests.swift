import Foundation
import Testing
@testable import CursorProMax

struct ShakeGesture {
    var strokeDistance: Double
    var strokeDuration: TimeInterval
    var strokes: Int
    var stepsPerStroke = 6
    var verticalDistance: Double = 0
    var startTime: TimeInterval = 100

    var endTime: TimeInterval {
        startTime + strokeDuration * Double(strokes)
    }

    func motions() -> [MouseMotion] {
        let stepDuration = strokeDuration / Double(stepsPerStroke)
        return (0..<strokes).flatMap { stroke in
            let direction: Double = stroke.isMultiple(of: 2) ? 1 : -1
            return (1...stepsPerStroke).map { step in
                MouseMotion(
                    deltaX: direction * strokeDistance / Double(stepsPerStroke),
                    deltaY: verticalDistance / Double(stepsPerStroke),
                    timestamp: startTime + Double(stroke) * strokeDuration + Double(step) * stepDuration
                )
            }
        }
    }
}

extension ShakeDetector {
    mutating func register(_ gesture: ShakeGesture) {
        gesture.motions().forEach { register($0) }
    }
}

struct ShakeDetectorTests {
    @Test func fastWideShakeIsDetected() {
        var detector = ShakeDetector()
        let gesture = ShakeGesture(strokeDistance: 160, strokeDuration: 0.1, strokes: 5)
        detector.register(gesture)
        #expect(detector.isShaking(at: gesture.endTime))
    }

    @Test func singleReversalIsNotAShake() {
        var detector = ShakeDetector()
        let gesture = ShakeGesture(strokeDistance: 200, strokeDuration: 0.1, strokes: 2)
        detector.register(gesture)
        #expect(!detector.isShaking(at: gesture.endTime))
    }

    @Test func standardSensitivityNeedsThreeReversals() {
        var detector = ShakeDetector()
        #expect(detector.configuration.reversalsToBeginShake == 3)
        detector.register(ShakeGesture(strokeDistance: 160, strokeDuration: 0.1, strokes: 3))
        #expect(!detector.isShaking(at: 100.3))
        detector.register(MouseMotion(deltaX: -160, deltaY: 0, timestamp: 100.35))
        #expect(detector.isShaking(at: 100.35))
    }

    @Test func slowStrokesAreIgnored() {
        var detector = ShakeDetector()
        let gesture = ShakeGesture(strokeDistance: 160, strokeDuration: 0.5, strokes: 8)
        detector.register(gesture)
        #expect(!detector.isShaking(at: gesture.endTime))
    }

    @Test func shortStrokesAreIgnored() {
        var detector = ShakeDetector()
        let gesture = ShakeGesture(strokeDistance: 25, strokeDuration: 0.02, strokes: 10)
        detector.register(gesture)
        #expect(!detector.isShaking(at: gesture.endTime))
    }

    @Test func verticalShakingIsIgnored() {
        var detector = ShakeDetector()
        let gesture = ShakeGesture(strokeDistance: 60, strokeDuration: 0.05, strokes: 8, verticalDistance: 200)
        detector.register(gesture)
        #expect(!detector.isShaking(at: gesture.endTime))
    }

    @Test func jitterBelowToleranceDoesNotReverse() {
        var detector = ShakeDetector()
        let gesture = ShakeGesture(strokeDistance: 4, strokeDuration: 0.01, strokes: 40)
        detector.register(gesture)
        #expect(!detector.isShaking(at: gesture.endTime))
    }

    @Test func higherSensitivityDetectsGentlerShakes() {
        let gentle = ShakeGesture(strokeDistance: 32, strokeDuration: 0.05, strokes: 6)
        var standard = ShakeDetector(sensitivity: .standard)
        var sensitive = ShakeDetector(sensitivity: .highest)
        standard.register(gentle)
        sensitive.register(gentle)
        #expect(!standard.isShaking(at: gentle.endTime))
        #expect(sensitive.isShaking(at: gentle.endTime))
    }

    @Test func lowerSensitivityRejectsStandardShakes() {
        let gesture = ShakeGesture(strokeDistance: 60, strokeDuration: 0.06, strokes: 6)
        var standard = ShakeDetector(sensitivity: .standard)
        var relaxed = ShakeDetector(sensitivity: .lowest)
        standard.register(gesture)
        relaxed.register(gesture)
        #expect(standard.isShaking(at: gesture.endTime))
        #expect(!relaxed.isShaking(at: gesture.endTime))
    }

    @Test func sensitivityMakesThresholdsMonotonic() {
        let values = stride(from: 0.0, through: 1.0, by: 0.25).map { ShakeDetector.Configuration(sensitivity: ShakeSensitivity($0)) }
        for (lower, higher) in zip(values, values.dropFirst()) {
            #expect(higher.minimumStrokeDistance < lower.minimumStrokeDistance)
            #expect(higher.minimumStrokeSpeed < lower.minimumStrokeSpeed)
            #expect(higher.reversalsToBeginShake <= lower.reversalsToBeginShake)
        }
    }

    @Test func shakingStopsAfterQuietTimeout() {
        var detector = ShakeDetector()
        let gesture = ShakeGesture(strokeDistance: 160, strokeDuration: 0.1, strokes: 5)
        detector.register(gesture)
        let timeout = detector.configuration.quietTimeout
        #expect(detector.isShaking(at: gesture.endTime + timeout * 0.5))
        #expect(!detector.isShaking(at: gesture.endTime + timeout + 0.1))
    }

    @Test func shakingPersistsWhileReversalsContinue() {
        var detector = ShakeDetector()
        let gesture = ShakeGesture(strokeDistance: 160, strokeDuration: 0.1, strokes: 40)
        for motion in gesture.motions() {
            detector.register(motion)
        }
        #expect(detector.isShaking(at: gesture.endTime))
    }

    @Test func continuingInOneDirectionEndsTheShake() {
        var detector = ShakeDetector()
        let gesture = ShakeGesture(strokeDistance: 160, strokeDuration: 0.1, strokes: 5)
        detector.register(gesture)
        let glide = (1...20).map { MouseMotion(deltaX: 20, deltaY: 0, timestamp: gesture.endTime + Double($0) * 0.05) }
        glide.forEach { detector.register($0) }
        #expect(!detector.isShaking(at: glide.last!.timestamp))
    }

    @Test func reversalsSpreadBeyondWindowDoNotStartShake() {
        var detector = ShakeDetector()
        var time = 100.0
        for stroke in 0..<8 {
            let direction: Double = stroke.isMultiple(of: 2) ? 1 : -1
            for _ in 0..<4 {
                time += 0.025
                detector.register(MouseMotion(deltaX: direction * 40, deltaY: 0, timestamp: time))
            }
            time += 0.6
        }
        #expect(!detector.isShaking(at: time))
    }

    @Test func resetClearsShakeState() {
        var detector = ShakeDetector()
        let gesture = ShakeGesture(strokeDistance: 160, strokeDuration: 0.1, strokes: 5)
        detector.register(gesture)
        detector.reset()
        #expect(!detector.isShaking(at: gesture.endTime))
    }
}
