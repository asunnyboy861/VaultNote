import CryptoKit
import SwiftUI

struct CardTemplatePickerView: View {
    let onSelect: (CardTemplateType) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(CardTemplateType.allCases, id: \.self) { template in
                Button {
                    onSelect(template)
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(templateColor(template).opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: template.icon)
                                .font(.title3)
                                .foregroundStyle(templateColor(template))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(template.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(templateDescription(template))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Choose Card Type")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func templateColor(_ template: CardTemplateType) -> Color {
        switch template {
        case .password: return .blue
        case .creditCard: return .green
        case .identity: return .orange
        case .custom: return .purple
        }
    }

    private func templateDescription(_ template: CardTemplateType) -> String {
        switch template {
        case .password: return "Store website logins and passwords"
        case .creditCard: return "Keep credit card details secure"
        case .identity: return "Protect ID cards and documents"
        case .custom: return "Create your own card template"
        }
    }
}
