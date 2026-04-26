import CoreData
import CryptoKit
import Foundation

final class NoteEditorViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var body: String = ""
    @Published var tags: [String] = []
    @Published var showPreview = false
    @Published var tagInput = ""
    
    private var note: VNNote?
    private var cryptoKey: SymmetricKey?
    private var context: NSManagedObjectContext?
    
    func loadNote(_ note: VNNote, key: SymmetricKey?, context: NSManagedObjectContext) {
        self.note = note
        self.cryptoKey = key
        self.context = context
        self.title = note.title ?? ""
        self.tags = note.tags
        
        if let key = cryptoKey {
            self.body = note.decryptBody(with: key)
        }
    }
    
    func saveNote() {
        guard let note = note, let context = context else { return }
        note.title = title.isEmpty ? "Untitled" : title
        note.tags = tags
        
        if let key = cryptoKey {
            note.encryptBody(body, with: key)
        }
        
        note.updatedAt = Date()
        try? context.save()
    }
    
    func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        tagInput = ""
        saveNote()
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        saveNote()
    }
}
