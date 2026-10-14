import Testing
@testable import CursorProMax

struct CursorSizeLimitTests {
    @Test func largestUsesTheSystemLimit() {
        #expect(CursorSizeLimit.unlimited.maximumScale(largestGrowth: 10.8) == 10.8)
    }

    @Test func finiteLimitsNeverExceedTheSystemLimit() {
        #expect(CursorSizeLimit.scale(4).maximumScale(largestGrowth: 10.8) == 4)
        #expect(CursorSizeLimit.scale(8).maximumScale(largestGrowth: 5) == 5)
    }

    @Test func limitsNeverShrinkBelowNormalSize() {
        #expect(CursorSizeLimit.unlimited.maximumScale(largestGrowth: 0.5) == 1)
    }

    @Test func sizeLimitRoundTripsThroughStorage() {
        for preset in CursorSizeLimit.presets {
            #expect(CursorSizeLimit(storedValue: preset.storedValue) == preset)
            #expect(CursorSizeLimit(presetIndex: preset.presetIndex) == preset)
        }
        #expect(CursorSizeLimit.presets.last == .unlimited)
    }
}
