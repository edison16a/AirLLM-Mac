import SwiftUI

/// A setting's name and info button on the left, its control on the right.
struct SettingRow<Content: View>: View {
    let title: String
    let info: String
    @ViewBuilder let content: Content

    init(_ title: String, info: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.info = info
        self.content = content()
    }

    var body: some View {
        LabeledContent {
            content
        } label: {
            HStack(spacing: 6) {
                Text(title)
                InfoButton(info)
            }
        }
    }
}

/// A button with an info button beside it, for one-off actions.
struct ActionRow: View {
    let title: String
    let info: String?
    let action: () -> Void

    init(_ title: String, info: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.info = info
        self.action = action
    }

    var body: some View {
        HStack {
            Button(title, action: action)
            if let info { InfoButton(info) }
            Spacer()
        }
    }
}
