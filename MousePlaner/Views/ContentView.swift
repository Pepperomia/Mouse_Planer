// ContentView.swift
import SwiftUI
import UserNotifications

// MARK: - Main ContentView
struct ContentView: View {
    
    // MARK: - Data
    @State private var workTasks: [Task] = []
    @State private var personalTasks: [Task] = []
    @State private var projects: [Project] = []
    
    // MARK: - UI
    @State private var selectedMainTab = 0  // 0 - Задачи, 1 - Проекты, 2 - Цели
    @State private var selectedTaskTab = 0
    @State private var personalSubTab = 0
    
    @State private var selectedTask: Task?
    @State private var selectedProject: Project?
    
    // MARK: - Filters
    @State private var selectedPriority: Task.Priority? = nil
    @State private var onlyWithDeadline = false
    @State private var sortType: SortType = .created
    @State private var expandedProjects: Set<UUID> = []
    
    @State private var selectedProjectTab = 0
    
    enum SortType {
        case created, deadline, priority
    }
    
    // MARK: - Sheets
    @State private var showAdd = false
    @State private var showAddProject = false
    @State private var showSettings = false
    
    // MARK: - Update App Badge
    private func updateAppBadge() {
        let allTasks = workTasks + personalTasks + projects.flatMap { $0.tasks }
        let activeCount = allTasks.filter { !$0.isCompleted && !$0.isArchived }.count
        
        // Современный способ для iOS 17+
        UNUserNotificationCenter.current().setBadgeCount(activeCount) { error in
            if let error = error {
                print("❌ Ошибка установки бейджа: \(error)")
            } else {
                print("📱 Бейдж обновлён: \(activeCount)")
            }
        }
    }
    
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
    
    // MARK: - Project Grouping Helpers
    private func groupTasksByProject(_ tasks: [Task]) -> (byProject: [Project: [Task]], withoutProject: [Task]) {
        var byProject: [Project: [Task]] = [:]
        var withoutProject: [Task] = []
        
        for task in tasks {
            if let project = projects.first(where: { $0.tasks.contains(where: { $0.id == task.id }) }) {
                byProject[project, default: []].append(task)
            } else {
                withoutProject.append(task)
            }
        }
        return (byProject, withoutProject)
    }
    
    private func isProjectExpanded(_ projectId: UUID) -> Bool {
        expandedProjects.contains(projectId)
    }
    
    private func toggleProject(_ projectId: UUID) {
        if expandedProjects.contains(projectId) {
            expandedProjects.remove(projectId)
        } else {
            expandedProjects.insert(projectId)
        }
    }
    
    // MARK: - Data Persistence
    private func loadData() {
        if let loaded = DataManager.shared.load() {
            workTasks = loaded.workTasks
            personalTasks = loaded.personalTasks
            projects = loaded.projects
            updateAllNotifications()
            updateAppBadge()
        }
    }
    
    private func updateAllNotifications() {
        let allTasks = workTasks + personalTasks + projects.flatMap { $0.tasks }
        NotificationManager.shared.scheduleAllTasksNotifications(tasks: allTasks)
    }
    
    private func saveData() {
        DataManager.shared.save(
            workTasks: workTasks,
            personalTasks: personalTasks,
            projects: projects
        )
        updateAllNotifications()
    }
    
