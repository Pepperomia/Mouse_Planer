// ContentView.swift
import SwiftUI

// MARK: - Main ContentView
struct ContentView: View {
    
    // MARK: - Data
    @State private var workTasks: [Task] = []
    @State private var personalTasks: [Task] = []  // ← ИСПРАВЛЕНО: убраны лишние скобки
    @State private var projects: [Project] = []
    
    // MARK: - UI
    @State private var selectedMainTab = 0
    @State private var selectedTaskTab = 0
    @State private var personalSubTab = 0
    
    @State private var selectedTask: Task?
    @State private var selectedProject: Project?
    
    // MARK: - Filters
    @State private var selectedPriority: Task.Priority? = nil
    @State private var onlyWithDeadline = false
    @State private var sortType: SortType = .created
    
    enum SortType {
        case created, deadline, priority
    }
    
    // MARK: - Sheets
    @State private var showAdd = false
    @State private var showAddProject = false
    
    // MARK: - Computed Properties
    var activeCount: Int {
        let allTasks = workTasks + personalTasks
        let projectTasks = projects.flatMap { $0.tasks }
        let allTasksWithProjects = allTasks + projectTasks
        return allTasksWithProjects.filter { !$0.isCompleted && !$0.isArchived }.count
    }

    var archivedTasks: [Task] {
        let allTasks = workTasks + personalTasks
        let projectTasks = projects.flatMap { $0.tasks }
        let allTasksWithProjects = allTasks + projectTasks
        return allTasksWithProjects.filter { $0.isArchived }
    }

    var archivedProjects: [Project] {
        projects.filter { $0.isArchived }
    }
    
    private func loadData() {
        if let loaded = DataManager.shared.load() {
            workTasks = loaded.workTasks
            personalTasks = loaded.personalTasks
            projects = loaded.projects
        }
    }

    private func saveData() {
        DataManager.shared.save(
            workTasks: workTasks,
            personalTasks: personalTasks,
            projects: projects
        )
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                addButtonView
                ScrollView {
                    VStack(spacing: 20) {
                        modernTabsView
                        
                        if selectedMainTab == 0 {
                            filtersContainer
                            taskListView
                        } else {
                            projectsView
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(
                    LinearGradient.customBlueGradient
                        .opacity(0.05)
                        .ignoresSafeArea()
                )
                .scrollIndicators(.hidden)
            }
            
            // Добавление задачи
            .sheet(isPresented: $showAdd) {
                AddTaskSheet(scope: selectedTaskTab == 0 ? .work : .personal) { title, description, deadline, priority in
                    addTask(
                        title: title,
                        description: description,
                        deadline: deadline,
                        type: selectedTaskTab == 1 ? (personalSubTab == 0 ? .chore : .dream) : nil,
                        priority: priority
                    )
                }
            }
            
            // Добавление проекта
            .sheet(isPresented: $showAddProject) {
                AddProjectSheet { title, description, scope in
                    addProject(title: title, description: description, scope: scope)
                }
            }
            
            // Детали задачи
            .sheet(item: $selectedTask) { task in
                TaskDetailView(
                    task: task,
                    onSave: { task, newTitle, newDescription, newDeadline in
                        updateTask(task, newTitle, newDescription, newDeadline)
                    },
                    onComplete: { completeTask($0) },
                    onDelete: { deleteTask($0) }
                )
            }
            
            // Детали проекта
            .sheet(item: $selectedProject) { project in
                ProjectDetailView(
                    project: project,
                    onSave: { updatedProject in
                        updateProject(updatedProject)
                    },
                    onDelete: { deleteProject($0) },
                    onArchive: { archiveProject($0) }
                )
            }
            .onAppear {
                    loadData()
            }
        }
    }
    
    // MARK: - Header
    var header: some View {
        HStack(spacing: 16) {
            Image(selectedMainTab == 0 ? "Mouse_Plan" : "Mouse_Project")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .shadow(color: Color.customBlueLight.opacity(0.3), radius: 10)
                .scaleEffect(selectedMainTab == 0 ? 1.0 : 0.95)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: selectedMainTab)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedMainTab == 0 ? "Мои задачи" : "Мои проекты")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(LinearGradient.customBlueGradient)
                
                HStack(spacing: 8) {
                    Image(systemName: selectedMainTab == 0 ? "checkmark.circle" : "folder")
                        .font(.caption)
                        .foregroundColor(Color.customBlueLight)
                    
                    Text(selectedMainTab == 0
                         ? "\(activeCount) активных задач"
                         : "\(projects.count) проектов")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            NavigationLink(destination: ArchiveView(
                        archivedTasks: archivedTasks,
                        archivedProjects: archivedProjects,
                        onUnarchiveTask: { task in unarchiveTask(task) },
                        onUnarchiveProject: { project in unarchiveProject(project) },
                        onDeleteTask: { task in deleteTask(task) },
                        onDeleteProject: { project in deleteProject(project) }
                    )) {
                        Image("Mouse_Done") // твоя мышка для архива
                            .resizable()
                            .scaledToFit()
                            .frame(width: 95, height: 95)
                            .background(
                            )
                    }
                    .buttonStyle(.plain)
                }
        .padding(.vertical, 8)
    }
    
