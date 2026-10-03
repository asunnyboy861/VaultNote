import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject var authManager: VaultAuthManager
    @EnvironmentObject var decoyManager: DecoyModeManager
    @EnvironmentObject var selfDestructManager: SelfDestructManager
    @State private var isAuthenticating = false
    @State private var showPasswordInput = false
    @State private var password = ""
    @State private var passwordError = ""
    @State private var showPasswordError = false
    @State private var shieldPulse = false
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                shieldHero

                VStack(spacing: 8) {
                    Text("SealNotes")
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    Text("Your Privacy, Protected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if selfDestructManager.isEnabled && selfDestructManager.remainingAttempts < selfDestructManager.attemptThreshold {
                    attemptsRemainingView
                }

                Spacer()

                unlockButtons

                if showPasswordInput {
                    passwordInputSection
                }

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .alert("Access Denied", isPresented: $showPasswordError) {
            Button("OK", role: .cancel) { password = "" }
        } message: {
            Text(passwordError)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                shieldPulse = true
                glowOpacity = 0.6
            }
        }
    }

    var shieldHero: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.blue.opacity(glowOpacity), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(shieldPulse ? 1.1 : 1.0)

            Circle()
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                .frame(width: 130, height: 130)

            Image(systemName: "shield.checkered")
                .font(.system(size: 56))
                .foregroundStyle(.blue)
                .shadow(color: .blue.opacity(0.4), radius: 12)
        }
    }

    var attemptsRemainingView: some View {
        VStack(spacing: 6) {
            Text("\(selfDestructManager.remainingAttempts) attempts remaining")
                .font(.caption.weight(.medium))
                .foregroundStyle(selfDestructManager.remainingAttempts <= 3 ? .red : .orange)

            ProgressView(
                value: Double(selfDestructManager.remainingAttempts),
                total: Double(selfDestructManager.attemptThreshold)
            )
            .tint(selfDestructManager.remainingAttempts <= 3 ? .red : .orange)
            .frame(width: 160)
        }
    }

    var unlockButtons: some View {
        VStack(spacing: 14) {
            Button {
                Task {
                    isAuthenticating = true
                    _ = await authManager.authenticate()
                    isAuthenticating = false
                }
            } label: {
                HStack(spacing: 10) {
                    if isAuthenticating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: authManager.biometricIcon)
                    }
                    Text(isAuthenticating ? "Authenticating..." : "Unlock with Biometrics")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: 280)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(isAuthenticating)

            if decoyManager.isDecoyModeEnabled {
                Button {
                    withAnimation(.spring(response: 0.4)) { showPasswordInput.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "keyboard")
                        Text("Enter Password")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
                }
            }
        }
    }

    var passwordInputSection: some View {
        VStack(spacing: 12) {
            SecureField("Enter Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 280)

            Button("Unlock with Password") {
                let result = authManager.authenticateWithPassword(
                    password,
                    decoyManager: decoyManager,
                    selfDestructManager: selfDestructManager
                )

                switch result {
                case .real, .decoy:
                    break
                case .failed:
                    passwordError = "Incorrect password."
                    if selfDestructManager.isEnabled {
                        passwordError += " \(selfDestructManager.remainingAttempts) attempts remaining."
                    }
                    showPasswordError = true
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    LockScreenView()
        .environmentObject(VaultAuthManager())
        .environmentObject(DecoyModeManager())
        .environmentObject(SelfDestructManager())
}
