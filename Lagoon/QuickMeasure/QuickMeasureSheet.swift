import SwiftUI

struct QuickMeasureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PoolWaterState.self) private var poolWaterState

    enum Phase {
        case messen
        case dosieren
        case bearbeiten
    }

    @State private var phase: Phase = .messen
    @State private var currentDetent: PresentationDetent = QuickMeasureSheet.messenDetent

    // Messen values
    @State private var phSelection: Int = 12
    @State private var chlorineSelection: Int = 10

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

    private var phValue: Double { 6.0 + Double(phSelection) * 0.1 }
    private var chlorineValue: Double { Double(chlorineSelection) * 0.1 }
    private var editedPHAmount: Double { Double(phAmountSelection) * 5.0 }
    private var editedChlorineAmount: Double { Double(chlorineAmountSelection) * 5.0 }

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

    private static let messenDetent = PresentationDetent.height(360)
    private static let dosierenDetent = PresentationDetent.height(300)

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
                    if phase == .dosieren {
                        Button {
                            prepareEditValues()
                            withAnimation {
                                phase = .bearbeiten
                                currentDetent = .medium
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                }
            }
        }
        .presentationDetents([Self.messenDetent, Self.dosierenDetent, .medium], selection: $currentDetent)
        .interactiveDismissDisabled(phase != .messen)
        .onAppear {
            phSelection = Int(((poolWaterState.lastPH - 6.0) / 0.1).rounded())
            chlorineSelection = Int((poolWaterState.lastChlorine / 0.1).rounded())
        }
    }

    private var headerTitle: String {
        switch phase {
        case .messen: return ""
        case .dosieren: return "Dosieren"
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
                    Spacer()
                    Text(String(format: "%.1f", phValue))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: phSelection)
                }
                TickPicker(count: 30, config: phTickConfig, selection: $phSelection)
            }

            VStack(spacing: 4) {
                HStack {
                    Label("Chlor", systemImage: "allergens.fill")
                    Spacer()
                    Text(String(format: "%.1f mg/l", chlorineValue))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: chlorineSelection)
                }
                TickPicker(count: 50, config: chlorineTickConfig, selection: $chlorineSelection)
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
                Text("Messen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        }
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
                        Spacer()
                        Text(String(format: "%.0f g", recommendedPHAmount))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                }

                if !chlorineInRange && recommendedChlorineAmount > 0 {
                    HStack {
                        Label(chlorineProductName, systemImage: "allergens.fill")
                        Spacer()
                        Text(String(format: "%.0f g", recommendedChlorineAmount))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                }
            } header: {
                Text("Empfehlung")
            }
        }

        Section {
            SlideToConfirm(
                config: .init(
                    idleText: phInRange && chlorineInRange ? "Speichern" : "Dosieren",
                    onSwipeText: "Wird gespeichert...",
                    confirmationText: "Gespeichert",
                    tint: phInRange && chlorineInRange ? .green : .blue,
                    foregroundColor: .white
                )
            ) {
                saveAll(phAmount: recommendedPHAmount, chlorineAmount: recommendedChlorineAmount)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            .frame(height: 60)
        }
    }

    // MARK: - Bearbeiten (Expanded)

    @ViewBuilder
    private var bearbeitenSections: some View {
        Section {
            VStack(spacing: 4) {
                HStack {
                    Label("pH", systemImage: "drop.fill")
                    Spacer()
                    Text(String(format: "%.0f g", editedPHAmount))
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

                TickPicker(count: 60, config: phTickConfig, selection: $phAmountSelection)
            }
        }

        Section {
            VStack(spacing: 4) {
                HStack {
                    Label("Chlor", systemImage: "allergens.fill")
                    Spacer()
                    Text(String(format: "%.0f g", editedChlorineAmount))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: chlorineAmountSelection)
                }

                TickPicker(count: 100, config: chlorineTickConfig, selection: $chlorineAmountSelection)
            }
        }

        Section {
            SlideToConfirm(
                config: .init(
                    idleText: "Dosieren",
                    onSwipeText: "Wird gespeichert...",
                    confirmationText: "Gespeichert",
                    tint: .blue,
                    foregroundColor: .white
                )
            ) {
                saveAll(phAmount: editedPHAmount, chlorineAmount: editedChlorineAmount)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            .frame(height: 60)
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
        phAmountSelection = Int((recommendedPHAmount / 5.0).rounded())
        chlorineAmountSelection = Int((recommendedChlorineAmount / 5.0).rounded())
    }

    private func saveAll(phAmount: Double, chlorineAmount: Double) {
        poolWaterState.recordMeasurement(
            chlorine: chlorineValue,
            pH: phValue
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
