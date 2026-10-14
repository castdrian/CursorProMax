import CoreGraphics
import Testing
@testable import CursorProMax

struct ScreenCoverageTests {
    private let screen = CGRect(x: 0, y: 0, width: 1600, height: 1000)

    @Test func farthestCornerFromCenter() {
        let distance = ScreenCoverage.farthestCornerDistance(from: CGPoint(x: 800, y: 500), in: screen)
        #expect(abs(distance - hypot(800, 500)) < 0.001)
    }

    @Test func farthestCornerFromCorner() {
        let distance = ScreenCoverage.farthestCornerDistance(from: .zero, in: screen)
        #expect(abs(distance - hypot(1600, 1000)) < 0.001)
    }

    @Test func coverageScaleMakesInteriorCircleReachEveryCorner() {
        let pointer = CGPoint(x: 300, y: 700)
        let radius: CGFloat = 4
        let scale = ScreenCoverage.scaleToCover(screen, from: pointer, interiorRadius: radius)
        let coveredRadius = radius * CGFloat(scale)
        for corner in [CGPoint(x: 0, y: 0), CGPoint(x: 1600, y: 0), CGPoint(x: 0, y: 1000), CGPoint(x: 1600, y: 1000)] {
            #expect(hypot(corner.x - pointer.x, corner.y - pointer.y) <= coveredRadius + 0.001)
        }
    }

    @Test func coverageScaleRespectsOffsetScreens() {
        let secondary = screen.offsetBy(dx: 1600, dy: 0)
        let local = ScreenCoverage.scaleToCover(screen, from: CGPoint(x: 800, y: 500), interiorRadius: 5)
        let offset = ScreenCoverage.scaleToCover(secondary, from: CGPoint(x: 2400, y: 500), interiorRadius: 5)
        #expect(abs(local - offset) < 0.0001)
    }

    @Test func coverageScaleIsBoundedForDegenerateRadius() {
        #expect(ScreenCoverage.scaleToCover(screen, from: .zero, interiorRadius: 0) == ScreenCoverage.maximumScale)
        #expect(ScreenCoverage.scaleToCover(screen, from: .zero, interiorRadius: 0.0001) == ScreenCoverage.maximumScale)
    }

    @Test func coverageScaleNeverDropsBelowRest() {
        let tiny = CGRect(x: 0, y: 0, width: 2, height: 2)
        #expect(ScreenCoverage.scaleToCover(tiny, from: CGPoint(x: 1, y: 1), interiorRadius: 50) == 1)
    }

    @Test func unlimitedSizeUsesCoverageScale() {
        #expect(CursorSizeLimit.unlimited.maximumScale(screenCoverageScale: 240) == 240)
    }

    @Test func finiteSizeLimitIsRespected() {
        #expect(CursorSizeLimit.scale(16).maximumScale(screenCoverageScale: 240) == 16)
        #expect(CursorSizeLimit.scale(128).maximumScale(screenCoverageScale: 40) == 40)
    }

    @Test func sizeLimitRoundTripsThroughStorage() {
        for preset in CursorSizeLimit.presets {
            #expect(CursorSizeLimit(storedValue: preset.storedValue) == preset)
            #expect(CursorSizeLimit(presetIndex: preset.presetIndex) == preset)
        }
        #expect(CursorSizeLimit.presets.last == .unlimited)
    }
}
