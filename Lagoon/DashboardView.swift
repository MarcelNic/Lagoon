//
//  DashboardView.swift
//  Lagoon
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(PoolWaterState.self) private var poolWaterState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var showMessenSheet = false
    @State private var showDosierenSheet = false
    @State private var showQuickMeasure = false
    @State private var showPoolcare = false
    @State private var showMeinPool = false
    @State private var timeOffsetSelection: Int = 0
    @Namespace private var namespace

    private var anySheetPresented: Bool {
        showMessenSheet || showDosierenSheet || showQuickMeasure
    }

    private var simulationTimeLabel: String {
        guard timeOffsetSelection > 0 else { return "Jetzt" }

        let calendar = Calendar.current
        let now = calendar.dateInterval(of: .hour, for: Date())?.start ?? Date()
        let targetDate = now.addingTimeInterval(Double(timeOffsetSelection) * 3600)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: targetDate)

        if calendar.isDateInToday(targetDate) {
            return timeString
        } else if calendar.isDateInTomorrow(targetDate) {
            return "Morgen, \(timeString)"
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.locale = Locale(identifier: "de_DE")
            dayFormatter.dateFormat = "EE"
            return "\(dayFormatter.string(from: targetDate)), \(timeString)"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "0a1628"),
                        Color(hex: "1a3a5c")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .scaleEffect(1.2)
                .ignoresSafeArea()

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            NotificationCenter.default.post(name: .openQuickMeasure, object: nil)
                        } label: {
                            Image(systemName: "bell.badge")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.orange.opacity(0.7))
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 8)
                    }

                    Spacer()
                        .frame(maxHeight: 120)

                    // Dashboard Content - Classic Style
                    HStack(spacing: 60) {
                        VerticalTrendBar(
                            title: "pH",
                            value: poolWaterState.estimatedPH,
                            minValue: 6.8,
                            maxValue: 8.0,
                            idealMin: poolWaterState.idealPHMin,
                            idealMax: poolWaterState.idealPHMax,
                            barColor: .phBarColor,
                            idealRangeColor: .phIdealColor,
                            trend: poolWaterState.phTrend,
                            scalePosition: .leading,
                            prediction: poolWaterState.phPrediction
                        )

                        VerticalTrendBar(
                            title: "Cl",
                            value: poolWaterState.estimatedChlorine,
                            minValue: 0,
                            maxValue: 5,
                            idealMin: poolWaterState.idealChlorineMin,
                            idealMax: poolWaterState.idealChlorineMax,
                            barColor: .chlorineBarColor,
                            idealRangeColor: .chlorineIdealColor,
                            trend: poolWaterState.chlorineTrend,
                            scalePosition: .trailing,
                            prediction: poolWaterState.chlorinePrediction
                        )
                    }
                    .offset(y: anySheetPresented ? -140 : 0)
                    .animation(.smooth, value: anySheetPresented)

                    // Time simulation picker
                    VStack(spacing: 4) {
                        Text(simulationTimeLabel)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .contentTransition(.numericText())
                            .animation(.snappy, value: timeOffsetSelection)

                        TickPicker(
                            count: 48,
                            config: TickConfig(
                                tickWidth: 1.5,
                                tickHeight: 16,
                                tickHPadding: 3,
                                activeTint: .white.opacity(0.8),
                                inActiveTint: .white.opacity(0.2),
                                alignment: .center
                            ),
                            selection: $timeOffsetSelection
                        )
                        .frame(height: 16)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    .onChange(of: timeOffsetSelection) { _, newValue in
                        poolWaterState.simulationOffsetHours = Double(newValue)
                        poolWaterState.recalculate()
                    }

                    Spacer()

                    // Bottom Bar
                    GlassEffectContainer(spacing: 12) {
                        HStack(spacing: 12) {
                            HStack(spacing: 0) {
                                Button {
                                    showPoolcare = true
                                } label: {
                                    Image(systemName: "checklist")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.leading, 24)
                                        .padding(.trailing, 12)
                                        .frame(height: 52)
                                }
                                .matchedTransitionSource(id: "poolcare", in: namespace)

                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(width: 1, height: 26)

                                Button {
                                    showMeinPool = true
                                } label: {
                                    Text("Mein Pool")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundStyle(.white)
                                        .padding(.leading, 12)
                                        .padding(.trailing, 24)
                                        .frame(height: 52)
                                }
                                .matchedTransitionSource(id: "meinPool", in: namespace)
                            }
                            .glassEffect(.clear.interactive(), in: .capsule)

                            Button {
                                showMessenSheet = true
                            } label: {
                                Image(systemName: "testtube.2")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 52, height: 52)
                            .glassEffect(.clear.interactive(), in: .circle)

                            Button {
                                showDosierenSheet = true
                            } label: {
                                Image(systemName: "circle.grid.cross")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 52, height: 52)
                            .glassEffect(.clear.interactive(), in: .circle)

                        }
                    }
                    .padding(.bottom, 8)
                }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $showPoolcare) {
                    PoolcareView()
                        .navigationTransition(.zoom(sourceID: "poolcare", in: namespace))
                }
                .navigationDestination(isPresented: $showMeinPool) {
                    MeinPoolView()
                        .navigationTransition(.zoom(sourceID: "meinPool", in: namespace))
                }
            }
        }
        .sheet(isPresented: $showMessenSheet) {
            MessenSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDosierenSheet) {
            DosierenSheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showQuickMeasure) {
            QuickMeasureSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openQuickMeasure)) { _ in
            showQuickMeasure = true
        }
        .onAppear {
            poolWaterState.setModelContext(modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                poolWaterState.reloadSettings()
            }
        }
    }
}

