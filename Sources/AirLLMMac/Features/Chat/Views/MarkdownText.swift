import SwiftUI

/// Just enough Markdown for chat replies. Fenced code gets its own box and the
/// rest goes through Foundation's inline Markdown with line breaks kept.
///
/// A full Markdown renderer would be nicer, but this has no dependencies and
/// copes with half-finished text while a reply is still streaming in.
struct MarkdownText: View {
    let text: String
    init(_ text: String) { self.text = text }

    enum Block: Equatable {
        case prose(String)
        case code(language: String, body: String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(Self.blocks(in: text).enumerated()), id: \.offset) { _, block in
                switch block {
                case .prose(let prose):
                    Text(Self.attributed(prose))
                        .textSelection(.enabled)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                case .code(let language, let body):
                    CodeBlock(language: language, code: body)
                }
            }
        }
    }

    /// Splits text on ``` fences. An unclosed fence still counts as code, which
    /// keeps a code block stable while it streams.
    static func blocks(in text: String) -> [Block] {
        var blocks: [Block] = []
        var prose: [String] = []
        var code: [String]?
        var language = ""
        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                if let finished = code {
                    blocks.append(.code(language: language, body: finished.joined(separator: "\n")))
                    code = nil
                } else {
                    if !prose.isEmpty { blocks.append(.prose(prose.joined(separator: "\n"))) }
                    prose = []
                    language = trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces)
                    code = []
                }
            } else if code != nil {
                code?.append(line)
            } else {
                prose.append(line)
            }
        }
        if let code { blocks.append(.code(language: language, body: code.joined(separator: "\n"))) }
        if !prose.isEmpty { blocks.append(.prose(prose.joined(separator: "\n"))) }
        return blocks
    }

    /// Inline Markdown doesn't handle lists or headings, so those are rewritten
    /// first: list items get a bullet and headings turn bold.
    static func attributed(_ prose: String) -> AttributedString {
        let lines = prose.components(separatedBy: "\n").map { line -> String in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                let indent = line.prefix(while: { $0 == " " }).count / 2
                return String(repeating: "    ", count: indent) + "•  " + trimmed.dropFirst(2)
            }
            if trimmed.hasPrefix("#") {
                return "**" + trimmed.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces) + "**"
            }
            return line
        }
        let joined = lines.joined(separator: "\n")
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: joined, options: options)) ?? AttributedString(joined)
    }
}
