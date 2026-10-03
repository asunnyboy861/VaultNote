import SwiftUI
import WidgetKit

struct NoteEntry: TimelineEntry {
    let date: Date
    let title: String
    let preview: String
    let hasEncryption: Bool
}

struct NoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> NoteEntry {
        NoteEntry(date: Date(), title: "My Note", preview: "Note preview...", hasEncryption: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (NoteEntry) -> Void) {
        let entry = loadLatestNote()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NoteEntry>) -> Void) {
        let entry = loadLatestNote()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadLatestNote() -> NoteEntry {
        let data = WidgetDataHelper.loadWidgetData()
        return NoteEntry(
            date: Date(),
            title: data.title,
            preview: data.preview,
            hasEncryption: data.hasEncryption
        )
    }
}

struct VaultNoteWidgetEntryView: View {
    var entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(.blue)
                Text("SealNotes")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                if entry.hasEncryption {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Text(entry.title)
                .font(.headline)
                .lineLimit(1)

            if !entry.preview.isEmpty {
                Text(entry.preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(entry.date, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

struct VaultNoteWidget: Widget {
    let kind: String = "VaultNoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NoteProvider()) { entry in
            VaultNoteWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Latest Note")
        .description("View your most recent encrypted note at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    VaultNoteWidget()
} timeline: {
    NoteEntry(date: .now, title: "Shopping List", preview: "Milk, Eggs, Bread...", hasEncryption: true)
    NoteEntry(date: .now.addingTimeInterval(3600), title: "Meeting Notes", preview: "Discuss Q2 roadmap...", hasEncryption: true)
}
