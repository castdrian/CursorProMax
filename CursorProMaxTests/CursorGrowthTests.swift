import Foundation
import Testing
@testable import CursorProMax

struct CursorGrowthTests {
    private let frame = 1.0 / 120

    @Test func startsAtRest() {
        let growth = CursorGrowth()
        #expect(growth.isResting)
        #expect(growth.scale == 1)
    }

    @Test func growsMonotonicallyWhileShaking() {
        var growth = CursorGrowth()
        var previous = growth.scale
        for _ in 0..<240 {
            growth.advance(by: frame, isShaking: true, maximumScale: 10_000)
            #expect(growth.scale > previous)
            previous = growth.scale
        }
    }

    @Test func growthIsExponential() {
        var growth = CursorGrowth()
        growth.advance(by: growth.doublingTime, isShaking: true, maximumScale: 10_000)
        #expect(abs(growth.scale - 2) < 1e-9)
        growth.advance(by: growth.doublingTime, isShaking: true, maximumScale: 10_000)
        #expect(abs(growth.scale - 4) < 1e-9)
    }

    @Test func respectsMaximumScale() {
        var growth = CursorGrowth()
        for _ in 0..<2_000 {
            growth.advance(by: frame, isShaking: true, maximumScale: 16)
            #expect(growth.scale <= 16)
        }
        #expect(growth.scale == 16)
    }

    @Test func easesDownWhenLimitShrinksWhileShaking() {
        var growth = CursorGrowth()
        growth.pin(at: 64)
        var previous = growth.scale
        for _ in 0..<600 {
            growth.advance(by: frame, isShaking: true, maximumScale: 8)
            #expect(growth.scale <= previous)
            #expect(growth.scale >= 8)
            previous = growth.scale
        }
        #expect(growth.scale == 8)
    }

    @Test func shrinksSmoothlyBackToRest() {
        var growth = CursorGrowth()
        growth.pin(at: 300)
        var previous = growth.scale
        var previousStep = Double.infinity
        var frames = 0
        while !growth.isResting && frames < 1_000 {
            growth.advance(by: frame, isShaking: false, maximumScale: 300)
            let step = log(previous / growth.scale)
            #expect(growth.scale < previous)
            #expect(growth.scale >= 1)
            #expect(growth.isResting || step <= previousStep)
            previous = growth.scale
            previousStep = step
            frames += 1
        }
        #expect(growth.isResting)
        #expect(Double(frames) * frame < 1.5)
    }

    @Test func resumesGrowingFromCurrentScale() {
        var growth = CursorGrowth()
        growth.pin(at: 20)
        growth.advance(by: 0.1, isShaking: false, maximumScale: 100)
        let shrunk = growth.scale
        growth.advance(by: frame, isShaking: true, maximumScale: 100)
        #expect(growth.scale > shrunk)
        #expect(growth.scale < 20)
    }

    @Test func ignoresNonPositiveTime() {
        var growth = CursorGrowth()
        growth.advance(by: 0, isShaking: true, maximumScale: 100)
        growth.advance(by: -1, isShaking: true, maximumScale: 100)
        #expect(growth.isResting)
    }

    @Test func pinningBelowRestClampsToRest() {
        var growth = CursorGrowth()
        growth.pin(at: 0.2)
        #expect(growth.isResting)
    }
}
