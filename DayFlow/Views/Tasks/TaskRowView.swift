import SwiftUI

// MARK: - Task List Row

struct ModernTaskListRow: View {
    let task: Task
    let rank: Int
    let score: Double
    let colorIndex: Int
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDelete = false

    private var rankColor: Color {
        return .gray
    }

    private var cardColor: Color {
        let colors: [Color] = [.cardGreen, .cardPink, .cardBlue, .cardYellow, .cardGray]
        return colors[colorIndex % colors.count]
    }
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 44, height: 44)
                    .shadow(color: rankColor.opacity(0.4), radius: 6, x: 0, y: 3)
                
                Text("\(rank)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            Image(systemName: task.iconName)
                .font(.title3)
                .foregroundColor(.black)
                .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let note = task.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.7))
                            .lineLimit(1)
                        
                        Text("•")
                            .foregroundColor(.black.opacity(0.5))
                    }
                    
                    if let mins = task.estimatedMinutes {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("\(mins) min")
                        }
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.7))
                    }
                }
            }
            
            Spacer()

            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .black : .gray.opacity(0.5))
            }
        }
        .padding(18)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: cardColor.opacity(0.3), radius: 8, x: 0, y: 4)
        .opacity(task.isCompleted ? 0.6 : 1.0)
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showDelete = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Task", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete'\(task.title)' ")
        }
    }
}
// MARK: - Task Card (Grid)

struct TaskCard: View {
    let task: Task
    let viewModel: TasksViewModel
    let colorIndex: Int

    @State private var showDelete = false

    private var cardColor: Color {
        let colors: [Color] = [.cardGreen, .cardPink, .cardBlue, .cardYellow, .cardGray]
        return colors[colorIndex % colors.count]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: task.iconName)
                    .font(.title2)
                    .foregroundColor(.black)
                    .frame(width: 50, height: 50)
                
                Spacer()
                
                Button {
                    viewModel.toggle(task)
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.isCompleted ? .black : .gray.opacity(0.4))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                if let note = task.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.6))
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .frame(height: 200)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: cardColor.opacity(0.3), radius: 8, x: 0, y: 4)
        .opacity(task.isCompleted ? 0.6 : 1.0)
        .contextMenu {
            Button {
                viewModel.startEditing(task)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showDelete = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Task", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteTask(task)
            }
        } message: {
            Text("Are you sure you want to delete'\(task.title)' ")
        }
    }
}
