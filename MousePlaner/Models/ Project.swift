// Project.swift
import Foundation

struct Project: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var scope: TaskScope
    var tasks: [Task]
    var isArchived = false
    let createdAt: Date
    
    init(id: UUID = UUID(),
         title: String,
         description: String? = nil,
         scope: TaskScope,
         tasks: [Task] = [],
         isArchived: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.scope = scope
        self.tasks = tasks
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
    
    var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count  // ← убираем && !$0.isArchived
    }

    var activeTasksCount: Int {
        tasks.filter { !$0.isCompleted && !$0.isArchived }.count
    }
    
    var archivedTasksCount: Int {
        tasks.filter { $0.isArchived }.count
    }

    var totalTasksCount: Int {
        tasks.count
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, title, description, scope, tasks, isArchived, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        scope = try container.decode(TaskScope.self, forKey: .scope)
        tasks = try container.decode([Task].self, forKey: .tasks)
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(scope, forKey: .scope)
        try container.encode(tasks, forKey: .tasks)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Hashable
extension Project: Hashable {
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
