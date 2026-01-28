//
//  LiveActivityBackgroundManager.swift
//  Lagoon
//

import Foundation
import BackgroundTasks
import ActivityKit

final class LiveActivityBackgroundManager {
    static let shared = LiveActivityBackgroundManager()

    static let taskIdentifier = "com.marcel.Lagoon.liveActivityRefresh"

    private init() {}

    // MARK: - Registration

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundTask(task as! BGAppRefreshTask)
        }
    }

    // MARK: - Scheduling

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        // Request to run in 30 seconds (system decides actual timing)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled")
        } catch {
            print("Could not schedule background refresh: \(error)")
        }
    }

    func cancelBackgroundRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
        print("Background refresh cancelled")
    }

    // MARK: - Task Handling

    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        // Schedule next refresh before handling current task
        scheduleBackgroundRefresh()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Update all active robot Live Activities
        Task {
            await updateAllRobotActivities()
            task.setTaskCompleted(success: true)
        }
    }

    private func updateAllRobotActivities() async {
        // Find all active robot Live Activities
        for activity in Activity<RobotActivityAttributes>.activities {
            let startTime = activity.attributes.startTime
            let duration = activity.attributes.duration
            let endTime = startTime.addingTimeInterval(duration)

            // Calculate current progress
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(1.0, max(0.0, elapsed / duration))

            // Check if activity should end
            if progress >= 1.0 {
                let finalState = RobotActivityAttributes.ContentState(
                    endTime: endTime,
                    progress: 1.0
                )
                await activity.end(
                    .init(state: finalState, staleDate: nil),
                    dismissalPolicy: .default
                )
            } else {
                // Update with current progress
                let updatedState = RobotActivityAttributes.ContentState(
                    endTime: endTime,
                    progress: progress
                )
                await activity.update(.init(state: updatedState, staleDate: endTime))
            }
        }
    }
}
