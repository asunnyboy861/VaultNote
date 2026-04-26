import CryptoKit
import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NoteEditorViewModel()
    @FocusState private var isEditorFocused: Bool
    
    let note: VNNote
    let cryptoKey: SymmetricKey?
    
    init(note: VNNote, cryptoKey: SymmetricKey?) {
        self.note = note
        self.cryptoKey = cryptoKey
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                titleField
                
                tagsBar
                
                Divider()
                
                if viewModel.showPreview {
                    MarkdownPreviewView(text: viewModel.body)
                } else {
                    editorArea
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        viewModel.saveNote()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation { viewModel.showPreview.toggle() }
                    } label: {
                        Image(systemName: viewModel.showPreview ? "pencil" : "eye")
                    }
                }
            }
            .onAppear {
                viewModel.loadNote(note, key: cryptoKey, context: note.managedObjectContext ?? VaultDataController.shared.container.viewContext)
                isEditorFocused = true
            }
        }
    }
    
    var titleField: some View {
        TextField("Title", text: $viewModel.title)
            .font(.title2.weight(.semibold))
            .padding(.horizontal)
            .padding(.top, 8)
            .onChange(of: viewModel.title) {
                viewModel.saveNote()
            }
    }
    
    var tagsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(viewModel.tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text(tag)
                            .font(.caption)
                        Button {
                            viewModel.removeTag(tag)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
                }
                
                TextField("Add tag", text: $viewModel.tagInput)
                    .font(.caption)
                    .frame(width: 80)
                    .onSubmit {
                        viewModel.addTag()
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }
    
    var editorArea: some View {
        TextEditor(text: $viewModel.body)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(.horizontal)
            .focused($isEditorFocused)
            .onChange(of: viewModel.body) {
                viewModel.saveNote()
            }
    }
}
