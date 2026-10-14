import SwiftUI

@main
struct CursorProMaxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra(isInserted: showsMenuBarItem) {
            MenuContentView(
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

    private var showsMenuBarItem: Binding<Bool> {
        Binding(
            get: { appDelegate.settings.showsMenuBarItem },
            set: { appDelegate.settings.showsMenuBarItem = $0 }
        )
    }
}
