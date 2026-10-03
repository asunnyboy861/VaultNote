import CoreData
import CryptoKit
import Foundation

final class NoteEditorViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var body: String = ""
    @Published var tags: [String] = []
    @Published var showPreview = false
    @Published var tagInput = ""
    @Published var suggestedTags: [String] = []

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

        loadSuggestedTags(context: context)
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

    private func loadSuggestedTags(context: NSManagedObjectContext) {
        let request: NSFetchRequest<VNNote> = VNNote.fetchRequest()
        request.fetchLimit = 100

        var allTags = Set<String>()
        if let results = try? context.fetch(request) {
            for n in results {
                allTags.formUnion(n.tags)
            }
        }

        suggestedTags = allTags.filter { !tags.contains($0) }.sorted()
    }
}
