import CoreData
import CryptoKit
import Foundation

final class NotesListViewModel: ObservableObject {
    @Published var notes: [VNNote] = []
    @Published var searchText = ""
    @Published var selectedFolder: String?
    @Published var folders: [String] = []
    
    private var context: NSManagedObjectContext
    private var cryptoKey: SymmetricKey?
    
    init(context: NSManagedObjectContext) {
        self.context = context
        setupCryptoKey()
        fetchNotes()
    }
    
    private func setupCryptoKey() {
        let salt = VaultCrypto.getOrCreateSalt()
        cryptoKey = VaultCrypto.deriveKey(from: "default", salt: salt)
    }
    
    func fetchNotes() {
        let request: NSFetchRequest<VNNote> = VNNote.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \VNNote.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \VNNote.updatedAt, ascending: false)
        ]
        
        if let folder = selectedFolder {
            request.predicate = NSPredicate(format: "folder == %@", folder)
        }
        
        notes = (try? context.fetch(request)) ?? []
        updateFolders()
    }
    
    private func updateFolders() {
        let request: NSFetchRequest<NSDictionary> = NSFetchRequest()
        request.entity = VNNote.entity()
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["folder"]
        request.returnsDistinctResults = true
        
        if let results = try? context.fetch(request) as? [[String: String]] {
            folders = results.compactMap { $0["folder"] }.filter { !$0.isEmpty }.sorted()
        }
    }
    
    func deleteNote(_ note: VNNote) {
        context.delete(note)
        try? context.save()
        fetchNotes()
    }
    
    func togglePin(_ note: VNNote) {
        note.isPinned.toggle()
        note.updatedAt = Date()
        try? context.save()
        fetchNotes()
    }
    
    func toggleFavorite(_ note: VNNote) {
        note.isFavorite.toggle()
        note.updatedAt = Date()
        try? context.save()
        fetchNotes()
    }
    
    func createNote() -> VNNote {
        let note = VNNote.create(
            in: context,
            title: "Untitled",
            body: "",
            folder: selectedFolder,
            cryptoKey: cryptoKey
        )
        fetchNotes()
        return note
    }
    
    func getCryptoKey() -> SymmetricKey? {
        cryptoKey
    }
}
