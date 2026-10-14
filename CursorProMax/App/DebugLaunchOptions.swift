import Foundation

struct DebugLaunchOptions: Sendable, Equatable {
    var opensMenuOnLaunch: Bool
    var pinnedScale: Double?
    var checksForUpdatesOnLaunch: Bool

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        opensMenuOnLaunch = environment["CURSORPROMAX_DEBUG_OPEN_MENU"] == "1"
        checksForUpdatesOnLaunch = environment["CURSORPROMAX_DEBUG_CHECK_UPDATES"] == "1"
        pinnedScale = environment["CURSORPROMAX_DEBUG_SCALE"].flatMap(Double.init).flatMap { $0 >= 1 ? $0 : nil }
    }
}
