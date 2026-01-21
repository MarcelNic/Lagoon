//
//  ScenarioDetailSheet.swift
//  Lagoon
//

import SwiftUI

struct ScenarioDetailSheet: View {
    let type: ScenarioType
    @Bindable var state: PoolcareState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch type {
                case .vacation:
                    VacationScenarioContent(state: state)
                case .season:
                    SeasonScenarioContent(state: state)
                }
            }
            .navigationTitle(type.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

struct VacationScenarioContent: View {
    @Bindable var state: PoolcareState

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { state.vacationScenario.isActive },
                    set: { _ in state.toggleVacationMode() }
                )) {
                    Label("Urlaubsmodus aktiv", systemImage: "airplane")
                }
            }

            Section("Davor") {
                ForEach(state.vacationScenario.beforeChecklist) { item in
                    ScenarioChecklistRow(item: item) {
                        state.toggleVacationItem(item, in: .before)
                    }
                }
            }

            Section("Danach") {
                ForEach(state.vacationScenario.afterChecklist) { item in
                    ScenarioChecklistRow(item: item) {
                        state.toggleVacationItem(item, in: .after)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct SeasonScenarioContent: View {
    @Bindable var state: PoolcareState

    var body: some View {
        Form {
            Section {
                Picker("Aktueller Modus", selection: Binding(
                    get: { state.seasonScenario.currentMode },
                    set: { _ in state.toggleSeasonMode() }
                )) {
                    ForEach(SeasonMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Pool öffnen") {
                ForEach(state.seasonScenario.openingChecklist) { item in
                    ScenarioChecklistRow(item: item) {
                        state.toggleSeasonItem(item, in: .opening)
                    }
                }
            }

            Section("Einwinterung") {
                ForEach(state.seasonScenario.closingChecklist) { item in
                    ScenarioChecklistRow(item: item) {
                        state.toggleSeasonItem(item, in: .closing)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct ScenarioChecklistRow: View {
    let item: ScenarioChecklistItem
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)

                Text(item.title)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .strikethrough(item.isCompleted)
            }
        }
        .buttonStyle(.plain)
    }
}
