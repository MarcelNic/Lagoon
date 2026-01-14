//
//  PoolVolumeCalculatorView.swift
//  Lagoon
//

import SwiftUI

struct PoolVolumeCalculatorView: View {
    @Binding var poolVolume: Double
    @Environment(\.dismiss) private var dismiss

    @State private var shape: PoolShape = .rectangular
    @State private var length: Double = 8.0
    @State private var width: Double = 4.0
    @State private var depth: Double = 1.5

    enum PoolShape: String, CaseIterable {
        case rectangular = "Rechteck"
        case round = "Rund"
        case oval = "Oval"
    }

    private var volume: Double {
        switch shape {
        case .rectangular:
            return length * width * depth
        case .round:
            return .pi * pow(length / 2, 2) * depth
        case .oval:
            return .pi * (length / 2) * (width / 2) * depth
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Volume Display
                Section {
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", volume))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                            .animation(.snappy, value: volume)

                        Text("Kubikmeter (m³)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // Shape Picker
                Section("Form") {
                    Picker("Poolform", selection: $shape) {
                        ForEach(PoolShape.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Dimensions
                Section("Abmessungen") {
                    switch shape {
                    case .rectangular:
                        DimensionRow(label: "Länge", value: $length, range: 1...20)
                        DimensionRow(label: "Breite", value: $width, range: 1...15)
                        DimensionRow(label: "Tiefe", value: $depth, range: 0.5...3)

                    case .round:
                        DimensionRow(label: "Durchmesser", value: $length, range: 1...15)
                        DimensionRow(label: "Tiefe", value: $depth, range: 0.5...3)

                    case .oval:
                        DimensionRow(label: "Länge", value: $length, range: 1...20)
                        DimensionRow(label: "Breite", value: $width, range: 1...15)
                        DimensionRow(label: "Tiefe", value: $depth, range: 0.5...3)
                    }
                }
            }
            .navigationTitle("Volumen berechnen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") {
                        poolVolume = volume
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }
}

// MARK: - Dimension Row

private struct DimensionRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: "%.2f m", value))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: value)
            }
            Slider(value: $value, in: range, step: 0.05)
        }
    }
}

#Preview {
    PoolVolumeCalculatorView(poolVolume: .constant(0.0))
}
