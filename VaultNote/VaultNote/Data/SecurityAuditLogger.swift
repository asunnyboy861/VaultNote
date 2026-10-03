import Foundation

final class SecurityAuditLogger: ObservableObject {

    static let shared = SecurityAuditLogger()

    @Published private(set) var events: [SecurityEvent] = []

    private let maxEvents = 500
    private let storageKey = "securityAuditLog"

    private init() {
        loadEvents()
    }

    func log(event type: SecurityEventType, details: String? = nil) {
        let event = SecurityEvent(type: type, details: details)
        events.append(event)

        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }

        saveEvents()
    }

    func recentEvents(limit: Int = 50) -> [SecurityEvent] {
        Array(events.suffix(limit).reversed())
    }

    func events(ofType type: SecurityEventType) -> [SecurityEvent] {
        events.filter { $0.type == type }
    }

    var criticalEvents: [SecurityEvent] {
        events.filter { $0.type.severity >= .warning }
    }

    func clearAllLogs() {
        events.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    func exportLogs() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        if let data = try? encoder.encode(events),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "[]"
    }

    private func saveEvents() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(events) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let loaded = try? decoder.decode([SecurityEvent].self, from: data) {
            events = loaded
        }
    }
}
