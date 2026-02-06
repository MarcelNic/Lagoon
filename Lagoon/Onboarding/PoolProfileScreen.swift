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

            Text("Pool-Daten.")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .microAnimation(delay: 0.2)
                .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 24) {
                // Volume Section with Slider
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Volumen", systemImage: "cube.fill")
                            Spacer()
                            Text(String(format: "%.0f m³", poolVolume))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $poolVolume, in: 5...150, step: 5)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    Button {
                        showVolumeCalculator = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "function")
                                .font(.caption)
                            Text("Volumen berechnen")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }

                // Cover Section
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $hasCover) {
                        Label("Abdeckung", systemImage: "shield.fill")
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Pump Runtime Section
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Pumpe", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                            Spacer()
                            Text(String(format: "%.0f Std./Tag", pumpRuntime))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $pumpRuntime, in: 0...24, step: 1)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    Text("Laufzeit pro Tag")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 30)
            .microAnimation(delay: 0.5)

            Spacer()

            PrimaryButton(title: "Weiter", action: action)
                .microAnimation(delay: 0.8)
        }
        .sheet(isPresented: $showVolumeCalculator) {
            PoolVolumeCalculatorView(poolVolume: $poolVolume)
        }
    }
}

#Preview {
    PoolProfileScreen(action: {})
}
