import CryptoKit
import SwiftUI

struct SecureCardEditorView: View {
    @ObservedObject var card: VNSecureCard
    let cryptoKey: SymmetricKey
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var title = ""
    @State private var fieldValues: [String: String] = [:]
    @State private var customFields: [CardField] = []
    @State private var showAddCustomField = false
    @State private var newFieldName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Info") {
                    TextField("Title", text: $title)

                    HStack {
                        Label(card.templateType.displayName, systemImage: card.templateType.icon)
                        Spacer()
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Section("Details") {
                    ForEach(templateFields) { field in
                        cardFieldRow(field)
                    }

                    ForEach(customFields) { field in
                        cardFieldRow(field)
                    }

                    if card.templateType == .custom {
                        addCustomFieldRow
                    }
                }
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveCard() }
                        .font(.headline)
                }
            }
            .onAppear {
                title = card.title ?? ""
                fieldValues = card.decryptFields(with: cryptoKey)
                if card.templateType == .custom, fieldValues.isEmpty == false {
                    customFields = fieldValues.keys.map { CardField(name: $0, type: .text) }
                }
            }
        }
    }

    private var templateFields: [CardField] {
        card.templateType.fields
    }

    private func cardFieldRow(_ field: CardField) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.name)
                .font(.caption)
                .foregroundStyle(.secondary)

            if field.type == .password {
                SecureField("Enter \(field.name.lowercased())", text: bindingFor(field.name))
                    .textContentType(.password)
            } else if field.type == .number {
                TextField("Enter \(field.name.lowercased())", text: bindingFor(field.name))
                    .keyboardType(.numberPad)
            } else if field.type == .url {
                TextField("Enter \(field.name.lowercased())", text: bindingFor(field.name))
                    .textContentType(.URL)
                    .autocapitalization(.none)
            } else if field.type == .date {
                TextField("e.g. 01/2026", text: bindingFor(field.name))
            } else {
                TextField("Enter \(field.name.lowercased())", text: bindingFor(field.name))
            }
        }
    }

    private var addCustomFieldRow: some View {
        Group {
            if showAddCustomField {
                HStack {
                    TextField("Field name", text: $newFieldName)
                    Button("Add") {
                        guard !newFieldName.isEmpty else { return }
                        let field = CardField(name: newFieldName, type: .text)
                        customFields.append(field)
                        fieldValues[newFieldName] = ""
                        newFieldName = ""
                        showAddCustomField = false
                    }
                    .font(.subheadline.weight(.medium))
                }
            } else {
                Button {
                    showAddCustomField = true
                } label: {
                    Label("Add Custom Field", systemImage: "plus.circle")
                }
            }
        }
    }

    private func bindingFor(_ key: String) -> Binding<String> {
        Binding(
            get: { fieldValues[key] ?? "" },
            set: { fieldValues[key] = $0 }
        )
    }

    private func saveCard() {
        card.title = title
        card.updateFields(fieldValues, with: cryptoKey)
        try? viewContext.save()
        dismiss()
    }
}
