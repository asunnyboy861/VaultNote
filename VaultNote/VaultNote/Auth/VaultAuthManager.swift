import LocalAuthentication
import SwiftUI

final class VaultAuthManager: ObservableObject {
    
    @Published var isUnlocked = false
    @Published var biometricType: LABiometryType = .none
    
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
            await MainActor.run { self.isUnlocked = success }
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
            await MainActor.run { self.isUnlocked = success }
            return success
        } catch {
            return false
        }
    }
    
    func lock() {
        isUnlocked = false
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
