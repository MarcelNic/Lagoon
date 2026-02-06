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
        VStack {
            Spacer()

            Text("Deine Einstellungen.")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .microAnimation(delay: 0.2)
                .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 24) {
                // Ideal Values Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Idealwerte")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        // pH Range Row
                        HStack {
                            Label("pH", systemImage: "drop.fill")
                                .foregroundStyle(.purple)
                            Spacer()
                            HStack(spacing: 4) {
                                TextField("", value: $idealPHMin, format: .number.precision(.fractionLength(1)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 40)
                                Text("-")
                                    .foregroundStyle(.secondary)
                                TextField("", value: $idealPHMax, format: .number.precision(.fractionLength(1)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 40)
                            }
                            .monospacedDigit()
                        }
                        .padding()

                        Divider().padding(.leading)

                        // Chlorine Range Row
                        HStack {
                            Label("Chlor", systemImage: "bubbles.and.sparkles.fill")
                                .foregroundStyle(.cyan)
                            Spacer()
                            HStack(spacing: 4) {
                                TextField("", value: $idealChlorineMin, format: .number.precision(.fractionLength(1)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 40)
                                Text("-")
                                    .foregroundStyle(.secondary)
                                TextField("", value: $idealChlorineMax, format: .number.precision(.fractionLength(1)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 40)
                                Text("mg/l")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .monospacedDigit()
                        }
                        .padding()
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Dosing Unit Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Deine Dosiereinheit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 12) {
                        Picker("Einheit", selection: $dosingUnit) {
                            Text("Gramm").tag("gramm")
                            Text("Messbecher/Tabs").tag("messbecher")
                        }
                        .pickerStyle(.segmented)

                        if dosingUnit == "messbecher" {
                            HStack {
                                Text("Inhalt pro Becher")
                                Spacer()
                                TextField("", value: $cupGrams, format: .number.precision(.fractionLength(0)))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                                Text("g")
                                    .foregroundStyle(.secondary)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .animation(.easeInOut(duration: 0.2), value: dosingUnit)
                }
            }
            .padding(.horizontal, 30)
            .microAnimation(delay: 0.5)

            Spacer()

            PrimaryButton(title: "Speichern", action: action)
                .microAnimation(delay: 0.8)
        }
    }
}

#Preview {
    GoalsUnitsScreen(action: {})
}
