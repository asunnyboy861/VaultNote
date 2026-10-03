import CoreData
import CryptoKit
import Foundation

@objc(VNVoiceMemo)
public class VNVoiceMemo: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String?
    @NSManaged public var encryptedAudioData: Data?
    @NSManaged public var duration: Double
    @NSManaged public var createdAt: Date
}

extension VNVoiceMemo {
    static func fetchRequest() -> NSFetchRequest<VNVoiceMemo> {
        NSFetchRequest<VNVoiceMemo>(entityName: "VNVoiceMemo")
    }

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        title: String,
        audioData: Data,
        duration: Double,
        cryptoKey: SymmetricKey
    ) -> VNVoiceMemo {
        let memo = VNVoiceMemo(context: context)
        memo.id = UUID()
        memo.title = title
        memo.duration = duration
        memo.createdAt = Date()

        memo.encryptedAudioData = try? VaultCrypto.encryptData(audioData, with: cryptoKey)

        try? context.save()
        return memo
    }

    func decryptAudio(with key: SymmetricKey) -> Data? {
        guard let encrypted = encryptedAudioData else { return nil }
        return try? VaultCrypto.decryptData(encrypted, with: key)
    }
}
