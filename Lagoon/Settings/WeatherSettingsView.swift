//
//  WeatherSettingsView.swift
//  Lagoon
//

import SwiftUI

struct WeatherSettingsView: View {
    @AppStorage("uvIndex") private var uvIndex: Double = 5.0
    @AppStorage("useManualWeather") private var useManualWeather: Bool = true

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
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Der UV-Index beeinflusst den Chlorabbau im Pool.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Wetter")
    }
}

#Preview {
    NavigationStack {
        WeatherSettingsView()
    }
}
