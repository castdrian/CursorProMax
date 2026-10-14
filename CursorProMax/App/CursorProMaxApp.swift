import SwiftUI

@main
struct CursorProMaxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(
                engine: appDelegate.engine,
                settings: appDelegate.settings,
                loginItem: appDelegate.loginItem,
                updates: appDelegate.updates
            )
        } label: {
            Image(systemName: "cursorarrow")
                .accessibilityLabel("CursorProMax")
        }
        .menuBarExtraStyle(.window)
    }
}