// MARK: - Messen Sheet

struct MessenSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PoolWaterState.self) private var poolWaterState

    // TickPicker uses Int, we convert to/from Double
    @State private var phSelection: Int = 6  // 6.8 + 6*0.1 = 7.4
    @State private var chlorineSelection: Int = 10  // 0.0 + 10*0.1 = 1.0
    @State private var waterTemperature: Double = 26.0
    @State private var measurementDate: Date = Date()

    private var phValue: Double { 6.8 + Double(phSelection) * 0.1 }
    private var chlorineValue: Double {
        if chlorineSelection <= 10 {
            return Double(chlorineSelection) * 0.1
        } else {
            return 1.0 + Double(chlorineSelection - 10) * 0.5
        }
    }

    private var phConfig: TickConfig {
        .init(
            tickWidth: 2,
            tickHeight: 24,
            tickHPadding: 4,
            activeTint: .phIdealColor,
            inActiveTint: .white.opacity(0.6),
            alignment: .center
        )
    }

    private var chlorineConfig: TickConfig {
        .init(
            tickWidth: 2,
            tickHeight: 24,
            tickHPadding: 4,
            activeTint: .chlorineIdealColor,
            inActiveTint: .white.opacity(0.6),
            alignment: .center
        )
    }

    var body: some View {
        NavigationStack {
            Form {
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

                        TickPicker(count: 12, config: phConfig, selection: $phSelection)
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

                        TickPicker(count: 18, config: chlorineConfig, selection: $chlorineSelection)
                    }
                }

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
                    DatePicker(
                        selection: $measurementDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    ) {
                        Label("Zeitpunkt", systemImage: "clock")
                            .foregroundStyle(.white)
                    }
                }
            }
            .contentMargins(.top, 0)
            .navigationTitle("Messen")
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
                        poolWaterState.recordMeasurement(
                            chlorine: chlorineValue,
                            pH: phValue,
                            waterTemperature: waterTemperature,
                            date: measurementDate
                        )
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
        .onAppear {
            // Initialize with last measured values
            phSelection = min(12, max(0, Int(((poolWaterState.lastPH - 6.8) / 0.1).rounded())))
            if poolWaterState.lastChlorine <= 1.0 {
                chlorineSelection = min(10, max(0, Int((poolWaterState.lastChlorine / 0.1).rounded())))
            } else {
                chlorineSelection = min(18, max(10, 10 + Int(((poolWaterState.lastChlorine - 1.0) / 0.5).rounded())))
            }
        }
    }
}

// MARK: - Dosieren Sheet

struct DosierenSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PoolWaterState.self) private var poolWaterState

    @State private var phType: PHType = .minus
    @State private var phAmountSelection: Int = 0  // 0-60 → 0-300g (step 5)
    @State private var chlorineAmountSelection: Int = 0  // 0-100 → 0-500g (step 5)
    @State private var dosingDate: Date = Date()

    private var phAmount: Double { Double(phAmountSelection) * 5.0 }
    private var chlorineAmount: Double { Double(chlorineAmountSelection) * 5.0 }

    enum PHType: String, CaseIterable {
        case minus, plus

        var label: String {
            switch self {
            case .minus: return "pH-"
            case .plus: return "pH+"
            }
        }

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

    private var phConfig: TickConfig {
        .init(
            tickWidth: 2,
            tickHeight: 24,
            tickHPadding: 4,
            activeTint: .phIdealColor,
            inActiveTint: .white.opacity(0.6),
            alignment: .center
        )
    }

    private var chlorineConfig: TickConfig {
        .init(
            tickWidth: 2,
            tickHeight: 24,
            tickHPadding: 4,
            activeTint: .chlorineIdealColor,
            inActiveTint: .white.opacity(0.6),
            alignment: .center
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 4) {
                        HStack {
                            Label("pH", systemImage: "drop.fill")
                                .foregroundStyle(.white)
                            Spacer()
                            Text(String(format: "%.0f g", phAmount))
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

                        TickPicker(count: 60, config: phConfig, selection: $phAmountSelection)
                    }
                }

                Section {
                    VStack(spacing: 4) {
                        HStack {
                            Label("Chlor", systemImage: "allergens.fill")
                                .foregroundStyle(.white)
                            Spacer()
                            Text(String(format: "%.0f g", chlorineAmount))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: chlorineAmountSelection)
                        }

                        TickPicker(count: 100, config: chlorineConfig, selection: $chlorineAmountSelection)
                    }
                }

                Section {
                    DatePicker(
                        selection: $dosingDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    ) {
                        Label("Zeitpunkt", systemImage: "clock")
                            .foregroundStyle(.white)
                    }
                }
            }
            .contentMargins(.top, 0)
            .navigationTitle("Dosieren")
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
                        // Save pH dosing if amount > 0
                        if phAmount > 0 {
                            poolWaterState.recordDosing(
                                productId: phType.productId,
                                productName: phType.productName,
                                amount: phAmount,
                                unit: "g",
                                date: dosingDate
                            )
                        }

                        // Save chlorine dosing if amount > 0
                        if chlorineAmount > 0 {
                            poolWaterState.recordDosing(
                                productId: "chlorine",
                                productName: "Chlorgranulat",
                                amount: chlorineAmount,
                                unit: "g",
                                date: dosingDate
                            )
                        }

                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environment(PoolWaterState())
}
