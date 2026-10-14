import AppKit

struct CursorArtwork: @unchecked Sendable {
    let image: CGImage
    let pointSize: CGSize
    let hotspot: CGPoint
    let interior: InscribedCircle

    static func current() -> CursorArtwork? {
        if let system = NSCursor.currentSystem, let artwork = CursorArtwork(cursor: system) {
            return artwork
        }
        return CursorArtwork(cursor: .arrow)
    }

    init?(cursor: NSCursor) {
        let pointSize = cursor.image.size
        guard pointSize.width > 0, pointSize.height > 0,
              let image = Self.sharpestImage(of: cursor.image),
              let mask = AlphaMask(image: image),
              let interior = mask.largestInscribedCircle()
        else { return nil }
        self.image = image
        self.pointSize = pointSize
        self.hotspot = cursor.hotSpot
        self.interior = interior.scaled(by: pointSize.width / CGFloat(mask.width))
    }

    func placement(baseScale: CGFloat) -> CursorPlacement {
        CursorPlacement(
            imageSize: CGSize(width: pointSize.width * baseScale, height: pointSize.height * baseScale),
            hotspot: CGPoint(x: hotspot.x * baseScale, y: hotspot.y * baseScale),
            interiorCenter: CGPoint(x: interior.center.x * baseScale, y: interior.center.y * baseScale)
        )
    }

    func interiorRadius(baseScale: CGFloat) -> CGFloat {
        interior.radius * baseScale
    }

    private static func sharpestImage(of image: NSImage) -> CGImage? {
        let bitmaps = image.representations.compactMap { $0 as? NSBitmapImageRep }
        if let largest = bitmaps.max(by: { $0.pixelsWide < $1.pixelsWide }), let cgImage = largest.cgImage {
            return cgImage
        }
        var proposedRect = CGRect(origin: .zero, size: CGSize(width: image.size.width * 8, height: image.size.height * 8))
        return image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }
}
