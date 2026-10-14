import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings: AppSettings
    let engine: CursorEngine
    let loginItem = LoginItemController()
    let updates = UpdateController()
    private let restorationGuard: CursorRestorationGuard
    private let debugOptions = DebugLaunchOptions()
    private var launchedAsLoginItem = false
    private lazy var settingsWindow = SettingsWindowController { [unowned self] in
        MenuContentView(settings: settings, loginItem: loginItem, updates: updates)
    }

    override init() {
        let settings = AppSettings()
        let engine = CursorEngine(settings: settings)
        self.settings = settings
        self.engine = engine
        restorationGuard = CursorRestorationGuard(engine: engine)
        super.init()
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        launchedAsLoginItem = Self.isLoginItemLaunch(NSAppleEventManager.shared().currentAppleEvent)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        restorationGuard.install()
        engine.start()
        applyDebugOptions()
        if !settings.showsMenuBarItem && !launchedAsLoginItem {
            settingsWindow.show()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !settings.showsMenuBarItem {
            settingsWindow.show()
        }
        return false
    }

    private static func isLoginItemLaunch(_ event: NSAppleEventDescriptor?) -> Bool {
        guard let event, event.eventID == kAEOpenApplication else { return false }
        return event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
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
