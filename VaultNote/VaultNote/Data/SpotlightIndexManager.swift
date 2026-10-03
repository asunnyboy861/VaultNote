import CoreSpotlight
import Foundation

final class SpotlightIndexManager {
    static let shared = SpotlightIndexManager()

    private let domainIdentifier = "com.zzoutuo.VaultNote"

    private init() {}

    func indexNote(_ note: VNNote) {
        let item = CSSearchableItem(
            uniqueIdentifier: "note-\(note.id.uuidString)",
            domainIdentifier: domainIdentifier,
            attributeSet: noteAttributeSet(for: note)
        )
        CSSearchableIndex.default().indexSearchableItems([item])
    }

    func indexNotes(_ notes: [VNNote]) {
        let items = notes.map { note in
            CSSearchableItem(
                uniqueIdentifier: "note-\(note.id.uuidString)",
                domainIdentifier: domainIdentifier,
                attributeSet: noteAttributeSet(for: note)
            )
        }
        CSSearchableIndex.default().indexSearchableItems(items)
    }

    func deindexNote(_ note: VNNote) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: ["note-\(note.id.uuidString)"]
        )
    }

    func deindexAll() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
    }

    private func noteAttributeSet(for note: VNNote) -> CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.title = note.title ?? "Untitled Note"
        attributes.contentDescription = "Encrypted note in VaultNote"
        attributes.keywords = ["vaultnote", "note", "encrypted", "secure"]
        return attributes
    }
}
