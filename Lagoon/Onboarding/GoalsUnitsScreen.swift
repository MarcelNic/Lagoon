import SwiftUI

struct GoalsUnitsScreen: View {
    var action: () -> Void

    // pH Range
    @AppStorage("idealPHMin") private var idealPHMin: Double = 7.2
    @AppStorage("idealPHMax") private var idealPHMax: Double = 7.6

    // Chlorine Range
    @AppStorage("idealChlorineMin") private var idealChlorineMin: Double = 1.0
    @AppStorage("idealChlorineMax") private var idealChlorineMax: Double = 1.5

    // Dosing Unit
    @AppStorage("dosingUnit") private var dosingUnit: String = "gramm"
    @AppStorage("cupGrams") private var cupGrams: Double = 50.0

    var body: some View {
        VStack {
            Spacer()

            Text("Deine Zielwerte.")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .microAnimation(delay: 0.2)
                .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 24) {
                // pH Range
                VStack(alignment: .leading, spacing: 8) {
                    Text("pH-Wert")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    VStack(spacing: 0) {
                        Stepper(value: $idealPHMin, in: 6.8...idealPHMax, step: 0.1) {
                            HStack {
                                Text("Minimum")
                                Spacer()
                                Text(String(format: "%.1f", idealPHMin))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .padding()
                        Divider().padding(.leading)
                        Stepper(value: $idealPHMax, in: idealPHMin...8.0, step: 0.1) {
                            HStack {
                                Text("Maximum")
                                Spacer()
                                Text(String(format: "%.1f", idealPHMax))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .padding()
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Chlorine Range
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chlor (mg/l)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    VStack(spacing: 0) {
                        Stepper(value: $idealChlorineMin, in: 0.3...idealChlorineMax, step: 0.1) {
                            HStack {
                                Text("Minimum")
                                Spacer()
                                Text(String(format: "%.1f", idealChlorineMin))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .padding()
                        Divider().padding(.leading)
                        Stepper(value: $idealChlorineMax, in: idealChlorineMin...3.0, step: 0.1) {
                            HStack {
                                Text("Maximum")
                                Spacer()
                                Text(String(format: "%.1f", idealChlorineMax))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .padding()
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Dosing Unit
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dosiereinheit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    VStack(spacing: 12) {
                        Picker("Einheit", selection: $dosingUnit) {
                            Text("Gramm").tag("gramm")
                            Text("Messbecher").tag("messbecher")
                        }
                        .pickerStyle(.segmented)

                        if dosingUnit == "messbecher" {
                            Stepper(value: $cupGrams, in: 10...200, step: 5) {
                                HStack {
                                    Text("Gramm pro Becher")
                                    Spacer()
                                    Text(String(format: "%.0f g", cupGrams))
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 30)
            .microAnimation(delay: 0.5)

            Spacer()

            PrimaryButton(title: "Speichern", action: action)
                .padding(.horizontal, 30)
                .microAnimation(delay: 0.8)

            Spacer()
        }
    }
}

#Preview {
    GoalsUnitsScreen(action: {})
}
