import CoreGraphics
import Foundation

struct CursorPlacement: Sendable, Equatable {
    var imageSize: CGSize
    var hotspot: CGPoint
    var interiorCenter: CGPoint

    static func interiorBlend(scale: Double, coverageScale: Double) -> Double {
        guard coverageScale > 1 else { return 1 }
        let progress = log(max(scale, 1)) / log(coverageScale)
        let clamped = min(max(progress, 0), 1)
        return clamped * clamped
    }

    func anchor(scale: Double, coverageScale: Double) -> CGPoint {
        let blend = CGFloat(Self.interiorBlend(scale: scale, coverageScale: coverageScale))
        return CGPoint(
            x: hotspot.x + (interiorCenter.x - hotspot.x) * blend,
            y: hotspot.y + (interiorCenter.y - hotspot.y) * blend
        )
    }

    func frame(pointer: CGPoint, scale: Double, coverageScale: Double) -> CGRect {
        let anchor = anchor(scale: scale, coverageScale: coverageScale)
        let factor = CGFloat(scale)
        let size = CGSize(width: imageSize.width * factor, height: imageSize.height * factor)
        let top = pointer.y + anchor.y * factor
        return CGRect(x: pointer.x - anchor.x * factor, y: top - size.height, width: size.width, height: size.height)
    }
}
