import Foundation
import SwiftUI
import Combine

final class HomeViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let tasksViewModel: TasksViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var selectedFilter: TaskFilter = .upcoming
    @Published private(set) var filteredTasks: [Task] = []
    
    // MARK: - Filter Types
    enum TaskFilter: String, CaseIterable, Identifiable {
        case upcoming = "Upcoming"
        case overdue = "Overdue"
        case completed = "Completed"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .upcoming: return "calendar.badge.clock"
            case .overdue: return "exclamationmark.triangle.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .upcoming: return Color(hex: "6B7FFF")
            case .overdue: return Color(hex: "FF8B9D")
            case .completed: return Color(hex: "A8E6CF")
            }
        }
    }
    
    // MARK: - Initialization
    init(tasksViewModel: TasksViewModel) {
        self.tasksViewModel = tasksViewModel
        setupBindings()
    }
    
    // MARK: - Reactive Bindings
    private func setupBindings() {
        Publishers.CombineLatest(
            tasksViewModel.$allTasks,
            $selectedFilter
        )
        .map { [weak self] tasks, filter in
            self?.applyFilter(filter, to: tasks) ?? []
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$filteredTasks)
        
        tasksViewModel.$allTasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        tasksViewModel.$selectedDate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Filtering
    private func applyFilter(_ filter: TaskFilter, to tasks: [Task]) -> [Task] {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: tasksViewModel.selectedDate)
        
        switch filter {
        case .upcoming:
            return getUpcomingTasks(tasks, selectedDay: selectedDay, calendar: calendar)
        case .overdue:
            return getOverdueTasks(tasks, selectedDay: selectedDay, calendar: calendar)
        case .completed:
            return getRecentCompletedTasks(tasks, calendar: calendar)
        }
    }

    private func getUpcomingTasks(_ tasks: [Task], selectedDay: Date, calendar: Calendar) -> [Task] {
        return tasks.filter { task in
            guard !task.isCompleted else { return false }
            
            let taskCreatedDay = calendar.startOfDay(for: task.createdAt)

            if taskCreatedDay > selectedDay {
                return true
            }

            if let dueDate = task.dueDate {
                let taskDueDay = calendar.startOfDay(for: dueDate)

                if taskCreatedDay <= selectedDay && taskDueDay > selectedDay {
                    return true
                }
            }
            
            return false
        }
        .sorted { task1, task2 in
            if let due1 = task1.dueDate, let due2 = task2.dueDate {
                return due1 < due2
            }
            return task1.createdAt < task2.createdAt
        }
    }
    
    private func getOverdueTasks(_ tasks: [Task], selectedDay: Date, calendar: Calendar) -> [Task] {
        return tasks.filter { task in
            guard !task.isCompleted else { return false }
            guard let dueDate = task.dueDate else { return false }
            
            let taskDueDay = calendar.startOfDay(for: dueDate)

            return taskDueDay < selectedDay
        }
        .sorted { $0.dueDate! < $1.dueDate! }
    }
    
    private func getRecentCompletedTasks(_ tasks: [Task], calendar: Calendar) -> [Task] {
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        return tasks.filter { task in
            guard task.isCompleted else { return false }
            let taskDate = task.dueDate ?? task.createdAt
            return taskDate >= sevenDaysAgo
        }
        .sorted { ($0.dueDate ?? $0.createdAt) > ($1.dueDate ?? $1.createdAt) }
    }
    
    // MARK: - Today Statistics
    var todayTasks: [Task] {
        return tasksViewModel.filteredTasks.filter { !$0.isCompleted }
    }
    
    var todayCompletedCount: Int {
        return tasksViewModel.filteredTasks.filter { $0.isCompleted }.count
    }

    var todayTotalCount: Int {
        return tasksViewModel.filteredTasks.count
    }
    
    var todayCompletionRate: Double {
        guard todayTotalCount > 0 else { return 0 }
        return Double(todayCompletedCount) / Double(todayTotalCount)
    }
    
    // MARK: - Filter Counts
    var upcomingCount: Int {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: tasksViewModel.selectedDate)
        
        return tasksViewModel.allTasks.filter { task in
            guard !task.isCompleted else { return false }
            
            let taskCreatedDay = calendar.startOfDay(for: task.createdAt)

            if taskCreatedDay > selectedDay {
                return true
            }

            if let dueDate = task.dueDate {
                let taskDueDay = calendar.startOfDay(for: dueDate)
                if taskCreatedDay <= selectedDay && taskDueDay > selectedDay {
                    return true
                }
            }
            
            return false
        }.count
    }
    
    var overdueCount: Int {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: tasksViewModel.selectedDate)
        
        return tasksViewModel.allTasks.filter { task in
            guard !task.isCompleted else { return false }
            guard let dueDate = task.dueDate else { return false }
            let taskDueDay = calendar.startOfDay(for: dueDate)
            return taskDueDay < selectedDay
        }.count
    }
    
    var completedCount: Int {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        return tasksViewModel.allTasks.filter { task in
            guard task.isCompleted else { return false }
            let taskDate = task.dueDate ?? task.createdAt
            return taskDate >= sevenDaysAgo
        }.count
    }
    
    // MARK: - Actions
    func selectFilter(_ filter: TaskFilter) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedFilter = filter
        }
    }
    
    func toggleTask(_ task: Task) {
        tasksViewModel.toggle(task)
    }
    
    func deleteTask(_ task: Task) {
        tasksViewModel.deleteTask(task)
    }
}
