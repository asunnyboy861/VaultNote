import CoreData
import CryptoKit
import SwiftUI

struct SecureCardListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = SecureCardListViewModel()
    @State private var showingEditor = false
    @State private var selectedCard: VNSecureCard?
    @State private var showingTemplatePicker = false

    var body: some View {
        List {
            if viewModel.cards.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.cards) { card in
                    SecureCardRow(card: card, cryptoKey: viewModel.cryptoKey)
                        .onTapGesture {
                            selectedCard = card
                            showingEditor = true
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteCard(card)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Secure Cards")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingTemplatePicker = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingTemplatePicker) {
            NavigationStack {
                CardTemplatePickerView { templateType in
                    showingTemplatePicker = false
                    let card = viewModel.createCard(templateType: templateType)
                    selectedCard = card
                    showingEditor = true
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let card = selectedCard {
                SecureCardEditorView(card: card, cryptoKey: viewModel.cryptoKey)
            }
        }
        .onAppear {
            viewModel.fetchCards()
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Secure Cards")
                .font(.title2.weight(.medium))
            Text("Store passwords, credit cards, and IDs with military-grade encryption")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct SecureCardRow: View {
    let card: VNSecureCard
    let cryptoKey: SymmetricKey

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(templateColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: card.templateType.icon)
                    .font(.body)
                    .foregroundStyle(templateColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(card.title ?? "Untitled")
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(card.templateType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var templateColor: Color {
        switch card.templateType {
        case .password: return .blue
        case .creditCard: return .green
        case .identity: return .orange
        case .custom: return .purple
        }
    }
}

final class SecureCardListViewModel: ObservableObject {
    @Published var cards: [VNSecureCard] = []

    let cryptoKey: SymmetricKey

    init() {
        let salt = VaultCrypto.getOrCreateSalt()
        cryptoKey = VaultCrypto.deriveKey(from: "default", salt: salt)
    }

    func fetchCards() {
        let context = VaultDataController.shared.container.viewContext
        let request = VNSecureCard.fetchRequest() as NSFetchRequest<VNSecureCard>
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        cards = (try? context.fetch(request)) ?? []
    }

    @discardableResult
    func createCard(templateType: CardTemplateType) -> VNSecureCard {
        let context = VaultDataController.shared.container.viewContext
        let card = VNSecureCard.create(
            in: context,
            title: "New \(templateType.displayName)",
            cardType: templateType,
            fields: [:],
            cryptoKey: cryptoKey
        )
        SecurityAuditLogger.shared.log(event: .secureCardCreated, details: templateType.displayName)
        fetchCards()
        return card
    }

    func deleteCard(_ card: VNSecureCard) {
        let context = VaultDataController.shared.container.viewContext
        context.delete(card)
        try? context.save()
        fetchCards()
    }
}
