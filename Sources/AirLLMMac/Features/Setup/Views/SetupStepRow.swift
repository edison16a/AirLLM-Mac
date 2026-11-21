import SwiftUI

/// One checklist row: a status icon, the step name and what it's doing.
struct SetupStepRow: View {
    let step: SetupStep

    var body: some View {
        HStack(spacing: 14) {
            icon
                .font(.system(size: 18))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .fontWeight(step.state == .running ? .semibold : .regular)
                    .foregroundStyle(step.state == .pending ? .secondary : .primary)
                Text(step.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .animation(.easeOut(duration: 0.2), value: step.state)
    }

    @ViewBuilder private var icon: some View {
        switch step.state {
        case .pending:
            Circle().stroke(.quaternary, lineWidth: 1.5).frame(width: 18, height: 18)
        case .running:
            ProgressView().controlSize(.small)
        case .done, .skipped:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        }
    }
}
