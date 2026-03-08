import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Sessions", systemImage: "bubble.left.and.bubble.right.fill", value: 0) {
                SessionListView()
            }

            Tab("Tasks", systemImage: "checklist", value: 1) {
                TaskListView()
            }

            Tab("Memory", systemImage: "brain.head.profile.fill", value: 2) {
                MemoryListView()
            }

            Tab("Settings", systemImage: "gear", value: 3) {
                SettingsView()
            }
        }
        .tint(.accentColor)
    }
}
