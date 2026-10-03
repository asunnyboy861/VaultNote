import CryptoKit
import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NoteEditorViewModel()
    @FocusState private var isEditorFocused: Bool
    @State private var showTimeLockSetup = false
    @State private var showGeoFenceSetup = false
    @State private var showLockOptions = false

    let note: VNNote
    let cryptoKey: SymmetricKey?

    init(note: VNNote, cryptoKey: SymmetricKey?) {
        self.note = note
        self.cryptoKey = cryptoKey
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                lockBadges

                titleField

                tagsBar

                Divider()

                if note.isTimeLockedAndActive {
                    TimeLockedNoteOverlay(unlockDate: note.unlockDate ?? Date())
                } else if note.isGeoFenced {
                    geoFenceContent
                } else {
                    if viewModel.showPreview {
                        MarkdownPreviewView(text: viewModel.body)
                    } else {
                        editorArea
                    }
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
                    HStack(spacing: 12) {
                        Menu {
                            Button {
                                showTimeLockSetup = true
                            } label: {
                                Label("Time Lock", systemImage: "lock.clock")
                            }

                            Button {
                                showGeoFenceSetup = true
                            } label: {
                                Label("Geo-Fence", systemImage: "location.circle")
                            }

                            if note.isTimeLocked {
                                Button(role: .destructive) {
                                    note.removeTimeLock()
                                    SecurityAuditLogger.shared.log(event: .timeLockRemoved)
                                    try? note.managedObjectContext?.save()
                                } label: {
                                    Label("Remove Time Lock", systemImage: "lock.clock")
                                }
                            }

                            if note.isGeoFenced {
                                Button(role: .destructive) {
                                    note.removeGeoFence()
                                    SecurityAuditLogger.shared.log(event: .geoFenceRemoved)
                                    try? note.managedObjectContext?.save()
                                } label: {
                                    Label("Remove Geo-Fence", systemImage: "location.circle")
                                }
                            }
                        } label: {
                            Image(systemName: "lock.shield")
                        }

                        Button {
                            withAnimation { viewModel.showPreview.toggle() }
                        } label: {
                            Image(systemName: viewModel.showPreview ? "pencil" : "eye")
                        }
                    }
                }
            }
            .sheet(isPresented: $showTimeLockSetup) {
                TimeLockSetupView(unlockDate: Binding(
                    get: { note.unlockDate ?? Date().addingTimeInterval(3600) },
                    set: { newDate in
                        note.setTimeLock(until: newDate)
                        SecurityAuditLogger.shared.log(event: .timeLockSet, details: newDate.description)
                        try? note.managedObjectContext?.save()
                    }
                ))
            }
            .sheet(isPresented: $showGeoFenceSetup) {
                GeoFenceSetupView(
                    latitude: Binding(
                        get: { note.geoLatitude },
                        set: { _ in }
                    ),
                    longitude: Binding(
                        get: { note.geoLongitude },
                        set: { _ in }
                    ),
                    radius: Binding(
                        get: { note.geoRadius },
                        set: { _ in }
                    )
                )
                .onDisappear {
                    if note.geoLatitude != 0 || note.geoLongitude != 0 {
                        SecurityAuditLogger.shared.log(event: .geoFenceSet)
                        try? note.managedObjectContext?.save()
                    }
                }
            }
            .onAppear {
                viewModel.loadNote(note, key: cryptoKey, context: note.managedObjectContext ?? VaultDataController.shared.container.viewContext)
                isEditorFocused = true
            }
        }
    }

    var lockBadges: some View {
        HStack(spacing: 8) {
            if note.isTimeLocked {
                HStack(spacing: 4) {
                    Image(systemName: "lock.clock")
                        .font(.caption2)
                    if let date = note.unlockDate {
                        Text(date, style: .timer)
                            .font(.caption2)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
            }

            if note.isGeoFenced {
                HStack(spacing: 4) {
                    Image(systemName: "location.circle")
                        .font(.caption2)
                    Text("Geo-Locked")
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    var geoFenceContent: some View {
        GeoFenceStatusView(
            latitude: note.geoLatitude,
            longitude: note.geoLongitude,
            radius: note.geoRadius
        )
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
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(viewModel.tags, id: \.self) { tag in
                            TagChipView(
                                tag: tag,
                                onDelete: { viewModel.removeTag(tag) }
                            )
                        }
                    }
                }
            }

            HStack {
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

                TextField("Add tag...", text: $viewModel.tagInput)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        viewModel.addTag()
                    }

                if !viewModel.tagInput.isEmpty {
                    Button(action: viewModel.addTag) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if !viewModel.suggestedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(viewModel.suggestedTags.prefix(8), id: \.self) { tag in
                            TagChipView(
                                tag: tag,
                                onTap: {
                                    if !viewModel.tags.contains(tag) {
                                        viewModel.tags.append(tag)
                                        viewModel.suggestedTags.removeAll { $0 == tag }
                                        viewModel.saveNote()
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
