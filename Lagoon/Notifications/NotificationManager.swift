import Foundation
import SwiftData
import UserNotifications

@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let measurementDosingActionID = "QUICK_MEASURE"
    static let categoryID = "DAILY_MEASURE"

    private(set) var isAuthorized = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Permission

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            if granted {
                registerCategory()
                scheduleDailyReminder()
            }
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    // MARK: - Category

    private func registerCategory() {
        let measureAction = UNNotificationAction(
            identifier: Self.measurementDosingActionID,
            title: "Jetzt messen",
            options: .foreground
        )

        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [measureAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Scheduling

    func scheduleDailyReminder(hour: Int? = nil, minute: Int? = nil) {
        let defaults = UserDefaults.standard
        let hour = hour ?? (defaults.object(forKey: "reminderHour") as? Int ?? 10)
        let minute = minute ?? (defaults.object(forKey: "reminderMinute") as? Int ?? 0)
        let center = UNUserNotificationCenter.current()

        // Remove existing daily reminders
        center.removePendingNotificationRequests(withIdentifiers: ["dailyMeasure"])

        let content = UNMutableNotificationContent()
        content.title = "Pool messen"
        content.body = "Zeit, pH und Chlor zu messen und zu dosieren."
        content.sound = .default
        content.categoryIdentifier = Self.categoryID

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "dailyMeasure",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Care Task Reminders

    func scheduleCareTaskReminder(task: CareTask) {
        guard isAuthorized, let reminderTime = task.reminderTime, let dueDate = task.dueDate else { return }

        let center = UNUserNotificationCenter.current()
        let identifier = "careTask-\(task.id.uuidString)"

        // Remove existing reminder for this task
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.isAction ? "Timer-Aufgabe steht an." : "Aufgabe ist fällig."
        content.sound = .default

        // Combine dueDate (day) with reminderTime (hour/minute)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        guard let fireDate = calendar.date(from: components), fireDate > Date() else { return }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelCareTaskReminder(taskId: UUID) {
        let identifier = "careTask-\(taskId.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllCareTaskReminders(for scenario: CareScenario) {
        let identifiers = scenario.tasks.map { "careTask-\($0.id.uuidString)" }
        guard !identifiers.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func scheduleAllCareTaskReminders(for scenario: CareScenario) {
        for task in scenario.tasks {
            scheduleCareTaskReminder(task: task)
        }
    }

    func scheduleTimerExpiredNotification(taskTitle: String, taskId: UUID) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = taskTitle
        content.body = "Timer ist abgelaufen."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "careTimer-\(taskId.uuidString)",
            content: content,
            trigger: nil // Fire immediately
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Delegate

    /// Called when notification arrives while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    /// Called when user taps the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        if response.notification.request.content.categoryIdentifier == Self.categoryID {
            await MainActor.run {
                NotificationCenter.default.post(name: .openMeasurementDosing, object: nil)
            }
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let openMeasurementDosing = Notification.Name("openMeasurementDosing")
}
