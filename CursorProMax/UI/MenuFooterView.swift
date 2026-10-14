import SwiftUI

struct MenuFooterView: View {
    let updates: UpdateController

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: updates.checkForUpdates) {
                    Label("Check for Updates…", systemImage: "arrow.triangle.2.circlepath")
                        .lineLimit(1)
                        .fixedSize()
                        .frame(maxWidth: .infinity)
                }
                .disabled(!updates.canCheckForUpdates)
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .accessibilityLabel("Quit CursorProMax")
                }
                .buttonBorderShape(.circle)
                .keyboardShortcut("q")
                .help("Quit CursorProMax")
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
    }
}
