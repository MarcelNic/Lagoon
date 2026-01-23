import SwiftUI

struct QuickMeasureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PoolWaterState.self) private var poolWaterState

    @AppStorage("dosingUnit") private var dosingUnit: String = "gramm"
    @AppStorage("cupGrams") private var cupGrams: Double = 50.0

    @Binding var externalPhase: Int

    enum Phase: Int {
        case messen = 0
        case dosieren = 1
        case bearbeiten = 2
    }

    @State private var phase: Phase = .messen
    @State private var currentDetent: PresentationDetent = QuickMeasureSheet.messenDetent

    // Messen values
    @State private var phSelection: Int = 6
    @State private var chlorineSelection: Int = 10
    @State private var waterTemperature: Double = 26.0

    // Dosieren computed values
    @State private var recommendedPHAmount: Double = 0
    @State private var recommendedChlorineAmount: Double = 0
    @State private var phProductId: String = "ph_minus"
    @State private var phProductName: String = "pH-Minus"
    @State private var chlorineProductName: String = "Chlorgranulat"
    @State private var phInRange: Bool = false
    @State private var chlorineInRange: Bool = false

    // Bearbeiten adjusted values
    @State private var phAmountSelection: Int = 0
    @State private var chlorineAmountSelection: Int = 0
    @State private var phType: PHType = .minus

    private var phValue: Double { 6.8 + Double(phSelection) * 0.1 }
    private var chlorineValue: Double {
        if chlorineSelection <= 10 {
            return Double(chlorineSelection) * 0.1
        } else {
            return 1.0 + Double(chlorineSelection - 10) * 0.5
        }
    }
    private var editedPHAmount: Double {
        dosingUnit == "becher"
            ? DosingFormatter.cupTickToGrams(phAmountSelection, cupGrams: cupGrams)
            : Double(phAmountSelection) * 5.0
    }
    private var editedChlorineAmount: Double {
        dosingUnit == "becher"
            ? DosingFormatter.cupTickToGrams(chlorineAmountSelection, cupGrams: cupGrams)
            : Double(chlorineAmountSelection) * 5.0
    }

    enum PHType: String, CaseIterable {
        case minus, plus
        var productId: String {
            switch self {
            case .minus: return "ph_minus"
            case .plus: return "ph_plus"
            }
        }
        var productName: String {
            switch self {
            case .minus: return "pH-Minus"
            case .plus: return "pH-Plus"
            }
        }
    }

    private var phTickConfig: TickConfig {
        .init(
            tickWidth: 2,
            tickHeight: 24,
            tickHPadding: 4,
            activeTint: .phIdealColor,
            inActiveTint: .white.opacity(0.6),
            alignment: .center
        )
    }

    private var chlorineTickConfig: TickConfig {
        .init(
            tickWidth: 2,
            tickHeight: 24,
            tickHPadding: 4,
            activeTint: .chlorineIdealColor,
            inActiveTint: .white.opacity(0.6),
            alignment: .center
        )
    }

    private static let messenDetent = PresentationDetent.height(415)

    private var dosierenDetent: PresentationDetent {
        if phInRange && chlorineInRange {
            return .height(200)
        } else if !phInRange && !chlorineInRange && recommendedPHAmount > 0 && recommendedChlorineAmount > 0 {
            return .height(262)
        } else {
            return .height(212)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                switch phase {
                case .messen:
                    messenSections
                case .dosieren:
                    dosierenSections
                case .bearbeiten:
                    bearbeitenSections
                }
            }
            .contentMargins(.top, phase == .messen ? 16 : 0)
            .navigationTitle(headerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(phase == .messen ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if phase != .messen {
                        Button {
                            withAnimation {
                                if phase == .bearbeiten {
                                    phase = .dosieren
                                    currentDetent = dosierenDetent
                                } else {
                                    phase = .messen
                                    currentDetent = Self.messenDetent
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if phase == .dosieren {
                        Button {
                            prepareEditValues()
                            withAnimation {
                                phase = .bearbeiten
                                currentDetent = .height(494)
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                }
            }
        }
        .presentationDetents([Self.messenDetent, .height(200), .height(212), .height(262), .height(494)], selection: $currentDetent)
        .interactiveDismissDisabled(phase != .messen)
        .onAppear {
            phSelection = min(12, max(0, Int(((poolWaterState.lastPH - 6.8) / 0.1).rounded())))
            if poolWaterState.lastChlorine <= 1.0 {
                chlorineSelection = min(10, max(0, Int((poolWaterState.lastChlorine / 0.1).rounded())))
            } else {
                chlorineSelection = min(18, max(10, 10 + Int(((poolWaterState.lastChlorine - 1.0) / 0.5).rounded())))
            }
        }
        .onChange(of: phase) { _, newPhase in
            externalPhase = newPhase.rawValue
        }
    }

    private var headerTitle: String {
        switch phase {
        case .messen: return ""
        case .dosieren: return "Empfehlung"
        case .bearbeiten: return "Anpassen"
        }
    }

    // MARK: - Messen

    @ViewBuilder
    private var messenSections: some View {
        Section {
            VStack(spacing: 4) {
                HStack {
                    Label("pH-Wert", systemImage: "drop.fill")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%.1f", phValue))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: phSelection)
                }
                TickPicker(count: 12, config: phTickConfig, selection: $phSelection)
            }

            VStack(spacing: 4) {
                HStack {
                    Label("Chlor", systemImage: "allergens.fill")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%.1f mg/l", chlorineValue))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: chlorineSelection)
                }
                TickPicker(count: 18, config: chlorineTickConfig, selection: $chlorineSelection)
            }
        }
        .listSectionSpacing(16)

        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Wassertemperatur", systemImage: "thermometer.medium")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(String(format: "%.0f °C", waterTemperature))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: waterTemperature)
                }
                Slider(value: $waterTemperature, in: 10.0...40.0, step: 1.0)
                    .tint(Color(hue: 0.6 * (1.0 - (waterTemperature - 10.0) / 30.0), saturation: 0.75, brightness: 0.9))
            }
        }

        Section {
            Button {
                calculateRecommendation()
                withAnimation {
                    phase = .dosieren
                    currentDetent = dosierenDetent
                }
            } label: {
                Text("Messen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glassProminent)
            .tint(.blue)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
        }
        .listSectionSpacing(16)
    }

    // MARK: - Dosieren (Compact)

    @ViewBuilder
    private var dosierenSections: some View {
        if phInRange && chlorineInRange {
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                    Text("Alles im optimalen Bereich")
                        .font(.subheadline.weight(.medium))
                }
            }
        } else {
            Section {
                if !phInRange && recommendedPHAmount > 0 {
                    HStack {
                        Label(phProductName, systemImage: "drop.fill")
                            .foregroundStyle(.white)
                        Spacer()
                        Text(DosingFormatter.format(grams: recommendedPHAmount, unit: dosingUnit, cupGrams: cupGrams))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                }

                if !chlorineInRange && recommendedChlorineAmount > 0 {
                    HStack {
                        Label(chlorineProductName, systemImage: "allergens.fill")
                            .foregroundStyle(.white)
                        Spacer()
                        Text(DosingFormatter.format(grams: recommendedChlorineAmount, unit: dosingUnit, cupGrams: cupGrams))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                }
            }
        }

        Section {
            SlideToConfirm(
                label: phInRange && chlorineInRange ? "Speichern" : "Dosieren",
                icon: "chevron.right"
            ) {
                saveAll(phAmount: recommendedPHAmount, chlorineAmount: recommendedChlorineAmount)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 4))
        }
        .listSectionSpacing(8)
    }

    // MARK: - Bearbeiten (Expanded)

    @ViewBuilder
    private var bearbeitenSections: some View {
        Section {
            VStack(spacing: 4) {
                HStack {
                    Label("pH", systemImage: "drop.fill")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(DosingFormatter.format(grams: editedPHAmount, unit: dosingUnit, cupGrams: cupGrams))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: phAmountSelection)
                }

                Picker("pH", selection: $phType) {
                    Text("pH-").tag(PHType.minus)
                    Text("pH+").tag(PHType.plus)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                TickPicker(count: dosingUnit == "becher" ? DosingFormatter.cupTickCount : 60, config: phTickConfig, selection: $phAmountSelection)
            }
        }

        Section {
            VStack(spacing: 4) {
                HStack {
                    Label("Chlor", systemImage: "allergens.fill")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(DosingFormatter.format(grams: editedChlorineAmount, unit: dosingUnit, cupGrams: cupGrams))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: chlorineAmountSelection)
                }

                TickPicker(count: dosingUnit == "becher" ? DosingFormatter.cupTickCount : 100, config: chlorineTickConfig, selection: $chlorineAmountSelection)
            }
        }

        Section {
            SlideToConfirm(
                label: "Dosieren",
                icon: "chevron.right"
            ) {
                saveAll(phAmount: editedPHAmount, chlorineAmount: editedChlorineAmount)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 18, leading: 4, bottom: 0, trailing: 4))
        }
    }

    // MARK: - Logic

    private func calculateRecommendation() {
        let engine = PoolWaterEngine()

        let input = PoolWaterEngineInput.create(
            poolVolume_m3: poolWaterState.poolVolume,
            lastChlorine_ppm: chlorineValue,
            lastPH: phValue,
            lastMeasurementISO: ISO8601DateFormatter().string(from: Date()),
            poolCovered: poolWaterState.hasCover,
            filterRuntime: poolWaterState.pumpRuntime,
            idealRanges: WaterTargets(
                freeChlorine: ChlorineTargets(
                    min_ppm: poolWaterState.idealChlorineMin,
                    max_ppm: poolWaterState.idealChlorineMax
                ),
                pH: PHTargets(
                    min: poolWaterState.idealPHMin,
                    max: poolWaterState.idealPHMax
                )
            )
        )

        let output = engine.process(input)

        if let phRec = output.recommendations.first(where: { $0.parameter == .pH }) {
            phInRange = phRec.action == .none
            recommendedPHAmount = phRec.amount ?? 0
            if let productId = phRec.productId {
                phProductId = productId
                phProductName = productId == "ph_plus" ? "pH-Plus" : "pH-Minus"
                phType = productId == "ph_plus" ? .plus : .minus
            }
        }

        if let clRec = output.recommendations.first(where: { $0.parameter == .freeChlorine }) {
            chlorineInRange = clRec.action == .none
            recommendedChlorineAmount = clRec.amount ?? 0
            chlorineProductName = "Chlorgranulat"
        }
    }

    private func prepareEditValues() {
        if dosingUnit == "becher" {
            phAmountSelection = DosingFormatter.gramsToCupTick(recommendedPHAmount, cupGrams: cupGrams)
            chlorineAmountSelection = DosingFormatter.gramsToCupTick(recommendedChlorineAmount, cupGrams: cupGrams)
        } else {
            phAmountSelection = Int((recommendedPHAmount / 5.0).rounded())
            chlorineAmountSelection = Int((recommendedChlorineAmount / 5.0).rounded())
        }
    }

    private func saveAll(phAmount: Double, chlorineAmount: Double) {
        poolWaterState.recordMeasurement(
            chlorine: chlorineValue,
            pH: phValue,
            waterTemperature: waterTemperature
        )

        if phAmount > 0 {
            poolWaterState.recordDosing(
                productId: phType.productId,
                productName: phType.productName,
                amount: phAmount,
                unit: "g"
            )
        }

        if chlorineAmount > 0 {
            poolWaterState.recordDosing(
                productId: "chlorine",
                productName: "Chlorgranulat",
                amount: chlorineAmount,
                unit: "g"
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}
