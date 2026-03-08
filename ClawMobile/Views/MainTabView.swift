import SwiftUI

struct MainTabView: View {
    @Environment(L10n.self) private var l10n
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(l10n.tabSessions, systemImage: "bubble.left.and.bubble.right.fill", value: 0) {
                SessionListView()
            }

            Tab(l10n.tabTasks, systemImage: "checklist", value: 1) {
                TaskListView()
            }

            Tab(l10n.tabMemory, systemImage: "brain.head.profile.fill", value: 2) {
                MemoryListView()
            }

            Tab(l10n.tabSettings, systemImage: "gear", value: 3) {
                SettingsView()
            }
        }
        .tint(.accentColor)
    }
}
