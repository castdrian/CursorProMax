import SwiftUI

struct LaunchAtLoginSettingView: View {
    let loginItem: LoginItemController

    var body: some View {
        Toggle(isOn: isEnabled) {
            SettingTitle(title: "Launch at login", systemImage: "person.crop.circle")
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        if loginItem.requiresApproval {
            HStack(spacing: 6) {
                SettingCaption(text: "Waiting for approval in Login Items.")
                Spacer(minLength: 0)
                Button("Open Settings…", action: loginItem.openLoginItemsSettings)
                    .buttonStyle(.link)
                    .font(.caption)
            }
        }
        if let failureMessage = loginItem.failureMessage {
            Label(failureMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var isEnabled: Binding<Bool> {
        Binding(
            get: { loginItem.isEnabled },
            set: { loginItem.setEnabled($0) }
        )
    }
}
