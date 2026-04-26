import SwiftUI

struct NotesListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: NotesListViewModel
    @State private var showingEditor = false
    @State private var selectedNote: VNNote?
    
    init() {
        _viewModel = StateObject(wrappedValue: NotesListViewModel(
            context: VaultDataController.shared.container.viewContext
        ))
    }
    
    var body: some View {
        NavigationStack {
            List {
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
                        ForEach(viewModel.notes) { note in
                            NoteRowView(note: note, cryptoKey: viewModel.getCryptoKey())
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
                    }
                }
            }
            .navigationTitle("VaultNote")
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
                    NoteEditorView(note: note, cryptoKey: viewModel.getCryptoKey())
                }
            }
            .refreshable {
                viewModel.fetchNotes()
            }
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
