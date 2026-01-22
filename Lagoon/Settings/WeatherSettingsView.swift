//
//  WeatherSettingsView.swift
//  Lagoon
//

import SwiftUI
import SwiftData

struct WeatherSettingsView: View {
    @Environment(PoolWaterState.self) private var poolWaterState
    @Environment(\.modelContext) private var modelContext

    @AppStorage("uvIndex") private var uvIndex: Double = 5.0
    @AppStorage("airTemperature") private var airTemperature: Double = 25.0
    @AppStorage("useManualWeather") private var useManualWeather: Bool = true

    @State private var showSaveConfirmation = false

    private var uvExposureLevel: String {
        switch uvIndex {
        case 0..<3:
            return "Niedrig"
        case 3..<6:
            return "Mittel"
        default:
            return "Hoch"
        }
    }

    private var uvExposureColor: Color {
        switch uvIndex {
        case 0..<3:
            return .green
        case 3..<6:
            return .yellow
        case 6..<8:
            return .orange
        default:
            return .red
        }
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $useManualWeather) {
                    Label("Manuelle Eingabe", systemImage: "hand.tap.fill")
                }
            } footer: {
                Text("Später kann WeatherKit für automatische Wetterdaten aktiviert werden.")
            }

            if useManualWeather {
                Section("Temperatur") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Lufttemperatur")
                            Spacer()
                            Text(String(format: "%.0f °C", airTemperature))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: airTemperature)
                        }
                        Slider(value: $airTemperature, in: 10...40, step: 1)
                            .tint(.orange)
                    }
                }

                Section("UV-Index") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("UV-Index")
                            Spacer()
                            Text(String(format: "%.0f", uvIndex))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: uvIndex)
                            Text("(\(uvExposureLevel))")
                                .foregroundStyle(uvExposureColor)
                                .fontWeight(.medium)
                        }
                        Slider(value: $uvIndex, in: 0...11, step: 1)
                            .tint(uvExposureColor)
                    }
                }

                Section {
                    Button {
                        saveWeatherInput()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Wetter speichern", systemImage: "cloud.sun")
                            Spacer()
                        }
                    }
                    .buttonStyle(.glassProminent)
                } footer: {
                    Text("Die Wetterdaten beeinflussen die Chlorabbau-Berechnung.")
                }

                if showSaveConfirmation {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Wetterdaten gespeichert")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Der UV-Index beeinflusst den Chlorabbau im Pool. Hohe UV-Werte führen zu schnellerem Abbau.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Wetter")
    }

    private func saveWeatherInput() {
        // Save to SwiftData
        let weather = WeatherInputModel(
            temperature: airTemperature,
            uvIndex: uvIndex,
            timestamp: Date(),
            source: "manual"
        )
        modelContext.insert(weather)

        do {
            try modelContext.save()

            // Also update PoolWaterState
            poolWaterState.recordWeather(
                temperature: airTemperature,
                uvIndex: uvIndex,
                source: "manual"
            )

            // Show confirmation
            withAnimation {
                showSaveConfirmation = true
            }

            // Hide confirmation after delay
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                withAnimation {
                    showSaveConfirmation = false
                }
            }
        } catch {
            print("Error saving weather: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        WeatherSettingsView()
            .environment(PoolWaterState())
    }
}
