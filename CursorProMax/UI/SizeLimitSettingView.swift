import SwiftUI

struct SizeLimitSettingView: View {
    @Binding var sizeLimit: CursorSizeLimit

    private static let presetRange: ClosedRange<Double> = 0...Double(CursorSizeLimit.presets.count - 1)

    var body: some View {
        SettingTitle(title: "Maximum size", systemImage: "arrow.up.left.and.arrow.down.right", value: sizeLimit.title)
        slider
        SettingCaption(text: caption)
    }

    private var slider: some View {
        Slider(value: presetPosition, in: Self.presetRange, step: 1) {
            Text("Maximum size")
        } minimumValueLabel: {
            Image(systemName: "cursorarrow")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Smaller")
        } maximumValueLabel: {
            Image(systemName: "infinity")
                .foregroundStyle(.secondary)
                .accessibilityLabel("No limit")
        }
        .labelsHidden()
        .controlSize(.small)
    }

    private var caption: String {
        switch sizeLimit {
        case .unlimited: "Grows until the pointer covers the whole screen."
        case .scale: "Stops growing at \(sizeLimit.title) the normal pointer size."
        }
    }

    private var presetPosition: Binding<Double> {
        Binding(
            get: { Double(sizeLimit.presetIndex) },
            set: { sizeLimit = CursorSizeLimit(presetIndex: Int($0.rounded())) }
        )
    }
}
