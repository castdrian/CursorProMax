import SwiftUI

struct MenuFooterView: View {
    let updates: UpdateController

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: updates.checkForUpdates) {
                    Label("Check for Updates…", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!updates.canCheckForUpdates)
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
                .keyboardShortcut("q")
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
    }
}
