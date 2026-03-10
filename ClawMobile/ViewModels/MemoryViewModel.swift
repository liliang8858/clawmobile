import SwiftUI

@MainActor
@Observable
final class MemoryViewModel {
    var items: [MemoryItem] = []
    var isLoading = false

    private let service = OpenClawService.shared

    var pinnedItems: [MemoryItem] { items.filter { $0.isPinned } }
    var facts: [MemoryItem] { items.filter { $0.category == .fact && !$0.isPinned } }
    var preferences: [MemoryItem] { items.filter { $0.category == .preference && !$0.isPinned } }
    var knowledge: [MemoryItem] { items.filter { $0.category == .knowledge && !$0.isPinned } }

    func loadItems() {
        guard service.isConnected else { return }
        isLoading = true
        Task {
            do {
                // Fetch MEMORY.md content and parse into items
                let content = try await service.getAgentFile(name: "MEMORY.md")
                if !content.isEmpty {
                    items = parseMemoryMd(content)
                }

                // Also fetch file list to show as knowledge items
                let files = try await service.memoryList()
                for file in files {
                    let name = file["name"] as? String ?? ""
                    if name == "MEMORY.md" { continue } // Already parsed above
                    let size = file["size"] as? Int ?? 0
                    items.append(MemoryItem(
                        id: "file-\(name)",
                        content: "\(name) (\(size) bytes)",
                        category: .knowledge,
                        createdAt: Date(),
                        isPinned: false
                    ))
                }
            } catch {}
            isLoading = false
        }
    }

    /// Parse MEMORY.md markdown into MemoryItem entries
    private func parseMemoryMd(_ content: String) -> [MemoryItem] {
        var result: [MemoryItem] = []
        let lines = content.components(separatedBy: "\n")
        var currentSection = ""
        var currentBlock = ""

        for line in lines {
            if line.hasPrefix("## ") {
                // Flush previous block
                if !currentBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result.append(MemoryItem(
                        id: UUID().uuidString,
                        content: currentBlock.trimmingCharacters(in: .whitespacesAndNewlines),
                        category: categoryFor(section: currentSection),
                        createdAt: Date(),
                        isPinned: false
                    ))
                }
                currentSection = String(line.dropFirst(3))
                currentBlock = ""
            } else if line.hasPrefix("# ") {
                // Top-level heading, skip
                continue
            } else {
                currentBlock += line + "\n"
            }
        }

        // Flush last block
        if !currentBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.append(MemoryItem(
                id: UUID().uuidString,
                content: currentBlock.trimmingCharacters(in: .whitespacesAndNewlines),
                category: categoryFor(section: currentSection),
                createdAt: Date(),
                isPinned: false
            ))
        }

        return result
    }

    private func categoryFor(section: String) -> MemoryItem.MemoryCategory {
        let lower = section.lowercased()
        if lower.contains("偏好") || lower.contains("prefer") || lower.contains("习惯") {
            return .preference
        } else if lower.contains("事实") || lower.contains("fact") || lower.contains("信息") {
            return .fact
        }
        return .knowledge
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
