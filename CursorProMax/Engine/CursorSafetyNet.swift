import Darwin
import Foundation

@MainActor
final class CursorSafetyNet {
    private enum Key {
        static let pendingCursorScale = "pendingCursorScale"
        static let restoresShakeToLocate = "restoresShakeToLocate"
    }

    private static let fatalSignals: [Int32] = [SIGSEGV, SIGBUS, SIGILL, SIGABRT, SIGTRAP, SIGFPE]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recoverFromPreviousRun() {
        if let scale = defaults.object(forKey: Key.pendingCursorScale) as? Double {
            WindowServer.setCursorScale(scale)
            defaults.removeObject(forKey: Key.pendingCursorScale)
        }
        installFatalSignalHandlers()
    }

    func suppressShakeToLocate() {
        if defaults.bool(forKey: Key.restoresShakeToLocate) {
            WindowServer.setShakeToLocateDisabled(true)
            CrashRecovery.restoresShakeToLocate = true
            return
        }
        guard WindowServer.isShakeToLocateDisabled() == false else { return }
        WindowServer.setShakeToLocateDisabled(true)
        defaults.set(true, forKey: Key.restoresShakeToLocate)
        CrashRecovery.restoresShakeToLocate = true
    }

    func restoreShakeToLocate() {
        guard defaults.bool(forKey: Key.restoresShakeToLocate) else { return }
        WindowServer.setShakeToLocateDisabled(false)
        defaults.removeObject(forKey: Key.restoresShakeToLocate)
        CrashRecovery.restoresShakeToLocate = false
    }

    func sessionBegan(baseScale: Double) {
        defaults.set(baseScale, forKey: Key.pendingCursorScale)
        CrashRecovery.pendingCursorScale = baseScale
    }

    func sessionEnded() {
        defaults.removeObject(forKey: Key.pendingCursorScale)
        CrashRecovery.pendingCursorScale = nil
    }

    private func installFatalSignalHandlers() {
        for signalNumber in Self.fatalSignals {
            signal(signalNumber, CrashRecovery.handleFatalSignal)
        }
    }
}

enum CrashRecovery {
    nonisolated(unsafe) static var pendingCursorScale: Double?
    nonisolated(unsafe) static var restoresShakeToLocate = false

    static let handleFatalSignal: @convention(c) (Int32) -> Void = { signalNumber in
        if let scale = CrashRecovery.pendingCursorScale {
            WindowServer.setCursorScale(scale)
        }
        if CrashRecovery.restoresShakeToLocate {
            WindowServer.setShakeToLocateDisabled(false)
        }
        signal(signalNumber, SIG_DFL)
        raise(signalNumber)
    }
}
