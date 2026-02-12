//
//  EditTaskSheet.swift
//  Lagoon
//

import SwiftUI

struct EditTaskSheet: View {
    let task: CareTask
    @Bindable var state: PoolcareState
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var selectedIcon: String
    @State private var dueDate: Date
    @State private var intervalDays: Int
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var remindAfterTimer: Bool
    @State private var actionHours: Int
    @State private var actionMinutes: Int

    private let intervalOptions: [(String, Int)] = [
        ("Einmalig", 0),
        ("Täglich", 1),
        ("Alle 2 Tage", 2),
        ("Wöchentlich", 7),
        ("Alle 2 Wochen", 14),
        ("Monatlich", 30),
    ]

    init(task: CareTask, state: PoolcareState) {
        self.task = task
        self.state = state
        _title = State(initialValue: task.title)
        _selectedIcon = State(initialValue: task.iconName ?? "water.waves")
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _intervalDays = State(initialValue: task.intervalDays)
        _reminderEnabled = State(initialValue: task.reminderTime != nil)
        _reminderTime = State(initialValue: task.reminderTime ?? {
            var c = DateComponents()
            c.hour = 9; c.minute = 0
            return Calendar.current.date(from: c) ?? Date()
        }())
        _remindAfterTimer = State(initialValue: task.remindAfterTimer)
        let secs = Int(task.actionDurationSeconds)
        _actionHours = State(initialValue: secs / 3600)
        _actionMinutes = State(initialValue: (secs % 3600) / 60)
    }

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

                Section("Fälligkeit") {
                    DatePicker("Fällig am", selection: $dueDate, displayedComponents: .date)

                    Picker("Intervall", selection: $intervalDays) {
                        ForEach(intervalOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                }

                if task.isAction {
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

                Section("Erinnerung") {
                    Toggle("Erinnern", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                    if task.isAction {
                        Toggle("Nach Timer-Ablauf", isOn: $remindAfterTimer)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        state.deleteTask(task)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Aufgabe löschen")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveChanges()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        let duration = Double(actionHours * 3600 + actionMinutes * 60)
        task.iconName = selectedIcon
        task.isCustomIcon = customTaskIconNames.contains(selectedIcon)
        task.reminderTime = reminderEnabled ? reminderTime : nil
        task.remindAfterTimer = task.isAction ? remindAfterTimer : false
        state.updateTask(
            task,
            title: title,
            dueDate: dueDate,
            intervalDays: intervalDays,
            actionDurationSeconds: task.isAction ? duration : nil
        )
    }
}
