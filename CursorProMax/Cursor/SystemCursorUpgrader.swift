import CoreGraphics
import Dispatch
import Foundation

final class SystemCursorUpgrader: @unchecked Sendable {
    static let additionalScales: [CGFloat] = [4, 6, 8, 12, 16]
    static let maximumMeanDifference = 1.5

    static let minimumSystemScale: CGFloat = 3

    private let queue = DispatchQueue(label: "dev.adrian.cursorpromax.cursors", qos: .utility)
    private var originals: [Int: RegisteredCursor] = [:]
    private var hasUpgraded = false

    func upgrade() {
        queue.async { [self] in performUpgrade() }
    }

    func refresh() {
        queue.async { [self] in
            if Self.pointerColorsAreCustomized {
                performRestore()
            } else if !hasUpgraded {
                performUpgrade()
            }
        }
    }

    func restore() {
        queue.sync { [self] in performRestore() }
    }

    private func performUpgrade() {
        guard CursorRegistry.isAvailable, !Self.pointerColorsAreCustomized, !hasUpgraded else { return }
        let sources = CursorArtworkSource.all()
        for identifier in CursorRegistry.systemCursorIdentifiers {
            guard let original = original(of: identifier),
                  let upgraded = Self.upgraded(original, using: sources)
            else { continue }
            CursorRegistry.registerGlobally(upgraded, as: CursorRegistry.name(ofSystemCursor: identifier))
        }
        hasUpgraded = true
    }

    private func performRestore() {
        guard hasUpgraded else { return }
        for (identifier, original) in originals {
            CursorRegistry.registerGlobally(original, as: CursorRegistry.name(ofSystemCursor: identifier))
        }
        hasUpgraded = false
    }

    private func original(of identifier: Int) -> RegisteredCursor? {
        if let cached = originals[identifier] { return cached }
        guard let registered = CursorRegistry.systemCursor(identifier) else { return nil }
        let original = Self.withoutUpgrades(registered, baseScale: WindowServer.cursorScale() ?? 1)
        originals[identifier] = original
        return original
    }

    static func withoutUpgrades(_ cursor: RegisteredCursor, baseScale: Double) -> RegisteredCursor {
        let systemScale = max(minimumSystemScale, CGFloat(baseScale) * 2)
        let limit = Int((cursor.pointSize.width * systemScale).rounded(.up)) + 1
        let systemImages = cursor.images.filter { $0.width <= limit }
        return cursor.withImages(systemImages.isEmpty ? cursor.images : systemImages)
    }

    static func matchingSource(for cursor: RegisteredCursor, in sources: [CursorArtworkSource]) -> CursorArtworkSource? {
        guard let reference = cursor.images.max(by: { $0.width < $1.width }) else { return nil }
        let stripSize = cursor.stripSize
        return sources.first { source in
            source.frameCount == max(cursor.frameCount, 1)
                && abs(source.pointSize.width - stripSize.width) < 0.5
                && abs(source.pointSize.height - stripSize.height) < 0.5
                && source.image(width: reference.width, height: reference.height).map {
                    meanDifference(between: $0, and: reference) <= maximumMeanDifference
                } == true
        }
    }

    static func upgraded(_ cursor: RegisteredCursor, using sources: [CursorArtworkSource]) -> RegisteredCursor? {
        guard let source = matchingSource(for: cursor, in: sources) else { return nil }
        let largestExisting = cursor.images.map(\.width).max() ?? 0
        let frames = max(cursor.frameCount, 1)
        let additions = additionalScales.compactMap { scale -> CGImage? in
            let width = Int((cursor.pointSize.width * scale).rounded())
            guard width > largestExisting else { return nil }
            let frameHeight = Int((cursor.pointSize.height * scale).rounded())
            return source.image(width: width, height: frameHeight * frames)
        }
        guard !additions.isEmpty else { return nil }
        return RegisteredCursor(
            pointSize: cursor.pointSize,
            hotspot: cursor.hotspot,
            frameCount: cursor.frameCount,
            frameDuration: cursor.frameDuration,
            images: cursor.images + additions
        )
    }

    static func meanDifference(between first: CGImage, and second: CGImage) -> Double {
        guard first.width == second.width, first.height == second.height,
              let a = rgbaBytes(of: first), let b = rgbaBytes(of: second), a.count == b.count, !a.isEmpty
        else { return .infinity }
        var total = 0
        for index in a.indices {
            total += abs(Int(a[index]) - Int(b[index]))
        }
        return Double(total) / Double(a.count)
    }

    private static func rgbaBytes(of image: CGImage) -> [UInt8]? {
        let width = image.width
        let height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? bytes : nil
    }

    private static var pointerColorsAreCustomized: Bool {
        let value = CFPreferencesCopyAppValue("cursorIsCustomized" as CFString, "com.apple.universalaccess" as CFString)
        return (value as? Bool) ?? ((value as? NSNumber)?.boolValue ?? false)
    }
}
