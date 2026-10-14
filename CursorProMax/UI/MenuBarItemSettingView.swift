import SwiftUI

struct MenuBarItemSettingView: View {
    @Binding var showsMenuBarItem: Bool

    var body: some View {
        Toggle(isOn: $showsMenuBarItem) {
            SettingTitle(title: "Show in menu bar", systemImage: "menubar.rectangle")
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        if !showsMenuBarItem {
            SettingCaption(text: "Open CursorProMax again to bring up these settings.")
        }
    }
}
