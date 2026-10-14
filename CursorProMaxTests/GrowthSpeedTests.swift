import Testing
@testable import CursorProMax

struct GrowthSpeedTests {
    @Test func fasterSpeedsDoubleSooner() {
        #expect(GrowthSpeed.fast.doublingTime < GrowthSpeed.standard.doublingTime)
        #expect(GrowthSpeed.standard.doublingTime < GrowthSpeed.relaxed.doublingTime)
    }

    @Test func standardKeepsTheOriginalPace() {
        #expect(GrowthSpeed.standard.doublingTime == CursorGrowth().doublingTime)
    }

    @Test func speedsRoundTripThroughStorage() {
        for speed in GrowthSpeed.allCases {
            #expect(GrowthSpeed(rawValue: speed.rawValue) == speed)
        }
    }
}
