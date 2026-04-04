import Foundation

class DataManager {
    static let shared = DataManager()
    private init() {}
    
    private let fileName = "mice_planner_data.json"
    
    private var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }
    
    struct SaveData: Codable {
        var workTasks: [Task]
        var personalTasks: [Task]
        var projects: [Project]
    }
    
    func save(workTasks: [Task], personalTasks: [Task], projects: [Project]) {
        let data = SaveData(workTasks: workTasks, personalTasks: personalTasks, projects: projects)
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: fileURL)
            print("✅ Данные сохранены в: \(fileURL)")
        } catch {
            print("❌ Ошибка сохранения: \(error)")
        }
    }
    
    func load() -> (workTasks: [Task], personalTasks: [Task], projects: [Project])? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ℹ️ Файл данных не найден, создаём новый")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(SaveData.self, from: data)
            print("✅ Данные загружены из: \(fileURL)")
            return (decoded.workTasks, decoded.personalTasks, decoded.projects)
        } catch {
            print("❌ Ошибка загрузки: \(error)")
            return nil
        }
    }
}
