//
//  ScenarioSheets.swift
//  Lagoon
//

import SwiftUI
import SwiftData

// MARK: - New Scenario Sheet

struct NewScenarioSheet: View {
    @Bindable var state: PoolcareState
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CareScenario.sortOrder) private var scenarios: [CareScenario]

    @State private var name = ""
    @State private var selectedIcon = "leaf.fill"
    @State private var nextScenarioId: UUID?

    private let iconOptions = scenarioIconOptions

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(iconOptions, id: \.self) { icon in
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

                Section("Wenn alles erledigt, wechseln zu") {
                    Picker("Folge-Szenario", selection: $nextScenarioId) {
                        Text("Keins").tag(UUID?.none)
                        Divider()
                        ForEach(scenarios) { s in
                            Text(s.name).tag(UUID?.some(s.id))
                        }
                    }
                }
            }
            .navigationTitle("Neues Szenario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let scenario = state.createScenario(name: name, icon: selectedIcon)
                        scenario.nextScenarioId = nextScenarioId
                        state.currentScenarioId = scenario.id
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Scenario Sheet

struct EditScenarioSheet: View {
    let scenario: CareScenario
    @Bindable var state: PoolcareState
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CareScenario.sortOrder) private var scenarios: [CareScenario]

    @State private var name: String
    @State private var selectedIcon: String
    @State private var nextScenarioId: UUID?
    @State private var showDeleteConfirmation = false

    private let iconOptions = scenarioIconOptions

    init(scenario: CareScenario, state: PoolcareState) {
        self.scenario = scenario
        self.state = state
        _name = State(initialValue: scenario.name)
        _selectedIcon = State(initialValue: scenario.icon)
        _nextScenarioId = State(initialValue: scenario.nextScenarioId)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(iconOptions, id: \.self) { icon in
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

                Section("Wenn alles erledigt, wechseln zu") {
                    Picker("Folge-Szenario", selection: $nextScenarioId) {
                        Text("Keins").tag(UUID?.none)
                        Divider()
                        ForEach(scenarios.filter { $0.id != scenario.id }) { s in
                            Text(s.name).tag(UUID?.some(s.id))
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Szenario löschen")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Szenario bearbeiten")
            .alert("Szenario löschen?", isPresented: $showDeleteConfirmation) {
                Button("Löschen", role: .destructive) {
                    state.deleteScenario(scenario)
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Das Szenario \"\(scenario.name)\" und alle zugehörigen Aufgaben werden unwiderruflich gelöscht.")
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        scenario.name = name
                        scenario.icon = selectedIcon
                        scenario.nextScenarioId = nextScenarioId
                        try? state.modelContext?.save()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Scenario Icon Options

let scenarioIconOptions = [
    // Wasser / Pool
    "drop.fill", "drop.triangle.fill", "water.waves", "figure.pool.swim",
    // Temperatur
    "thermometer.medium", "thermometer.sun", "thermometer.snowflake", "flame.fill",
    // Wetter / Jahreszeiten
    "sun.max.fill", "snowflake", "cloud.fill", "wind",
    "moon.fill", "leaf.fill", "umbrella.fill", "bolt.fill",
    // Werkzeug / Chemie
    "wrench.fill", "gearshape.fill", "sparkles", "testtube.2",
    "flask.fill", "lightbulb.fill",
    // Szenarien / Lifestyle
    "door.left.hand.open", "power", "calendar", "checklist",
    "airplane", "suitcase.fill", "house.fill", "tent.fill",
    "person.2.fill", "flag.fill",
    // Allgemein
    "heart.fill", "star.fill", "arrow.triangle.2.circlepath", "exclamationmark.triangle.fill",
]
