import AppIntents
import CoreSpotlight
import SwiftUI

struct CreateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Note in VaultNote"
    static var description = IntentDescription("Create a new encrypted note in VaultNote")
    static var openAppWhenRun = true

    @Parameter(title: "Note Title", default: "Untitled")
    var noteTitle: String

    @Parameter(title: "Note Content", default: "")
    var noteContent: String

    func perform() async throws -> some IntentResult {
        let context = VaultDataController.shared.container.viewContext
        let salt = VaultCrypto.getOrCreateSalt()
        let key = VaultCrypto.deriveKey(from: "default", salt: salt)

        let note = VNNote.create(
            in: context,
            title: noteTitle,
            body: noteContent,
            cryptoKey: key
        )

        WidgetDataHelper.updateWidgetData(context: context, cryptoKey: key)

        return .result(dialog: "Created note \"\(note.title ?? "Untitled")\" in VaultNote")
    }
}

struct SearchNotesIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Notes in VaultNote"
    static var description = IntentDescription("Search for notes in VaultNote")
    static var openAppWhenRun = true

    @Parameter(title: "Search Query")
    var query: String

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .openSearch, object: nil)
        return .result(dialog: "Searching for \"\(query)\" in VaultNote")
    }
}

struct OpenVaultNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Open VaultNote"
    static var description = IntentDescription("Open VaultNote app")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        return .result(dialog: "Opening VaultNote")
    }
}

struct CreateSecureCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Secure Card in VaultNote"
    static var description = IntentDescription("Create a new encrypted secure card in VaultNote")
    static var openAppWhenRun = true

    @Parameter(title: "Card Title", default: "New Card")
    var cardTitle: String

    @Parameter(title: "Card Type", default: CardTypeEnum.password)
    var cardType: CardTypeEnum

    enum CardTypeEnum: String, AppEnum {
        case password
        case creditCard
        case identity
        case custom

        static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Card Type")
        static var caseDisplayRepresentations: [CardTypeEnum: DisplayRepresentation] = [
            .password: "Password",
            .creditCard: "Credit Card",
            .identity: "ID Card",
            .custom: "Custom"
        ]
    }

    func perform() async throws -> some IntentResult {
        let context = VaultDataController.shared.container.viewContext
        let salt = VaultCrypto.getOrCreateSalt()
        let key = VaultCrypto.deriveKey(from: "default", salt: salt)

        let templateType: CardTemplateType = switch cardType {
        case .password: .password
        case .creditCard: .creditCard
        case .identity: .identity
        case .custom: .custom
        }

        _ = VNSecureCard.create(
            in: context,
            title: cardTitle,
            cardType: templateType,
            fields: [:],
            cryptoKey: key
        )

        SecurityAuditLogger.shared.log(event: .secureCardCreated, details: cardTitle)
        return .result(dialog: "Created secure card \"\(cardTitle)\" in VaultNote")
    }
}

struct RecordVoiceMemoIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Voice Memo in VaultNote"
    static var description = IntentDescription("Open VaultNote to record an encrypted voice memo")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .openVoiceMemo, object: nil)
        return .result(dialog: "Opening voice recorder in VaultNote")
    }
}

struct LockVaultIntent: AppIntent {
    static var title: LocalizedStringResource = "Lock VaultNote"
    static var description = IntentDescription("Immediately lock VaultNote and require biometric authentication")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .lockVault, object: nil)
        return .result(dialog: "SealNotes is now locked")
    }
}

struct VaultNoteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateNoteIntent(),
            phrases: [
                "Create a note in \(.applicationName)",
                "New note in \(.applicationName)",
                "Save note to \(.applicationName)"
            ],
            shortTitle: "Create Note",
            systemImageName: "square.and.pencil"
        )

        AppShortcut(
            intent: SearchNotesIntent(),
            phrases: [
                "Search notes in \(.applicationName)",
                "Find note in \(.applicationName)"
            ],
            shortTitle: "Search Notes",
            systemImageName: "magnifyingglass"
        )

        AppShortcut(
            intent: OpenVaultNoteIntent(),
            phrases: [
                "Open \(.applicationName)"
            ],
            shortTitle: "Open VaultNote",
            systemImageName: "lock.shield"
        )

        AppShortcut(
            intent: CreateSecureCardIntent(),
            phrases: [
                "Create a secure card in \(.applicationName)",
                "New card in \(.applicationName)"
            ],
            shortTitle: "Create Secure Card",
            systemImageName: "creditcard"
        )

        AppShortcut(
            intent: RecordVoiceMemoIntent(),
            phrases: [
                "Record voice memo in \(.applicationName)",
                "Record memo in \(.applicationName)"
            ],
            shortTitle: "Record Voice Memo",
            systemImageName: "mic"
        )

        AppShortcut(
            intent: LockVaultIntent(),
            phrases: [
                "Lock \(.applicationName)",
                "Secure \(.applicationName)"
            ],
            shortTitle: "Lock Vault",
            systemImageName: "lock.shield"
        )
    }
}

extension Notification.Name {
    static let openVoiceMemo = Notification.Name("openVoiceMemo")
    static let lockVault = Notification.Name("lockVault")
}
