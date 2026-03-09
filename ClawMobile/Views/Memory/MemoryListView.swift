import SwiftUI

struct MemoryListView: View {
    @State private var viewModel = MemoryViewModel()
    @Environment(L10n.self) private var l10n
    @State private var showingAddMemory = false
    @State private var newContent = ""
    @State private var newCategory: MemoryItem.MemoryCategory = .fact

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.pinnedItems.isEmpty {
                    Section(l10n.pinned) {
                        ForEach(viewModel.pinnedItems) { item in
                            memoryRow(item)
                        }
                    }
                }

                if !viewModel.facts.isEmpty {
                    Section(l10n.facts) {
                        ForEach(viewModel.facts) { item in
                            memoryRow(item)
                        }
                    }
                }

                if !viewModel.preferences.isEmpty {
                    Section(l10n.preferences) {
                        ForEach(viewModel.preferences) { item in
                            memoryRow(item)
                        }
                    }
                }

                if !viewModel.knowledge.isEmpty {
                    Section(l10n.knowledge) {
                        ForEach(viewModel.knowledge) { item in
                            memoryRow(item)
                        }
                    }
                }
            }
            .navigationTitle(l10n.memory)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddMemory = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .alert(l10n.addMemory, isPresented: $showingAddMemory) {
                TextField(l10n.content, text: $newContent)
                Button(l10n.add) {
                    if !newContent.isEmpty {
                        viewModel.addItem(content: newContent, category: newCategory)
                        newContent = ""
                    }
                }
                Button(l10n.cancel, role: .cancel) { }
            } message: {
                Text(l10n.enterMemoryItem)
            }
            .onAppear {
                viewModel.loadItems()
            }
        }
    }

    private func categoryLabel(_ category: MemoryItem.MemoryCategory) -> String {
        switch category {
        case .fact: return l10n.factLabel
        case .preference: return l10n.preferenceLabel
        case .knowledge: return l10n.knowledgeLabel
        }
    }

    private func memoryRow(_ item: MemoryItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.icon)
                .font(.subheadline)
                .foregroundStyle(categoryColor(item.category))
                .frame(width: 28, height: 28)
                .background(categoryColor(item.category).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .font(.subheadline)

                HStack {
                    Text(categoryLabel(item.category))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor(item.category).opacity(0.15))
                        .foregroundStyle(categoryColor(item.category))
                        .clipShape(Capsule())

                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    Spacer()

                    Text(item.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteItem(item)
            } label: {
                Label(l10n.delete, systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                viewModel.togglePin(item)
            } label: {
                Label(item.isPinned ? l10n.unpin : l10n.pin, systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            .tint(.orange)
        }
    }

    private func categoryColor(_ category: MemoryItem.MemoryCategory) -> Color {
        switch category {
        case .fact: return .blue
        case .preference: return .pink
        case .knowledge: return .purple
        }
    }
}
