import SwiftUI
import Combine

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        Form {
            Section("Уведомления") {
                Toggle("Напоминать о сроках задач", isOn: $notificationsEnabled)
                    .onReceive(Just(notificationsEnabled)) { newValue in
                        if newValue {
                            NotificationManager.shared.requestAuthorization()
                        } else {
                            NotificationManager.shared.cancelAllNotifications()
                        }
                    }
            }
            
            Section("Информация") {
                HStack {
                    Text("Версия")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Настройки")
    }
}