    // MARK: - Modern Tabs
    var modernTabsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                modernTab(
                    title: "Задачи",
                    isSelected: selectedMainTab == 0,
                    action: { selectedMainTab = 0 }
                )
                
                modernTab(
                    title: "Проекты",
                    isSelected: selectedMainTab == 1,
                    action: { selectedMainTab = 1 }
                )
            }
            
            if selectedMainTab == 0 {
                HStack(spacing: 6) {
                    modernSubTab(
                        title: "Рабочие",
                        isSelected: selectedTaskTab == 0,
                        action: { selectedTaskTab = 0 }
                    )
                    
                    modernSubTab(
                        title: "Личные",
                        isSelected: selectedTaskTab == 1,
                        action: { selectedTaskTab = 1 }
                    )
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedMainTab)
    }
    
    func modernTab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.customBlueLight)
                                .shadow(color: Color.customBlueLight.opacity(0.3), radius: 5)
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.adaptiveTabBackground)
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : .gray)
        }
    }
    
    func modernSubTab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.customBlueLight.opacity(0.15) : Color.clear)
                )
                .foregroundColor(isSelected ? Color.customBlueLight : .gray)
        }
    }
    
    // MARK: - Filters
    var filtersContainer: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Фильтры")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 10) {
                HStack {
                    FilterChipSimple(
                        title: "Все",
                        isSelected: selectedPriority == nil,
                        color: .gray
                    ) {
                        selectedPriority = nil
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    ForEach(Task.Priority.allCases, id: \.self) { priority in
                        FilterChipSimple(
                            title: priorityFullName(priority),
                            isSelected: selectedPriority == priority,
                            color: priorityColor(priority)
                        ) {
                            selectedPriority = priority
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 1)
            
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: onlyWithDeadline ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline)
                        .foregroundColor(onlyWithDeadline ? Color.customBlueLight : .gray)
                    
                    Text("Только со сроком")
                        .font(.subheadline)
                        .foregroundColor(onlyWithDeadline ? Color.customBlueLight : .gray)
                    
                    Spacer()
                }
                .onTapGesture {
                    onlyWithDeadline.toggle()
                }
                
                Menu {
                    Picker("Сортировка", selection: $sortType) {
                        Label("Новые", systemImage: "clock").tag(SortType.created)
                        Label("Срок", systemImage: "calendar").tag(SortType.deadline)
                        Label("Приоритет", systemImage: "flag").tag(SortType.priority)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: sortIcon)
                            .font(.subheadline)
                        Text(sortLabel)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.customBlueLight.opacity(0.1))
                    )
                    .foregroundColor(Color.customBlueLight)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveCard)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Task List
    var taskListView: some View {
        VStack(spacing: 16) {
            if selectedTaskTab == 1 {
                HStack(spacing: 12) {
                    personalSubTab(
                        title: "📌 Дела",
                        count: personalTasks.filter { $0.personalType == .chore && !$0.isCompleted && !$0.isArchived }.count,
                        isSelected: personalSubTab == 0
                    ) {
                        personalSubTab = 0
                    }
                    
                    personalSubTab(
                        title: "✨ Мечты",
                        count: personalTasks.filter { $0.personalType == .dream && !$0.isCompleted && !$0.isArchived }.count,
                        isSelected: personalSubTab == 1
                    ) {
                        personalSubTab = 1
                    }
                }
            }
            
            if currentTasks.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(currentTasks.sorted(by: sortTasks)) { task in
                        TaskCard(
                            task: task,
                            onComplete: { completeTask(task) },
                            onEdit: { editTask(task) },
                            onDelete: { deleteTask(task) }
                        )
                        .onTapGesture {
                            selectedTask = task
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Нет активных задач")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Нажмите на кнопку ниже,\nчтобы добавить новую задачу")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Projects View
    var projectsView: some View {
        VStack(spacing: 16) {
            if projects.isEmpty {
                emptyProjectsView
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(projects) { project in
                        ProjectCard(project: project)
                            .onTapGesture {
                                selectedProject = project
                            }
                    }
                }
            }
        }
    }
    
    var emptyProjectsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Нет проектов")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Нажмите на кнопку ниже,\nчтобы создать первый проект")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Buttons
    var addButtonView: some View {
        Button {
            if selectedMainTab == 0 {
                showAdd = true
            } else {
                showAddProject = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text(selectedMainTab == 0 ? "Новая задача" : "Новый проект")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient.customBlueGradient
                    .shadow(.drop(color: Color.customBlueLight.opacity(0.3), radius: 8, x: 0, y: 4))
            )
            .clipShape(RoundedRectangle(cornerRadius: 30))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
    
    // MARK: - Personal Sub Tab
    func personalSubTab(title: String, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.customBlueLight.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.customBlueLight.opacity(0.15) : Color.clear)
            )
            .foregroundColor(isSelected ? Color.customBlueLight : .gray)
        }
    }
}

