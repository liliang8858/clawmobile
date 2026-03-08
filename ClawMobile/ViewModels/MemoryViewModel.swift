import SwiftUI

@MainActor
@Observable
final class MemoryViewModel {
    var items: [MemoryItem] = []

    var pinnedItems: [MemoryItem] { items.filter { $0.isPinned } }
    var facts: [MemoryItem] { items.filter { $0.category == .fact && !$0.isPinned } }
    var preferences: [MemoryItem] { items.filter { $0.category == .preference && !$0.isPinned } }
    var knowledge: [MemoryItem] { items.filter { $0.category == .knowledge && !$0.isPinned } }

    func loadItems(isDemoMode: Bool = false) {
        if isDemoMode {
            items = MockService.shared.memoryItems
        }
        // Real OpenClaw memory is managed via MEMORY.md on the agent side.
        // For now, real mode shows empty (future: fetch via agents.files.get)
    }

    func togglePin(_ item: MemoryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isPinned.toggle()
        }
    }

    func deleteItem(_ item: MemoryItem) {
        items.removeAll { $0.id == item.id }
    }

    func addItem(content: String, category: MemoryItem.MemoryCategory) {
        let item = MemoryItem(
            id: UUID().uuidString,
            content: content,
            category: category,
            createdAt: Date(),
            isPinned: false
        )
        items.insert(item, at: 0)
    }
}
