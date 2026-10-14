import CoreGraphics
import Foundation

struct CursorArtworkSource: @unchecked Sendable {
    static let directory = URL(fileURLWithPath: "/System/Library/Frameworks/ApplicationServices.framework/Frameworks/HIServices.framework/Resources/cursors")

    let name: String
    let page: CGPDFPage
    let shadowBlur: CGFloat
    let shadowOffset: CGSize
    let shadowColor: CGColor
    let frameCount: Int

    var pointSize: CGSize { page.getBoxRect(.mediaBox).size }

    static func all(in directory: URL = directory) -> [CursorArtworkSource] {
        let fileManager = FileManager.default
        let folders = (try? fileManager.contentsOfDirectory(atPath: directory.path)) ?? []
        let nested = folders.flatMap { folder -> [String] in
            let children = (try? fileManager.contentsOfDirectory(atPath: directory.appendingPathComponent(folder).path)) ?? []
            return children.map { "\(folder)/\($0)" }
        }
        return (nested + folders).sorted().compactMap { CursorArtworkSource(folder: directory.appendingPathComponent($0), name: $0) }
    }

    init?(folder: URL, name: String) {
        guard let page = CGPDFDocument(folder.appendingPathComponent("cursor.pdf") as CFURL)?.page(at: 1) else { return nil }
        let info = (try? Data(contentsOf: folder.appendingPathComponent("info.plist")))
            .flatMap { try? PropertyListSerialization.propertyList(from: $0, format: nil) as? [String: Any] } ?? [:]
        let color = (info["shadowcolor"] as? [Double]) ?? [0, 0, 0, 0.45]
        self.name = name
        self.page = page
        shadowBlur = CGFloat(info["blur"] as? Double ?? 0)
        shadowOffset = CGSize(width: info["shadowoffsetx"] as? Double ?? 0, height: info["shadowoffsety"] as? Double ?? 0)
        shadowColor = CGColor(
            srgbRed: color.indices.contains(0) ? color[0] : 0,
            green: color.indices.contains(1) ? color[1] : 0,
            blue: color.indices.contains(2) ? color[2] : 0,
            alpha: color.indices.contains(3) ? color[3] : 0.45
        )
        frameCount = info["frames"] as? Int ?? 1
    }

    func image(width: Int, height: Int) -> CGImage? {
        guard width > 0, height > 0,
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return nil }
        let box = page.getBoxRect(.mediaBox)
        let horizontalScale = CGFloat(width) / box.width
        let verticalScale = CGFloat(height) / box.height
        context.setShadow(
            offset: CGSize(width: shadowOffset.width * horizontalScale, height: shadowOffset.height * horizontalScale),
            blur: shadowBlur * horizontalScale,
            color: shadowColor
        )
        context.scaleBy(x: horizontalScale, y: verticalScale)
        context.translateBy(x: -box.minX, y: -box.minY)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        context.drawPDFPage(page)
        context.endTransparencyLayer()
        return context.makeImage()
    }
}
