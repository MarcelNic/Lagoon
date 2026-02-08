import SwiftUI
import CoreLocation
import MapKit

struct LocationWeatherScreen: View {
    var action: () -> Void

    @AppStorage("latitude") private var latitude: Double = 0.0
    @AppStorage("longitude") private var longitude: Double = 0.0
    @AppStorage("locationName") private var storedLocationName: String = ""

    @State private var locationManager = LocationManager()
    @State private var showSearch = false

    @Environment(\.colorScheme) private var colorScheme

    private var hasLocation: Bool {
        locationManager.locationName != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Location icon
            Image(systemName: "location.circle.fill")
                .font(.system(size: 120))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .blue)
                .microAnimation(delay: 0.2)
                .padding(.bottom, 24)

            // Title
            Text("Standort")
                .font(.system(size: 32, weight: .bold))
                .microAnimation(delay: 0.3)
                .padding(.bottom, 10)

            // Description
            Text("Das Wetter beeinflusst die Wasserqualität. Wir nutzen lokale Daten, um den Chlorverbrauch vorherzusagen.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .microAnimation(delay: 0.4)
                .padding(.horizontal, 40)

            // Status
            if locationManager.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Standort wird ermittelt...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                .microAnimation(delay: 0.5)
            } else if let name = locationManager.locationName {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(name)
                        .font(.subheadline.weight(.medium))
                }
                .padding(.top, 24)
                .microAnimation(delay: 0.5)
            } else if let error = locationManager.error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                .microAnimation(delay: 0.5)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                // Search button
                Button {
                    showSearch = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                        Text("Suchen")
                    }
                    .bold()
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                }
                .glassEffect(.regular.interactive(), in: .capsule)
                .padding(.horizontal, 40)
                .microAnimation(delay: 0.6)

                // Current location / Continue button
                Button {
                    if hasLocation {
                        if let loc = locationManager.location {
                            latitude = loc.coordinate.latitude
                            longitude = loc.coordinate.longitude
                            if let name = locationManager.locationName {
                                storedLocationName = name
                            }
                        }
                        action()
                    } else {
                        locationManager.requestLocation()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: hasLocation ? "checkmark" : "location.fill")
                        Text(hasLocation ? "Weiter" : "Aktuellen Standort verwenden")
                    }
                    .bold()
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .animation(.smooth, value: hasLocation)
                }
                .glassEffect(.regular.tint(colorScheme == .dark ? .white : .black).interactive(), in: .capsule)
                .padding(.horizontal, 40)
                .microAnimation(delay: 0.7)
                .padding(.bottom, 20)

            }
        }
        .sheet(isPresented: $showSearch) {
            LocationSearchSheet(
                locationManager: locationManager,
                onSelect: { coordinate, name in
                    latitude = coordinate.latitude
                    longitude = coordinate.longitude
                    storedLocationName = name
                }
            )
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            latitude = 0.0
            longitude = 0.0
            storedLocationName = ""
        }
    }
}

// MARK: - Location Search Sheet

private struct LocationSearchSheet: View {
    var locationManager: LocationManager
    var onSelect: (CLLocationCoordinate2D, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    HStack {
                        ProgressView()
                        Text("Suche...")
                            .foregroundStyle(.secondary)
                    }
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("Keine Ergebnisse")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(searchResults, id: \.self) { item in
                        let displayName: String = item.name ?? item.address?.shortAddress ?? "Unbekannt"
                        Button {
                            let coord = item.location.coordinate
                            locationManager.location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                            locationManager.locationName = displayName
                            onSelect(coord, displayName)
                            dismiss()
                        } label: {
                            Label(displayName, systemImage: "mappin.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle("Standort suchen")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Stadt oder Postleitzahl")
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.count >= 3 {
                    performSearch()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        let search = MKLocalSearch(request: request)

        Task {
            do {
                let response = try await search.start()
                searchResults = response.mapItems
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }
}

#Preview {
    LocationWeatherScreen(action: {})
}
