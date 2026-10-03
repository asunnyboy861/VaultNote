import LocalAuthentication
import SwiftUI

final class VaultAuthManager: ObservableObject {

    @Published var isUnlocked = false
    @Published var biometricType: LABiometryType = .none
    @Published var isDecoySpace = false

    init() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        }
    }

    func authenticate(reason: String = "Unlock VaultNote") async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return await authenticateWithPasscode()
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            await MainActor.run {
                self.isUnlocked = success
                self.isDecoySpace = false
            }
            if success {
                SecurityAuditLogger.shared.log(event: .unlockSuccess)
            }
            return success
        } catch {
            return await authenticateWithPasscode()
        }
    }

    private func authenticateWithPasscode() async -> Bool {
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Enter your passcode to unlock VaultNote"
            )
            await MainActor.run {
                self.isUnlocked = success
                self.isDecoySpace = false
            }
            if success {
                SecurityAuditLogger.shared.log(event: .unlockSuccess)
            }
            return success
        } catch {
            return false
        }
    }

    func authenticateWithPassword(
        _ password: String,
        decoyManager: DecoyModeManager,
        selfDestructManager: SelfDestructManager
    ) -> AuthResult {

        if selfDestructManager.isEnabled && selfDestructManager.isEmergencyPassword(password) {
            SecurityAuditLogger.shared.log(event: .emergencyPasswordUsed)
            return .failed
        }

        let result = decoyManager.authenticate(password: password)

        switch result {
        case .real:
            isUnlocked = true
            isDecoySpace = false
            selfDestructManager.resetFailedAttempts()
        case .decoy:
            isUnlocked = true
            isDecoySpace = true
            selfDestructManager.resetFailedAttempts()
        case .failed:
            let shouldDestruct = selfDestructManager.recordFailedAttempt()
            if shouldDestruct {
                isUnlocked = false
            }
        }

        return result
    }

    func lock() {
        isUnlocked = false
        isDecoySpace = false
    }

    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield"
        }
    }
}
