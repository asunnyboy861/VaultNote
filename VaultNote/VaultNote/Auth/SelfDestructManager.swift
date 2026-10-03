import CoreData
import Foundation

final class SelfDestructManager: ObservableObject {

    @Published var remainingAttempts: Int = 10
    @Published var isWarningShown = false

    private let failedAttemptsKey = "failedAuthAttempts"
    private let selfDestructEnabledKey = "selfDestructEnabled"
    private let selfDestructAttemptsKey = "selfDestructAttempts"
    private let emergencyPasswordKey = "vn_emergency_password_hash"
    private var failedAttempts: Int = 0

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: selfDestructEnabledKey)
    }

    var attemptThreshold: Int {
        let val = UserDefaults.standard.integer(forKey: selfDestructAttemptsKey)
        return val > 0 ? val : 10
    }

    init() {
        loadFailedAttempts()
    }

    func recordFailedAttempt() -> Bool {
        guard isEnabled else { return false }

        failedAttempts += 1
        saveFailedAttempts()
        remainingAttempts = max(0, attemptThreshold - failedAttempts)

        SecurityAuditLogger.shared.log(
            event: .failedAttemptRecorded,
            details: "Attempt \(failedAttempts)/\(attemptThreshold), \(remainingAttempts) remaining"
        )

        if remainingAttempts <= 3 && remainingAttempts > 0 {
            isWarningShown = true
        }

        if failedAttempts >= attemptThreshold {
            executeSelfDestruct()
            return true
        }

        return false
    }

    func isEmergencyPassword(_ password: String) -> Bool {
        let inputHash = VaultKeychainHelper.hashPassword(password)
        guard let storedHash = VaultKeychainHelper.retrieveString(key: emergencyPasswordKey),
              !storedHash.isEmpty else { return false }

        if inputHash == storedHash {
            SecurityAuditLogger.shared.log(event: .emergencyPasswordUsed)
            executeSelfDestruct()
            return true
        }
        return false
    }

    func setEmergencyPassword(_ password: String) -> Bool {
        guard password.count >= 4 else { return false }
        VaultKeychainHelper.storeString(VaultKeychainHelper.hashPassword(password), key: emergencyPasswordKey)
        return true
    }

    func clearEmergencyPassword() {
        VaultKeychainHelper.delete(key: emergencyPasswordKey)
    }

    var hasEmergencyPassword: Bool {
        VaultKeychainHelper.retrieveString(key: emergencyPasswordKey) != nil
    }

    func resetFailedAttempts() {
        failedAttempts = 0
        saveFailedAttempts()
        remainingAttempts = attemptThreshold
    }

    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: selfDestructEnabledKey)
        if enabled {
            resetFailedAttempts()
        }
    }

    func setAttemptThreshold(_ count: Int) {
        UserDefaults.standard.set(count, forKey: selfDestructAttemptsKey)
        updateRemainingAttempts()
    }

    func executeSelfDestruct() {
        SecurityAuditLogger.shared.log(event: .selfDestructExecuted)

        UserDefaults.standard.removeObject(forKey: failedAttemptsKey)

        let context = VaultDataController.shared.container.viewContext
        let request: NSFetchRequest<VNNote> = VNNote.fetchRequest()
        if let notes = try? context.fetch(request) {
            for note in notes {
                context.delete(note)
            }
            try? context.save()
        }

        failedAttempts = 0
        remainingAttempts = attemptThreshold
    }

    private func loadFailedAttempts() {
        failedAttempts = UserDefaults.standard.integer(forKey: failedAttemptsKey)
        updateRemainingAttempts()
    }

    private func saveFailedAttempts() {
        UserDefaults.standard.set(failedAttempts, forKey: failedAttemptsKey)
    }

    private func updateRemainingAttempts() {
        remainingAttempts = max(0, attemptThreshold - failedAttempts)
    }
}
