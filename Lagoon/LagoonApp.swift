//
//  LagoonApp.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 11.01.26.
//

import SwiftUI
import SwiftData

@main
struct LagoonApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PoolSettings.self,
            Measurement.self,
            DosingEventModel.self,
            WeatherInputModel.self,
            CareTaskModel.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var poolWaterState = PoolWaterState()
    @State private var notificationManager = NotificationManager()

    private var colorScheme: ColorScheme? {
        (AppearanceMode(rawValue: appearanceMode) ?? .system).colorScheme
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .preferredColorScheme(colorScheme)
                .environment(poolWaterState)
                .task {
                    await notificationManager.requestPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