// MARK: - Logic Extension
extension ContentView {
    
    var currentTasks: [Task] {
        var allTasks: [Task] = []
        allTasks.append(contentsOf: workTasks)
        allTasks.append(contentsOf: personalTasks)
        
        for project in projects {
            allTasks.append(contentsOf: project.tasks)
        }
        
        var filtered = allTasks.filter { !$0.isCompleted && !$0.isArchived }
        
        if selectedTaskTab == 0 {
            filtered = filtered.filter { $0.scope == .work }
        } else {
            filtered = filtered.filter { $0.scope == .personal }
        }
        
        if selectedTaskTab == 1 {
            filtered = filtered.filter {
                $0.personalType?.rawValue == (personalSubTab == 0 ? "Дело" : "Мечта")
            }
        }
        
        if let selectedPriority {
            filtered = filtered.filter { $0.priority == selectedPriority }
        }
        
        if onlyWithDeadline {
            filtered = filtered.filter { $0.deadline != nil }
        }
        
        return filtered
    }
    
    func sortTasks(_ a: Task, _ b: Task) -> Bool {
        switch sortType {
        case .created:
            return a.createdAt > b.createdAt
        case .deadline:
            return (a.deadline ?? .distantFuture) < (b.deadline ?? .distantFuture)
        case .priority:
            let order: [Task.Priority] = [.high, .medium, .low]
            return order.firstIndex(of: a.priority)! < order.firstIndex(of: b.priority)!
        }
    }
    

