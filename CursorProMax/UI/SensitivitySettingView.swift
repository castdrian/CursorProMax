import SwiftUI

struct SensitivitySettingView: View {
    @Binding var sensitivity: ShakeSensitivity

    var body: some View {
        SettingTitle(title: "Shake sensitivity", systemImage: "hand.wave", value: sensitivity.title)
        Slider(value: sliderValue, in: ShakeSensitivity.range, step: 0.25) {
            Text("Shake sensitivity")
        } minimumValueLabel: {
            Image(systemName: "tortoise")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Lower")
        } maximumValueLabel: {
            Image(systemName: "hare")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Higher")
        }
        .labelsHidden()
        .controlSize(.small)
        SettingCaption(text: "Standard matches the macOS shake to locate gesture.")
    }

    private var sliderValue: Binding<Double> {
        Binding(
            get: { sensitivity.value },
            set: { sensitivity = ShakeSensitivity($0) }
        )
    }
}
