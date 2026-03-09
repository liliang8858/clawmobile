import SwiftUI

struct SessionListView: View {
    @State private var viewModel = SessionsViewModel()
    @Environment(AppState.self) private var appState
    @Environment(L10n.self) private var l10n

    var body: some View {
        NavigationStack {
            List {
                if let agent = appState.connectedAgent {
                    Section {
                        HStack(spacing: 12) {
                            if let discovered = appState.discoveredAgent {
                                Text(discovered.avatar)
                                    .font(.title2)
                            } else {
                                Circle()
                                    .fill(agent.status == .online ? Color.green : Color.orange)
                                    .frame(width: 10, height: 10)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(agent.name)
                                    .font(.headline)
                                Text(agent.model)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(l10n.agentStatus(agent.status))
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

                Section(l10n.sessions) {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
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
            }
            .navigationTitle(l10n.appName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingNewSession = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .refreshable {
                viewModel.loadSessions()
            }
            .alert(l10n.newSession, isPresented: $viewModel.showingNewSession) {
                TextField(l10n.sessionName, text: $viewModel.newSessionName)
                Button(l10n.create) { viewModel.createSession() }
                Button(l10n.cancel, role: .cancel) { }
            } message: {
                Text(l10n.enterSessionName)
            }
            .onAppear {
                viewModel.loadSessions()
            }
        }
    }
}
