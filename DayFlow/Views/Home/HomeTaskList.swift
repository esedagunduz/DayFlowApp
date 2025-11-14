import SwiftUI

struct HomeTaskList: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            if viewModel.filteredTasks.isEmpty {
                EmptyStateCard(filter: viewModel.selectedFilter)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredTasks) { task in
                        TaskRowCard(task: task)
                    }
                }
            }
        }
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    let filter: HomeViewModel.TaskFilter
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(filter.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: emptyIcon)
                    .font(.system(size: 36))
                    .foregroundColor(filter.color)
            }
            
            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(emptyMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .padding(.horizontal, 32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
    
    private var emptyIcon: String {
        switch filter {
        case .upcoming: return "calendar.badge.clock"
        case .overdue: return "checkmark.seal.fill"
        case .completed: return "hands.sparkles.fill"
        }
    }
    
    private var emptyTitle: String {
        switch filter {
        case .upcoming: return "No Upcoming Tasks"
        case .overdue: return "All Caught Up!"
        case .completed: return "No Completed Tasks"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .upcoming:
            return "No tasks scheduled in the near future"
        case .overdue:
            return "No overdue tasks. You're doing great!"
        case .completed:
            return "Completed tasks will appear here"
        }
    }
}

// MARK: - Task Row Card (READ-ONLY)
struct TaskRowCard: View {
    let task: Task
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: task.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .strikethrough(task.isCompleted, color: .gray)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let dueDate = task.dueDate {
                        Label(formatDate(dueDate), systemImage: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(isOverdue ? Color.cardPink : .secondary)
                    }
                    if let mins = task.estimatedMinutes {
                        Label("\(mins) min", systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .opacity(task.isCompleted ? 0.6 : 1.0)
    }
    
    // MARK: - Helpers

    private var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return dueDate < Date() && !task.isCompleted
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview
struct HomeTaskList_Previews: PreviewProvider {
    static var previews: some View {
        let tasksVM = TasksViewModel()
        let homeVM = HomeViewModel(tasksViewModel: tasksVM)
        
        HomeTaskList(viewModel: homeVM)
            .padding()
            .background(Color(red: 0.98, green: 0.97, blue: 0.95))
    }
}
