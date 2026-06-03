import Foundation
import UserNotifications

protocol NotificationService: Sendable {
    func enableDailyReminder() async throws
    func disableDailyReminder() async
}

enum NotificationServiceError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notifications are disabled for Wordbook in System Settings."
        }
    }
}

struct LiveNotificationService: NotificationService, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func enableDailyReminder() async throws {
        let granted = try await center.requestAuthorization(options: [.alert, .sound])
        guard granted else {
            throw NotificationServiceError.permissionDenied
        }

        await disableDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = "Word of the Day"
        content.body = "Today's English word is ready in Wordbook."
        content.sound = .default

        var components = DateComponents()
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "wordbook.daily-word-reminder",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    func disableDailyReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: ["wordbook.daily-word-reminder"])
    }
}
