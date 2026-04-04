import SwiftUI

struct TaskDetailView: View {
    
    let task: Task
    let onSave: (Task, String, String?, Date?) -> Void
    let onComplete: (Task) -> Void
    let onDelete: (Task) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isEditing = false
    @State private var title: String
    @State private var description: String
    @State private var deadline: Date
    @State private var hasDeadline: Bool
    
    init(
        task: Task,
        onSave: @escaping (Task, String, String?, Date?) -> Void,
        onComplete: @escaping (Task) -> Void,
        onDelete: @escaping (Task) -> Void
    ) {
        self.task = task
        self.onSave = onSave
        self.onComplete = onComplete
        self.onDelete = onDelete
        
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        _deadline = State(initialValue: task.deadline ?? Date())
        _hasDeadline = State(initialValue: task.deadline != nil)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Градиентный фон
                LinearGradient.customBlueGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Основная карточка с задачей
                        mainCard
                        
                        // Кнопки действий
                        actionButtons
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                
                // Декоративная иконка в углу
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("Mouse_TaskIn")
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
                            onSave(
                                task,
                                title,
                                description.isEmpty ? nil : description,
                                hasDeadline ? deadline : nil
                            )
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
        }
    }
    
    // MARK: - UI Components
    
    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Заголовок и приоритет
            VStack(alignment: .leading, spacing: 12) {
                if isEditing {
                    TextField("Название задачи", text: $title)
                        .font(.title.bold())
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(title)
                        .font(.title.bold())
                        .foregroundColor(.white)
                }
                
                HStack {
                    Image(systemName: priorityIcon)
                        .foregroundColor(priorityColor)
                    Text(task.priority.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(priorityColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(priorityColor.opacity(0.2))
                .clipShape(Capsule())
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Дедлайн
            VStack(alignment: .leading, spacing: 12) {
                if isEditing {
                    Toggle("Установить срок", isOn: $hasDeadline)
                        .tint(Color.customBlueLight)
                        .foregroundColor(.white)
                    
                    if hasDeadline {
                        DatePicker("Дата выполнения", selection: $deadline, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Color.customBlueLight)
                    }
                } else {
                    HStack {
                        Image(systemName: hasDeadline ? "calendar" : "infinity")
                            .foregroundColor(.white.opacity(0.7))
                        Text(
                            hasDeadline
                            ? deadline.formatted(date: .long, time: .omitted)
                            : "Без срока"
                        )
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Описание
            VStack(alignment: .leading, spacing: 12) {
                if !isEditing && !description.isEmpty {
                    Text("Описание")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                if isEditing {
                    TextField("Описание", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                } else if !description.isEmpty {
                    Text(description)
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
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !isEditing {
                Button(action: {
                    onComplete(task)
                    dismiss()
                }) {
                    Label("Завершить задачу", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            
            if !isEditing {
                Button(action: {
                    onDelete(task)
                    dismiss()
                }) {
                    Label("Удалить задачу", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var priorityIcon: String {
        switch task.priority {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "equal.circle.fill"
        case .low: return "arrow.down.circle.fill"
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high: return Color(red: 1.0, green: 0.65, blue: 0.65) // нежный коралл
        case .medium: return Color(red: 1.0, green: 0.8, blue: 0.55) // теплый персик
        case .low: return Color(red: 0.65, green: 0.85, blue: 0.65) // мягкая мята
        }
    }
}
