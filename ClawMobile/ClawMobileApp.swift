import SwiftUI

@main
struct ClawMobileApp: App {
    @State private var appState = AppState()
    @State private var l10n = L10n.shared

    init() {
        NSLog("[ClawMobile] App init")
    }

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
            .environment(l10n)
            .preferredColorScheme(.dark)
            .task {
                NSLog("[ClawMobile] root .task fired, isConnected=\(appState.isConnected)")
                if !appState.isConnected && !appState.isScanning {
                    appState.scanForAgent()
                }
            }
        }
    }
}
