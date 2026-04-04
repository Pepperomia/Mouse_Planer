import SwiftUI

struct TaskListView: View {
    
    let tasks: [Task]
    
    let onComplete: (Task) -> Void
    let onEdit: (Task) -> Void
    let onDelete: (Task) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tasks) { task in
                    TaskCard(
                        task: task,
                        onComplete: { onComplete(task) },
                        onEdit: { onEdit(task) },
                        onDelete: { onDelete(task) }
                    )
                }
            }
            .padding(.top, 4)
        }
    }
}
