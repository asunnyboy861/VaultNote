import SwiftUI

struct DecoyNotesListView: View {
    @ObservedObject var decoyManager: DecoyModeManager
    @State private var selectedNote: DecoyNote?
    @State private var showingDetail = false
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                if decoyManager.decoyNotes.isEmpty {
                    ContentUnavailableView(
                        "No Notes",
                        systemImage: "note.text",
                        description: Text("Tap + to add a note")
                    )
                } else {
                    ForEach(decoyManager.decoyNotes) { note in
                        Button {
                            selectedNote = note
                            showingDetail = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(note.body.prefix(80))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete { offsets in
                        decoyManager.deleteDecoyNote(at: offsets)
                    }
                }
            }
            .navigationTitle("SealNotes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let note = selectedNote {
                    DecoyNoteDetailView(note: note)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddDecoyNoteView(decoyManager: decoyManager)
            }
        }
    }
}

struct DecoyNoteDetailView: View {
    let note: DecoyNote
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(note.title)
                        .font(.title.weight(.bold))
                    Text(note.body)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AddDecoyNoteView: View {
    @ObservedObject var decoyManager: DecoyModeManager
    @Environment(\.dismiss) private var dismiss
    @State private var noteTitle = ""
    @State private var noteContent = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Note title", text: $noteTitle)
                }
                Section("Content") {
                    TextEditor(text: $noteContent)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard !noteTitle.isEmpty else { return }
                        decoyManager.addDecoyNote(title: noteTitle, body: noteContent)
                        dismiss()
                    }
                    .disabled(noteTitle.isEmpty)
                }
            }
        }
    }
}
