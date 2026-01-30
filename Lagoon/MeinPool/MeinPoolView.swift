//
//  MeinPoolView.swift
//  Lagoon
//

import SwiftUI
import SwiftData

struct MeinPoolView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PoolWaterState.self) private var poolWaterState
    @AppStorage("poolName") private var poolName: String = "Pool"
    @State private var meinPoolState = MeinPoolState()
    @Binding var showSettings: Bool
    @State private var selectedEntry: LogbookEntry?

    // Init für Binding
    init(showSettings: Binding<Bool> = .constant(false)) {
        self._showSettings = showSettings
    }

    // Separate sheet states for each type
    @State private var showMessenSheet = false
    @State private var showDosierenSheet = false
    @State private var showPflegeSheet = false
    @State private var entryToEdit: LogbookEntry?

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                stops: [
                    .init(color: Color(light: Color(hex: "0443a6"), dark: Color(hex: "0a1628")), location: 0.0),
                    .init(color: Color(light: Color(hex: "b2e1ec"), dark: Color(hex: "1a3a5c")), location: 0.5),
                    .init(color: Color(light: Color(hex: "2fb4a0"), dark: Color(hex: "1a3a5c")), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .scaleEffect(1.2)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    VStack(spacing: 12) {
                        PoolIdentityCard(
                            poolName: poolName,
                            isVacationModeActive: false
                        )

                        InfoPillsRow(state: meinPoolState)
                    }

                    // Logbook Section
                    LogbookSection(
                        state: meinPoolState,
                        selectedEntry: $selectedEntry
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }

        }
        .safeAreaInset(edge: .top) {
            HStack {
                Text("Status")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color(light: .black, dark: .white))

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: selectedEntry) { _, entry in
            guard let entry = entry else { return }
            entryToEdit = entry
            selectedEntry = nil

            switch entry.type {
            case .messen:
                showMessenSheet = true
            case .dosieren:
                showDosierenSheet = true
            case .poolpflege:
                showPflegeSheet = true
            }
        }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: showSettings) { _, isShowing in
            if !isShowing {
                poolWaterState.reloadSettings()
            }
        }
        .sheet(isPresented: $showMessenSheet) {
            EditMessenSheet(entry: entryToEdit, state: meinPoolState)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDosierenSheet) {
            EditDosierenSheet(entry: entryToEdit, state: meinPoolState)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPflegeSheet) {
            if let entry = entryToEdit {
                LogbookEditSheet(entry: entry, state: meinPoolState)
                    .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            meinPoolState.setModelContext(modelContext)
        }
    }
}

// MARK: - Edit Messen Sheet

struct EditMessenSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: LogbookEntry?
    @Bindable var state: MeinPoolState

    @State private var phValue: Double = 7.2
    @State private var chlorineValue: Double = 1.0
    @State private var waterTemperature: Double = 26.0
    @State private var measurementDate: Date = Date()

    init(entry: LogbookEntry? = nil, state: MeinPoolState) {
        self.entry = entry
        self.state = state
        if let entry = entry {
            _phValue = State(initialValue: entry.phValue ?? 7.2)
            _chlorineValue = State(initialValue: entry.chlorineValue ?? 1.0)
            _waterTemperature = State(initialValue: entry.waterTemperature ?? 26.0)
            _measurementDate = State(initialValue: entry.timestamp)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("pH-Wert", systemImage: "drop.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(String(format: "%.1f", phValue))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: phValue)
                        }
                        Slider(value: $phValue, in: 6.0...9.0, step: 0.1)
                            .tint(.phIdealColor)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Chlor", systemImage: "allergens.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(String(format: "%.1f mg/l", chlorineValue))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: chlorineValue)
                        }
                        Slider(value: $chlorineValue, in: 0.0...5.0, step: 0.1)
                            .tint(.chlorineIdealColor)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Wassertemperatur", systemImage: "thermometer.medium")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(String(format: "%.0f °C", waterTemperature))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: waterTemperature)
                        }
                        Slider(value: $waterTemperature, in: 10.0...40.0, step: 1.0)
                            .tint(.orange)
                    }
                }

                Section {
                    DatePicker(
                        selection: $measurementDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    ) {
                        Label("Zeitpunkt", systemImage: "clock")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .contentMargins(.top, 0)
            .navigationTitle(entry == nil ? "Messen" : "Messung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveEntry()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveEntry() {
        let ph = String(format: "%.1f", phValue).replacingOccurrences(of: ".", with: ",")
        let cl = String(format: "%.1f", chlorineValue).replacingOccurrences(of: ".", with: ",")
        let summary = "pH \(ph) · Cl \(cl) mg/l"

        if var existingEntry = entry {
            existingEntry.phValue = phValue
            existingEntry.chlorineValue = chlorineValue
            existingEntry.waterTemperature = waterTemperature
            existingEntry.timestamp = measurementDate
            existingEntry.summary = summary
            state.updateEntry(existingEntry)
        }
    }
}

// MARK: - Edit Dosieren Sheet

struct EditDosierenSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: LogbookEntry?
    @Bindable var state: MeinPoolState

    @State private var selectedProduct: String = "pH-Minus"
    @State private var amount: Double = 50
    @State private var unit: String = "g"
    @State private var dosingDate: Date = Date()

    let products = ["pH-Minus", "pH-Plus", "Chlorgranulat", "Chlortabletten", "Algizid", "Flockmittel"]
    let units = ["g", "ml", "Tabletten"]

    init(entry: LogbookEntry? = nil, state: MeinPoolState) {
        self.entry = entry
        self.state = state
        if let entry = entry {
            _selectedProduct = State(initialValue: entry.product ?? "pH-Minus")
            _amount = State(initialValue: entry.amount ?? 50)
            _unit = State(initialValue: entry.unit ?? "g")
            _dosingDate = State(initialValue: entry.timestamp)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Produkt", selection: $selectedProduct) {
                        ForEach(products, id: \.self) { product in
                            Text(product).tag(product)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Menge", systemImage: "scalemass")
                            Spacer()
                            Text("\(Int(amount)) \(unit)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: amount)
                        }
                        Slider(value: $amount, in: 10...500, step: 10)
                            .tint(.chlorineIdealColor)
                    }

                    Picker("Einheit", selection: $unit) {
                        ForEach(units, id: \.self) { u in
                            Text(u).tag(u)
                        }
                    }
                }

                Section {
                    DatePicker(
                        selection: $dosingDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    ) {
                        Label("Zeitpunkt", systemImage: "clock")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .contentMargins(.top, 0)
            .navigationTitle(entry == nil ? "Dosieren" : "Dosierung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveEntry()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveEntry() {
        let summary = "\(Int(amount)) \(unit) \(selectedProduct)"

        if var existingEntry = entry {
            existingEntry.product = selectedProduct
            existingEntry.amount = amount
            existingEntry.unit = unit
            existingEntry.timestamp = dosingDate
            existingEntry.summary = summary
            state.updateEntry(existingEntry)
        }
    }
}

#Preview {
    NavigationStack {
        MeinPoolView()
    }
}
