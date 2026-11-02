import Foundation
import UserNotifications

enum NotificationManager {
    static let morningID = "norte.morning"
    static let eveningID = "norte.evening"
    static let focusID = "norte.focus"

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleDailyReminders(for profile: UserProfile) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningID, eveningID])
        guard profile.remindersEnabled else { return }

        let cal = Calendar.current
        let morningComponents = cal.dateComponents([.hour, .minute], from: profile.morningTime)
        let eveningComponents = cal.dateComponents([.hour, .minute], from: profile.eveningTime)
        let greetingName = profile.name.isEmpty ? "" : ", \(profile.name)"

        let morning = UNMutableNotificationContent()
        morning.title = "Buenos días\(greetingName) ☀️"
        morning.body = "¿Cuál es tu rana de hoy? Elige la tarea más importante y hazla primero."
        morning.sound = .default
        center.add(UNNotificationRequest(identifier: morningID, content: morning,
                                         trigger: UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: true)))

        let evening = UNMutableNotificationContent()
        evening.title = "Cierre del día 🌙"
        evening.body = "2 minutos: ¿qué lograste, qué te frenó y qué harás mañana?"
        evening.sound = .default
        center.add(UNNotificationRequest(identifier: eveningID, content: evening,
                                         trigger: UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: true)))
    }

    static func scheduleFocusEnd(after seconds: TimeInterval, title: String, body: String) {
        cancelFocusEnd()
        guard seconds > 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: focusID, content: content, trigger: trigger))
    }

    static func cancelFocusEnd() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [focusID])
    }
}
