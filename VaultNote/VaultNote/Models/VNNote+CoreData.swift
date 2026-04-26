import CoreData
import CryptoKit
import Foundation

@objc(VNNote)
public class VNNote: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String?
    @NSManaged public var encryptedBody: Data?
    @NSManaged public var tagsData: Data?
    @NSManaged public var isPinned: Bool
    @NSManaged public var isFavorite: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var folder: String?
    
    var tags: [String] {
        get {
            guard let data = tagsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            tagsData = try? JSONEncoder().encode(newValue)
        }
    }
}

extension VNNote {
    static func fetchRequest() -> NSFetchRequest<VNNote> {
        NSFetchRequest<VNNote>(entityName: "VNNote")
    }
    
    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        title: String = "",
        body: String = "",
        tags: [String] = [],
        folder: String? = nil,
        cryptoKey: SymmetricKey? = nil
    ) -> VNNote {
        let note = VNNote(context: context)
        note.id = UUID()
        note.title = title
        note.isPinned = false
        note.isFavorite = false
        note.createdAt = Date()
        note.updatedAt = Date()
        note.folder = folder
        note.tags = tags
        
        if let key = cryptoKey, !body.isEmpty {
            note.encryptedBody = try? VaultCrypto.encrypt(body, with: key)
        } else if !body.isEmpty {
            let salt = VaultCrypto.getOrCreateSalt()
            let key = VaultCrypto.deriveKey(from: "default", salt: salt)
            note.encryptedBody = try? VaultCrypto.encrypt(body, with: key)
        }
        
        try? context.save()
        return note
    }
    
    func decryptBody(with key: SymmetricKey) -> String {
        guard let encrypted = encryptedBody else { return "" }
        return (try? VaultCrypto.decrypt(encrypted, with: key)) ?? ""
    }
    
    func encryptBody(_ text: String, with key: SymmetricKey) {
        if text.isEmpty {
            encryptedBody = nil
        } else {
            encryptedBody = try? VaultCrypto.encrypt(text, with: key)
        }
        updatedAt = Date()
    }
}
