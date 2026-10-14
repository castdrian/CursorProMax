import CoreGraphics

struct AlphaMask: Sendable, Equatable {
    let width: Int
    let height: Int
    private let opaquePixels: [Bool]

    init(width: Int, height: Int, opaquePixels: [Bool]) {
        precondition(opaquePixels.count == width * height)
        self.width = width
        self.height = height
        self.opaquePixels = opaquePixels
    }

    init?(image: CGImage, maximumDimension: Int = 120, alphaThreshold: UInt8 = 128) {
        let reduction = max(1, Double(max(image.width, image.height)) / Double(maximumDimension))
        let width = max(1, Int((Double(image.width) / reduction).rounded()))
        let height = max(1, Int((Double(image.height) / reduction).rounded()))
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue
        ) else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return nil }
        let alpha = data.bindMemory(to: UInt8.self, capacity: width * height)
        let pixels = (0..<(width * height)).map { alpha[$0] >= alphaThreshold }
        self.init(width: width, height: height, opaquePixels: pixels)
    }

    func isOpaque(x: Int, y: Int) -> Bool {
        guard (0..<width).contains(x), (0..<height).contains(y) else { return false }
        return opaquePixels[y * width + x]
    }

    func largestInscribedCircle() -> InscribedCircle? {
        let edges = transparentEdgePixels()
        var best: InscribedCircle?
        for y in 0..<height {
            for x in 0..<width where isOpaque(x: x, y: y) {
                let nearestSquared = edges.reduce(Int.max) { nearest, edge in
                    let dx = edge.x - x
                    let dy = edge.y - y
                    return min(nearest, dx * dx + dy * dy)
                }
                let radius = CGFloat(Double(nearestSquared).squareRoot()) - 0.5
                if radius > (best?.radius ?? 0) {
                    best = InscribedCircle(center: CGPoint(x: Double(x) + 0.5, y: Double(y) + 0.5), radius: radius)
                }
            }
        }
        return best
    }

    private func transparentEdgePixels() -> [(x: Int, y: Int)] {
        var edges: [(x: Int, y: Int)] = []
        for y in -1...height {
            for x in -1...width where !isOpaque(x: x, y: y) && touchesOpaquePixel(x: x, y: y) {
                edges.append((x, y))
            }
        }
        return edges
    }

    private func touchesOpaquePixel(x: Int, y: Int) -> Bool {
        isOpaque(x: x - 1, y: y) || isOpaque(x: x + 1, y: y) || isOpaque(x: x, y: y - 1) || isOpaque(x: x, y: y + 1)
    }
}

struct InscribedCircle: Sendable, Equatable {
    var center: CGPoint
    var radius: CGFloat

    func scaled(by factor: CGFloat) -> InscribedCircle {
        InscribedCircle(center: CGPoint(x: center.x * factor, y: center.y * factor), radius: radius * factor)
    }
}
