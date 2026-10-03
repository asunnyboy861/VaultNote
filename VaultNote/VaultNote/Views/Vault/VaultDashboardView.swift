import CryptoKit
import SwiftUI

struct VaultDashboardView: View {
    @EnvironmentObject var authManager: VaultAuthManager
    @EnvironmentObject var decoyManager: DecoyModeManager
    @EnvironmentObject var selfDestructManager: SelfDestructManager
    @StateObject private var viewModel = VaultDashboardViewModel()
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @AppStorage("screenshotProtectionEnabled") private var screenshotProtectionEnabled = true
    @AppStorage("selfDestructEnabled") private var selfDestructEnabled = false
    @AppStorage("shakeToDestroyEnabled") private var shakeToDestroyEnabled = false
    @State private var showingEditor = false
    @State private var selectedNote: VNNote?
    @State private var navigateToNotes = false
    @State private var navigateToCards = false
    @State private var navigateToVoiceMemos = false
    @State private var navigateToFiles = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                securityStatusHero
                quickActionsGrid
                vaultContentsSection
                recentNotesSection
            }
            .padding()
        }
        .navigationTitle("SealNotes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let newNote = createNewNote()
                    selectedNote = newNote
                    showingEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let note = selectedNote {
                NoteEditorView(note: note, cryptoKey: viewModel.cryptoKey)
            }
        }
        .navigationDestination(isPresented: $navigateToNotes) {
            NotesListView()
        }
        .navigationDestination(isPresented: $navigateToCards) {
            SecureCardListView()
        }
        .navigationDestination(isPresented: $navigateToVoiceMemos) {
            VoiceMemoListView()
        }
        .navigationDestination(isPresented: $navigateToFiles) {
            SecureFileListView()
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    var securityStatusHero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: scoreGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 6
                    )
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: scoreBackgroundColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 108, height: 108)

                VStack(spacing: 2) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 28))
                        .foregroundStyle(scoreForeground)
                    Text("\(viewModel.securityScore)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreForeground)
                }
            }

            Text(viewModel.scoreLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(scoreForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(icon: "note.text.badge.plus", title: "New Note", color: .blue) {
                    let newNote = createNewNote()
                    selectedNote = newNote
                    showingEditor = true
                }
                QuickActionCard(icon: "key.fill", title: "Secure Card", color: .purple) {
                    navigateToCards = true
                }
                QuickActionCard(icon: "mic.fill", title: "Voice Memo", color: .orange) {
                    navigateToVoiceMemos = true
                }
                QuickActionCard(icon: "doc.fill", title: "Secure File", color: .green) {
                    navigateToFiles = true
                }
            }
        }
    }

    var vaultContentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vault Contents")
                .font(.headline)

            HStack(spacing: 12) {
                VaultStatCard(icon: "note.text", count: viewModel.totalNotes, label: "Notes", color: .blue)
                VaultStatCard(icon: "creditcard", count: viewModel.totalCards, label: "Cards", color: .purple)
                VaultStatCard(icon: "mic", count: viewModel.totalVoiceMemos, label: "Memos", color: .orange)
                VaultStatCard(icon: "doc", count: viewModel.totalFiles, label: "Files", color: .green)
            }
        }
    }

    var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Notes")
                    .font(.headline)
                Spacer()
                if viewModel.totalNotes > 3 {
                    Button("See All") {
                        navigateToNotes = true
                    }
                    .font(.subheadline)
                }
            }

            if viewModel.recentNotes.isEmpty {
                emptyVaultState
            } else {
                ForEach(viewModel.recentNotes.prefix(3)) { note in
                    NoteRowView(note: note, cryptoKey: viewModel.cryptoKey)
                        .onTapGesture {
                            selectedNote = note
                            showingEditor = true
                        }
                }
            }
        }
    }

    var emptyVaultState: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Your vault is empty")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Tap + to start protecting your data")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func createNewNote() -> VNNote {
        let context = VaultDataController.shared.container.viewContext
        let note = VNNote.create(in: context, cryptoKey: viewModel.cryptoKey)
        viewModel.loadData()
        return note
    }

    private var scoreGradientColors: [Color] {
        viewModel.securityScore >= 80 ? [.green, .green.opacity(0.6)]
        : viewModel.securityScore >= 40 ? [.orange, .orange.opacity(0.6)]
        : [.red, .red.opacity(0.6)]
    }

    private var scoreBackgroundColors: [Color] {
        viewModel.securityScore >= 80 ? [.green.opacity(0.15), .green.opacity(0.05)]
        : viewModel.securityScore >= 40 ? [.orange.opacity(0.15), .orange.opacity(0.05)]
        : [.red.opacity(0.15), .red.opacity(0.05)]
    }

    private var scoreForeground: Color {
        viewModel.securityScore >= 80 ? .green
        : viewModel.securityScore >= 40 ? .orange : .red
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct VaultStatCard: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.system(.title3, design: .rounded).weight(.bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
