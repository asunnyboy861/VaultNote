import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: VaultAuthManager
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authManager.isUnlocked {
                mainContent
            } else {
                LockScreenView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isUnlocked)
        .task {
            #if targetEnvironment(simulator)
            authManager.isUnlocked = true
            #endif
        }
    }
    
    var mainContent: some View {
        TabView(selection: $selectedTab) {
            NotesListView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(0)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(VaultAuthManager())
        .environmentObject(VaultDataController.shared)
}
