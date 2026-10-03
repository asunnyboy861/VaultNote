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
    @NSManaged public var isTimeLocked: Bool
    @NSManaged public var unlockDate: Date?
    @NSManaged public var geoLatitude: Double
    @NSManaged public var geoLongitude: Double
    @NSManaged public var geoRadius: Double
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

    var isGeoFenced: Bool {
        geoRadius > 0
    }

    var isTimeLockedAndActive: Bool {
        guard isTimeLocked, let unlock = unlockDate else { return false }
        return Date() < unlock
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
        note.isTimeLocked = false
        note.unlockDate = nil
        note.geoLatitude = 0
        note.geoLongitude = 0
        note.geoRadius = 0
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

    func setTimeLock(until date: Date) {
        isTimeLocked = true
        unlockDate = date
        updatedAt = Date()
    }

    func removeTimeLock() {
        isTimeLocked = false
        unlockDate = nil
        updatedAt = Date()
    }

    func setGeoFence(latitude: Double, longitude: Double, radius: Double) {
        geoLatitude = latitude
        geoLongitude = longitude
        geoRadius = radius
        updatedAt = Date()
    }

    func removeGeoFence() {
        geoLatitude = 0
        geoLongitude = 0
        geoRadius = 0
        updatedAt = Date()
    }
}
