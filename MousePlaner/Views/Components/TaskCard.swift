// TaskCard.swift
import SwiftUI

struct TaskCard: View {
    let task: Task
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                
                if let deadline = task.deadline {
                    Text("📅 \(deadline.formatted(date: .numeric, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Исправлено: используем функцию вместо .color
                HStack {
                    Image(systemName: priorityIcon(task.priority))
                        .foregroundColor(priorityColor(task.priority))
                    Text(task.priority.rawValue)
                        .font(.caption)
                        .foregroundColor(priorityColor(task.priority))
                }
            }
            
            Spacer()
            
            // Кнопки действий
            HStack(spacing: 12) {
                Button(action: onComplete) {
                    Image(systemName: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle")
                        .foregroundColor(task.isCompleted ? .orange : .green)
                }
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.adaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // Вспомогательные функции
    private func priorityIcon(_ priority: Task.Priority) -> String {
        switch priority {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "equal.circle.fill"
        case .low: return "arrow.down.circle.fill"
        }
    }
    
    private func priorityColor(_ priority: Task.Priority) -> Color {
        switch priority {
        case .high: return Color(red: 1.0, green: 0.65, blue: 0.65)
        case .medium: return Color(red: 1.0, green: 0.8, blue: 0.55)
        case .low: return Color(red: 0.65, green: 0.85, blue: 0.65)
        }
    }
}
