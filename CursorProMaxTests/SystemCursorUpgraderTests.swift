import CoreGraphics
import Testing
@testable import CursorProMax

@Suite(.serialized)
struct SystemCursorUpgraderTests {
    private let sources = CursorArtworkSource.all()

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

    @Test func animatedCursorsMatchTheirFrameStrips() throws {
        let busy = try #require(CursorRegistry.systemCursor(4))
        #expect(busy.frameCount > 1)
        let source = try #require(SystemCursorUpgrader.matchingSource(for: busy, in: sources))
        #expect(source.name == "busybutclickable")
        let upgraded = try #require(SystemCursorUpgrader.upgraded(busy, using: sources))
        let largest = try #require(upgraded.images.max { $0.width < $1.width })
        #expect(largest.height == largest.width / Int(busy.pointSize.width) * Int(busy.pointSize.height) * busy.frameCount)
        #expect(upgraded.frameDuration == busy.frameDuration)
    }

    @Test func leftoverUpgradesAreStrippedBackToTheSystemImages() throws {
        let hand = try #require(CursorRegistry.systemCursor(13))
        let upgraded = try #require(SystemCursorUpgrader.upgraded(hand, using: sources))
        #expect(SystemCursorUpgrader.withoutUpgrades(upgraded, baseScale: 1.4728).images.map(\.width) == hand.images.map(\.width))
    }

    @Test func identicalImagesHaveNoDifference() throws {
        let image = try #require(sources.first?.image(width: 64, height: 64))
        #expect(SystemCursorUpgrader.meanDifference(between: image, and: image) == 0)
    }
}
