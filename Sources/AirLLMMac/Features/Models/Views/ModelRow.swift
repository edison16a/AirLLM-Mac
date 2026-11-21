import SwiftUI

/// One model in the picker: logo, name and blurb on the left, the fit verdict,
/// speed and disk on the right. The selected row also explains its verdict.
struct ModelRow: View {
    let model: CatalogModel
    let report: FitReport
    let info: SystemInfo
    let selected: Bool
    let loaded: Bool
    var unsupported = false
    @State private var hovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ProviderLogo(name: model.provider, size: 30).padding(.top, 2)
            VStack(alignment: .leading, spacing: 6) {
                title
                Text(model.blurb)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if !unsupported {
                    MemoryBar(sizeGB: model.sizeGB, ramGB: info.ramGB, level: report.level)
                    if selected {
                        Text(report.explanation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Spacer(minLength: 8)
            if unsupported {
                Text("Not supported").font(.caption.weight(.medium)).foregroundStyle(.red)
            } else {
                verdict
            }
        }
        .padding(12)
        .contentShape(Rectangle())
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(fill))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(selected ? Color.accentColor.opacity(0.5) : .clear, lineWidth: 1))
        .onHover { hovering = $0 }
        .opacity(report.level.canRun || unsupported ? 1 : 0.7)
        .animation(.easeOut(duration: 0.15), value: selected)
    }

    private var fill: Color {
        if selected { return Color.accentColor.opacity(0.10) }
        return hovering ? Color.primary.opacity(0.04) : .clear
    }

    private var title: some View {
        HStack(spacing: 6) {
            Text(model.name).font(.body.weight(.medium))
            if !model.params.isEmpty { Text(model.params).foregroundStyle(.secondary) }
            if model.gated {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .help("Gated: needs a Hugging Face token and accepting the license on huggingface.co")
            }
            if loaded {
                Tag(text: "In use", color: .accentColor)
            } else if report.downloaded {
                Tag(text: "Downloaded", color: .secondary)
            }
        }
    }

    private var verdict: some View {
        VStack(alignment: .trailing, spacing: 5) {
            HStack(spacing: 5) {
                Circle().fill(report.level.color).frame(width: 7, height: 7)
                Text(report.level.label)
            }
            .font(.caption.weight(.medium))
            if report.level.canRun {
                Text((report.calibrated ? "" : "about ") + Format.speed(secondsPerToken: report.secondsPerToken))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .help(report.calibrated ? "Measured on this Mac" : "Estimated from size. It gets exact after you use the model.")
            }
            Text(report.diskNeededGB > 0 ? "needs \(Format.gigabytes(report.diskNeededGB)) disk" : "ready on disk")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(minWidth: 130, alignment: .trailing)
    }
}
