//
//  AddItemSheet.swift
//  Lagoon
//

import SwiftUI

struct AddItemSheet: View {
    @Bindable var state: PoolcareState
    @Environment(\.dismiss) private var dismiss

    @State private var itemType: ItemType = .task
    @State private var title = ""
    @State private var selectedIcon = "water.waves"
    @State private var dueDate = Date()
    @State private var intervalDays = 0
    @State private var reminderEnabled = true
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var remindAfterTimer = true
    @State private var actionHours = 1
    @State private var actionMinutes = 0

    enum ItemType: String, CaseIterable {
        case task = "Aufgabe"
        case action = "Timer"
    }

    private let intervalOptions: [(String, Int)] = [
        ("Einmalig", 0),
        ("Täglich", 1),
        ("Alle 2 Tage", 2),
        ("Wöchentlich", 7),
        ("Alle 2 Wochen", 14),
        ("Monatlich", 30),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $title)
                }

                Section("Symbol") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        Button {
                            selectedIcon = "Robi"
                        } label: {
                            Image("Robi")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .frame(width: 44, height: 44)
                                .foregroundStyle(selectedIcon == "Robi" ? .white : .primary)
                                .background {
                                    if selectedIcon == "Robi" {
                                        Circle()
                                            .fill(.tint)
                                    }
                                }
                        }
                        .buttonStyle(.plain)

                        ForEach(taskIconOptions, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                    .background {
                                        if selectedIcon == icon {
                                            Circle()
                                                .fill(.tint)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                if itemType == .action {
                    Section("Timer-Dauer") {
                        HStack(spacing: 0) {
                            Picker("Stunden", selection: $actionHours) {
                                ForEach(0..<24) { Text("\($0) h").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)

                            Picker("Minuten", selection: $actionMinutes) {
                                ForEach(0..<60) { Text("\($0) m").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                    }
                }

                Section("Fälligkeit") {
                    DatePicker("Fällig ab", selection: $dueDate, displayedComponents: .date)

                    Picker("Intervall", selection: $intervalDays) {
                        ForEach(intervalOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                }

                Section("Erinnerung") {
                    Toggle("Erinnern", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                    if itemType == .action {
                        Toggle("Nach Timer-Ablauf", isOn: $remindAfterTimer)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.large])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .principal) {
                    Picker("Typ", selection: $itemType) {
                        ForEach(ItemType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        addItem()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addItem() {
        guard let scenario = state.currentScenario() else { return }
        let duration = Double(actionHours * 3600 + actionMinutes * 60)

        state.addTask(
            to: scenario,
            title: title,
            dueDate: dueDate,
            intervalDays: intervalDays,
            isAction: itemType == .action,
            actionDurationSeconds: itemType == .action ? duration : 0,
            iconName: selectedIcon,
            isCustomIcon: customTaskIconNames.contains(selectedIcon),
            reminderTime: reminderEnabled ? reminderTime : nil,
            remindAfterTimer: itemType == .action ? remindAfterTimer : false
        )
    }
}
