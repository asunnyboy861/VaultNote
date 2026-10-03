import CoreData
import CryptoKit
import Foundation

@objc(VNSecureFile)
public class VNSecureFile: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String?
    @NSManaged public var fileType: String?
    @NSManaged public var encryptedData: Data?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var fileSize: Int64
    @NSManaged public var createdAt: Date
}

extension VNSecureFile {
    static func fetchRequest() -> NSFetchRequest<VNSecureFile> {
        NSFetchRequest<VNSecureFile>(entityName: "VNSecureFile")
    }

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        fileType: String,
        data: Data,
        thumbnail: Data? = nil,
        cryptoKey: SymmetricKey
    ) -> VNSecureFile {
        let file = VNSecureFile(context: context)
        file.id = UUID()
        file.name = name
        file.fileType = fileType
        file.fileSize = Int64(data.count)
        file.createdAt = Date()

        file.encryptedData = try? VaultCrypto.encryptData(data, with: cryptoKey)

        if let thumb = thumbnail {
            file.thumbnailData = try? VaultCrypto.encryptData(thumb, with: cryptoKey)
        }

        try? context.save()
        return file
    }

    func decryptData(with key: SymmetricKey) -> Data? {
        guard let encrypted = encryptedData else { return nil }
        return try? VaultCrypto.decryptData(encrypted, with: key)
    }

    func decryptThumbnail(with key: SymmetricKey) -> Data? {
        guard let encrypted = thumbnailData else { return nil }
        return try? VaultCrypto.decryptData(encrypted, with: key)
    }
}
