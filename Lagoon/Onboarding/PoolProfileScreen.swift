import SwiftUI

struct PoolProfileScreen: View {
    var action: () -> Void

    @AppStorage("poolVolume") private var poolVolume: Double = 40.0
    @AppStorage("hasCover") private var hasCover: Bool = false
    @AppStorage("hasHeating") private var hasHeating: Bool = false
    @AppStorage("pumpRuntime") private var pumpRuntime: Double = 8.0

    @State private var showVolumeCalculator = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Pool-Daten.")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .microAnimation(delay: 0.2)
                .padding(.top, 60)
                .padding(.bottom, 10)

            Form {
                Section("Wasser") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Volumen")
                            Spacer()
                            Text("\(poolVolume, specifier: "%.0f") m³")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: poolVolume)
                        }
                        Slider(value: $poolVolume, in: 5...150, step: 5)
                    }
                    .listRowBackground(Color(.systemGray6))

                    Button {
                        showVolumeCalculator = true
                    } label: {
                        Label("Volumen berechnen", systemImage: "ruler")
                    }
                    .listRowBackground(Color(.systemGray6))
                }

                Section("Ausstattung") {
                    Toggle(isOn: $hasCover) {
                        Label("Abdeckung vorhanden", systemImage: "square.topthird.inset.filled")
                    }
                    .listRowBackground(Color(.systemGray6))
                    Toggle(isOn: $hasHeating) {
                        Label("Heizung vorhanden", systemImage: "thermometer.sun.fill")
                    }
                    .listRowBackground(Color(.systemGray6))
                }

                Section("Pumpe") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Laufzeit pro Tag")
                            Spacer()
                            Text("\(pumpRuntime, specifier: "%.0f") h")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: pumpRuntime)
                        }
                        Slider(value: $pumpRuntime, in: 0...24, step: 1)
                    }
                    .listRowBackground(Color(.systemGray6))
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .microAnimation(delay: 0.5)

            PrimaryButton(title: "Weiter", action: action)
                .microAnimation(delay: 0.8)
                .padding(.bottom, 10)
        }
        .sheet(isPresented: $showVolumeCalculator) {
            PoolVolumeCalculatorView(poolVolume: $poolVolume)
        }
    }
}

#Preview {
    PoolProfileScreen(action: {})
}
