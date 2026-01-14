//
//  ContentView.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 11.01.26.
//

import SwiftUI

struct ContentView: View {
    @State private var showMessenSheet = false
    @State private var showDosierenSheet = false
    @State private var showPoolcare = false
    @State private var showPoolOverview = false
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        .blue, .cyan, .teal,
                        .cyan, .mint, .cyan,
                        .teal, .cyan, .blue
                    ]
                )
                .scaleEffect(1.2)
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    // pH und Chlor Trend Bars
                    HStack(spacing: 60) {
                        VerticalTrendBar(
                            title: "pH",
                            value: 7.2,
                            minValue: 6.8,
                            maxValue: 8.0,
                            idealMin: 7.2,
                            idealMax: 7.6,
                            tintColor: .green,
                            trend: .up,
                            scalePosition: .leading
                        )

                        VerticalTrendBar(
                            title: "Cl",
                            value: 1.5,
                            minValue: 0,
                            maxValue: 5,
                            idealMin: 1.0,
                            idealMax: 3.0,
                            tintColor: .blue,
                            trend: .down,
                            scalePosition: .trailing
                        )
                    }

                    Spacer()

                    // Bottom Bar
                    GlassEffectContainer(spacing: 12) {
                        HStack(spacing: 12) {
                            // Linker Button - Poolcare + Pool Name
                            HStack(spacing: 0) {
                                Button {
                                    showPoolcare = true
                                } label: {
                                    Image(systemName: "checklist")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.leading, 24)
                                        .padding(.trailing, 12)
                                        .frame(height: 52)
                                }
                                .matchedTransitionSource(id: "poolcare", in: namespace)

                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(width: 1, height: 26)

                                Button {
                                    showPoolOverview = true
                                } label: {
                                    Text("Mein Pool")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundStyle(.white)
                                        .padding(.leading, 12)
                                        .padding(.trailing, 24)
                                        .frame(height: 52)
                                }
                                .matchedTransitionSource(id: "poolOverview", in: namespace)
                            }
                            .glassEffect(.clear.interactive(), in: .capsule)

                            // Mittlerer Button - Messen
                            Button {
                                showMessenSheet = true
                            } label: {
                                Image(systemName: "testtube.2")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 52, height: 52)
                            .glassEffect(.clear.interactive(), in: .circle)

                            // Rechter Button - Dosieren
                            Button {
                                showDosierenSheet = true
                            } label: {
                                Image(systemName: "circle.grid.cross")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 52, height: 52)
                            .glassEffect(.clear.interactive(), in: .circle)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .navigationDestination(isPresented: $showPoolcare) {
                    PoolcareView()
                        .navigationTransition(.zoom(sourceID: "poolcare", in: namespace))
                }
                .navigationDestination(isPresented: $showPoolOverview) {
                    PoolOverviewView()
                        .navigationTransition(.zoom(sourceID: "poolOverview", in: namespace))
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .sheet(isPresented: $showMessenSheet) {
            MessenSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDosierenSheet) {
            DosierenSheet()
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Messen Sheet

struct MessenSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var phValue: Double = 7.2
    @State private var chlorineValue: Double = 1.0
    @State private var waterTemperature: Double = 26.0
    @State private var batherLoad: BatherLoadLevel = .normal
    @State private var measurementDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("pH-Wert", systemImage: "drop.fill")
                            Spacer()
                            Text(String(format: "%.1f", phValue))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: phValue)
                        }
                        Slider(value: $phValue, in: 6.0...9.0, step: 0.1)
                            .tint(.green)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Chlor", systemImage: "allergens.fill")
                            Spacer()
                            Text(String(format: "%.1f mg/l", chlorineValue))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: chlorineValue)
                        }
                        Slider(value: $chlorineValue, in: 0.0...5.0, step: 0.1)
                            .tint(.cyan)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Wassertemperatur", systemImage: "thermometer.medium")
                            Spacer()
                            Text(String(format: "%.0f °C", waterTemperature))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: waterTemperature)
                        }
                        Slider(value: $waterTemperature, in: 10.0...40.0, step: 1.0)
                            .tint(.orange)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Nutzung", systemImage: "figure.pool.swim")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker("Nutzung", selection: $batherLoad) {
                            Text("Keine").tag(BatherLoadLevel.none)
                            Text("Normal").tag(BatherLoadLevel.normal)
                            Text("Viel").tag(BatherLoadLevel.high)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }

                Section {
                    DatePicker(
                        selection: $measurementDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    ) {
                        Label("Zeitpunkt", systemImage: "clock")
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
                        // TODO: Save measurement to SwiftData
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

// MARK: - Dosieren Sheet

struct DosierenSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var phType: PHType = .minus
    @State private var phAmount: Double = 0
    @State private var chlorineAmount: Double = 0
    @State private var dosingDate: Date = Date()

    enum PHType: String, CaseIterable {
        case minus, plus

        var label: String {
            switch self {
            case .minus: return "pH-"
            case .plus: return "pH+"
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
                            Spacer()
                            Text(String(format: "%.0f g", phAmount))
                                .foregroundStyle(.secondary)
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
                        Slider(value: $phAmount, in: 0...300, step: 5)
                            .tint(phType == .minus ? .orange : .purple)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Chlor", systemImage: "allergens.fill")
                            Spacer()
                            Text(String(format: "%.0f g", chlorineAmount))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.snappy, value: chlorineAmount)
                        }
                        Slider(value: $chlorineAmount, in: 0...500, step: 5)
                            .tint(.cyan)
                    }
                }

                Section {
                    DatePicker(
                        selection: $dosingDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    ) {
                        Label("Zeitpunkt", systemImage: "clock")
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
                        // TODO: Save dosing to SwiftData
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

// MARK: - Poolcare View

struct PoolcareView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header mit Liquid Glass
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive(), in: .circle)

                Spacer()

                Text("Poolcare")
                    .font(.headline)

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            Text("Poolcare Inhalt")

            Spacer()
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Pool Overview View

struct PoolOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header mit Liquid Glass
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive(), in: .circle)

                Spacer()

                Text("Mein Pool")
                    .font(.headline)

                Spacer()

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            Text("Pool Übersicht Inhalt")

            Spacer()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            PoolSettingsSheet()
        }
    }
}

// MARK: - Pool Settings Sheet

struct PoolSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        PoolSettingsView()
                    } label: {
                        Label("Pool", systemImage: "drop.fill")
                    }

                    NavigationLink {
                        ChemistrySettingsView()
                    } label: {
                        Label("Chemie", systemImage: "flask.fill")
                    }

                    NavigationLink {
                        WeatherSettingsView()
                    } label: {
                        Label("Wetter", systemImage: "sun.max.fill")
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
