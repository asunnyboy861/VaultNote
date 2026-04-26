import CoreData
import CryptoKit
import Foundation

final class VaultSearchEngine {
    
    static func search(
        query: String,
        context: NSManagedObjectContext,
        cryptoKey: SymmetricKey? = nil
    ) -> [VNNote] {
        guard !query.isEmpty else { return [] }
        
        let request: NSFetchRequest<VNNote> = VNNote.fetchRequest()
        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let folderPredicate = NSPredicate(format: "folder CONTAINS[cd] %@", query)
        request.predicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: [titlePredicate, folderPredicate]
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \VNNote.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \VNNote.updatedAt, ascending: false)
        ]
        
        var results = (try? context.fetch(request)) ?? []
        
        if let key = cryptoKey {
            let contentRequest: NSFetchRequest<VNNote> = VNNote.fetchRequest()
            contentRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \VNNote.updatedAt, ascending: false)
            ]
            contentRequest.fetchLimit = 100
            contentRequest.predicate = NSPredicate(format: "encryptedBody != nil")
            
            let allNotes = (try? context.fetch(contentRequest)) ?? []
            for note in allNotes {
                let decrypted = note.decryptBody(with: key)
                if decrypted.localizedCaseInsensitiveContains(query),
                   !results.contains(where: { $0.id == note.id }) {
                    results.append(note)
                }
            }
        }
        
        return results
    }
}
