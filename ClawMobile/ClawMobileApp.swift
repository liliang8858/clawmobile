import SwiftUI

@main
struct ClawMobileApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isConnected {
                    MainTabView()
                } else {
                    ConnectView()
                }
            }
            .environment(appState)
            .preferredColorScheme(.dark)
        }
    }
}
