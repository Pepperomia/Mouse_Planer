// Task.swift
import Foundation

enum TaskScope: String, Codable {
    case work = "work"
    case personal = "personal"
}

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var deadline: Date?
    var personalType: PersonalType?
    var priority: Priority
    var scope: TaskScope
    var isCompleted = false
    var isArchived = false
    let createdAt: Date
    
    enum Priority: String, CaseIterable, Codable {
        case low = "low"
        case medium = "med"
        case high = "high"
        
        var icon: String {
            switch self {
            case .high: return "high"
            case .medium: return "med"
            case .low: return "low"
            }
        }
    }
    
    enum PersonalType: String, Codable {
        case chore = "Дело"
        case dream = "Мечта"
    }
    
    // Инициализатор по умолчанию
    init(id: UUID = UUID(),
         title: String,
         description: String? = nil,
         deadline: Date? = nil,
         personalType: PersonalType? = nil,
         priority: Priority,
         scope: TaskScope,
         isCompleted: Bool = false,
         isArchived: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.deadline = deadline
        self.personalType = personalType
        self.priority = priority
        self.scope = scope
        self.isCompleted = isCompleted
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
    
    // Инициализатор для декодирования из JSON
    enum CodingKeys: String, CodingKey {
        case id, title, description, deadline, personalType, priority, scope, isCompleted, isArchived, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        deadline = try container.decodeIfPresent(Date.self, forKey: .deadline)
        personalType = try container.decodeIfPresent(PersonalType.self, forKey: .personalType)
        priority = try container.decode(Priority.self, forKey: .priority)
        scope = try container.decode(TaskScope.self, forKey: .scope)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(deadline, forKey: .deadline)
        try container.encodeIfPresent(personalType, forKey: .personalType)
        try container.encode(priority, forKey: .priority)
        try container.encode(scope, forKey: .scope)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Hashable
extension Task: Hashable {
    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
