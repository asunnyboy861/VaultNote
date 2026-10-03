import CoreSpotlight
import SwiftUI

@main
struct VaultNoteApp: App {
    @StateObject private var dataController = VaultDataController.shared
    @StateObject private var authManager = VaultAuthManager()
    @StateObject private var decoyManager = DecoyModeManager()
    @StateObject private var selfDestructManager = SelfDestructManager()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .environmentObject(authManager)
                    .environmentObject(dataController)
                    .environmentObject(decoyManager)
                    .environmentObject(selfDestructManager)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onContinueUserActivity("com.zzoutuo.VaultNote.note") { activity in
                        handleSpotlightActivity(activity)
                    }

                if showOnboarding {
                    OnboardingView(isPresented: $showOnboarding)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let host = url.host() else { return }
        switch host {
        case "new":
            NotificationCenter.default.post(name: .createNewNote, object: nil)
        case "search":
            NotificationCenter.default.post(name: .openSearch, object: nil)
        default:
            break
        }
    }

    private func handleSpotlightActivity(_ activity: NSUserActivity) {
        if let uniqueId = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
           uniqueId.hasPrefix("note-") {
            let idString = uniqueId.replacingOccurrences(of: "note-", with: "")
            if let uuid = UUID(uuidString: idString) {
                NotificationCenter.default.post(name: .openNote, object: nil, userInfo: ["noteId": uuid])
            }
        }
    }
}

extension Notification.Name {
    static let createNewNote = Notification.Name("createNewNote")
    static let openSearch = Notification.Name("openSearch")
    static let openNote = Notification.Name("openNote")
}
