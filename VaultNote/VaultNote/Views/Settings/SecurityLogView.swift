import SwiftUI

struct SecurityLogView: View {
    @ObservedObject var logger = SecurityAuditLogger.shared
    @State private var showingClearConfirm = false
    @State private var selectedFilter: SecurityEventType?

    private var filteredEvents: [SecurityEvent] {
        guard let filter = selectedFilter else {
            return logger.recentEvents(limit: 100)
        }
        return logger.events(ofType: filter).reversed()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    filterPicker
                }

                if filteredEvents.isEmpty {
                    ContentUnavailableView(
                        "No Events",
                        systemImage: "checkmark.shield",
                        description: Text("No security events have been recorded yet.")
                    )
                } else {
                    ForEach(filteredEvents) { event in
                        eventRow(event)
                    }
                }
            }
            .navigationTitle("Security Log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showingClearConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(logger.events.isEmpty)
                }
            }
            .alert("Clear All Logs?", isPresented: $showingClearConfirm) {
                Button("Clear", role: .destructive) {
                    logger.clearAllLogs()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all security event logs.")
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            Label("All Events", systemImage: "list.bullet").tag(nil as SecurityEventType?)
            ForEach(SecurityEventType.allCases, id: \.self) { type in
                Label(type.displayName, systemImage: type.icon).tag(type as SecurityEventType?)
            }
        }
    }

    private func eventRow(_ event: SecurityEvent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: event.type.icon)
                .font(.title3)
                .foregroundStyle(severityColor(event.type.severity))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.displayName)
                    .font(.subheadline.weight(.medium))

                if let details = event.details {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(event.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                + Text(" ")
                + Text(event.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private func severityColor(_ severity: EventSeverity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}
