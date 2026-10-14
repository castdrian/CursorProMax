import Foundation

struct MouseMotion: Sendable, Equatable {
    var deltaX: Double
    var deltaY: Double
    var timestamp: TimeInterval
}
