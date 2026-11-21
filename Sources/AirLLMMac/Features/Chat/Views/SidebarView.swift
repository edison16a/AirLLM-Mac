import SwiftUI

/// The list of chats, with search and a right-click menu to rename, clear or delete.
struct SidebarView: View {
    @Environment(AppState.self) private var state
    @State private var search = ""
    @State private var renaming: Conversation.ID?
    @State private var renameText = ""

    var body: some View {
        @Bindable var library = state.library
        List(selection: $library.selection) {
            ForEach(library.search(search)) { conversation in
                SidebarRow(title: conversation.title,
                           isGenerating: state.chat.generatingConversation == conversation.id)
                    .tag(conversation.id)
                    .contextMenu { menu(for: conversation) }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $search, placement: .sidebar, prompt: "Search")
        .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 320)
        .toolbar {
            ToolbarItem {
                Button { library.newConversation() } label: { Image(systemName: "square.and.pencil") }
                    .help("New Chat (⌘N)")
            }
        }
        .alert("Rename Chat", isPresented: isRenaming) {
            TextField("Title", text: $renameText)
            Button("Rename") {
                if let id = renaming { library.rename(id, to: renameText) }
                renaming = nil
            }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
    }

    @ViewBuilder private func menu(for conversation: Conversation) -> some View {
        Button("Rename…") {
            renameText = conversation.title
            renaming = conversation.id
        }
        Button("Clear Messages") { state.library.clear(conversation.id) }
            .disabled(state.chat.isGenerating)
        Divider()
        Button("Delete", role: .destructive) { state.deleteConversation(conversation.id) }
    }

    private var isRenaming: Binding<Bool> {
        Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })
    }
}

private struct SidebarRow: View {
    let title: String
    let isGenerating: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(title).lineLimit(1)
            Spacer(minLength: 0)
            if isGenerating { ProgressView().controlSize(.mini) }
        }
        .padding(.vertical, 3)
    }
}
