import SwiftUI

struct StatusHeaderView: View {
    let engine: CursorEngine

    var body: some View {
        HStack(spacing: 12) {
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
        case .atMaximum: return "Maximum size · \(scaleText)"
        case .shrinking: return "Shrinking · \(scaleText)"
        }
    }
}
