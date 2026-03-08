import SwiftUI

struct SessionListView: View {
    @State private var viewModel = SessionsViewModel()
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                // Agent status header
                if let agent = appState.connectedAgent {
                    Section {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(agent.status == .online ? Color.green : Color.orange)
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(agent.name)
                                    .font(.headline)
                                Text(agent.model)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(agent.status.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(agent.status == .online ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                .foregroundStyle(agent.status == .online ? .green : .orange)
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Sessions
                Section("Sessions") {
                    ForEach(viewModel.sessions) { session in
                        NavigationLink {
                            ChatView(session: session)
                        } label: {
                            SessionRowView(session: session)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteSession(viewModel.sessions[index])
                        }
                    }
                }
            }
            .navigationTitle("Claw Mobile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingNewSession = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .alert("New Session", isPresented: $viewModel.showingNewSession) {
                TextField("Session name", text: $viewModel.newSessionName)
                Button("Create") { viewModel.createSession() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a name for the new session")
            }
        }
    }
}
