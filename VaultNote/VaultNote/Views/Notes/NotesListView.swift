import CryptoKit
import SwiftUI

struct NotesListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: NotesListViewModel
    @State private var showingEditor = false
    @State private var selectedNote: VNNote?
    @State private var sharedNotesBadge = 0

    init() {
        let salt = VaultCrypto.getOrCreateSalt()
        let key = VaultCrypto.deriveKey(from: "default", salt: salt)
        _viewModel = StateObject(wrappedValue: NotesListViewModel(
            context: VaultDataController.shared.container.viewContext,
            cryptoKey: key
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                if sharedNotesBadge > 0 {
                    Section {
                        sharedNotesBanner
                    }
                }

                if !viewModel.folders.isEmpty {
                    Section("Folders") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FolderChip(name: "All", isSelected: viewModel.selectedFolder == nil) {
                                    viewModel.selectedFolder = nil
                                    viewModel.fetchNotes()
                                }
                                ForEach(viewModel.folders, id: \.self) { folder in
                                    FolderChip(name: folder, isSelected: viewModel.selectedFolder == folder) {
                                        viewModel.selectedFolder = folder
                                        viewModel.fetchNotes()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section {
                    if viewModel.notes.isEmpty {
                        emptyState
                    } else {
                        if !viewModel.pinnedNotes.isEmpty {
                            ForEach(viewModel.pinnedNotes) { note in
                                noteRow(note)
                            }
                        }

                        ForEach(viewModel.unpinnedNotes) { note in
                            noteRow(note)
                        }
                    }
                }
            }
            .navigationTitle("SealNotes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let newNote = viewModel.createNote()
                        selectedNote = newNote
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                if let note = selectedNote {
                    NoteEditorView(note: note, cryptoKey: viewModel.cryptoKey)
                }
            }
            .refreshable {
                viewModel.fetchNotes()
                checkSharedNotes()
            }
            .onAppear {
                checkSharedNotes()
            }
        }
    }

    private func noteRow(_ note: VNNote) -> some View {
        NoteRowView(note: note, cryptoKey: viewModel.cryptoKey)
            .onTapGesture {
                selectedNote = note
                showingEditor = true
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    viewModel.deleteNote(note)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading) {
                Button {
                    viewModel.togglePin(note)
                } label: {
                    Label(note.isPinned ? "Unpin" : "Pin",
                          systemImage: note.isPinned ? "pin.slash" : "pin")
                }
                .tint(.orange)
            }
    }

    var sharedNotesBanner: some View {
        Button {
            importSharedNotes()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(sharedNotesBadge) Shared Note\(sharedNotesBadge > 1 ? "s" : "")")
                        .font(.subheadline.weight(.medium))
                    Text("Tap to import into VaultNote")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Notes Yet")
                .font(.title2)
                .fontWeight(.medium)
            Text("Tap + to create your first encrypted note")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func checkSharedNotes() {
        let shared = ShareDataHelper.loadSharedNotes()
        sharedNotesBadge = shared.count
    }

    private func importSharedNotes() {
        let shared = ShareDataHelper.loadSharedNotes()
        for item in shared {
            let _ = VNNote.create(
                in: viewContext,
                title: item.title,
                body: item.body,
                tags: ["shared"],
                folder: nil,
                cryptoKey: viewModel.cryptoKey
            )
        }
        ShareDataHelper.clearSharedNotes()
        sharedNotesBadge = 0
        viewModel.fetchNotes()
    }
}

struct FolderChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    NotesListView()
        .environment(\.managedObjectContext, VaultDataController.shared.container.viewContext)
}
