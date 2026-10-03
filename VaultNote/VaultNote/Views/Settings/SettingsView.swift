import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: VaultAuthManager
    @EnvironmentObject var decoyManager: DecoyModeManager
    @EnvironmentObject var selfDestructManager: SelfDestructManager
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @AppStorage("cloudSyncEnabled") private var cloudSyncEnabled = false
    @AppStorage("screenshotProtectionEnabled") private var screenshotProtectionEnabled = true
    @AppStorage("shakeToDestroyEnabled") private var shakeToDestroyEnabled = false
    @AppStorage("defaultFolder") private var defaultFolder = ""
    @State private var showingContactSupport = false
    @State private var showOnboardingResetConfirm = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            Form {
                securitySection
                featuresSection
                syncSection
                shortcutsSection
                aboutSection
                supportSection
            }
            .navigationTitle("Settings")
        }
    }

    var securitySection: some View {
        Section("Security") {
            Toggle(isOn: $biometricLockEnabled) {
                Label("Biometric Lock", systemImage: authManager.biometricIcon)
            }

            if biometricLockEnabled {
                Button {
                    authManager.lock()
                } label: {
                    Label("Lock Now", systemImage: "lock.fill")
                        .foregroundStyle(.red)
                }
            }

            HStack {
                Label("Encryption", systemImage: "lock.shield.fill")
                Spacer()
                Text("AES-256-GCM")
                    .foregroundStyle(.secondary)
            }

            NavigationLink {
                SecuritySettingsView(
                    decoyManager: decoyManager,
                    selfDestructManager: selfDestructManager
                )
            } label: {
                Label("Advanced Security", systemImage: "shield.checkered")
            }
        }
    }

    var featuresSection: some View {
        Section("Features") {
            Toggle(isOn: $screenshotProtectionEnabled) {
                Label("Screenshot Protection", systemImage: "camera.fill")
            }

            Toggle(isOn: $shakeToDestroyEnabled) {
                Label("Shake-to-Destroy", systemImage: "iphone.radiowaves.left.and.right")
            }

            if shakeToDestroyEnabled {
                Text("Shake your device in an emergency to trigger data wipe")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            NavigationLink {
                SecureCardListView()
            } label: {
                Label("Secure Cards", systemImage: "creditcard")
            }

            NavigationLink {
                VoiceMemoListView()
            } label: {
                Label("Voice Memos", systemImage: "mic")
            }

            NavigationLink {
                SecureFileListView()
            } label: {
                Label("Secure Files", systemImage: "doc.lock")
            }
        }
    }

    var syncSection: some View {
        Section("Sync & Backup") {
            Toggle(isOn: $cloudSyncEnabled) {
                Label("iCloud Sync", systemImage: "icloud")
            }
            .onChange(of: cloudSyncEnabled) {
                if cloudSyncEnabled {
                    cloudSyncEnabled = true
                }
            }

            if cloudSyncEnabled {
                Text("Notes will sync across your devices via iCloud with end-to-end encryption")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("All data is stored locally on this device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var shortcutsSection: some View {
        Section("Shortcuts") {
            Link(destination: URL(string: "shortcuts://")!) {
                Label("Siri Shortcuts", systemImage: "waveform.circle")
            }

            Button {
                showOnboardingResetConfirm = true
            } label: {
                Label("Replay Welcome", systemImage: "hand.wave")
            }
        }
        .alert("Replay Welcome Screen?", isPresented: $showOnboardingResetConfirm) {
            Button("Replay", role: .destructive) {
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The welcome screen will appear next time you launch the app.")
        }
    }

    var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("License")
                Spacer()
                Text("One-time Purchase")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://github.com/glushchenko/fsnotes")!) {
                HStack {
                    Text("Built with open source")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    var supportSection: some View {
        Section("Support") {
            Button {
                showingContactSupport = true
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }

            Link(destination: URL(string: "https://asunnyboy861.github.io/VaultNote-pages/privacy.html")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }

            Link(destination: URL(string: "https://asunnyboy861.github.io/VaultNote-pages/support.html")!) {
                Label("Support Page", systemImage: "questionmark.circle")
            }
        }
        .sheet(isPresented: $showingContactSupport) {
            ContactSupportView()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(VaultAuthManager())
        .environmentObject(DecoyModeManager())
        .environmentObject(SelfDestructManager())
}
