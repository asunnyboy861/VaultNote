import CoreData
import CryptoKit
import Foundation

enum WidgetDataHelper {

    private static let appGroupID = "group.com.zzoutuo.VaultNote"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static var latestNoteTitle: String? {
        sharedDefaults?.string(forKey: "widget_latestNoteTitle")
    }

    static var latestNotePreview: String? {
        sharedDefaults?.string(forKey: "widget_latestNotePreview")
    }

    static var noteCount: Int {
        sharedDefaults?.integer(forKey: "widget_noteCount") ?? 0
    }

    static func updateWidgetData(context: NSManagedObjectContext, cryptoKey: SymmetricKey?) {
        let request: NSFetchRequest<VNNote> = VNNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \VNNote.updatedAt, ascending: false)]
        request.fetchLimit = 1

        guard let latestNote = try? context.fetch(request).first else {
            sharedDefaults?.set("No Notes Yet", forKey: "widget_latestNoteTitle")
            sharedDefaults?.set("", forKey: "widget_latestNotePreview")
            sharedDefaults?.set(false, forKey: "widget_hasEncryption")
            sharedDefaults?.set(0, forKey: "widget_noteCount")
            return
        }

        let preview: String
        if let key = cryptoKey, latestNote.encryptedBody != nil {
            preview = String(latestNote.decryptBody(with: key).prefix(80))
        } else {
            preview = ""
        }

        let countRequest: NSFetchRequest<VNNote> = VNNote.fetchRequest()
        let totalCount = (try? context.count(for: countRequest)) ?? 0

        let defaults = sharedDefaults
        defaults?.set(latestNote.title ?? "Untitled", forKey: "widget_latestNoteTitle")
        defaults?.set(preview, forKey: "widget_latestNotePreview")
        defaults?.set(latestNote.encryptedBody != nil, forKey: "widget_hasEncryption")
        defaults?.set(totalCount, forKey: "widget_noteCount")
    }
}
