import Foundation
import Observation

@Observable
@MainActor
final class AppSettings {
    private enum Key {
        static let shakeSensitivity = "shakeSensitivity"
        static let maximumScale = "maximumScale"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var shakeSensitivity: ShakeSensitivity {
        didSet { defaults.set(shakeSensitivity.value, forKey: Key.shakeSensitivity) }
    }

    var sizeLimit: CursorSizeLimit {
        didSet { defaults.set(sizeLimit.storedValue, forKey: Key.maximumScale) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        shakeSensitivity = (defaults.object(forKey: Key.shakeSensitivity) as? Double).map(ShakeSensitivity.init) ?? .standard
        sizeLimit = (defaults.object(forKey: Key.maximumScale) as? Double).map(CursorSizeLimit.init(storedValue:)) ?? .unlimited
    }
}
