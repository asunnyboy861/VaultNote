import CryptoKit
import SwiftUI

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var searchResults: [VNNote] = []
    @State private var selectedNote: VNNote?
    @State private var showingEditor = false
    
    private var cryptoKey: SymmetricKey? {
        let salt = VaultCrypto.getOrCreateSalt()
        return VaultCrypto.deriveKey(from: "default", salt: salt)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("No notes matching \"\(searchText)\"")
                    )
                } else {
                    ForEach(searchResults) { note in
                        NoteRowView(note: note, cryptoKey: cryptoKey)
                            .onTapGesture {
                                selectedNote = note
                                showingEditor = true
                            }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search notes, tags, content...")
            .onChange(of: searchText) {
                performSearch()
            }
            .sheet(isPresented: $showingEditor) {
                if let note = selectedNote {
                    NoteEditorView(note: note, cryptoKey: cryptoKey)
                }
            }
        }
    }
    
    private func performSearch() {
        searchResults = VaultSearchEngine.search(
            query: searchText,
            context: viewContext,
            cryptoKey: cryptoKey
        )
    }
}

#Preview {
    SearchView()
        .environment(\.managedObjectContext, VaultDataController.shared.container.viewContext)
}
