import CoreGraphics
import Testing
@testable import CursorProMax

struct CursorPlacementTests {
    private let placement = CursorPlacement(
        imageSize: CGSize(width: 28, height: 40),
        hotspot: CGPoint(x: 5, y: 5),
        interiorCenter: CGPoint(x: 9, y: 17)
    )

    @Test func restingFrameAlignsHotspotWithPointer() {
        let pointer = CGPoint(x: 500, y: 400)
        let frame = placement.frame(pointer: pointer, scale: 1, coverageScale: 200)
        #expect(frame.minX == 495)
        #expect(frame.maxY == 405)
        #expect(frame.size == CGSize(width: 28, height: 40))
    }

    @Test func frameScalesAroundAnchor() {
        let frame = placement.frame(pointer: CGPoint(x: 500, y: 400), scale: 10, coverageScale: 200)
        #expect(abs(frame.width - 280) < 0.001)
        #expect(abs(frame.height - 400) < 0.001)
    }

    @Test func anchorMovesTowardInteriorAsCursorGrows() {
        let small = placement.anchor(scale: 2, coverageScale: 200)
        let large = placement.anchor(scale: 50, coverageScale: 200)
        let full = placement.anchor(scale: 200, coverageScale: 200)
        #expect(small.y < large.y)
        #expect(large.y < full.y)
        #expect(full == placement.interiorCenter)
    }

    @Test func blendIsMonotonicAndBounded() {
        let blends = [1.0, 2, 8, 32, 128, 400, 1_000].map { CursorPlacement.interiorBlend(scale: $0, coverageScale: 400) }
        #expect(blends.first == 0)
        #expect(blends.last == 1)
        #expect(zip(blends, blends.dropFirst()).allSatisfy { $0 <= $1 })
    }

    @Test func fullCoveragePlacesInteriorCenterUnderPointer() {
        let pointer = CGPoint(x: 700, y: 300)
        let scale = 150.0
        let frame = placement.frame(pointer: pointer, scale: scale, coverageScale: scale)
        let interiorOnScreen = CGPoint(
            x: frame.minX + placement.interiorCenter.x * scale,
            y: frame.maxY - placement.interiorCenter.y * scale
        )
        #expect(abs(interiorOnScreen.x - pointer.x) < 0.001)
        #expect(abs(interiorOnScreen.y - pointer.y) < 0.001)
    }
}
