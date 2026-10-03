import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: VaultAuthManager
    @EnvironmentObject var decoyManager: DecoyModeManager
    @EnvironmentObject var selfDestructManager: SelfDestructManager
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @StateObject private var shakeDetector = ShakeDetector()
    @State private var selectedTab = 0
    @State private var showShakeConfirm = false

    var body: some View {
        Group {
            if !biometricLockEnabled || authManager.isUnlocked {
                if authManager.isDecoySpace && biometricLockEnabled {
                    DecoyNotesListView(decoyManager: decoyManager)
                } else {
                    mainContent
                }
            } else {
                LockScreenView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isUnlocked)
        .screenshotProtected()
        .onShake {
            if UserDefaults.standard.bool(forKey: "shakeToDestroyEnabled") {
                showShakeConfirm = true
            }
        }
        .alert("Emergency Wipe", isPresented: $showShakeConfirm) {
            Button("DESTROY ALL DATA", role: .destructive) {
                selfDestructManager.executeSelfDestruct()
            }
            Button("Cancel", role: .cancel) {
                shakeDetector.shakeTriggered = false
            }
        } message: {
            Text("Shake-to-Destroy was triggered. All data will be permanently erased. This cannot be undone.")
        }
        .task {
            #if DEBUG
            if !authManager.isUnlocked {
                authManager.isUnlocked = true
            }
            #endif
        }
    }

    var mainContent: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VaultDashboardView()
            }
            .tabItem {
                Label("Vault", systemImage: "shield.checkered")
            }
            .tag(0)

            NavigationStack {
                NotesListView()
            }
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            .tag(1)

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(3)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(VaultAuthManager())
        .environmentObject(VaultDataController.shared)
        .environmentObject(DecoyModeManager())
        .environmentObject(SelfDestructManager())
}
