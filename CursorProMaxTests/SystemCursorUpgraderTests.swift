import CoreGraphics
import Testing
@testable import CursorProMax

struct SystemCursorUpgraderTests {
    private let sources = CursorArtworkSource.all().filter { $0.frameCount == 1 }

    @Test func pointingHandMatchesItsVectorSourceExactly() throws {
        let hand = try #require(CursorRegistry.systemCursor(13))
        let source = try #require(SystemCursorUpgrader.matchingSource(for: hand, in: sources))
        #expect(source.name.hasSuffix("pointinghand"))
    }

    @Test func upgradeKeepsTheOriginalImagesAndAddsSharperOnes() throws {
        let hand = try #require(CursorRegistry.systemCursor(13))
        let upgraded = try #require(SystemCursorUpgrader.upgraded(hand, using: sources))
        #expect(Array(upgraded.images.prefix(hand.images.count)).map(\.width) == hand.images.map(\.width))
        #expect((upgraded.images.map(\.width).max() ?? 0) >= Int(hand.pointSize.width * 16))
        #expect(upgraded.hotspot == hand.hotspot)
    }

    @Test func identicalImagesHaveNoDifference() throws {
        let image = try #require(sources.first?.image(width: 64, height: 64))
        #expect(SystemCursorUpgrader.meanDifference(between: image, and: image) == 0)
    }
}
