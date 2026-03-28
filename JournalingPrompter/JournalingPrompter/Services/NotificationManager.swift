import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderIdentifier = "daily-journal-reminder"

    init() {
        Task {
            await checkAuthorizationStatus()
            loadSavedReminderTime()
        }
    }

    func requestAuthorization() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                isAuthorized = granted
            }
            if granted {
                await scheduleDailyReminder()
            }
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    func scheduleDailyReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Time to Journal"
        content.body = "Take a moment to reflect on your day. Your personalized prompt is waiting."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            saveReminderTime()
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    func updateReminderTime(_ newTime: Date) async {
        reminderTime = newTime
        await scheduleDailyReminder()
    }

    func cancelReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }

    private func saveReminderTime() {
        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
    }

    private func loadSavedReminderTime() {
        if let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
            reminderTime = savedTime
        }
    }
}
