import CoreGraphics
import Testing
@testable import CursorProMax

struct AlphaMaskTests {
    private func mask(width: Int, height: Int, isOpaque: (Int, Int) -> Bool) -> AlphaMask {
        let pixels = (0..<height).flatMap { y in (0..<width).map { x in isOpaque(x, y) } }
        return AlphaMask(width: width, height: height, opaquePixels: pixels)
    }

    @Test func emptyMaskHasNoInterior() {
        #expect(mask(width: 8, height: 8) { _, _ in false }.largestInscribedCircle() == nil)
    }

    @Test func squareInteriorIsCentered() throws {
        let circle = try #require(mask(width: 20, height: 20) { x, y in (5..<15).contains(x) && (5..<15).contains(y) }.largestInscribedCircle())
        #expect(abs(circle.center.x - 10) <= 1)
        #expect(abs(circle.center.y - 10) <= 1)
        #expect(abs(circle.radius - 5) <= 1)
    }

    @Test func interiorFindsTheThickestRegion() throws {
        let circle = try #require(mask(width: 40, height: 20) { x, y in
            let thinBar = (0..<20).contains(x) && (9..<11).contains(y)
            let thickBlock = (24..<36).contains(x) && (4..<16).contains(y)
            return thinBar || thickBlock
        }.largestInscribedCircle())
        #expect(circle.center.x > 24 && circle.center.x < 36)
        #expect(circle.radius >= 5)
    }

    @Test func rasterizedImageProducesMask() throws {
        let context = try #require(CGContext(
            data: nil, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 32, width: 32, height: 32))
        let image = try #require(context.makeImage())
        let mask = try #require(AlphaMask(image: image, maximumDimension: 32))
        #expect(mask.width == 32)
        #expect(mask.isOpaque(x: 4, y: 4))
        #expect(!mask.isOpaque(x: 28, y: 28))
    }

    @Test func scaledCircleScalesCenterAndRadius() {
        let circle = InscribedCircle(center: CGPoint(x: 2, y: 3), radius: 1.5).scaled(by: 2)
        #expect(circle == InscribedCircle(center: CGPoint(x: 4, y: 6), radius: 3))
    }
}
