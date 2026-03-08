import SwiftUI

struct MemoryListView: View {
    @State private var viewModel = MemoryViewModel()
    @State private var showingAddMemory = false
    @State private var newContent = ""
    @State private var newCategory: MemoryItem.MemoryCategory = .fact

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.pinnedItems.isEmpty {
                    Section("Pinned") {
                        ForEach(viewModel.pinnedItems) { item in
                            memoryRow(item)
                        }
                    }
                }

                if !viewModel.facts.isEmpty {
                    Section("Facts") {
                        ForEach(viewModel.facts) { item in
                            memoryRow(item)
                        }
                    }
                }

                if !viewModel.preferences.isEmpty {
                    Section("Preferences") {
                        ForEach(viewModel.preferences) { item in
                            memoryRow(item)
                        }
                    }
                }

                if !viewModel.knowledge.isEmpty {
                    Section("Knowledge") {
                        ForEach(viewModel.knowledge) { item in
                            memoryRow(item)
                        }
                    }
                }
            }
            .navigationTitle("Memory")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddMemory = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .alert("Add Memory", isPresented: $showingAddMemory) {
                TextField("Content", text: $newContent)
                Button("Add") {
                    if !newContent.isEmpty {
                        viewModel.addItem(content: newContent, category: newCategory)
                        newContent = ""
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a new memory item")
            }
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
                    Text(item.category.label)
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
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                viewModel.togglePin(item)
            } label: {
                Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
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
