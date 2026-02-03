import SwiftUI
import CoreLocation

struct LocationWeatherScreen: View {
    var action: () -> Void

    @AppStorage("latitude") private var latitude: Double = 0.0
    @AppStorage("longitude") private var longitude: Double = 0.0
    @AppStorage("locationName") private var storedLocationName: String = ""

    @State private var locationManager = LocationManager()
    @State private var showManualEntry = false
    @State private var postalCode = ""

    private var hasLocation: Bool {
        latitude != 0.0 && longitude != 0.0
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange, .yellow)
                    .microAnimation(delay: 0.2)

                Text("Sonne, Regen oder Sturm?")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .microAnimation(delay: 0.3)

                Text("Mit deinem Standort kann Lagoon Wetterdaten abrufen und die Wasserchemie genauer vorhersagen.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .microAnimation(delay: 0.5)
            }
            .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 16) {
                // Status display
                if locationManager.isLoading {
                    ProgressView("Standort wird ermittelt...")
                        .padding()
                } else if let name = locationManager.locationName {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(name)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                } else if hasLocation && !storedLocationName.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(storedLocationName)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                } else if let error = locationManager.error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                // Primary button - GPS
                if !hasLocation && locationManager.locationName == nil {
                    PrimaryButton(title: "Standort automatisch ermitteln") {
                        locationManager.requestLocation()
                    }
                    .microAnimation(delay: 0.7)
                }

                // Manual entry toggle
                if !showManualEntry && !hasLocation && locationManager.locationName == nil {
                    Button("PLZ manuell eingeben") {
                        withAnimation { showManualEntry = true }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .microAnimation(delay: 0.9)
                }

                // Manual entry field
                if showManualEntry {
                    VStack(spacing: 12) {
                        TextField("Postleitzahl", text: $postalCode)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)

                        Button("Übernehmen") {
                            // For simplicity, use a default German location
                            // In production, you'd geocode the postal code
                            latitude = 51.1657
                            longitude = 10.4515
                            storedLocationName = "PLZ \(postalCode)"
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(postalCode.count < 4)
                    }
                    .padding()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 30)

            Spacer()

            // Continue button (always visible, even without location)
            PrimaryButton(title: hasLocation || locationManager.locationName != nil ? "Weiter" : "Überspringen") {
                // Save location if we got one from GPS
                if let loc = locationManager.location {
                    latitude = loc.coordinate.latitude
                    longitude = loc.coordinate.longitude
                    if let name = locationManager.locationName {
                        storedLocationName = name
                    }
                }
                action()
            }
            .padding(.horizontal, 30)
            .microAnimation(delay: 1.0)

            Spacer()
        }
    }
}

#Preview {
    LocationWeatherScreen(action: {})
}
