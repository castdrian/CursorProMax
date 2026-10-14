import Foundation
import Observation

@Observable
@MainActor
final class AppSettings {
    private enum Key {
        static let shakeSensitivity = "shakeSensitivity"
        static let maximumScale = "maximumScale"
        static let showsMenuBarItem = "showsMenuBarItem"
        static let growthSpeed = "growthSpeed"
        static let hasSeenWelcome = "hasSeenWelcome"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var shakeSensitivity: ShakeSensitivity {
        didSet { defaults.set(shakeSensitivity.value, forKey: Key.shakeSensitivity) }
    }

    var sizeLimit: CursorSizeLimit {
        didSet { defaults.set(sizeLimit.storedValue, forKey: Key.maximumScale) }
    }

    var showsMenuBarItem: Bool {
        didSet { defaults.set(showsMenuBarItem, forKey: Key.showsMenuBarItem) }
    }

    var growthSpeed: GrowthSpeed {
        didSet { defaults.set(growthSpeed.rawValue, forKey: Key.growthSpeed) }
    }

    var hasSeenWelcome: Bool {
        didSet { defaults.set(hasSeenWelcome, forKey: Key.hasSeenWelcome) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        shakeSensitivity = (defaults.object(forKey: Key.shakeSensitivity) as? Double).map(ShakeSensitivity.init) ?? .standard
        sizeLimit = (defaults.object(forKey: Key.maximumScale) as? Double).map(CursorSizeLimit.init(storedValue:)) ?? .unlimited
        showsMenuBarItem = defaults.object(forKey: Key.showsMenuBarItem) as? Bool ?? true
        growthSpeed = defaults.string(forKey: Key.growthSpeed).flatMap(GrowthSpeed.init(rawValue:)) ?? .standard
        hasSeenWelcome = defaults.bool(forKey: Key.hasSeenWelcome)
    }
}
