import Foundation

enum GrowthSpeed: String, CaseIterable, Identifiable, Sendable {
    case relaxed
    case standard
    case fast

    var id: Self { self }

    var title: String {
        switch self {
        case .relaxed: "Relaxed"
        case .standard: "Standard"
        case .fast: "Fast"
        }
    }

    var doublingTime: TimeInterval {
        switch self {
        case .relaxed: 0.9
        case .standard: 0.5
        case .fast: 0.3
        }
    }
}
