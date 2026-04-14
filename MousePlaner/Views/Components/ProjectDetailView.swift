// ProjectDetailView.swift
import SwiftUI

struct ProjectDetailView: View {
    
    let project: Project
    let onSave: (Project) -> Void
    let onDelete: (Project) -> Void
    let onArchive: (Project) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedDescription: String
    @State private var editedScope: TaskScope
    @State private var tasks: [Task]
    @State private var showAddTask = false
    @State private var selectedTask: Task?
    @State private var refreshTrigger = false
    
    init(
        project: Project,
        onSave: @escaping (Project) -> Void,
        onDelete: @escaping (Project) -> Void,
        onArchive: @escaping (Project) -> Void
    ) {
        self.project = project
        self.onSave = onSave
        self.onDelete = onDelete
        self.onArchive = onArchive
        _editedTitle = State(initialValue: project.title)
        _editedDescription = State(initialValue: project.description ?? "")
        _editedScope = State(initialValue: project.scope)
        _tasks = State(initialValue: project.tasks)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.customBlueGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        mainCard
                        tasksSection
                        
                        if !isEditing {
                            actionButtons
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("Mouse_ProjectIn")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                            .padding(.trailing, 8)
                            .padding(.bottom, 8)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Сохранить") {
                            saveChanges()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    } else {
                        Button(action: { isEditing = true }) {
                            Text("Править")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet(scope: editedScope) { title, description, deadline, priority in
                    addTaskToProject(
                        title: title,
                        description: description,
                        deadline: deadline,
                        priority: priority
                    )
                }
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(
                    task: task,
                    onSave: { updatedTask, newTitle, newDescription, newDeadline in
                        updateTaskInProject(updatedTask, newTitle, newDescription, newDeadline)
                    },
                    onComplete: { completeTask($0) },
                    onDelete: { deleteTask($0) }
                )
            }
        }
    }
    
    private func saveChanges() {
        var updatedProject = project
        updatedProject.title = editedTitle
        updatedProject.description = editedDescription.isEmpty ? nil : editedDescription
        updatedProject.scope = editedScope
        updatedProject.tasks = tasks.map { task in
            var updatedTask = task
            updatedTask.scope = editedScope
            return updatedTask
        }
        onSave(updatedProject)
    }
    
    // MARK: - UI Components
    
    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                if isEditing {
                    TextField("Название проекта", text: $editedTitle)
                        .font(.title.bold())
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(editedTitle)
                        .font(.title.bold())
                        .foregroundColor(.white)
                }
                
                if isEditing {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Тип проекта")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Picker("Тип проекта", selection: $editedScope) {
                            Label("Рабочий", systemImage: "briefcase").tag(TaskScope.work)
                            Label("Личный", systemImage: "person").tag(TaskScope.personal)
                        }
                        .pickerStyle(.segmented)
                        .colorMultiply(.white)
                    }
                } else {
                    HStack {
                        Image(systemName: editedScope == .work ? "briefcase" : "person")
                            .foregroundColor(.white.opacity(0.8))
                        Text(editedScope == .work ? "Рабочий проект" : "Личный проект")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Прогресс-бар вместо старых бейджей
            if !isEditing {
                VStack(spacing: 8) {
                    let totalTasks = tasks.count
                    let completed = completedTasksCount
                    let progress = totalTasks == 0 ? 0 : Double(completed) / Double(totalTasks)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(width: geometry.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("\(completed) из \(totalTasks) завершено")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text("\(activeTasksCount) активных")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                if !isEditing && !editedDescription.isEmpty {
                    Text("Описание")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                if isEditing {
                    TextField("Описание", text: $editedDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                } else if !editedDescription.isEmpty {
                    Text(editedDescription)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.leading, 4)
                } else if !isEditing {
                    Text("Нет описания")
                        .foregroundColor(.white.opacity(0.5))
                        .italic()
                }
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📋 Задачи проекта")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if !isEditing {
                    Button {
                        showAddTask = true
                    } label: {
                        Label("Добавить", systemImage: "plus")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundColor(.white)
                    }
                }
            }
            
            if tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Нет задач")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Нажмите + чтобы добавить")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(tasks) { task in
                        Button {
                            openTaskDetail(task)
                        } label: {
                            TaskCard(
                                task: task,
                                onComplete: { completeTask(task) },
                                onEdit: { editTask(task) },
                                onDelete: { deleteTask(task) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .id(refreshTrigger)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                onArchive(project)
                dismiss()
            }) {
                Label("Архивировать проект", systemImage: "archivebox.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Button(action: {
                onDelete(project)
                dismiss()
            }) {
                Label("Удалить проект", systemImage: "trash.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.9))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var activeTasksCount: Int {
        tasks.filter { !$0.isCompleted && !$0.isArchived }.count
    }
    
    private var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    private var archivedTasksCount: Int {
        tasks.filter { $0.isArchived }.count
    }
    
    // MARK: - Task Management
    
    private func addTaskToProject(title: String, description: String, deadline: Date?, priority: Task.Priority) {
        let newTask = Task(
            title: title,
            description: description,
            deadline: deadline,
            personalType: nil,
            priority: priority,
            scope: editedScope
        )
        tasks.append(newTask)
        saveChanges()
    }
    
    private func completeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            // Меняем состояние
            tasks[index].isCompleted.toggle()
            tasks[index].isArchived = tasks[index].isCompleted
            
            // Сохраняем изменения
            saveChanges()
            refreshTrigger.toggle()
            
            // Принудительно обновляем массив, чтобы триггернуть UI
            tasks = tasks.map { $0 }
        }
    }
    
    private func editTask(_ task: Task) {
        openTaskDetail(task)
    }
    
    private func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveChanges()
    }
    
    // MARK: - Navigation Helpers
    
    private func openTaskDetail(_ task: Task) {
        selectedTask = task
    }
    
    private func updateTaskInProject(_ task: Task, _ newTitle: String, _ newDescription: String?, _ newDeadline: Date?) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].title = newTitle
            tasks[index].description = newDescription
            tasks[index].deadline = newDeadline
            saveChanges()
        }
    }
}
