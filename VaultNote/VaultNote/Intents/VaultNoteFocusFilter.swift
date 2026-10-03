import AppIntents
import Foundation

struct VaultNoteFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "SealNotes Focus"
    static var description = IntentDescription("Control what VaultNote shows during Focus modes")

    @Parameter(title: "Hide Content Previews", default: true)
    var hideContentPreviews: Bool

    @Parameter(title: "Silence Notifications", default: false)
    var silenceNotifications: Bool

    var displayRepresentation: DisplayRepresentation {
        if hideContentPreviews && silenceNotifications {
            "SealNotes: Full Privacy"
        } else if hideContentPreviews {
            "SealNotes: Hidden Previews"
        } else if silenceNotifications {
            "SealNotes: Silent"
        } else {
            "SealNotes: Standard"
        }
    }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
