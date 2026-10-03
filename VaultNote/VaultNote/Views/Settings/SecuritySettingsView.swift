import SwiftUI

struct SecuritySettingsView: View {
    @ObservedObject var decoyManager: DecoyModeManager
    @ObservedObject var selfDestructManager: SelfDestructManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage("screenshotProtectionEnabled") private var screenshotProtectionEnabled = true
    @AppStorage("selfDestructEnabled") private var selfDestructEnabled = false
    @AppStorage("selfDestructAttempts") private var selfDestructAttempts = 10

    @State private var showingDecoySetup = false
    @State private var showingDisableDecoyConfirm = false
    @State private var showingEmergencyPasswordSheet = false
    @State private var emergencyPassword = ""
    @State private var confirmEmergencyPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            decoyModeSection
            selfDestructSection
            screenshotProtectionSection
            emergencyPasswordSection
            securityLogSection
        }
        .navigationTitle("Security")
        .sheet(isPresented: $showingDecoySetup) {
            DecoySetupView(decoyManager: decoyManager)
        }
        .sheet(isPresented: $showingEmergencyPasswordSheet) {
            emergencyPasswordSheet
        }
        .alert("Disable Decoy Mode?", isPresented: $showingDisableDecoyConfirm) {
            Button("Disable", role: .destructive) {
                decoyManager.disableDecoyMode()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the decoy vault and its password. Your real notes will not be affected.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var decoyModeSection: some View {
        Section {
            if decoyManager.isDecoyModeEnabled {
                HStack {
                    Label("Decoy Mode", systemImage: "theatermasks")
                    Spacer()
                    Text("Active")
                        .foregroundStyle(.green)
                        .font(.subheadline.weight(.medium))
                }

                Button {
                    showingDisableDecoyConfirm = true
                } label: {
                    Label("Disable Decoy Mode", systemImage: "xmark.shield")
                        .foregroundStyle(.red)
                }
            } else {
                Button {
                    showingDecoySetup = true
                } label: {
                    Label("Set Up Decoy Mode", systemImage: "theatermasks")
                }
            }
        } header: {
            Text("Decoy Mode")
        } footer: {
            Text("Create a fake vault with a decoy password. If someone forces you to unlock, use the decoy password to protect your real notes.")
        }
    }

    private var selfDestructSection: some View {
        Section {
            Toggle(isOn: $selfDestructEnabled) {
                Label("Self-Destruct", systemImage: "exclamationmark.triangle")
            }
            .onChange(of: selfDestructEnabled) {
                selfDestructManager.setEnabled(selfDestructEnabled)
            }

            if selfDestructEnabled {
                Stepper("Failed Attempts: \(selfDestructAttempts)", value: $selfDestructAttempts, in: 3...20)
                    .onChange(of: selfDestructAttempts) {
                        selfDestructManager.setAttemptThreshold(selfDestructAttempts)
                    }

                if selfDestructManager.remainingAttempts < selfDestructAttempts {
                    HStack {
                        Text("Remaining Attempts")
                        Spacer()
                        Text("\(selfDestructManager.remainingAttempts)")
                            .foregroundStyle(selfDestructManager.remainingAttempts <= 3 ? .red : .secondary)
                    }
                }

                Text("All notes will be permanently deleted after \(selfDestructAttempts) failed unlock attempts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Self-Destruct")
        } footer: {
            Text("Automatically erase all data after too many failed password attempts. This cannot be undone.")
        }
    }

    private var screenshotProtectionSection: some View {
        Section {
            Toggle(isOn: $screenshotProtectionEnabled) {
                Label("Screenshot Protection", systemImage: "eye.slash")
            }
        } header: {
            Text("Screen Capture")
        } footer: {
            Text("Hide content when screen recording or screenshots are detected.")
        }
    }

    private var emergencyPasswordSection: some View {
        Section {
            if selfDestructManager.hasEmergencyPassword {
                HStack {
                    Label("Emergency Password", systemImage: "flame")
                    Spacer()
                    Text("Set")
                        .foregroundStyle(.green)
                        .font(.subheadline.weight(.medium))
                }

                Button {
                    selfDestructManager.clearEmergencyPassword()
                } label: {
                    Label("Remove Emergency Password", systemImage: "flame.slash")
                        .foregroundStyle(.red)
                }
            } else {
                Button {
                    showingEmergencyPasswordSheet = true
                } label: {
                    Label("Set Emergency Password", systemImage: "flame")
                }
            }
        } header: {
            Text("Emergency Password")
        } footer: {
            Text("Entering this password will immediately erase all your data. Use only in extreme situations.")
        }
    }

    private var emergencyPasswordSheet: some View {
        NavigationStack {
            Form {
                Section("Emergency Password") {
                    SecureField("Password", text: $emergencyPassword)
                    SecureField("Confirm Password", text: $confirmEmergencyPassword)
                }

                Section {
                    Button("Set Emergency Password") {
                        guard emergencyPassword.count >= 4 else {
                            errorMessage = "Password must be at least 4 characters."
                            showError = true
                            return
                        }
                        guard emergencyPassword == confirmEmergencyPassword else {
                            errorMessage = "Passwords do not match."
                            showError = true
                            return
                        }
                        _ = selfDestructManager.setEmergencyPassword(emergencyPassword)
                        emergencyPassword = ""
                        confirmEmergencyPassword = ""
                        showingEmergencyPasswordSheet = false
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Emergency Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        emergencyPassword = ""
                        confirmEmergencyPassword = ""
                        showingEmergencyPasswordSheet = false
                    }
                }
            }
        }
    }

    private var securityLogSection: some View {
        Section {
            NavigationLink {
                SecurityLogView()
            } label: {
                Label("Security Log", systemImage: "list.bullet.clipboard")
            }

            if !SecurityAuditLogger.shared.criticalEvents.isEmpty {
                HStack {
                    Label("Warnings", systemImage: "exclamationmark.triangle")
                    Spacer()
                    Text("\(SecurityAuditLogger.shared.criticalEvents.count)")
                        .foregroundStyle(.orange)
                        .font(.subheadline.weight(.medium))
                }
            }
        } header: {
            Text("Audit")
        }
    }
}
