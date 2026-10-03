import CoreData
import CryptoKit
import Foundation

@objc(VNSecureCard)
public class VNSecureCard: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String?
    @NSManaged public var cardType: String?
    @NSManaged public var encryptedData: Data?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

    var templateType: CardTemplateType {
        get { CardTemplateType(rawValue: cardType ?? "custom") ?? .custom }
        set { cardType = newValue.rawValue }
    }
}

extension VNSecureCard {
    static func fetchRequest() -> NSFetchRequest<VNSecureCard> {
        NSFetchRequest<VNSecureCard>(entityName: "VNSecureCard")
    }

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        title: String,
        cardType: CardTemplateType,
        fields: [CardField: String],
        cryptoKey: SymmetricKey
    ) -> VNSecureCard {
        let card = VNSecureCard(context: context)
        card.id = UUID()
        card.title = title
        card.cardType = cardType.rawValue
        card.createdAt = Date()
        card.updatedAt = Date()

        var dict: [String: String] = [:]
        for (field, value) in fields {
            dict[field.name] = value
        }
        if let jsonData = try? JSONEncoder().encode(dict) {
            card.encryptedData = try? VaultCrypto.encrypt(
                String(data: jsonData, encoding: .utf8) ?? "{}",
                with: cryptoKey
            )
        }

        try? context.save()
        return card
    }

    func decryptFields(with key: SymmetricKey) -> [String: String] {
        guard let encrypted = encryptedData else { return [:] }
        let decrypted = (try? VaultCrypto.decrypt(encrypted, with: key)) ?? "{}"
        guard let data = decrypted.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return dict
    }

    func updateFields(_ fields: [String: String], with key: SymmetricKey) {
        if let jsonData = try? JSONEncoder().encode(fields) {
            encryptedData = try? VaultCrypto.encrypt(
                String(data: jsonData, encoding: .utf8) ?? "{}",
                with: key
            )
        }
        updatedAt = Date()
    }
}
