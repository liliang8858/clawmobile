import SwiftUI

struct ConnectView: View {
    @Environment(AppState.self) private var appState
    @Environment(L10n.self) private var l10n
    @State private var token = ""
    @State private var showTokenInput = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.accentColor.opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)

                        Image(systemName: "cpu")
                            .font(.system(size: 60, weight: .light))
                            .foregroundStyle(Color.accentColor)
                    }

                    Text(l10n.appName)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(l10n.appSlogan)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 16) {
                    if appState.isConnecting {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.accentColor)
                        Text(l10n.connecting)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else if showTokenInput {
                        VStack(spacing: 12) {
                            TextField(l10n.agentURLOrToken, text: $token)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            Button {
                                appState.connect(token: token.isEmpty ? "demo" : token)
                            } label: {
                                Text(l10n.connect)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button(l10n.back) {
                                withAnimation { showTokenInput = false }
                            }
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        }
                        .padding(.horizontal)
                    } else {
                        Button {
                            appState.connect(token: "demo-token")
                        } label: {
                            Label(l10n.scanQR, systemImage: "qrcode.viewfinder")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        Button {
                            withAnimation { showTokenInput = true }
                        } label: {
                            Label(l10n.enterToken, systemImage: "keyboard")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        Button {
                            appState.connect(token: "demo")
                        } label: {
                            Text(l10n.tryDemo)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }

                Spacer()
                    .frame(height: 40)
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }
}
