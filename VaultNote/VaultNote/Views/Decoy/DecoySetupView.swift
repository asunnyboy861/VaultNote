import SwiftUI

struct DecoySetupView: View {
    @ObservedObject var decoyManager: DecoyModeManager
    @Environment(\.dismiss) private var dismiss

    @State private var step = 1
    @State private var realPassword = ""
    @State private var confirmRealPassword = ""
    @State private var decoyPassword = ""
    @State private var confirmDecoyPassword = ""
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                stepIndicator

                TabView(selection: $step) {
                    step1.tag(1)
                    step2.tag(2)
                    step3.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)
            }
            .padding()
            .navigationTitle("Decoy Mode Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { s in
                Circle()
                    .fill(s <= step ? Color.accentColor : Color(.separator))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var step1: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Set Your Real Password")
                .font(.title2.weight(.bold))

            Text("Use this password to access your actual private notes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("Real Password", text: $realPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Confirm Password", text: $confirmRealPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Spacer()

            Button("Continue") {
                if validateStep1() {
                    withAnimation { step = 2 }
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var step2: some View {
        VStack(spacing: 20) {
            Image(systemName: "theatermasks")
                .font(.system(size: 48))
                .foregroundStyle(Color.orange)

            Text("Set Your Decoy Password")
                .font(.title2.weight(.bold))

            Text("Use this password to open a fake vault with harmless notes. If someone forces you to unlock, use this password instead.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("Decoy Password", text: $decoyPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Confirm Decoy Password", text: $confirmDecoyPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Spacer()

            Button("Continue") {
                if validateStep2() {
                    withAnimation { step = 3 }
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var step3: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.green)

            Text("Setup Complete")
                .font(.title2.weight(.bold))

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24)
                    Text("Real password → Your private notes")
                        .font(.subheadline)
                }
                HStack {
                    Image(systemName: "theatermasks")
                        .foregroundStyle(Color.orange)
                        .frame(width: 24)
                    Text("Decoy password → Fake harmless notes")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Important: Remember both passwords. There is no way to recover them.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Activate Decoy Mode") {
                let success = decoyManager.setup(realPassword: realPassword, decoyPassword: decoyPassword)
                if success {
                    dismiss()
                } else {
                    errorMessage = "Setup failed. Please try again."
                    showError = true
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func validateStep1() -> Bool {
        guard realPassword.count >= 4 else {
            errorMessage = "Password must be at least 4 characters."
            showError = true
            return false
        }
        guard realPassword == confirmRealPassword else {
            errorMessage = "Passwords do not match."
            showError = true
            return false
        }
        return true
    }

    private func validateStep2() -> Bool {
        guard decoyPassword.count >= 4 else {
            errorMessage = "Decoy password must be at least 4 characters."
            showError = true
            return false
        }
        guard decoyPassword == confirmDecoyPassword else {
            errorMessage = "Decoy passwords do not match."
            showError = true
            return false
        }
        guard decoyPassword != realPassword else {
            errorMessage = "Decoy password must be different from your real password."
            showError = true
            return false
        }
        return true
    }
}
