//
//  SettingsView.swift
//  Lagoon
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @AppStorage("barStyle") private var barStyle: String = "classic"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenDashboardOverlay") private var hasSeenDashboardOverlay = false
    @Environment(\.modelContext) private var modelContext
    @State private var showResetConfirmation = false

    var body: some View {
        Form {
            Section {
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

            Section {
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Label("Benachrichtigungen", systemImage: "bell")
                }
            }

            Section {
                Picker("Erscheinungsbild", selection: $appearanceMode) {
                    Text("System").tag("system")
                    Text("Hell").tag("light")
                    Text("Dunkel").tag("dark")
                }

                Picker("Bar-Stil", selection: $barStyle) {
                    Text("Klassisch").tag("classic")
                    Text("V2").tag("v2")
                }
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("App zurücksetzen", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("Einstellungen")
        .confirmationDialog("Alle Daten löschen und zum Onboarding zurückkehren?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Zurücksetzen", role: .destructive) {
                resetApp()
            }
        }
    }

    private func resetApp() {
        // Clear SwiftData
        try? modelContext.delete(model: Measurement.self)
        try? modelContext.delete(model: DosingEventModel.self)
        try? modelContext.delete(model: WeatherInputModel.self)
        try? modelContext.delete(model: PoolSettings.self)
        try? modelContext.delete(model: CareTaskModel.self)
        try? modelContext.delete(model: CareScenario.self)
        try? modelContext.delete(model: CareTask.self)
        try? modelContext.save()

        // Clear UserDefaults
        let keys = ["hasFirstMeasurement", "hasSeenDashboardOverlay", "hasCompletedOnboarding",
                     "lastChlorine", "lastPH", "lastMeasurementDate",
                     "poolVolume", "hasCover", "hasHeating", "pumpRuntime",
                     "idealPHMin", "idealPHMax", "idealChlorineMin", "idealChlorineMax",
                     "phMin", "phMax", "chlorineMin", "chlorineMax",
                     "dosingUnit", "cupGrams", "reminderHour", "reminderMinute",
                     "latitude", "longitude", "locationName", "selectedCareTasks"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // Back to onboarding
        hasCompletedOnboarding = false
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @Environment(NotificationManager.self) private var notificationManager
    @AppStorage("reminderHour") private var reminderHour: Int = 10
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = components.hour ?? 10
                reminderMinute = components.minute ?? 0
                notificationManager.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
            }
        )
    }

    var body: some View {
        Form {
            Section {
                DatePicker("Mess- und Dosiererinnerung", selection: reminderTime, displayedComponents: .hourAndMinute)
            }
        }
        .navigationTitle("Benachrichtigungen")
    }
}

#Preview {
    SettingsView()
}
