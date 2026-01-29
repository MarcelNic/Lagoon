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

    @AppStorage("dosingUnit") private var dosingUnit: String = "gramm"
    @AppStorage("cupGrams") private var cupGrams: Double = 50.0

    @State private var showMessenSheet = false
    @State private var showDosierenSheet = false
    @State private var showQuickMeasure = false
    @State private var quickMeasurePhase: Int = 0  // 0=messen, 1=dosieren, 2=bearbeiten
    @State private var showPoolcare = false
    @State private var showMeinPool = false
    @State private var timeOffsetSelection: Int = 0
    @Namespace private var namespace

    private var anySheetPresented: Bool {
        showMessenSheet || showDosierenSheet || showQuickMeasure
    }

    private var showDosingPill: Bool {
        poolWaterState.recentDosingActive || poolWaterState.dosingNeeded
    }

    private var barScale: CGFloat {
        guard anySheetPresented else { return 1.0 }
        if showQuickMeasure {
            switch quickMeasurePhase {
            case 1: return 1.0    // dosieren – kleines sheet
            case 2: return 0.65   // bearbeiten – großes sheet
            default: return 0.80  // messen
            }
        }
        return 0.80
    }

    private var recentDosingLabel: String {
        var parts: [String] = []
        if poolWaterState.lastDosingChlorineAmount > 0 {
            let formatted = DosingFormatter.format(grams: poolWaterState.lastDosingChlorineAmount, unit: dosingUnit, cupGrams: cupGrams)
                .replacingOccurrences(of: " Becher", with: "")
                .replacingOccurrences(of: " g", with: "g")
            parts.append("\(formatted) Cl")
        }
        if poolWaterState.lastDosingPHAmount > 0 {
            let formatted = DosingFormatter.format(grams: poolWaterState.lastDosingPHAmount, unit: dosingUnit, cupGrams: cupGrams)
                .replacingOccurrences(of: " Becher", with: "")
                .replacingOccurrences(of: " g", with: "g")
            parts.append("\(formatted) \(poolWaterState.lastDosingPHType)")
        }
        return parts.isEmpty ? "Dosiert" : parts.joined(separator: " ")
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
                    stops: [
                        .init(color: Color(light: Color(hex: "0443a6"), dark: Color(hex: "0a1628")), location: 0.0),
                        .init(color: Color(light: Color(hex: "b2e1ec"), dark: Color(hex: "1a3a5c")), location: 0.5),
                        .init(color: Color(light: Color(hex: "2fb4a0"), dark: Color(hex: "1a3a5c")), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    // Dashboard Content - Classic Style
                    HStack(spacing: 72) {
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
                            prediction: poolWaterState.phPrediction,
                            compact: anySheetPresented
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)

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
                            prediction: poolWaterState.chlorinePrediction,
                            compact: anySheetPresented
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scaleEffect(barScale, anchor: .top)
                    .offset(y: anySheetPresented ? -100 : (showDosingPill ? -12 : 0))
                    .animation(.smooth, value: anySheetPresented)
                    .animation(.smooth, value: quickMeasurePhase)
                    .animation(.smooth(duration: 0.35), value: showDosingPill)
                    .padding(.bottom, 20)

                    // Dosing status pill
                    if poolWaterState.recentDosingActive {
                        Button { showQuickMeasure = true } label: {
                            InfoPill(
                                icon: "checkmark.circle.fill",
                                text: recentDosingLabel,
                                foregroundColor: .black
                            )
                        }
                        .buttonStyle(.plain)
                        .transition(.blurReplace.combined(with: .scale(0.8)).combined(with: .opacity))
                        .opacity(anySheetPresented ? 0 : 1)
                        .animation(.smooth, value: anySheetPresented)
                    } else if poolWaterState.dosingNeeded {
                        Button { showQuickMeasure = true } label: {
                            InfoPill(
                                icon: "exclamationmark.triangle.fill",
                                text: "Dosierung",
                                tint: Color(light: .red.opacity(0.9), dark: .red.opacity(0.5))
                            )
                        }
                        .buttonStyle(.plain)
                        .transition(.blurReplace.combined(with: .scale(0.8)).combined(with: .opacity))
                        .opacity(anySheetPresented ? 0 : 1)
                        .animation(.smooth, value: anySheetPresented)
                    }

                    // Time simulation picker
                    VStack(spacing: 4) {
                        Text(simulationTimeLabel)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(light: Color.black, dark: Color.white.opacity(0.6)))
                            .contentTransition(.numericText())
                            .animation(.snappy, value: timeOffsetSelection)

                        TickPicker(
                            count: 48,
                            config: TickConfig(
                                tickWidth: 1.5,
                                tickHeight: 16,
                                tickHPadding: 3,
                                activeTint: Color(light: Color.black, dark: Color.white.opacity(0.8)),
                                inActiveTint: Color(light: Color.black.opacity(0.3), dark: Color.white.opacity(0.2)),
                                alignment: .center
                            ),
                            selection: $timeOffsetSelection
                        )
                        .frame(height: 16)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    .offset(y: showDosingPill ? 8 : 0)
                    .opacity(anySheetPresented ? 0 : 1)
                    .animation(.smooth, value: anySheetPresented)
                    .animation(.smooth(duration: 0.35), value: showDosingPill)
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
                                        .foregroundStyle(Color(light: Color.black, dark: Color.white))
                                        .padding(.leading, 24)
                                        .padding(.trailing, 12)
                                        .frame(height: 52)
                                }
                                .matchedTransitionSource(id: "poolcare", in: namespace)

                                Rectangle()
                                    .fill(Color(light: Color.black, dark: Color.white).opacity(0.3))
                                    .frame(width: 1, height: 26)

                                Button {
                                    showMeinPool = true
                                } label: {
                                    Text("Mein Pool")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundStyle(Color(light: Color.black, dark: Color.white))
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
                                    .foregroundStyle(Color(light: Color.black, dark: Color.white))
                            }
                            .frame(width: 52, height: 52)
                            .glassEffect(.clear.interactive(), in: .circle)

                            Button {
                                showDosierenSheet = true
                            } label: {
                                Image(systemName: "circle.grid.cross")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color(light: Color.black, dark: Color.white))
                            }
                            .frame(width: 52, height: 52)
                            .glassEffect(.clear.interactive(), in: .circle)

                        }
                    }
                    .padding(.bottom, 8)
                }
                .animation(.smooth(duration: 0.35), value: showDosingPill)
                .overlay(alignment: .topTrailing) {
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
        .sheet(isPresented: $showQuickMeasure, onDismiss: { quickMeasurePhase = 0 }) {
            QuickMeasureSheet(externalPhase: $quickMeasurePhase)
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

    @State private var phValue: Double = 7.4
    @State private var chlorineIndex: Double = 10  // Index in chlorineSteps
    @State private var waterTemperature: Double = 26.0
    @State private var measurementDate: Date = Date()

    // 0-1 in 0.1er Schritten, 1-3 in 0.5er Schritten, 3-5 in 1er Schritten
    private let chlorineSteps: [Double] = [
        0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0,  // Index 0-10
        1.5, 2.0, 2.5, 3.0,  // Index 11-14
        4.0, 5.0  // Index 15-16
    ]

    private var chlorineValue: Double {
        chlorineSteps[Int(chlorineIndex)]
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
                            Label("Chlor", systemImage: "allergens.fill")
                                .foregroundStyle(.primary)
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

                Section {
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
                            .tint(temperatureColor(for: waterTemperature))
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
            phValue = poolWaterState.lastPH
            // Find closest index for chlorine value
            let lastCl = poolWaterState.lastChlorine
            if let idx = chlorineSteps.enumerated().min(by: { abs($0.element - lastCl) < abs($1.element - lastCl) })?.offset {
                chlorineIndex = Double(idx)
            }
        }
    }
}

// MARK: - Dosieren Sheet

struct DosierenSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PoolWaterState.self) private var poolWaterState

    @AppStorage("dosingUnit") private var dosingUnit: String = "gramm"
    @AppStorage("cupGrams") private var cupGrams: Double = 50.0

    @State private var phType: PHType = .minus
    @State private var phAmount: Double = 0
    @State private var chlorineAmount: Double = 0
    @State private var dosingDate: Date = Date()

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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("pH", systemImage: "drop.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(DosingFormatter.format(grams: phAmount, unit: dosingUnit, cupGrams: cupGrams))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: phAmount)
                        }
                        Picker("pH", selection: $phType) {
                            Text("pH-").tag(PHType.minus)
                            Text("pH+").tag(PHType.plus)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Slider(value: $phAmount, in: 0...maxPHAmount, step: stepSize)
                            .tint(.phIdealColor)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Chlor", systemImage: "allergens.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(DosingFormatter.format(grams: chlorineAmount, unit: dosingUnit, cupGrams: cupGrams))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: chlorineAmount)
                        }

                        Slider(value: $chlorineAmount, in: 0...maxChlorineAmount, step: stepSize)
                            .tint(.chlorineIdealColor)
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
