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
    @State private var selectedTimeRange: ChartTimeRange = .sevenDays
    @State private var showLogbookList = false
    init(showSettings: Binding<Bool> = .constant(false)) {
        self._showSettings = showSettings
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
                        lineColor: .red,
                        idealRangeColor: .clear,
                        yDomain: 10.0...40.0,
                        timeRange: selectedTimeRange,
                        showAreaFill: true
                    )

                    // All entries button
                    NavigationLink {
                        LogbookListView(state: meinPoolState)
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet")
                                .font(.subheadline.weight(.medium))
                            Text("Alle Einträge")
                                .font(.subheadline.weight(.medium))
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

    @AppStorage("dosingUnit") private var dosingUnit: String = "gramm"
    @AppStorage("cupGrams") private var cupGrams: Double = 50.0

    @State private var editedPHAmount: Double = 0
    @State private var editedChlorineAmount: Double = 0
    @State private var phType: EditDosierenPHType = .minus
    @State private var editedDate: Date = Date()

    private var hasPH: Bool {
        entry?.dosings.contains(where: { $0.productId == "ph_minus" || $0.productId == "ph_plus" }) ?? false
    }
    private var hasChlor: Bool {
        entry?.dosings.contains(where: { $0.productId == "chlorine" }) ?? false
    }
    private var effectiveCupGrams: Double { cupGrams > 0 ? cupGrams : 50.0 }
    private var stepSize: Double { dosingUnit == "becher" ? effectiveCupGrams : 10 }
    private var maxPHAmount: Double { 500 }
    private var maxChlorAmount: Double { 1000 }

    init(entry: LogbookEntry? = nil, state: MeinPoolState) {
        self.entry = entry
        self.state = state
        if let entry = entry {
            _editedDate = State(initialValue: entry.timestamp)
            if let ph = entry.dosings.first(where: { $0.productId == "ph_minus" || $0.productId == "ph_plus" }) {
                _editedPHAmount = State(initialValue: ph.amount)
                _phType = State(initialValue: ph.productId == "ph_plus" ? .plus : .minus)
            }
            if let cl = entry.dosings.first(where: { $0.productId == "chlorine" }) {
                _editedChlorineAmount = State(initialValue: cl.amount)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if hasPH {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("pH")
                                Spacer()
                                Text(DosingFormatter.format(grams: editedPHAmount, unit: dosingUnit, cupGrams: effectiveCupGrams))
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                    .animation(.snappy, value: editedPHAmount)
                            }
                            Picker("pH", selection: $phType) {
                                Text("pH-").tag(EditDosierenPHType.minus)
                                Text("pH+").tag(EditDosierenPHType.plus)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            Slider(value: $editedPHAmount, in: 0...maxPHAmount, step: stepSize)
                                .tint(.phIdealColor)
                        }
                    }
                }

                if hasChlor {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Chlor")
                                Spacer()
                                Text(DosingFormatter.format(grams: editedChlorineAmount, unit: dosingUnit, cupGrams: effectiveCupGrams))
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                    .animation(.snappy, value: editedChlorineAmount)
                            }
                            Slider(value: $editedChlorineAmount, in: 0...maxChlorAmount, step: stepSize)
                                .tint(.chlorineIdealColor)
                        }
                    }
                }

                Section {
                    DatePicker(
                        selection: $editedDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    ) {
                        Label("Zeitpunkt", systemImage: "clock")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .contentMargins(.top, 0)
            .navigationTitle("Dosierung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
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
        guard var existingEntry = entry else { return }
        var updatedDosings = existingEntry.dosings

        if hasPH, let idx = updatedDosings.firstIndex(where: { $0.productId == "ph_minus" || $0.productId == "ph_plus" }) {
            updatedDosings[idx].amount = editedPHAmount
            updatedDosings[idx].productId = phType.productId
            updatedDosings[idx].productName = phType.productName
        }
        if hasChlor, let idx = updatedDosings.firstIndex(where: { $0.productId == "chlorine" }) {
            updatedDosings[idx].amount = editedChlorineAmount
        }

        let summaryParts = updatedDosings.map { item in
            "\(DosingFormatter.format(grams: item.amount, unit: dosingUnit, cupGrams: effectiveCupGrams)) \(item.productName)"
        }
        existingEntry.dosings = updatedDosings
        existingEntry.timestamp = editedDate
        existingEntry.summary = summaryParts.joined(separator: " · ")
        state.updateEntry(existingEntry)
    }
}

private enum EditDosierenPHType {
    case minus, plus
    var productId: String {
        switch self { case .minus: return "ph_minus"; case .plus: return "ph_plus" }
    }
    var productName: String {
        switch self { case .minus: return "pH-Minus"; case .plus: return "pH-Plus" }
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
