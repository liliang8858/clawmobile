import SwiftUI

struct ChatView: View {
    let session: Session
    @State private var viewModel = ChatViewModel()
    @Environment(L10n.self) private var l10n
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                    }
                }
            }

            if viewModel.showApproval, let pending = viewModel.pendingApproval {
                ApprovalView(
                    message: pending,
                    onApprove: { viewModel.approveToolCall() },
                    onDeny: { viewModel.denyToolCall() }
                )
            }

            Divider()

            HStack(spacing: 12) {
                TextField(l10n.messageAgent, text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($isInputFocused)

                if viewModel.isStreaming {
                    Button {
                        viewModel.abortChat()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                    }
                } else {
                    Button {
                        viewModel.sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : Color.accentColor)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(l10n.clearChat, systemImage: "trash") {
                        viewModel.messages.removeAll()
                    }
                    Button(l10n.sessionInfo, systemImage: "info.circle") { }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            viewModel.setup(sessionKey: session.id)
        }
    }
}
