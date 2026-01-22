import Foundation
import UserNotifications

@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let quickMeasureActionID = "QUICK_MEASURE"
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
            identifier: Self.quickMeasureActionID,
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

    func scheduleDailyReminder(hour: Int = 10, minute: Int = 0) {
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
                NotificationCenter.default.post(name: .openQuickMeasure, object: nil)
            }
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let openQuickMeasure = Notification.Name("openQuickMeasure")
}