    func unarchiveTask(_ task: Task) {
        // Находим задачу и убираем флаг isArchived
        if let index = workTasks.firstIndex(where: { $0.id == task.id }) {
            workTasks[index].isArchived = false
            workTasks[index].isCompleted = false // опционально
        }
        
        if let index = personalTasks.firstIndex(where: { $0.id == task.id }) {
            personalTasks[index].isArchived = false
            personalTasks[index].isCompleted = false
        }
        
        for projectIndex in projects.indices {
            if let taskIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                projects[projectIndex].tasks[taskIndex].isArchived = false
                projects[projectIndex].tasks[taskIndex].isCompleted = false
                projects[projectIndex] = projects[projectIndex]
            }
        }
        saveData()
    }

    func unarchiveProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isArchived = false
            projects = projects
        }
        saveData()
    }
    
    func completeTask(_ task: Task) {
        if let index = workTasks.firstIndex(where: { $0.id == task.id }) {
            workTasks[index].isCompleted = true
            workTasks[index].isArchived = true  // ✅ добавить эту строку
        }
        if let index = personalTasks.firstIndex(where: { $0.id == task.id }) {
            personalTasks[index].isCompleted = true
            personalTasks[index].isArchived = true  // ✅ добавить эту строку
        }
        
        for projectIndex in projects.indices {
            if let taskIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                projects[projectIndex].tasks[taskIndex].isCompleted = true
                projects[projectIndex].tasks[taskIndex].isArchived = true  // ✅ добавить эту строку
                projects[projectIndex] = projects[projectIndex]
            }
        }
        saveData()
    }
    
    // MARK: - Project Management
    func addProject(title: String, description: String?, scope: TaskScope) {
        let newProject = Project(
            title: title,
            description: description,
            scope: scope,
            tasks: []
        )
        projects.append(newProject)
        saveData()
    }
    
    func updateProject(_ updatedProject: Project) {
        if let index = projects.firstIndex(where: { $0.id == updatedProject.id }) {
            projects[index] = updatedProject
            projects = projects
        }
        saveData()
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        saveData()
    }
    
    func archiveProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isArchived = true
            projects = projects
        }
        saveData()
    }
    
    // MARK: - Task Management
    func addTask(
        title: String,
        description: String,
        deadline: Date?,
        type: Task.PersonalType?,
        priority: Task.Priority
    ) {
        let task = Task(
            title: title,
            description: description,    
            deadline: deadline,
            personalType: type,
            priority: priority,
            scope: selectedTaskTab == 0 ? .work : .personal
        )
        
        if selectedTaskTab == 0 {
            workTasks.append(task)
        } else {
            personalTasks.append(task)
        }
        saveData()
    }
    
    func updateTask(
        _ task: Task,
        _ newTitle: String,
        _ newDescription: String?,
        _ newDeadline: Date?
    ) {
        if let index = workTasks.firstIndex(where: { $0.id == task.id }) {
            workTasks[index].title = newTitle
            workTasks[index].description = newDescription
            workTasks[index].deadline = newDeadline
        }
        
        if let index = personalTasks.firstIndex(where: { $0.id == task.id }) {
            personalTasks[index].title = newTitle
            personalTasks[index].description = newDescription
            personalTasks[index].deadline = newDeadline
        }
        
        for projectIndex in projects.indices {
            if let taskIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                projects[projectIndex].tasks[taskIndex].title = newTitle
                projects[projectIndex].tasks[taskIndex].description = newDescription
                projects[projectIndex].tasks[taskIndex].deadline = newDeadline
                projects[projectIndex] = projects[projectIndex]
            }
        }
        saveData()
    }
    
    func editTask(_ task: Task) {
        selectedTask = task
    }
    
    func deleteTask(_ task: Task) {
        workTasks.removeAll { $0.id == task.id }
        personalTasks.removeAll { $0.id == task.id }
        
        for projectIndex in projects.indices {
            projects[projectIndex].tasks.removeAll { $0.id == task.id }
        }
        saveData()
    }
    
    // MARK: - Helpers
    var sortIcon: String {
        switch sortType {
        case .created: return "clock"
        case .deadline: return "calendar"
        case .priority: return "flag"
        }
    }
    
    var sortLabel: String {
        switch sortType {
        case .created: return "Новые"
        case .deadline: return "Срок"
        case .priority: return "Приоритет"
        }
    }
    
    func priorityFullName(_ priority: Task.Priority) -> String {
        switch priority {
        case .high: return "Высокий"
        case .medium: return "Средний"
        case .low: return "Низкий"
        }
    }
    
    func priorityColor(_ priority: Task.Priority) -> Color {
        switch priority {
        case .high: return Color(red: 1.0, green: 0.65, blue: 0.65)
        case .medium: return Color(red: 1.0, green: 0.8, blue: 0.55)
        case .low: return Color(red: 0.65, green: 0.85, blue: 0.65)
        }
    }
}

// MARK: - Helper Components
struct FilterChipSimple: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color.opacity(0.15) : Color.adaptiveTabBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
                .foregroundColor(isSelected ? color : .gray)
        }
    }
}

struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.largeTitle)
                .foregroundColor(Color.customBlueLight)
            
            Text(project.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            HStack {
                Text("\(project.activeTasksCount) активных")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(project.completedTasksCount) завершено")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.adaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}
