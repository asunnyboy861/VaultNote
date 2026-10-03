import SwiftUI

struct TimeLockSetupView: View {
    @Binding var unlockDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPreset: TimeLockPreset = .custom
    @State private var customDate = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Presets") {
                    ForEach(TimeLockPreset.allCases) { preset in
                        Button {
                            selectedPreset = preset
                            if preset != .custom {
                                customDate = preset.date
                            }
                        } label: {
                            HStack {
                                Label(preset.displayName, systemImage: preset.icon)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedPreset == preset {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                if selectedPreset == .custom {
                    Section("Custom Date & Time") {
                        DatePicker("Unlock Date", selection: $customDate, in: Date()...)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("How Time-Lock Works", systemImage: "info.circle")
                            .font(.subheadline.weight(.medium))
                        Text("Once set, this note cannot be viewed until the unlock date. The content remains encrypted and inaccessible even to you.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Time Lock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Set Lock") {
                        unlockDate = customDate
                        dismiss()
                    }
                    .font(.headline)
                    .disabled(customDate <= Date())
                }
            }
        }
    }
}

enum TimeLockPreset: String, CaseIterable, Identifiable {
    case oneHour = "1h"
    case tomorrow = "tomorrow"
    case nextWeek = "next_week"
    case nextMonth = "next_month"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneHour: return "1 Hour"
        case .tomorrow: return "Tomorrow"
        case .nextWeek: return "Next Week"
        case .nextMonth: return "Next Month"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .oneHour: return "clock"
        case .tomorrow: return "sunrise"
        case .nextWeek: return "calendar"
        case .nextMonth: return "calendar.badge.clock"
        case .custom: return "slider.horizontal.3"
        }
    }

    var date: Date {
        switch self {
        case .oneHour: return Date().addingTimeInterval(3600)
        case .tomorrow: return Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        case .nextWeek: return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!
        case .nextMonth: return Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        case .custom: return Date().addingTimeInterval(3600)
        }
    }
}
