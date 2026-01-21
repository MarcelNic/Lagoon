//
//  AddItemSheet.swift
//  Lagoon
//

import SwiftUI

enum AddItemType: String, CaseIterable {
    case action = "Aktion"
    case task = "Aufgabe"
    case scenario = "Szenario"
}

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var state: PoolcareState
    @State private var selectedType: AddItemType = .task

    // Task fields
    @State private var taskTitle: String = ""
    @State private var taskSubtitle: String = "Heute fällig"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment Control
                Picker("Typ", selection: $selectedType) {
                    ForEach(AddItemType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Content based on selection
                Form {
                    switch selectedType {
                    case .action:
                        actionContent
                    case .task:
                        taskContent
                    case .scenario:
                        scenarioContent
                    }
                }
                .formStyle(.grouped)
            }
            .navigationTitle("Hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        addItem()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canAdd)
                }
            }
        }
    }

    // MARK: - Action Content

    @ViewBuilder
    private var actionContent: some View {
        Section {
            Button {
                state.startAction(.robot)
                dismiss()
            } label: {
                Label("Roboter starten", systemImage: "figure.pool.swim")
            }

            Button {
                state.startAction(.backwash)
                dismiss()
            } label: {
                Label("Rückspülen starten", systemImage: "arrow.circlepath")
            }
        } header: {
            Text("Timer starten")
        }
    }

    // MARK: - Task Content

    @ViewBuilder
    private var taskContent: some View {
        Section {
            TextField("Titel", text: $taskTitle)

            Picker("Fälligkeit", selection: $taskSubtitle) {
                Text("Heute fällig").tag("Heute fällig")
                Text("Morgen fällig").tag("Morgen fällig")
                Text("Wöchentlich").tag("Wöchentlich")
                Text("Monatlich").tag("Monatlich")
            }
        } header: {
            Text("Neue Aufgabe")
        }

        Section {
            Button {
                taskTitle = "Skimmer leeren"
                taskSubtitle = "Heute fällig"
            } label: {
                Text("Skimmer leeren")
            }

            Button {
                taskTitle = "Wasserlinie bürsten"
                taskSubtitle = "Wöchentlich"
            } label: {
                Text("Wasserlinie bürsten")
            }

            Button {
                taskTitle = "Filterdruck prüfen"
                taskSubtitle = "Wöchentlich"
            } label: {
                Text("Filterdruck prüfen")
            }

            Button {
                taskTitle = "Poolboden saugen"
                taskSubtitle = "Wöchentlich"
            } label: {
                Text("Poolboden saugen")
            }
        } header: {
            Text("Vorschläge")
        }
    }

    // MARK: - Scenario Content

    @ViewBuilder
    private var scenarioContent: some View {
        Section {
            Button {
                state.toggleVacationMode()
                dismiss()
            } label: {
                HStack {
                    Label("Urlaubsmodus", systemImage: "airplane")
                    Spacer()
                    Text(state.vacationScenario.isActive ? "Aktiv" : "Inaktiv")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Urlaubsmodus umschalten")
        }

        Section {
            Button {
                state.toggleSeasonMode()
                dismiss()
            } label: {
                HStack {
                    Label("Saisonwechsel", systemImage: "snowflake")
                    Spacer()
                    Text(state.seasonScenario.currentMode == .summer ? "→ Winter" : "→ Sommer")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Saison umschalten")
        }
    }

    // MARK: - Logic

    private var canAdd: Bool {
        switch selectedType {
        case .action:
            return true
        case .task:
            return !taskTitle.isEmpty
        case .scenario:
            return true
        }
    }

    private func addItem() {
        switch selectedType {
        case .action:
            break // Handled by buttons directly
        case .task:
            guard !taskTitle.isEmpty else { return }
            state.addTask(title: taskTitle, subtitle: taskSubtitle)
        case .scenario:
            break // Handled by buttons directly
        }
    }
}
