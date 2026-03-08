import SwiftUI

struct MessageBubble: View {
    let message: Message
    @Environment(L10n.self) private var l10n

    var body: some View {
        switch message.role {
        case .user:
            userBubble
        case .agent:
            agentBubble
        case .tool:
            if let toolCall = message.toolCall {
                ToolCallView(toolCall: toolCall)
            }
        case .system:
            systemBubble
        }
    }

    private var userBubble: some View {
        HStack {
            Spacer(minLength: 60)
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var agentBubble: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                    Text(l10n.agent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(message.content + (message.isStreaming ? " |" : ""))
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if !message.isStreaming {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 60)
        }
    }

    private var systemBubble: some View {
        Text(message.content)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
    }
}
