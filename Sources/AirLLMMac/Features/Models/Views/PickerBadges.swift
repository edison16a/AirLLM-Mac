import SwiftUI

/// A small capsule with an icon and a number, like "16 GB memory".
struct MacStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(.secondary)
            Text(value).fontWeight(.medium)
            Text(label).foregroundStyle(.secondary)
        }
        .font(.callout)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.05), in: Capsule())
    }
}

/// A tiny colored label, like "In use" or "Downloaded".
struct Tag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }
}

/// A model's size drawn against this Mac's memory, so "will it fit" reads at a glance.
struct MemoryBar: View {
    let sizeGB: Double
    let ramGB: Double
    let level: FitLevel

    var body: some View {
        HStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.07))
                    Capsule().fill(level.color.opacity(0.65))
                        .frame(width: max(3, geometry.size.width * min(sizeGB / ramGB, 1)))
                }
            }
            .frame(width: 150, height: 4)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var caption: String {
        if sizeGB > ramGB {
            return "\(Format.gigabytes(sizeGB)), \(String(format: "%.0f", sizeGB / ramGB))x your memory"
        }
        return "\(Format.gigabytes(sizeGB)) of \(Format.gigabytes(ramGB)) memory"
    }
}
