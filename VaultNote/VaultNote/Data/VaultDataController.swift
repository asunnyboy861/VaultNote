import CoreData
import Foundation

final class VaultDataController: ObservableObject {
    
    static let shared = VaultDataController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "VaultNote")
        
        let storeURL = URL.storeDirectory()
            .appendingPathComponent("VaultNote.sqlite")
        
        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData failed: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

extension URL {
    static func storeDirectory() -> URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let url = urls[0].appendingPathComponent("VaultNote")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
