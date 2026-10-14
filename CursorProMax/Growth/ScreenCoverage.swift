import CoreGraphics

enum ScreenCoverage {
    static let maximumScale = 4000.0

    static func farthestCornerDistance(from point: CGPoint, in rect: CGRect) -> CGFloat {
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY),
        ]
        return corners.map { hypot($0.x - point.x, $0.y - point.y) }.max() ?? 0
    }

    static func scaleToCover(_ screen: CGRect, from point: CGPoint, interiorRadius: CGFloat) -> Double {
        guard interiorRadius > 0 else { return maximumScale }
        let required = Double(farthestCornerDistance(from: point, in: screen) / interiorRadius)
        return min(max(required, 1), maximumScale)
    }
}
