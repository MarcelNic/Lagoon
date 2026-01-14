//
//  PoolSettingsView.swift
//  Lagoon
//

import SwiftUI

struct PoolSettingsView: View {
    @AppStorage("poolName") private var poolName: String = "Pool"
    @AppStorage("poolVolume") private var poolVolume: Double = 0.0
    @AppStorage("hasCover") private var hasCover: Bool = false
    @AppStorage("hasHeating") private var hasHeating: Bool = false
    @AppStorage("pumpRuntime") private var pumpRuntime: Double = 8.0

    @State private var showingVolumeCalc = false

    var body: some View {
        Form {
            Section("Allgemein") {
                HStack {
                    Text("Name")
                    TextField("Name des Pools", text: $poolName)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                }
            }

            Section("Wasser") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Volumen")
                        Spacer()
                        Text("\(poolVolume, specifier: "%.1f") m³")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.snappy, value: poolVolume)
                    }
                    Slider(value: $poolVolume, in: 0...100, step: 0.5)
                }

                Button {
                    showingVolumeCalc = true
                } label: {
                    Label("Volumen berechnen", systemImage: "ruler")
                }
            }

            Section("Ausstattung") {
                Toggle(isOn: $hasCover) {
                    Label("Abdeckung vorhanden", systemImage: "square.topthird.inset.filled")
                }
                Toggle(isOn: $hasHeating) {
                    Label("Heizung vorhanden", systemImage: "thermometer.sun.fill")
                }
            }

            Section("Pumpe") {
                VStack(alignment: .leading) {
                    HStack {
                        Label("Laufzeit pro Tag", systemImage: "clock")
                        Spacer()
                        Text("\(pumpRuntime, specifier: "%.1f") h")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.snappy, value: pumpRuntime)
                    }
                    Slider(value: $pumpRuntime, in: 0...24, step: 0.5)
                }
            }
        }
        .navigationTitle("Pool")
        .sheet(isPresented: $showingVolumeCalc) {
            PoolVolumeCalculatorView(poolVolume: $poolVolume)
        }
    }
}

#Preview {
    NavigationStack {
        PoolSettingsView()
    }
}
