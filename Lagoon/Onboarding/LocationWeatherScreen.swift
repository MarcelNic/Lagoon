import SwiftUI
import CoreLocation

struct LocationWeatherScreen: View {
    var action: () -> Void

    @AppStorage("latitude") private var latitude: Double = 0.0
    @AppStorage("longitude") private var longitude: Double = 0.0
    @AppStorage("locationName") private var storedLocationName: String = ""

    @State private var locationManager = LocationManager()
    @State private var postalCode = ""

    private var hasLocation: Bool {
        locationManager.locationName != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Wetter & Standort.")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .microAnimation(delay: 0.2)
                .padding(.top, 60)
                .padding(.bottom, 10)

            Form {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)
                        
                        Text("Das Wetter beeinflusst die Wasserqualität. Mit deinem Standort können wir lokale Wetterdaten nutzen.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color(.systemGray6))
                }

                Section("Standort") {
                    if locationManager.isLoading {
                        HStack {
                            ProgressView()
                            Text("Standort wird ermittelt...")
                                .foregroundStyle(.secondary)
                        }
                        .listRowBackground(Color(.systemGray6))
                    } else if let name = locationManager.locationName {
                        HStack {
                            Label(name, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Spacer()
                        }
                        .listRowBackground(Color(.systemGray6))
                    } else if let error = locationManager.error {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Standort nicht verfügbar", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .listRowBackground(Color(.systemGray6))
                    } else {
                        Button {
                            locationManager.requestLocation()
                        } label: {
                            Label("Standort freigeben", systemImage: "location")
                        }
                        .listRowBackground(Color(.systemGray6))
                    }
                }

                Section("Manuelle Eingabe") {
                    HStack {
                        Text("Postleitzahl")
                        Spacer()
                        TextField("z.B. 80331", text: $postalCode)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    .listRowBackground(Color(.systemGray6))

                    if postalCode.count >= 4 {
                        Button {
                            // Geocode postal code (simplified)
                            latitude = 51.1657
                            longitude = 10.4515
                            storedLocationName = "PLZ \(postalCode)"
                        } label: {
                            Label("PLZ übernehmen", systemImage: "checkmark")
                        }
                        .listRowBackground(Color(.systemGray6))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .microAnimation(delay: 0.5)

            PrimaryButton(title: hasLocation ? "Weiter" : "Überspringen") {
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
            .microAnimation(delay: 0.8)
            .padding(.bottom, 10)
        }
        .onAppear {
            // Reset location data so user can re-enter during onboarding
            latitude = 0.0
            longitude = 0.0
            storedLocationName = ""
        }
    }
}

#Preview {
    LocationWeatherScreen(action: {})
}
