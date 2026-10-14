import SwiftUI

struct SizeLimitSettingView: View {
    @Binding var sizeLimit: CursorSizeLimit

    private static let presetRange: ClosedRange<Double> = 0...Double(CursorSizeLimit.presets.count - 1)

    var body: some View {
        SettingTitle(title: "Maximum size", systemImage: "plus.magnifyingglass", value: sizeLimit.title)
        slider
        SettingCaption(text: caption)
    }

    private var slider: some View {
        Slider(value: presetPosition, in: Self.presetRange, step: 1) {
            Text("Maximum size")
        } minimumValueLabel: {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Smaller")
        } maximumValueLabel: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Largest")
        }
        .labelsHidden()
        .controlSize(.small)
    }

    private var caption: String {
        switch sizeLimit {
        case .unlimited: "Grows to the largest size macOS allows."
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
