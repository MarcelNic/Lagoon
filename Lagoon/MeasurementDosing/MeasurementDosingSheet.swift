import SwiftUI

struct MeasurementDosingSheet: View {
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
    @State private var currentDetent: PresentationDetent = MeasurementDosingSheet.messenDetent

    // Messen values
    @State private var phValue: Double = 7.4
    @State private var chlorineIndex: Double = 10  // Index in chlorineSteps
    @State private var waterTemperature: Double = 26.0

    // 0-1 in 0.1er Schritten, 1-3 in 0.5er Schritten, 3-5 in 1er Schritten
    private let chlorineSteps: [Double] = [
        0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0,  // Index 0-10
        1.5, 2.0, 2.5, 3.0,  // Index 11-14
        4.0, 5.0  // Index 15-16
    ]

    private var chlorineValue: Double {
        chlorineSteps[Int(chlorineIndex)]
    }

    // Dosieren computed values
    @State private var recommendedPHAmount: Double = 0
    @State private var recommendedChlorineAmount: Double = 0
    @State private var phProductId: String = "ph_minus"
    @State private var phProductName: String = "pH-Minus"
    @State private var chlorineProductName: String = "Chlorgranulat"
    @State private var phInRange: Bool = false
    @State private var chlorineInRange: Bool = false
    @State private var particlesDissolving: Bool = false

    // Bearbeiten adjusted values
    @State private var editedPHAmount: Double = 0
    @State private var editedChlorineAmount: Double = 0
    @State private var phType: PHType = .minus
    @State private var editedDate: Date = Date()

    private var maxPHAmount: Double {
        dosingUnit == "becher" ? cupGrams * 10 : 300
    }

    private var maxChlorineAmount: Double {
        dosingUnit == "becher" ? cupGrams * 10 : 500
    }

