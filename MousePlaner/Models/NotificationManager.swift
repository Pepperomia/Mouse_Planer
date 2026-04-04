import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    // Запрос разрешения на уведомления
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Разрешение на уведомления получено")
            } else if let error = error {
                print("❌ Ошибка запроса разрешения: \(error)")
            }
        }
    }
    
    // Запланировать уведомление для задачи
    func scheduleNotification(for task: Task) {
        guard let deadline = task.deadline else { return }
        
        // Проверяем, что дедлайн в будущем
        guard deadline > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ Срок задачи!"
        content.body = "\(task.title)"
        if let description = task.description, !description.isEmpty {
            content.body += "\n\(description)"
        }
        content.sound = .default
        content.badge = 1
        
        // Настраиваем триггер на точную дату
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: deadline
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Уникальный ID для уведомления
        let request = UNNotificationRequest(
            identifier: "task_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Ошибка планирования уведомления: \(error)")
            } else {
                print("✅ Уведомление запланировано для задачи: \(task.title) на \(deadline)")
            }
        }
    }
    
    // Отменить уведомление для задачи
    func cancelNotification(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task_\(task.id.uuidString)"]
        )
        print("🗑 Уведомление отменено для задачи: \(task.title)")
    }
    
    // Отменить все уведомления
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑 Все уведомления отменены")
    }
    
    // Проверить все задачи и запланировать уведомления
    func scheduleAllTasksNotifications(tasks: [Task]) {
        // Сначала очищаем старые уведомления
        cancelAllNotifications()
        
        // Планируем для каждой задачи с дедлайном
        for task in tasks where task.deadline != nil && !task.isCompleted && !task.isArchived {
            scheduleNotification(for: task)
        }
        
        // ✅ ИСПРАВЛЕНА ЭТА СТРОЧКА:
        let count = tasks.filter { $0.deadline != nil && !$0.isCompleted && !$0.isArchived }.count
        print("📅 Запланировано уведомлений: \(count)")
    }
}
