import SwiftUI

@main
struct VaultNoteApp: App {
    @StateObject private var dataController = VaultDataController.shared
    @StateObject private var authManager = VaultAuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(authManager)
                .environmentObject(dataController)
        }
    }
}
