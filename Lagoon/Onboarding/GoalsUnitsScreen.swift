import SwiftUI

struct GoalsUnitsScreen: View {
    var action: () -> Void

    // pH Range
    @AppStorage("idealPHMin") private var idealPHMin: Double = 7.0
    @AppStorage("idealPHMax") private var idealPHMax: Double = 7.4

    // Chlorine Range
    @AppStorage("idealChlorineMin") private var idealChlorineMin: Double = 0.5
    @AppStorage("idealChlorineMax") private var idealChlorineMax: Double = 1.0

    // Dosing Unit
    @AppStorage("dosingUnit") private var dosingUnit: String = "gramm"
    @AppStorage("cupGrams") private var cupGrams: Double = 50.0

    var body: some View {
        VStack(spacing: 0) {
            Text("Deine Einstellungen.")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .microAnimation(delay: 0.2)
                .padding(.top, 60)
                .padding(.bottom, 10)

            Form {
                Section("Idealbereich pH") {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        Text(String(format: "%.1f", idealPHMin))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: idealPHMin)
                        Stepper("", value: $idealPHMin, in: 6.8...8.2, step: 0.1)
                            .labelsHidden()
                    }
                    .listRowBackground(Color(.systemGray6))

                    HStack {
                        Text("Maximum")
                        Spacer()
                        Text(String(format: "%.1f", idealPHMax))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: idealPHMax)
                        Stepper("", value: $idealPHMax, in: 6.8...8.2, step: 0.1)
                            .labelsHidden()
                    }
                    .listRowBackground(Color(.systemGray6))
                }

                Section("Idealbereich Chlor (mg/l)") {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        Text(String(format: "%.1f", idealChlorineMin))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: idealChlorineMin)
                        Stepper("", value: $idealChlorineMin, in: 0.0...5.0, step: 0.1)
                            .labelsHidden()
                    }
                    .listRowBackground(Color(.systemGray6))

                    HStack {
                        Text("Maximum")
                        Spacer()
                        Text(String(format: "%.1f", idealChlorineMax))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: idealChlorineMax)
                        Stepper("", value: $idealChlorineMax, in: 0.0...5.0, step: 0.1)
                            .labelsHidden()
                    }
                    .listRowBackground(Color(.systemGray6))
                }

                Section("Dosiereinheit") {
                    Picker("Einheit", selection: $dosingUnit) {
                        Text("Gramm").tag("gramm")
                        Text("Messbecher/Tabs").tag("messbecher")
                    }
                    .listRowBackground(Color(.systemGray6))

                    if dosingUnit == "messbecher" {
                        HStack {
                            Text("Gramm pro Becher")
                            Spacer()
                            Text(String(format: "%.0f g", cupGrams))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: cupGrams)
                            Stepper("", value: $cupGrams, in: 10...500, step: 5)
                                .labelsHidden()
                        }
                        .listRowBackground(Color(.systemGray6))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: dosingUnit)
            }
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .microAnimation(delay: 0.5)

            PrimaryButton(title: "Speichern", action: action)
                .microAnimation(delay: 0.8)
                .padding(.bottom, 10)
        }
    }
}

#Preview {
    GoalsUnitsScreen(action: {})
}
