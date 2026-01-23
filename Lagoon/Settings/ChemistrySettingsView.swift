//
//  ChemistrySettingsView.swift
//  Lagoon
//

import SwiftUI

struct ChemistrySettingsView: View {
    // Idealwerte
    @AppStorage("phMin") private var phMin: Double = 7.0
    @AppStorage("phMax") private var phMax: Double = 7.4
    @AppStorage("chlorineMin") private var chlorineMin: Double = 0.5
    @AppStorage("chlorineMax") private var chlorineMax: Double = 1.5

    // Dosiereinheit
    @AppStorage("dosingUnit") private var dosingUnit: String = "gramm"
    @AppStorage("cupGrams") private var cupGrams: Double = 50.0

    var body: some View {
        Form {
            Section("Idealbereich pH") {
                HStack {
                    Text("Minimum")
                    Spacer()
                    Text(String(format: "%.1f", phMin))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: phMin)
                    Stepper("", value: $phMin, in: 6.8...8.2, step: 0.1)
                        .labelsHidden()
                }
                HStack {
                    Text("Maximum")
                    Spacer()
                    Text(String(format: "%.1f", phMax))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: phMax)
                    Stepper("", value: $phMax, in: 6.8...8.2, step: 0.1)
                        .labelsHidden()
                }
            }

            Section("Idealbereich Chlor (mg/l)") {
                HStack {
                    Text("Minimum")
                    Spacer()
                    Text(String(format: "%.1f", chlorineMin))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: chlorineMin)
                    Stepper("", value: $chlorineMin, in: 0.0...5.0, step: 0.1)
                        .labelsHidden()
                }
                HStack {
                    Text("Maximum")
                    Spacer()
                    Text(String(format: "%.1f", chlorineMax))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: chlorineMax)
                    Stepper("", value: $chlorineMax, in: 0.0...5.0, step: 0.1)
                        .labelsHidden()
                }
            }

            Section("Dosierung") {
                Picker("Einheit", selection: $dosingUnit) {
                    Text("Gramm").tag("gramm")
                    Text("Becher").tag("becher")
                }

                if dosingUnit == "becher" {
                    HStack {
                        Text("Gramm pro Becher")
                        Spacer()
                        Text(String(format: "%.0f g", cupGrams))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.snappy, value: cupGrams)
                        Stepper("", value: $cupGrams, in: 10...500, step: 5)
                            .labelsHidden()
                    }
                }
            }
        }
        .navigationTitle("Chemie")
    }
}

#Preview {
    NavigationStack {
        ChemistrySettingsView()
    }
}
