//
//  AddItemSheet.swift
//  Lagoon
//

import SwiftUI

struct TaskTemplate: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let isCustomIcon: Bool
    let isAction: Bool
    let intervalDays: Int
    let durationSeconds: Double // nur für Aktionen

    init(title: String, icon: String, isCustomIcon: Bool = false, isAction: Bool = false, intervalDays: Int = 0, durationSeconds: Double = 0) {
        self.title = title
        self.icon = icon
        self.isCustomIcon = isCustomIcon
        self.isAction = isAction
        self.intervalDays = intervalDays
        self.durationSeconds = durationSeconds
    }
}

let taskTemplates: [TaskTemplate] = [
    // Tägliche Aufgaben
    TaskTemplate(title: "Käschern", icon: "leaf.fill", intervalDays: 1),
    TaskTemplate(title: "Skimmer leeren", icon: "xmark.bin.fill", intervalDays: 7),
    TaskTemplate(title: "Pumpenkorb leeren", icon: "basket.fill", intervalDays: 7),
    TaskTemplate(title: "Wasserstand prüfen", icon: "arrow.up.and.down.circle", intervalDays: 7),
    TaskTemplate(title: "Filterdruck prüfen", icon: "gauge.with.dots.needle.50percent", intervalDays: 7),
    TaskTemplate(title: "Wasserlinie bürsten", icon: "bubbles.and.sparkles", intervalDays: 14),
    TaskTemplate(title: "Boden saugen", icon: "water.waves", intervalDays: 7),
    TaskTemplate(title: "Abdeckung prüfen", icon: "checkmark.circle", intervalDays: 30),
    // Aktionen (mit Timer)
    TaskTemplate(title: "Roboter", icon: "Robi", isCustomIcon: true, isAction: true, intervalDays: 2, durationSeconds: 7200),
    TaskTemplate(title: "Rückspülen", icon: "arrow.counterclockwise.circle", isAction: true, intervalDays: 7, durationSeconds: 180),
    TaskTemplate(title: "Stoßchloren", icon: "bolt.circle.fill"),
    TaskTemplate(title: "Wasser nachfüllen", icon: "spigot.fill", isAction: true, durationSeconds: 3600),
    TaskTemplate(title: "Wasser ablassen", icon: "water.waves.and.arrow.trianglehead.down"),
    TaskTemplate(title: "Wasser einlassen", icon: "drop.fill"),
    // Einmalige Aufgaben
    TaskTemplate(title: "Heizung anschalten", icon: "flame.fill"),
    TaskTemplate(title: "Ventil öffnen", icon: "pipe.and.drop"),
    TaskTemplate(title: "Ventil schließen", icon: "arrow.up.and.down.circle"),
    TaskTemplate(title: "Poollicht", icon: "lightbulb.fill"),
    TaskTemplate(title: "Kärchern", icon: "figure.hunting"),
    TaskTemplate(title: "Abdeckung schließen", icon: "rectangle.inset.filled"),
    TaskTemplate(title: "Abdeckung öffnen", icon: "rectangle.lefthalf.inset.filled"),
]

struct AddItemSheet: View {
    @Bindable var state: PoolcareState
    @Environment(\.dismiss) private var dismiss

    @State private var itemType: ItemType = .task
    @State private var title = ""
    @State private var selectedIcon = "water.waves"
    @State private var showTemplates = false
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
                    Button {
                        showTemplates = true
                    } label: {
                        Label("Vorlagen", systemImage: "list.bullet")
                    }
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
        .sheet(isPresented: $showTemplates) {
            NavigationStack {
                List(taskTemplates) { template in
                    Button {
                        title = template.title
                        selectedIcon = template.icon
                        itemType = template.isAction ? .action : .task
                        intervalDays = template.intervalDays
                        let totalSeconds = Int(template.durationSeconds)
                        actionHours = totalSeconds / 3600
                        actionMinutes = (totalSeconds % 3600) / 60
                        showTemplates = false
                    } label: {
                        HStack(spacing: 12) {
                            if template.isCustomIcon {
                                Image(template.icon)
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: template.icon)
                            }
                            Text(template.title)
                        }
                    }
                }
                .navigationTitle("Vorlage")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { showTemplates = false }
                    }
                }
            }
            .presentationDetents([.medium])
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
