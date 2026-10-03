import Foundation

enum AuthResult {
    case real
    case decoy
    case failed
}

final class DecoyModeManager: ObservableObject {

    @Published var isInDecoySpace = false
    @Published var isSetup = false

    private let realPasswordKey = "vn_real_password_hash"
    private let decoyPasswordKey = "vn_decoy_password_hash"
    private let decoyNotesKey = "vn_decoy_notes"
    private let decoyEnabledKey = "decoyModeEnabled"

    init() {
        isSetup = UserDefaults.standard.bool(forKey: decoyEnabledKey)
    }

    var isDecoyModeEnabled: Bool {
        UserDefaults.standard.bool(forKey: decoyEnabledKey)
    }

    func authenticate(password: String) -> AuthResult {
        let inputHash = VaultKeychainHelper.hashPassword(password)

        if let realHash = VaultKeychainHelper.retrieveString(key: realPasswordKey), inputHash == realHash {
            isInDecoySpace = false
            SecurityAuditLogger.shared.log(event: .unlockSuccess)
            return .real
        }

        if let decoyHash = VaultKeychainHelper.retrieveString(key: decoyPasswordKey), inputHash == decoyHash {
            isInDecoySpace = true
            SecurityAuditLogger.shared.log(event: .decoyAccessed)
            return .decoy
        }

        SecurityAuditLogger.shared.log(event: .unlockFailed)
        return .failed
    }

    @discardableResult
    func setup(realPassword: String, decoyPassword: String) -> Bool {
        guard realPassword.count >= 4, decoyPassword.count >= 4 else { return false }
        guard realPassword != decoyPassword else { return false }

        VaultKeychainHelper.storeString(VaultKeychainHelper.hashPassword(realPassword), key: realPasswordKey)
        VaultKeychainHelper.storeString(VaultKeychainHelper.hashPassword(decoyPassword), key: decoyPasswordKey)

        UserDefaults.standard.set(true, forKey: decoyEnabledKey)
        isSetup = true

        createDefaultDecoyNotes()
        SecurityAuditLogger.shared.log(event: .passwordChanged, details: "Decoy mode configured")
        return true
    }

    func updateRealPassword(_ newPassword: String) -> Bool {
        guard newPassword.count >= 4 else { return false }
        VaultKeychainHelper.storeString(VaultKeychainHelper.hashPassword(newPassword), key: realPasswordKey)
        SecurityAuditLogger.shared.log(event: .passwordChanged, details: "Real password updated")
        return true
    }

    func updateDecoyPassword(_ newPassword: String) -> Bool {
        guard newPassword.count >= 4 else { return false }
        VaultKeychainHelper.storeString(VaultKeychainHelper.hashPassword(newPassword), key: decoyPasswordKey)
        SecurityAuditLogger.shared.log(event: .passwordChanged, details: "Decoy password updated")
        return true
    }

    func disableDecoyMode() {
        VaultKeychainHelper.delete(key: decoyPasswordKey)
        UserDefaults.standard.set(false, forKey: decoyEnabledKey)
        isSetup = false
        isInDecoySpace = false
        UserDefaults.standard.removeObject(forKey: decoyNotesKey)
    }

    var decoyNotes: [DecoyNote] {
        guard let data = UserDefaults.standard.data(forKey: decoyNotesKey) else { return [] }
        return (try? JSONDecoder().decode([DecoyNote].self, from: data)) ?? []
    }

    func addDecoyNote(title: String, body: String) {
        var notes = decoyNotes
        notes.append(DecoyNote(title: title, body: body))
        saveDecoyNotes(notes)
    }

    func deleteDecoyNote(at offsets: IndexSet) {
        var notes = decoyNotes
        notes.remove(atOffsets: offsets)
        saveDecoyNotes(notes)
    }

    func hasRealPassword() -> Bool {
        VaultKeychainHelper.retrieveString(key: realPasswordKey) != nil
    }

    private func createDefaultDecoyNotes() {
        let samples = [
            DecoyNote(title: "Shopping List", body: "- Milk\n- Eggs\n- Bread\n- Coffee"),
            DecoyNote(title: "Meeting Notes", body: "Monday: Team sync at 10am\nTuesday: Client review at 2pm\nWednesday: 1:1 with manager"),
            DecoyNote(title: "To-Do", body: "1. Water the plants\n2. Call the dentist\n3. Pick up dry cleaning")
        ]
        saveDecoyNotes(samples)
    }

    private func saveDecoyNotes(_ notes: [DecoyNote]) {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: decoyNotesKey)
        }
    }
}

struct DecoyNote: Codable, Identifiable {
    let id: UUID
    let title: String
    let body: String

    init(title: String, body: String) {
        self.id = UUID()
        self.title = title
        self.body = body
    }
}
