import Foundation

enum CursorSizeLimit: Sendable, Hashable {
    case scale(Double)
    case unlimited

    static let presets: [CursorSizeLimit] = [
        .scale(2), .scale(3), .scale(4), .scale(6), .scale(8), .unlimited,
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
        case .unlimited: "Largest"
        }
    }

    var presetIndex: Int {
        Self.presets.firstIndex(of: self) ?? Self.presets.count - 1
    }

    init(presetIndex: Int) {
        self = Self.presets[min(max(presetIndex, 0), Self.presets.count - 1)]
    }

    func maximumScale(largestGrowth: Double) -> Double {
        switch self {
        case .scale(let value): max(min(value, largestGrowth), 1)
        case .unlimited: max(largestGrowth, 1)
        }
    }
}
