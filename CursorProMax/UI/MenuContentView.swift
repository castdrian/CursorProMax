import SwiftUI

struct MenuContentView: View {
    @Bindable var settings: AppSettings
    let loginItem: LoginItemController
    let updates: UpdateController

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatusHeaderView()
            VStack(spacing: 8) {
                SettingCard {
                    SensitivitySettingView(sensitivity: $settings.shakeSensitivity)
                }
                SettingCard {
                    SizeLimitSettingView(sizeLimit: $settings.sizeLimit)
                }
                SettingCard {
                    LaunchAtLoginSettingView(loginItem: loginItem)
                    Divider()
                    MenuBarItemSettingView(showsMenuBarItem: $settings.showsMenuBarItem)
                }
            }
            MenuFooterView(updates: updates)
        }
        .padding(16)
        .frame(width: 320)
        .onAppear(perform: loginItem.refresh)
    }
}

struct SettingCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.quaternary, in: .rect(cornerRadius: 14, style: .continuous))
    }
}

struct SettingTitle: View {
    let title: String
    let systemImage: String
    var value: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .frame(width: 18)
            Text(title)
                .font(.body.weight(.medium))
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
    }
}

struct SettingCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
