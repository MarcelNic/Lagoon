//
//  LagoonApp.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 11.01.26.
//

import SwiftUI
import SwiftData
import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

@main
struct LagoonApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        // Register background task for Live Activity updates
        LiveActivityBackgroundManager.shared.registerBackgroundTask()
    }

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PoolSettings.self,
            Measurement.self,
            DosingEventModel.self,
            WeatherInputModel.self,
            CareTaskModel.self,
            CareScenario.self,
            CareTask.self,
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
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .preferredColorScheme(colorScheme)
                        .environment(poolWaterState)
                        .environment(notificationManager)
                        .task {
                            await notificationManager.requestPermission()
                        }
                        .transition(.opacity)
                } else {
                    OnboardingStartView(onComplete: {
                        hasCompletedOnboarding = true
                    })
                    .preferredColorScheme(colorScheme)
                    .environment(notificationManager)
                    .transition(.opacity)
                }
            }
            .animation(.smooth(duration: 0.8), value: hasCompletedOnboarding)
        }
        .modelContainer(sharedModelContainer)
    }
}
