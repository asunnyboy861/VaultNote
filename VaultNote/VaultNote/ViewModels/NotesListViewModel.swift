import CoreData
import CryptoKit
import SwiftUI

final class NotesListViewModel: ObservableObject {
    @Published var notes: [VNNote] = []
    @Published var searchText = ""
    @Published var selectedFolder: String?

    let context: NSManagedObjectContext
    let cryptoKey: SymmetricKey?

    init(context: NSManagedObjectContext, cryptoKey: SymmetricKey?) {
        self.context = context
        self.cryptoKey = cryptoKey
        fetchNotes()
    }

    var folders: [String] {
        let folderSet = Set(notes.compactMap { $0.folder })
        return folderSet.sorted()
    }

    var filteredNotes: [VNNote] {
        if searchText.isEmpty {
            return notes
        }
        return notes.filter { note in
            (note.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            note.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var pinnedNotes: [VNNote] {
        filteredNotes.filter { $0.isPinned }
    }

    var unpinnedNotes: [VNNote] {
        filteredNotes.filter { !$0.isPinned }
    }

    func fetchNotes() {
        let request: NSFetchRequest<VNNote> = VNNote.fetchRequest()

        var predicates: [NSPredicate] = []
        if let folder = selectedFolder {
            predicates.append(NSPredicate(format: "folder == %@", folder))
        }
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \VNNote.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \VNNote.updatedAt, ascending: false)
        ]

        notes = (try? context.fetch(request)) ?? []

        WidgetDataHelper.updateWidgetData(context: context, cryptoKey: cryptoKey)
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
}
