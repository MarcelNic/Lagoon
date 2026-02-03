import SwiftUI

struct PoolProfileScreen: View {
    var action: () -> Void

    @AppStorage("poolVolume") private var poolVolume: Double = 40.0
    @AppStorage("hasCover") private var hasCover: Bool = false
    @AppStorage("pumpRuntime") private var pumpRuntime: Double = 8.0

    @State private var showVolumeCalculator = false

    var body: some View {
        VStack {
            Spacer()

            Text("Dein Pool.")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .microAnimation(delay: 0.2)
                .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 24) {
                // Volume Section
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        showVolumeCalculator = true
                    } label: {
                        HStack {
                            Label("Volumen", systemImage: "cube.fill")
                            Spacer()
                            Text(String(format: "%.0f m³", poolVolume))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .tint(.primary)
                    Text("Tippe, um das Volumen zu berechnen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                // Cover Section
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $hasCover) {
                        Label("Abdeckung vorhanden", systemImage: "shield.fill")
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    Text("Eine Abdeckung reduziert Verdunstung und Verschmutzung")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                // Pump Runtime Section
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Pumplaufzeit", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                            Spacer()
                            Text(String(format: "%.0f Std.", pumpRuntime))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $pumpRuntime, in: 0...24, step: 1)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    Text("Wie lange läuft deine Pumpe täglich?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 30)
            .microAnimation(delay: 0.5)

            Spacer()

            PrimaryButton(title: "Weiter", action: action)
                .padding(.horizontal, 30)
                .microAnimation(delay: 0.8)

            Spacer()
        }
        .sheet(isPresented: $showVolumeCalculator) {
            PoolVolumeCalculatorView(poolVolume: $poolVolume)
        }
    }
}

#Preview {
    PoolProfileScreen(action: {})
}
