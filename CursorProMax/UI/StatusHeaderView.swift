import SwiftUI

struct StatusHeaderView: View {
    let engine: CursorEngine

    var body: some View {
        HStack(spacing: 12) {
            CursorPreviewBadge(scale: engine.scale, isActive: engine.phase != .idle)
            VStack(alignment: .leading, spacing: 2) {
                Text("CursorProMax")
                    .font(.title3.weight(.semibold))
                Text(statusText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var statusText: String {
        let scaleText = "\(engine.scale.formatted(.number.precision(.fractionLength(1))))×"
        switch engine.phase {
        case .idle: return "Shake the pointer to supersize it"
        case .growing: return "Growing · \(scaleText)"
        case .atMaximum: return engine.isCoveringScreen ? "Covering the screen · \(scaleText)" : "Maximum size · \(scaleText)"
        case .shrinking: return "Shrinking · \(scaleText)"
        }
    }
}

struct CursorPreviewBadge: View {
    static let diameter: CGFloat = 46

    let scale: Double
    let isActive: Bool

    var body: some View {
        Image(systemName: "cursorarrow")
            .font(.system(size: 17, weight: .semibold))
            .scaleEffect(previewScale, anchor: .center)
            .foregroundStyle(isActive ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .frame(width: Self.diameter, height: Self.diameter)
            .glassEffect(isActive ? .regular.tint(.accentColor) : .regular, in: .circle)
            .animation(.smooth(duration: 0.2), value: isActive)
    }

    private var previewScale: CGFloat {
        CGFloat(min(1 + log2(max(scale, 1)) * 0.12, 1.6))
    }
}
