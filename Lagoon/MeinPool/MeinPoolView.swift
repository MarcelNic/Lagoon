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
    @State private var meinPoolState = MeinPoolState()
    @Binding var showSettings: Bool
    @State private var selectedTimeRange: ChartTimeRange = .threeDays
    @State private var showLogbookList = false

    init(showSettings: Binding<Bool> = .constant(false)) {
        self._showSettings = showSettings
    }

    private var predictions: (ph: [ChartDataPoint], chlorine: [ChartDataPoint]) {
        poolWaterState.predictionPoints(until: selectedTimeRange.endDate)
    }

    var body: some View {
        ZStack {
            AdaptiveBackgroundGradient()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Time range picker
                    Picker("Zeitraum", selection: $selectedTimeRange) {
                        ForEach(ChartTimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    // pH Chart
                    PoolChartView(
                        title: "pH-Wert",
                        unit: "",
                        data: meinPoolState.phChartData(in: selectedTimeRange),
                        predictionData: predictions.ph,
                        idealMin: poolWaterState.idealPHMin,
                        idealMax: poolWaterState.idealPHMax,
                        lineColor: .phIdealColor,
                        idealRangeColor: .phIdealColor,
                        yDomain: 6.8...8.0,
                        timeRange: selectedTimeRange
                    )

                    // Chlorine Chart
                    PoolChartView(
                        title: "Chlor",
                        unit: "mg/l",
                        data: meinPoolState.chlorineChartData(in: selectedTimeRange),
                        predictionData: predictions.chlorine,
                        idealMin: poolWaterState.idealChlorineMin,
                        idealMax: poolWaterState.idealChlorineMax,
                        lineColor: .chlorineIdealColor,
                        idealRangeColor: .chlorineIdealColor,
                        yDomain: 0.0...5.0,
                        timeRange: selectedTimeRange
                    )

                    // Temperature Chart (no prediction)
                    PoolChartView(
                        title: "Wassertemperatur",
                        unit: "°C",
                        data: meinPoolState.temperatureChartData(in: selectedTimeRange),
                        idealMin: nil,
                        idealMax: nil,
                        lineColor: .orange,
                        idealRangeColor: .clear,
                        yDomain: 10.0...40.0,
                        timeRange: selectedTimeRange
                    )

                    // All entries button
                    NavigationLink {
                        LogbookListView(state: meinPoolState)
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 15, weight: .medium))
                            Text("Alle Einträge")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .glassEffect(.clear.interactive(), in: .capsule)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            SettingsFullScreenCover(showSettings: $showSettings)
                .presentationDetents([.large])
        }
        .onChange(of: showSettings) { _, isShowing in
            if !isShowing {
                poolWaterState.reloadSettings()
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

// MARK: - Settings Full Screen Cover

private struct SettingsFullScreenCover: View {
    @Binding var showSettings: Bool
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    private var colorScheme: ColorScheme? {
        (AppearanceMode(rawValue: appearanceMode) ?? .system).colorScheme
    }

    var body: some View {
        NavigationStack {
            SettingsView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            showSettings = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
        }
        .preferredColorScheme(colorScheme)
    }
}

#Preview {
    NavigationStack {
        MeinPoolView()
    }
}
