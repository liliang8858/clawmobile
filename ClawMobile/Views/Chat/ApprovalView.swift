import SwiftUI

struct ApprovalView: View {
    let message: Message
    let onApprove: () -> Void
    let onDeny: () -> Void
    @Environment(L10n.self) private var l10n

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
                Text(l10n.agentWantsToRun)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            if let toolCall = message.toolCall {
                HStack {
                    Text(toolCall.command)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 12) {
                Button {
                    onDeny()
                } label: {
                    Text(l10n.deny)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.2))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    onApprove()
                } label: {
                    Text(l10n.approve)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}
