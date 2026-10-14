import Foundation

enum CursorSizeLimit: Sendable, Hashable {
    case scale(Double)
    case unlimited

    static let presets: [CursorSizeLimit] = [
        .scale(2), .scale(4), .scale(8), .scale(16), .scale(32), .scale(64), .scale(128), .unlimited,
    ]

    init(storedValue: Double) {
        self = storedValue >= 1 ? .scale(storedValue) : .unlimited
    }

    var storedValue: Double {
        switch self {
        case .scale(let value): value
        case .unlimited: 0
        }
    }

    var title: String {
        switch self {
        case .scale(let value): "\(value.formatted(.number.precision(.fractionLength(0...1))))×"
        case .unlimited: "No limit"
        }
    }

    var presetIndex: Int {
        Self.presets.firstIndex(of: self) ?? Self.presets.count - 1
    }

    init(presetIndex: Int) {
        self = Self.presets[min(max(presetIndex, 0), Self.presets.count - 1)]
    }

    func maximumScale(screenCoverageScale: Double) -> Double {
        switch self {
        case .scale(let value): min(value, screenCoverageScale)
        case .unlimited: screenCoverageScale
        }
    }
}
