//
//  SettingsView.swift
//  Lagoon
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

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
            }
        }
        .navigationTitle("Einstellungen")
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
