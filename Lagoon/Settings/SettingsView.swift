//
//  SettingsView.swift
//  Lagoon
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    var body: some View {
        NavigationStack {
            Form {
                Section("Pool") {
                    NavigationLink {
                        PoolSettingsView()
                    } label: {
                        Label("Pool", systemImage: "figure.pool.swim")
                    }

                    NavigationLink {
                        ChemistrySettingsView()
                    } label: {
                        Label("Chemie", systemImage: "testtube.2")
                    }

                    NavigationLink {
                        WeatherSettingsView()
                    } label: {
                        Label("Wetter", systemImage: "cloud.sun")
                    }
                }

                Section("App") {
                    Picker("Erscheinungsbild", selection: $appearanceMode) {
                        Text("System").tag("system")
                        Text("Hell").tag("light")
                        Text("Dunkel").tag("dark")
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