    // MARK: - Task Actions
    func completeTask(_ task: Task) {
        if let index = workTasks.firstIndex(where: { $0.id == task.id }) {
            workTasks[index].isCompleted = true
            workTasks[index].isArchived = true
        }
        if let index = personalTasks.firstIndex(where: { $0.id == task.id }) {
            personalTasks[index].isCompleted = true
            personalTasks[index].isArchived = true
        }
        
        for projectIndex in projects.indices {
            if let taskIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                projects[projectIndex].tasks[taskIndex].isCompleted = true
                projects[projectIndex].tasks[taskIndex].isArchived = true
                projects[projectIndex] = projects[projectIndex]
            }
        }
        NotificationManager.shared.cancelNotification(for: task)
        saveData()
        updateAppBadge()
    }
    
    func unarchiveTask(_ task: Task) {
        if let index = workTasks.firstIndex(where: { $0.id == task.id }) {
            workTasks[index].isArchived = false
            workTasks[index].isCompleted = false
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
        updateAppBadge()
    }
    
    func unarchiveProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isArchived = false
            projects = projects
        }
        saveData()
        updateAppBadge()
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
        updateAppBadge()
    }
    
    func updateProject(_ updatedProject: Project) {
        if let index = projects.firstIndex(where: { $0.id == updatedProject.id }) {
            projects[index] = updatedProject
            projects = projects
        }
        saveData()
        updateAppBadge()
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        saveData()
        updateAppBadge()
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
        updateAppBadge()
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
    
    // MARK: - Body
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                
                // Табы навигации (Задачи, Проекты, Цели) — остаются на месте
                modernTabsView
                
                // Основной контент с скроллом
                TabView(selection: $selectedMainTab) {
                    // Вкладка Задачи
                    ScrollView {
                        VStack(spacing: 16) {
                            // Кнопка добавления
                            addButtonView
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            
                            // Фильтры
                            filtersContainer
                            
                            // Список задач
                            taskListView
                                .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 20)
                    }
                    .background(
                        LinearGradient.customBlueGradient
                            .opacity(0.05)
                            .ignoresSafeArea()
                    )
                    .scrollIndicators(.hidden)
                    .tag(0)
                    
                    // Вкладка Проекты
                    ScrollView {
                        VStack(spacing: 16) {
                            // Табы проектов (Рабочие/Личные)
                            HStack(spacing: 6) {
                                modernSubTab(
                                    title: "Рабочие",
                                    isSelected: selectedProjectTab == 0,
                                    action: { selectedProjectTab = 0 }
                                )
                                modernSubTab(
                                    title: "Личные",
                                    isSelected: selectedProjectTab == 1,
                                    action: { selectedProjectTab = 1 }
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            // Кнопка добавления
                            addButtonView
                                .padding(.horizontal, 16)
                            
                            // Список проектов
                            projectsView
                                .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 20)
                    }
                    .background(
                        LinearGradient.customBlueGradient
                            .opacity(0.05)
                            .ignoresSafeArea()
                    )
                    .scrollIndicators(.hidden)
                    .tag(1)
                    
                    // Вкладка Цели
                    GoalsView()
                        .background(
                            LinearGradient.customBlueGradient
                                .opacity(0.05)
                                .ignoresSafeArea()
                        )
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedMainTab)
            }
            
            // Sheets
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
            
            .sheet(isPresented: $showAddProject) {
                AddProjectSheet(
                    scope: selectedProjectTab == 0 ? .work : .personal
                ) { title, description in
                    addProject(
                        title: title,
                        description: description,
                        scope: selectedProjectTab == 0 ? .work : .personal
                    )
                }
            }
            
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
            
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            
            .onAppear {
                loadData()
                NotificationManager.shared.requestAuthorization()
                
                // Сбрасываем бейдж при открытии приложения
                UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
            }
        }
    }
    
    // MARK: - Archive Button
    var archiveButton: some View {
        NavigationLink(destination: ArchiveView(
            archivedTasks: archivedTasks,
            archivedProjects: archivedProjects,
            onUnarchiveTask: { task in unarchiveTask(task) },
            onUnarchiveProject: { project in unarchiveProject(project) },
            onDeleteTask: { task in deleteTask(task) },
            onDeleteProject: { project in deleteProject(project) }
        )) {
            Image("Mouse_Done")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .shadow(color: Color.customBlueLight.opacity(0.3), radius: 5)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Header
    var header: some View {
        HStack(spacing: 16) {
            Button {
                showSettings = true
            } label: {
                Image(selectedMainTab == 0 ? "Mouse_Plan" : selectedMainTab == 1 ? "Mouse_Project" : "Mouse_Bow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.customBlueLight.opacity(0.3), radius: 10)
                    .scaleEffect(selectedMainTab == 0 ? 1.0 : selectedMainTab == 1 ? 0.95 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: selectedMainTab)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedMainTab == 0 ? "Мои задачи" : selectedMainTab == 1 ? "Мои проекты" : "Мои цели")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(LinearGradient.customBlueGradient)
                
                HStack(spacing: 8) {
                    Image(systemName: selectedMainTab == 0 ? "checkmark.circle" : selectedMainTab == 1 ? "folder" : "target")
                        .font(.caption)
                        .foregroundColor(Color.customBlueLight)
                    
                    Text(selectedMainTab == 0
                         ? "\(activeCount) активных задач"
                         : selectedMainTab == 1
                         ? "\(projects.count) проектов"
                         : "Скоро здесь появятся цели")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // ✅ Кнопка архива в правом верхнем углу
            archiveButton
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
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
                
                modernTab(
                    title: "Цели",
                    isSelected: selectedMainTab == 2,
                    action: { selectedMainTab = 2 }
                )
            }
            .padding(.horizontal, 16)
            
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
                .padding(.horizontal, 16)
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
                    .padding(.top, 40)
            } else {
                LazyVStack(spacing: 16) {
                    let grouped = groupTasksByProject(currentTasks)
                    
                    if !grouped.withoutProject.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📌 Без проекта")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            
                            ForEach(grouped.withoutProject) { task in
                                TaskCard(
                                    task: task,
                                    onComplete: { completeTask(task) },
                                    onEdit: { editTask(task) },
                                    onDelete: { deleteTask(task) }
                                )
                                .onTapGesture {
                                    selectedTask = task
                                }
                            }
                        }
                    }
                    
                    ForEach(grouped.byProject.keys.sorted { $0.title < $1.title }, id: \.id) { project in
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                toggleProject(project.id)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: isProjectExpanded(project.id) ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                                        .foregroundColor(Color.customBlueLight)
                                        .font(.title3)
                                    
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(Color.customBlueLight)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(grouped.byProject[project]?.count ?? 0) задач")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    let activeCount = grouped.byProject[project]?.filter { !$0.isCompleted && !$0.isArchived }.count ?? 0
                                    if activeCount > 0 {
                                        Text("\(activeCount)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.customBlueLight)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(12)
                                .background(Color.adaptiveCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.customBlueLight.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            if isProjectExpanded(project.id) {
                                VStack(spacing: 10) {
                                    ForEach(grouped.byProject[project] ?? []) { task in
                                        TaskCard(
                                            task: task,
                                            onComplete: { completeTask(task) },
                                            onEdit: { editTask(task) },
                                            onDelete: { deleteTask(task) }
                                        )
                                        .onTapGesture {
                                            selectedTask = task
                                        }
                                    }
                                }
                                .padding(.leading, 8)
                            }
                        }
                    }
                }
            }
        }
    }
    
    var currentTasks: [Task] {
        var allTasks: [Task] = []
        allTasks.append(contentsOf: workTasks)
        allTasks.append(contentsOf: personalTasks)
        
        for project in projects {
            allTasks.append(contentsOf: project.tasks)
        }
        
        print("📊 ДИАГНОСТИКА currentTasks:")
        print("   workTasks.count = \(workTasks.count)")
        print("   personalTasks.count = \(personalTasks.count)")
        print("   проектов = \(projects.count)")
        print("   всего задач = \(allTasks.count)")
        
        for task in allTasks {
            print("   - \(task.title): isCompleted=\(task.isCompleted), isArchived=\(task.isArchived)")
        }
        
        // Фильтруем: только НЕ завершённые и НЕ архивные
        var filtered = allTasks.filter { !$0.isCompleted && !$0.isArchived }
        print("   после фильтрации active: \(filtered.count)")
        
        if selectedTaskTab == 0 {
            filtered = filtered.filter { $0.scope == .work }
            print("   после фильтрации по работе: \(filtered.count)")
        } else {
            filtered = filtered.filter { $0.scope == .personal }
            print("   после фильтрации по личным: \(filtered.count)")
        }
        
        if let selectedPriority {
            filtered = filtered.filter { $0.priority == selectedPriority }
            print("   после фильтрации по приоритету: \(filtered.count)")
        }
        
        if onlyWithDeadline {
            filtered = filtered.filter { $0.deadline != nil }
            print("   после фильтрации по дедлайну: \(filtered.count)")
        }
        
        print("   ИТОГОВО задач для отображения: \(filtered.count)")
        
        return filtered
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
            let filteredProjects = projects.filter { $0.scope == (selectedProjectTab == 0 ? .work : .personal) && !$0.isArchived }
            
            if filteredProjects.isEmpty {
                emptyProjectsView
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredProjects) { project in
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
            } else if selectedMainTab == 1 {
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

// MARK: - Goals View
struct GoalsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundColor(Color.customBlueLight.opacity(0.6))
            
            Text("Цели")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.customBlueLight)
            
            Text("Здесь будут собираться ваши цели\nи отслеживаться прогресс")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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


#Preview {
    ContentView()
}
