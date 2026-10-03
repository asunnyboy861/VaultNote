import Foundation

enum CardTemplateType: String, Codable, CaseIterable {
    case password = "password"
    case creditCard = "credit_card"
    case identity = "identity"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .password: return "Password"
        case .creditCard: return "Credit Card"
        case .identity: return "ID Card"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .password: return "key"
        case .creditCard: return "creditcard"
        case .identity: return "person.badge.key"
        case .custom: return "square.grid.2x2"
        }
    }

    var color: String {
        switch self {
        case .password: return "blue"
        case .creditCard: return "green"
        case .identity: return "orange"
        case .custom: return "purple"
        }
    }

    var fields: [CardField] {
        switch self {
        case .password:
            return [
                CardField(name: "Website", type: .url, isRequired: true),
                CardField(name: "Username", type: .text, isRequired: true),
                CardField(name: "Password", type: .password, isRequired: true),
                CardField(name: "Notes", type: .text, isRequired: false)
            ]
        case .creditCard:
            return [
                CardField(name: "Card Number", type: .number, isRequired: true),
                CardField(name: "Cardholder", type: .text, isRequired: true),
                CardField(name: "Expiry", type: .text, isRequired: true),
                CardField(name: "CVV", type: .password, isRequired: true),
                CardField(name: "Notes", type: .text, isRequired: false)
            ]
        case .identity:
            return [
                CardField(name: "Full Name", type: .text, isRequired: true),
                CardField(name: "ID Number", type: .text, isRequired: true),
                CardField(name: "Issue Date", type: .date, isRequired: false),
                CardField(name: "Expiry Date", type: .date, isRequired: false),
                CardField(name: "Notes", type: .text, isRequired: false)
            ]
        case .custom:
            return []
        }
    }
}

enum CardFieldType: String, Codable {
    case text
    case password
    case number
    case url
    case date
}

struct CardField: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var type: CardFieldType
    var isRequired: Bool

    init(name: String, type: CardFieldType, isRequired: Bool = false) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.isRequired = isRequired
    }
}
