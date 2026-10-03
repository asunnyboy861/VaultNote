import CryptoKit
import Foundation

enum ShareDataHelper {

    private static let appGroupID = "group.com.zzoutuo.VaultNote"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func saveSharedNote(title: String, body: String) -> Bool {
        guard let defaults = sharedDefaults else { return false }

        var sharedNotes = loadSharedNotes()
        sharedNotes.append(SharedNoteItem(title: title, body: body, timestamp: Date()))
        if sharedNotes.count > 20 {
            sharedNotes = Array(sharedNotes.suffix(20))
        }

        guard let data = try? JSONEncoder().encode(sharedNotes) else { return false }
        defaults.set(data, forKey: "shared_notes_queue")
        return true
    }

    static func loadSharedNotes() -> [SharedNoteItem] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "shared_notes_queue"),
              let notes = try? JSONDecoder().decode([SharedNoteItem].self, from: data) else {
            return []
        }
        return notes
    }

    static func clearSharedNotes() {
        sharedDefaults?.removeObject(forKey: "shared_notes_queue")
    }
}

struct SharedNoteItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let body: String
    let timestamp: Date

    init(title: String, body: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.timestamp = timestamp
    }
}
