import CryptoKit
import Foundation

enum SecurityEventType: String, Codable, CaseIterable {
    case unlockSuccess = "unlock_success"
    case unlockFailed = "unlock_failed"
    case screenshotDetected = "screenshot_detected"
    case screenRecordingDetected = "screen_recording_detected"
    case selfDestructExecuted = "self_destruct_executed"
    case passwordChanged = "password_changed"
    case decoyAccessed = "decoy_accessed"
    case emergencyPasswordUsed = "emergency_password_used"
    case failedAttemptRecorded = "failed_attempt_recorded"
    case shakeToDestroyTriggered = "shake_to_destroy_triggered"
    case timeLockSet = "time_lock_set"
    case timeLockRemoved = "time_lock_removed"
    case geoFenceSet = "geo_fence_set"
    case geoFenceRemoved = "geo_fence_removed"
    case secureCardCreated = "secure_card_created"
    case voiceMemoCreated = "voice_memo_created"
    case secureFileImported = "secure_file_imported"

    var displayName: String {
        switch self {
        case .unlockSuccess: return "Unlock Succeeded"
        case .unlockFailed: return "Unlock Failed"
        case .screenshotDetected: return "Screenshot Detected"
        case .screenRecordingDetected: return "Screen Recording Detected"
        case .selfDestructExecuted: return "Self-Destruct Executed"
        case .passwordChanged: return "Password Changed"
        case .decoyAccessed: return "Decoy Vault Accessed"
        case .emergencyPasswordUsed: return "Emergency Password Used"
        case .failedAttemptRecorded: return "Failed Attempt Recorded"
        case .shakeToDestroyTriggered: return "Shake-to-Destroy Triggered"
        case .timeLockSet: return "Time Lock Set"
        case .timeLockRemoved: return "Time Lock Removed"
        case .geoFenceSet: return "Geo-Fence Set"
        case .geoFenceRemoved: return "Geo-Fence Removed"
        case .secureCardCreated: return "Secure Card Created"
        case .voiceMemoCreated: return "Voice Memo Created"
        case .secureFileImported: return "Secure File Imported"
        }
    }

    var icon: String {
        switch self {
        case .unlockSuccess: return "lock.open"
        case .unlockFailed: return "lock.slash"
        case .screenshotDetected, .screenRecordingDetected: return "camera"
        case .selfDestructExecuted: return "exclamationmark.triangle"
        case .passwordChanged: return "key"
        case .decoyAccessed: return "theatermasks"
        case .emergencyPasswordUsed: return "flame"
        case .failedAttemptRecorded: return "xmark.shield"
        case .shakeToDestroyTriggered: return "iphone.radiowaves.left.and.right"
        case .timeLockSet: return "lock.clock"
        case .timeLockRemoved: return "lock.clock"
        case .geoFenceSet: return "location.circle"
        case .geoFenceRemoved: return "location.circle"
        case .secureCardCreated: return "creditcard"
        case .voiceMemoCreated: return "mic"
        case .secureFileImported: return "doc"
        }
    }

    var severity: EventSeverity {
        switch self {
        case .unlockSuccess, .decoyAccessed, .timeLockSet, .timeLockRemoved,
             .geoFenceSet, .geoFenceRemoved, .secureCardCreated,
             .voiceMemoCreated, .secureFileImported:
            return .info
        case .unlockFailed, .screenshotDetected, .failedAttemptRecorded:
            return .warning
        case .selfDestructExecuted, .emergencyPasswordUsed, .shakeToDestroyTriggered:
            return .critical
        default:
            return .info
        }
    }
}

enum EventSeverity: Int, Codable, Comparable {
    case info = 0
    case warning = 1
    case critical = 2

    static func < (lhs: EventSeverity, rhs: EventSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct SecurityEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: SecurityEventType
    let details: String?

    init(type: SecurityEventType, details: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.details = details
    }
}
