import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings: AppSettings
    let engine: CursorEngine
    let loginItem = LoginItemController()
    let updates = UpdateController()
    private let restorationGuard: CursorRestorationGuard
    private let debugOptions = DebugLaunchOptions()

    override init() {
        let settings = AppSettings()
        let engine = CursorEngine(settings: settings)
        self.settings = settings
        self.engine = engine
        restorationGuard = CursorRestorationGuard(engine: engine)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        restorationGuard.install()
        engine.start()
        applyDebugOptions()
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine.stop()
    }

    private func applyDebugOptions() {
        if let pinnedScale = debugOptions.pinnedScale {
            engine.pin(scale: pinnedScale)
        }
        if debugOptions.opensMenuOnLaunch {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                StatusItemOpener.openMenuBarExtra()
            }
        }
    }
}
