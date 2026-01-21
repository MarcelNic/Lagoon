//
//  LogbookEditSheet.swift
//  Lagoon
//

import SwiftUI

struct LogbookEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: LogbookEntry
    @Bindable var state: MeinPoolState

    @State private var editedEntry: LogbookEntry
    @State private var showDeleteConfirmation = false

    init(entry: LogbookEntry, state: MeinPoolState) {
        self.entry = entry
        self.state = state
        self._editedEntry = State(initialValue: entry)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    switch editedEntry.type {
                    case .messen:
                        messenFields
                    case .dosieren:
                        dosierenFields
                    case .poolpflege:
                        poolpflegeFields
                    }
                }

                Section("Zeitpunkt") {
                    DatePicker(
                        "Datum & Uhrzeit",
                        selection: $editedEntry.timestamp,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Eintrag löschen", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Eintrag bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        updateSummary()
                        state.updateEntry(editedEntry)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Eintrag löschen?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    state.deleteEntry(entry)
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
    }

    // MARK: - Messen Fields

    @ViewBuilder
    private var messenFields: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("pH-Wert")
                Spacer()
                Text(String(format: "%.1f", editedEntry.phValue ?? 7.2))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { editedEntry.phValue ?? 7.2 },
                    set: { editedEntry.phValue = $0 }
                ),
                in: 6.0...8.5,
                step: 0.1
            )
        }

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Chlor (mg/l)")
                Spacer()
                Text(String(format: "%.1f", editedEntry.chlorineValue ?? 1.0))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { editedEntry.chlorineValue ?? 1.0 },
                    set: { editedEntry.chlorineValue = $0 }
                ),
                in: 0.0...5.0,
                step: 0.1
            )
        }

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Wassertemperatur (°C)")
                Spacer()
                Text(String(format: "%.0f", editedEntry.waterTemperature ?? 24))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { editedEntry.waterTemperature ?? 24 },
                    set: { editedEntry.waterTemperature = $0 }
                ),
                in: 10...40,
                step: 1
            )
        }
    }

    // MARK: - Dosieren Fields

    @ViewBuilder
    private var dosierenFields: some View {
        Picker("Produkt", selection: Binding(
            get: { editedEntry.product ?? "pH-Minus" },
            set: { editedEntry.product = $0 }
        )) {
            Text("pH-Minus").tag("pH-Minus")
            Text("pH-Plus").tag("pH-Plus")
            Text("Chlorgranulat").tag("Chlorgranulat")
            Text("Chlortabletten").tag("Chlortabletten")
            Text("Algizid").tag("Algizid")
            Text("Flockmittel").tag("Flockmittel")
        }

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Menge")
                Spacer()
                Text("\(Int(editedEntry.amount ?? 50)) \(editedEntry.unit ?? "g")")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { editedEntry.amount ?? 50 },
                    set: { editedEntry.amount = $0 }
                ),
                in: 10...500,
                step: 10
            )
        }

        Picker("Einheit", selection: Binding(
            get: { editedEntry.unit ?? "g" },
            set: { editedEntry.unit = $0 }
        )) {
            Text("g").tag("g")
            Text("ml").tag("ml")
            Text("Tabletten").tag("Tabletten")
        }
    }

    // MARK: - Poolpflege Fields

    @ViewBuilder
    private var poolpflegeFields: some View {
        TextField("Beschreibung", text: Binding(
            get: { editedEntry.description ?? "" },
            set: { editedEntry.description = $0 }
        ), axis: .vertical)
        .lineLimit(2...4)
    }

    // MARK: - Helper

    private func updateSummary() {
        switch editedEntry.type {
        case .messen:
            let ph = String(format: "%.1f", editedEntry.phValue ?? 7.2)
            let cl = String(format: "%.1f", editedEntry.chlorineValue ?? 1.0)
            editedEntry.summary = "pH \(ph) · Cl \(cl) mg/l"
        case .dosieren:
            let amount = Int(editedEntry.amount ?? 50)
            let unit = editedEntry.unit ?? "g"
            let product = editedEntry.product ?? ""
            editedEntry.summary = "\(amount) \(unit) \(product)"
        case .poolpflege:
            editedEntry.summary = editedEntry.description ?? ""
        }
    }
}

#Preview {
    LogbookEditSheet(
        entry: LogbookEntry.sampleEntries()[0],
        state: MeinPoolState()
    )
}
