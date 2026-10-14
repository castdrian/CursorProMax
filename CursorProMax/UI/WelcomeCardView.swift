import SwiftUI

struct WelcomeCardView: View {
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text("Give it a shake")
                    .font(.body.weight(.semibold))
                Text("Shake your pointer back and forth quickly and keep going to watch it grow.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button("Got It", action: dismiss)
                .buttonStyle(.glass)
                .controlSize(.small)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(.accentColor.opacity(0.25)), in: .rect(cornerRadius: 14, style: .continuous))
    }
}
