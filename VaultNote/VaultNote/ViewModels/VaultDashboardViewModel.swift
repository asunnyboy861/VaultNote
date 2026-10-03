import CoreData
import CryptoKit
import Foundation

final class VaultDashboardViewModel: ObservableObject {
    @Published var recentNotes: [VNNote] = []
    @Published var securityScore: Int = 0
    @Published var totalNotes: Int = 0
    @Published var totalCards: Int = 0
    @Published var totalVoiceMemos: Int = 0
    @Published var totalFiles: Int = 0

    let cryptoKey: SymmetricKey

    init() {
        let salt = VaultCrypto.getOrCreateSalt()
        cryptoKey = VaultCrypto.deriveKey(from: "default", salt: salt)
        loadData()
    }

    func loadData() {
        loadRecentNotes()
        calculateSecurityScore()
        loadCounts()
    }

    func loadRecentNotes() {
        let context = VaultDataController.shared.container.viewContext
        let request = VNNote.fetchRequest() as NSFetchRequest<VNNote>
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        request.fetchLimit = 5
        recentNotes = (try? context.fetch(request)) ?? []
    }

    func loadCounts() {
        let context = VaultDataController.shared.container.viewContext

        let noteRequest = VNNote.fetchRequest() as NSFetchRequest<VNNote>
        totalNotes = (try? context.count(for: noteRequest)) ?? 0

        let cardRequest = VNSecureCard.fetchRequest() as NSFetchRequest<VNSecureCard>
        totalCards = (try? context.count(for: cardRequest)) ?? 0

        let memoRequest = VNVoiceMemo.fetchRequest() as NSFetchRequest<VNVoiceMemo>
        totalVoiceMemos = (try? context.count(for: memoRequest)) ?? 0

        let fileRequest = VNSecureFile.fetchRequest() as NSFetchRequest<VNSecureFile>
        totalFiles = (try? context.count(for: fileRequest)) ?? 0
    }

    func calculateSecurityScore() {
        var score = 0
        if UserDefaults.standard.bool(forKey: "biometricLockEnabled") { score += 20 }
        if UserDefaults.standard.bool(forKey: "decoyModeEnabled") { score += 20 }
        if UserDefaults.standard.bool(forKey: "selfDestructEnabled") { score += 20 }
        if UserDefaults.standard.bool(forKey: "screenshotProtectionEnabled") { score += 20 }
        if UserDefaults.standard.bool(forKey: "shakeToDestroyEnabled") { score += 10 }
        if totalNotes > 0 || totalCards > 0 { score += 10 }
        securityScore = min(score, 100)
    }

    var scoreColor: String {
        if securityScore >= 80 { return "green" }
        if securityScore >= 40 { return "orange" }
        return "red"
    }

    var scoreLabel: String {
        if securityScore >= 80 { return "Excellent" }
        if securityScore >= 60 { return "Good" }
        if securityScore >= 40 { return "Fair" }
        return "At Risk"
    }
}
