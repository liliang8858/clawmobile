import SwiftUI

struct ChatView: View {
    let session: Session
    @State private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages
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

            // Approval banner
            if viewModel.showApproval, let pending = viewModel.pendingApproval {
                ApprovalView(
                    message: pending,
                    onApprove: { viewModel.approveToolCall() },
                    onDeny: { viewModel.denyToolCall() }
                )
            }

            Divider()

            // Input bar
            HStack(spacing: 12) {
                TextField("Message agent...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($isInputFocused)

                Button {
                    viewModel.sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundStyle(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isStreaming ? .gray : .accentColor)
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isStreaming)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Clear Chat", systemImage: "trash") {
                        viewModel.messages.removeAll()
                    }
                    Button("Session Info", systemImage: "info.circle") { }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
