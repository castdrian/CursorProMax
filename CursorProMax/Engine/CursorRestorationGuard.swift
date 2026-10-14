import AppKit
import Dispatch

@MainActor
final class CursorRestorationGuard {
    private static let terminationSignals: [Int32] = [SIGINT, SIGTERM, SIGHUP, SIGQUIT]

    private let engine: CursorEngine
    private var signalSources: [DispatchSourceSignal] = []
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    init(engine: CursorEngine) {
        self.engine = engine
    }

    func install() {
        installSignalHandlers()
        observeWorkspace(NSWorkspace.willSleepNotification)
        observeWorkspace(NSWorkspace.screensDidSleepNotification)
        observeWorkspace(NSWorkspace.sessionDidResignActiveNotification)
        observe(NSApplication.didChangeScreenParametersNotification, in: .default) { engine in
            engine.screensChanged()
        }
    }

    private func installSignalHandlers() {
        signalSources = Self.terminationSignals.map { signalNumber in
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler { [engine] in
                MainActor.assumeIsolated {
                    engine.restoreSystemCursor()
                    exit(EXIT_SUCCESS)
                }
            }
            source.resume()
            return source
        }
    }

    private func observeWorkspace(_ name: Notification.Name) {
        observe(name, in: NSWorkspace.shared.notificationCenter) { engine in
            engine.restoreSystemCursor()
        }
    }

    private func observe(_ name: Notification.Name, in center: NotificationCenter, perform action: @escaping @MainActor (CursorEngine) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [engine] _ in
            MainActor.assumeIsolated { action(engine) }
        }
        observers.append((center, token))
    }
}
