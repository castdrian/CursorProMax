import Foundation

struct ShakeSensitivity: Sendable, Equatable, Hashable {
    static let range: ClosedRange<Double> = 0...1
    static let standard = ShakeSensitivity(0.5)
    static let lowest = ShakeSensitivity(range.lowerBound)
    static let highest = ShakeSensitivity(range.upperBound)

    let value: Double

    init(_ value: Double) {
        self.value = min(max(value, Self.range.lowerBound), Self.range.upperBound)
    }

    var title: String {
        switch value {
        case ..<0.125: "Lowest"
        case ..<0.375: "Low"
        case ..<0.625: "Standard"
        case ..<0.875: "High"
        default: "Highest"
        }
    }

    func interpolated(from least: Double, to most: Double) -> Double {
        least * pow(most / least, value)
    }
}