    private var stepSize: Double {
        dosingUnit == "becher" ? cupGrams * 0.25 : 5.0
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

    private func temperatureColor(for temp: Double) -> Color {
        // 10: blau, 20: grün, 25: gelb, 30+: rot
        let hue: Double
        if temp < 20 {
            // 10-20: blau (0.6) → grün (0.33)
            let t = (temp - 10) / 10
            hue = 0.6 - t * 0.27
        } else if temp < 25 {
            // 20-25: grün (0.33) → gelb (0.15)
            let t = (temp - 20) / 5
            hue = 0.33 - t * 0.18
        } else if temp < 30 {
            // 25-30: gelb (0.15) → rot (0.0)
            let t = (temp - 25) / 5
            hue = 0.15 - t * 0.15
        } else {
            // 30+: rot
            hue = 0.0
        }
        return Color(hue: hue, saturation: 0.75, brightness: 0.9)
    }

    private static let messenDetent = PresentationDetent.height(415)

    private static let dosierenDetent = PresentationDetent.height(380)

    private var targetDetent: PresentationDetent {
        switch phase {
        case .messen:
            return Self.messenDetent
        case .dosieren:
            return Self.dosierenDetent
        case .bearbeiten:
            return .height(470)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .messen:
                    Form { messenSections }
                        .contentMargins(.top, 0)
                        .scrollDisabled(true)
                case .dosieren:
                    dosierenView
                        .ignoresSafeArea(edges: .bottom)
                case .bearbeiten:
                    Form { bearbeitenSections }
                        .listSectionSpacing(.compact)
                        .contentMargins(.top, 0)
                        .scrollDisabled(true)
                }
            }
            .navigationTitle(headerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if phase == .messen {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    } else {
                        Button {
                            withAnimation {
                                if phase == .bearbeiten {
                                    phase = .dosieren
                                    currentDetent = Self.dosierenDetent
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
                    if phase == .messen {
                        Button {
                            saveMeasurementOnly()
                        } label: {
                            Image(systemName: "arrow.up")
                        }
                    } else if phase == .dosieren {
                        Button {
                            prepareEditValues()
                            withAnimation {
                                phase = .bearbeiten
                                currentDetent = .height(470)
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                }
            }
        }
        .presentationDetents([Self.messenDetent, Self.dosierenDetent, .height(470)], selection: $currentDetent)
        .presentationDragIndicator(phase == .messen ? .visible : .hidden)
        .interactiveDismissDisabled(phase != .messen)
        .onChange(of: currentDetent) { _, newDetent in
            if newDetent != targetDetent {
                currentDetent = targetDetent
            }
        }
        .onAppear {
            phValue = poolWaterState.estimatedPH
            waterTemperature = poolWaterState.lastWaterTemperature
            // Find closest index for estimated chlorine value
            let estCl = poolWaterState.estimatedChlorine
            if let idx = chlorineSteps.enumerated().min(by: { abs($0.element - estCl) < abs($1.element - estCl) })?.offset {
                chlorineIndex = Double(idx)
            }
        }
        .onChange(of: phase) { _, newPhase in
            externalPhase = newPhase.rawValue
        }
    }

    private var headerTitle: String {
        switch phase {
        case .messen: return "Messen"
        case .dosieren: return "Empfehlung"
        case .bearbeiten: return "Anpassen"
        }
    }

    // MARK: - Messen

    @ViewBuilder
    private var messenSections: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("pH-Wert")
                    Spacer()
                    Text(String(format: "%.1f", phValue))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: phValue)
                }
                Slider(value: $phValue, in: 6.8...8.0, step: 0.1)
                    .tint(.phIdealColor)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Chlor")
                    Spacer()
                    Text(String(format: "%.1f mg/l", chlorineValue))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: chlorineIndex)
                }
                Slider(value: $chlorineIndex, in: 0...Double(chlorineSteps.count - 1), step: 1)
                    .tint(.chlorineIdealColor)
            }
        }
        .listSectionSpacing(16)

        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Wassertemperatur", systemImage: "thermometer.medium")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(String(format: "%.0f °C", waterTemperature))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: waterTemperature)
                }
                Slider(value: $waterTemperature, in: 10.0...40.0, step: 1.0)
                    .tint(temperatureColor(for: waterTemperature))
            }
        }

        Section {
            Button {
                calculateRecommendation()
                withAnimation {
                    phase = .dosieren
                    currentDetent = Self.dosierenDetent
                }
            } label: {
                Text("Dosieren")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glassProminent)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
        }
        .listSectionSpacing(16)
    }

    // MARK: - Dosieren

    private var dosierenView: some View {
        VStack(spacing: 0) {
            if phInRange && chlorineInRange {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title)
                    Text("Alles im optimalen Bereich")
                        .font(.subheadline.weight(.medium))
                }
                Spacer()
            } else {
                Spacer()
                let showPH = !phInRange && recommendedPHAmount > 0
                let showCl = !chlorineInRange && recommendedChlorineAmount > 0
                let phAmount = DosingFormatter.formatAmount(grams: recommendedPHAmount, unit: dosingUnit, cupGrams: cupGrams)
                let clAmount = DosingFormatter.formatAmount(grams: recommendedChlorineAmount, unit: dosingUnit, cupGrams: cupGrams)
                let unitLabel = DosingFormatter.formatUnit(unit: dosingUnit)

                // Labels row
                HStack(spacing: 0) {
                    if showPH {
                        HStack(spacing: 4) {
                            Text("pH")
                            Image(systemName: phProductId == "ph_plus" ? "plus.circle" : "minus.circle")
                        }
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.phIdealColor)
                        .frame(maxWidth: .infinity)
                    }
                    if showCl {
                        Text("Chlor")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.chlorineIdealColor)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Combined particle text
                Color.clear
                    .frame(height: 120)
                    .overlay {
                        let particleTexts = [showPH ? phAmount : nil, showCl ? clAmount : nil].compactMap { $0 }
                        ParticleTextView(texts: particleTexts, fontSize: particleFontSize, dissolving: $particlesDissolving)
                            .frame(height: 500)
                            .allowsHitTesting(false)
                    }

                // Unit labels row
                HStack(spacing: 0) {
                    if showPH {
                        Text(unitLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    if showCl {
                        Text(unitLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                Spacer()
            }

            SlideToConfirm(
                label: phInRange && chlorineInRange ? "Speichern" : "Dosieren",
                icon: "chevron.right"
            ) {
                particlesDissolving = true
                saveAll(phAmount: recommendedPHAmount, chlorineAmount: recommendedChlorineAmount)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var particleFontSize: CGFloat {
        dosingUnit == "becher" ? 96 : 72
    }

    // MARK: - Bearbeiten (Expanded)

    @ViewBuilder
    private var bearbeitenSections: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("pH")
                    Spacer()
                    Text(DosingFormatter.format(grams: editedPHAmount, unit: dosingUnit, cupGrams: cupGrams))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: editedPHAmount)
                }

                Picker("pH", selection: $phType) {
                    Text("pH-").tag(PHType.minus)
                    Text("pH+").tag(PHType.plus)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Slider(value: $editedPHAmount, in: 0...maxPHAmount, step: stepSize)
                    .tint(.phIdealColor)
            }
        }

        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Chlor")
                    Spacer()
                    Text(DosingFormatter.format(grams: editedChlorineAmount, unit: dosingUnit, cupGrams: cupGrams))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: editedChlorineAmount)
                }

                Slider(value: $editedChlorineAmount, in: 0...maxChlorineAmount, step: stepSize)
                    .tint(.chlorineIdealColor)
            }
        }

        Section {
            DatePicker("Zeitpunkt", selection: $editedDate)
        }

        Section {
            SlideToConfirm(
                label: "Dosieren",
                icon: "chevron.right"
            ) {
                saveAll(phAmount: editedPHAmount, chlorineAmount: editedChlorineAmount)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 20, trailing: 4))
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
        editedPHAmount = recommendedPHAmount
        editedChlorineAmount = recommendedChlorineAmount
        editedDate = Date()
    }

    private func saveMeasurementOnly() {
        poolWaterState.recordMeasurement(
            chlorine: chlorineValue,
            pH: phValue,
            waterTemperature: waterTemperature
        )
        dismiss()
    }

    private func saveAll(phAmount: Double, chlorineAmount: Double) {
        let baseDate = phase == .bearbeiten ? editedDate : Date()
        let dosingDate = baseDate.addingTimeInterval(1)

        poolWaterState.recordMeasurement(
            chlorine: chlorineValue,
            pH: phValue,
            waterTemperature: waterTemperature,
            date: baseDate
        )

        if phAmount > 0 {
            poolWaterState.recordDosing(
                productId: phType.productId,
                productName: phType.productName,
                amount: phAmount,
                unit: "g",
                date: dosingDate
            )
        }

        if chlorineAmount > 0 {
            poolWaterState.recordDosing(
                productId: "chlorine",
                productName: "Chlorgranulat",
                amount: chlorineAmount,
                unit: "g",
                date: dosingDate
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}
