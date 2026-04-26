import CryptoKit
import Foundation

final class VaultCrypto {
    
    static func deriveKey(from password: String, salt: Data) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: Data(password.utf8)),
            salt: salt,
            info: Data("VaultNote-E2E-Key".utf8),
            outputByteCount: 32
        )
    }
    
    static func encrypt(_ plaintext: String, with key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(
            Data(plaintext.utf8),
            using: key
        )
        return sealedBox.combined!
    }
    
    static func decrypt(_ encryptedData: Data, with key: SymmetricKey) throws -> String {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8)!
    }
    
    static func generateSalt() -> Data {
        var salt = Data(count: 16)
        salt.withUnsafeMutableBytes { ptr in
            _ = SecRandomCopyBytes(kSecRandomDefault, 16, ptr.baseAddress!)
        }
        return salt
    }
    
    static func storeSalt(_ salt: Data, key: String = "com.vaultnote.salt") {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: salt
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func retrieveSalt(key: String = "com.vaultnote.salt") -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
    
    static func getOrCreateSalt() -> Data {
        if let existing = retrieveSalt() {
            return existing
        }
        let newSalt = generateSalt()
        storeSalt(newSalt)
        return newSalt
    }
}
