import SwiftUI

/// A scrolling, selectable view of command or server output that follows new lines.
struct LogView: View {
    let lines: [String]

    /// Only the tail is drawn. Long pip installs print thousands of lines and
    /// SwiftUI slows down badly laying them all out.
    private static let visibleLines = 250

    var body: some View {
        let tail = Array(lines.suffix(Self.visibleLines))
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(tail.enumerated()), id: \.offset) { i, line in
                        Text(line)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(i)
                    }
                }
                .textSelection(.enabled)
                .padding(8)
            }
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
            .onChange(of: lines.count) { _, _ in
                proxy.scrollTo(tail.count - 1, anchor: .bottom)
            }
        }
    }
}
