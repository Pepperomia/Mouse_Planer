import SwiftUI

struct ArchiveView: View {
    let archivedTasks: [Task]
    let archivedProjects: [Project]
    let onUnarchiveTask: (Task) -> Void
    let onUnarchiveProject: (Project) -> Void
    let onDeleteTask: (Task) -> Void
    let onDeleteProject: (Project) -> Void
    
    @State private var selectedSegment = 0 // 0 - задачи, 1 - проекты
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Тип", selection: $selectedSegment) {
                    Text("Задачи").tag(0)
                    Text("Проекты").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView {
                    if selectedSegment == 0 {
                        if archivedTasks.isEmpty {
                            emptyStateView(
                                icon: "archivebox",
                                title: "Нет архивных задач",
                                message: "Завершённые задачи попадут сюда"
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(archivedTasks) { task in
                                    ArchiveTaskCard(
                                        task: task,
                                        onUnarchive: { onUnarchiveTask(task) },
                                        onDelete: { onDeleteTask(task) }
                                    )
                                }
                            }
                            .padding()
                        }
                    } else {
                        if archivedProjects.isEmpty {
                            emptyStateView(
                                icon: "folder.archive",
                                title: "Нет архивных проектов",
                                message: "Архивированные проекты появятся здесь"
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(archivedProjects) { project in
                                    ArchiveProjectCard(
                                        project: project,
                                        onUnarchive: { onUnarchiveProject(project) },
                                        onDelete: { onDeleteProject(project) }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Архив")
            .background(Color.adaptiveBackground)
        }
    }
    
    @ViewBuilder
    func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Archive Task Card
struct ArchiveTaskCard: View {
    let task: Task
    let onUnarchive: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                    
                    if let description = task.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                PriorityBadge(priority: task.priority)
            }
            
            HStack {
                if let deadline = task.deadline {
                    Label(
                        title: { Text(deadline.formatted(date: .abbreviated, time: .omitted)) },
                        icon: { Image(systemName: "calendar") }
                    )
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onUnarchive) {
                    Label("Разархивировать", systemImage: "archivebox.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: onDelete) {
                    Label("Удалить", systemImage: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.adaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Archive Project Card
struct ArchiveProjectCard: View {
    let project: Project
    let onUnarchive: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(Color.customBlueLight)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.headline)
                    
                    if let description = project.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            
            HStack {
                // ✅ ИСПРАВЛЕНО: используем правильные свойства Project
                Label("\(project.activeTasksCount) активных", systemImage: "checkmark.circle")
                    .font(.caption2)
                    .foregroundColor(.green)
                
                Label("\(project.completedTasksCount) завершено", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: onUnarchive) {
                    Label("Разархивировать", systemImage: "archivebox.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: onDelete) {
                    Label("Удалить", systemImage: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.adaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: Task.Priority
    
    var color: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    
    var text: String {
        switch priority {
        case .high: return "Высокий"
        case .medium: return "Средний"
        case .low: return "Низкий"
        }
    }
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
