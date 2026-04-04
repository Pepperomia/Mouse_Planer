// ProjectDetailView.swift
import SwiftUI

struct ProjectDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    let project: Project
    let onSave: (Project) -> Void
    let onDelete: (Project) -> Void
    let onArchive: (Project) -> Void
    
    @State private var editedTitle: String
    @State private var editedDescription: String
    @State private var tasks: [Task]
    @State private var isEditing = false
    @State private var showAddTask = false
    
    init(project: Project,
         onSave: @escaping (Project) -> Void,
         onDelete: @escaping (Project) -> Void,
         onArchive: @escaping (Project) -> Void) {
        self.project = project
        self.onSave = onSave
        self.onDelete = onDelete
        self.onArchive = onArchive
        _editedTitle = State(initialValue: project.title)
        _editedDescription = State(initialValue: project.description ?? "")
        _tasks = State(initialValue: project.tasks)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    projectInfoCard
                    tasksSection
                }
                .padding()
            }
            .background(Color.adaptiveBackground)
            .navigationTitle(isEditing ? "Редактирование" : project.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if !isEditing {
                            Button {
                                onArchive(project)
                                dismiss()
                            } label: {
                                Image(systemName: "archivebox")
                            }
                            .tint(.orange)
                        }
                        
                        Button(isEditing ? "Сохранить" : "Править") {
                            if isEditing {
                                saveChanges()
                            }
                            isEditing.toggle()
                        }
                        
                        if !isEditing {
                            Button(role: .destructive) {
                                onDelete(project)
                                dismiss()
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet(scope: project.scope) { title, description, deadline, priority in
                    addTaskToProject(
                        title: title,
                        description: description,
                        deadline: deadline,
                        priority: priority
                    )
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedProject = project
        updatedProject.title = editedTitle
        updatedProject.description = editedDescription.isEmpty ? nil : editedDescription
        updatedProject.tasks = tasks
        onSave(updatedProject)
    }
    
    var projectInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEditing {
                TextField("Название проекта", text: $editedTitle)
                    .font(.title2.bold())
                    .textFieldStyle(.roundedBorder)
                
                TextField("Описание", text: $editedDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            } else {
                if let description = project.description, !description.isEmpty {
                    Text(description)
                        .foregroundColor(.gray)
                } else {
                    Text("Нет описания")
                        .foregroundColor(.gray.opacity(0.6))
                        .italic()
                }
                
                HStack {
                    Label("\(activeTasksCount) активных", systemImage: "checkmark.circle")
                    Spacer()
                    Label("\(completedTasksCount) завершено", systemImage: "checkmark.circle.fill")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.adaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Задачи")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showAddTask = true
                } label: {
                    Label("Добавить", systemImage: "plus")
                        .font(.caption)
                }
            }
            
            if tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Нет задач")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Добавьте первую задачу в проект")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(tasks) { task in
                        TaskCard(
                            task: task,
                            onComplete: { completeTask(task) },
                            onEdit: { editTask(task) },
                            onDelete: { deleteTask(task) }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.adaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var activeTasksCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
    
    private var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    // ИСПРАВЛЕННАЯ ФУНКЦИЯ - правильный порядок параметров
    private func addTaskToProject(title: String, description: String, deadline: Date?, priority: Task.Priority) {
        let newTask = Task(
            title: title,
            description: description,    
            deadline: deadline,
            personalType: nil,
            priority: priority,
            scope: project.scope
        )
        tasks.append(newTask)
        saveChanges()
    }
    
    private func completeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveChanges()
        }
    }
    
    private func editTask(_ task: Task) {
        // Можно реализовать редактирование задачи
    }
    
    private func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveChanges()
    }
}
