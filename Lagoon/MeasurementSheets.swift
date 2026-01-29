//
//  MeasurementSheets.swift
//  Lagoon
//
//  Sheets for recording measurements and dosing
//

import SwiftUI

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
