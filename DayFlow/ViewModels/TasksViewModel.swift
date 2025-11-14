
import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

final class TasksViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let firebaseService = FirebaseService.shared
    private let strategyService = StrategyService.shared
    private var tasksListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var allTasks: [Task] = []
    @Published var period: Period = .day
    @Published var selectedDate: Date = Date()

    @Published var newTitle: String = ""
    @Published var newNote: String = ""
    @Published var newPriority: Task.Priority = .normal
    @Published var newDueDate: Date?
    @Published var newIcon: String = "book.fill"
    @Published var newEstimatedMinutes: String = ""
    @Published var newEffort: Task.Effort = .medium

    @Published var editingTask: Task?
    @Published var showEditSheet: Bool = false

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Computed Properties (Strategy Delegation)

    var lastTaskScores: [UUID: Double] {
        strategyService.cachedScores
    }

    var autoSortEnabled: Bool {
        get { strategyService.autoSortEnabled }
        set { strategyService.autoSortEnabled = newValue }
    }

    var currentStrategy: TaskStrategy {
        get { strategyService.currentStrategy }
        set { strategyService.currentStrategy = newValue }
    }
    
    // MARK: - Enums
    enum Period: String, CaseIterable {
        case day = "Day"
        case month = "Month"
        case year = "Year"
    }
    
    // MARK: - Initialization
    init() {
        setupRealtimeListener()
        observeStrategyChanges()
    }
    
    deinit {
        tasksListener?.remove()
        cancellables.removeAll()
    }
    
    // MARK: - Strategy Integration
    
    private func observeStrategyChanges() {
        NotificationCenter.default.publisher(for: .strategyDidChange)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Firebase Operations
    
    private func setupRealtimeListener() {
        isLoading = true
        
        tasksListener = firebaseService.observeTasks { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.handleTasksResult(result)
            }
        }
    }
    
    private func handleTasksResult(_ result: Result<[Task], Error>) {
        switch result {
        case .success(let tasks):
            allTasks = tasks
            print(" \(tasks.count) görev yüklendi")
            
        case .failure(let error):
            handleError(error)
            if case FirebaseError.userNotAuthenticated = error {
                errorMessage = nil
            }
        }
    }
    
    func loadTasks() {
        isLoading = true
        
        firebaseService.fetchTasks { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.handleTasksResult(result)
            }
        }
    }
    
    func addTask() {
        guard validateNewTask() else { return }
        
        let task = createTaskFromForm()
        optimisticallyAddTask(task)
        
        firebaseService.addTask(task) { [weak self] result in
            self?.handleAddTaskResult(result, task: task)
        }
        
        resetForm()
    }
    
    func updateTask(_ task: Task) {
        guard let index = allTasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let oldTask = allTasks[index]
        allTasks[index] = task
        
        firebaseService.updateTask(task) { [weak self] result in
            self?.handleUpdateTaskResult(result, oldTask: oldTask, index: index)
        }
    }
    
    func toggle(_ task: Task) {
        guard let index = allTasks.firstIndex(of: task) else { return }
        
        allTasks[index].isCompleted.toggle()
        let updatedTask = allTasks[index]
        
        firebaseService.updateTask(updatedTask) { [weak self] result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    self?.handleError(error)
                    self?.allTasks[index].isCompleted.toggle()
                }
            }
        }
    }
    
    func deleteTask(_ task: Task) {
        allTasks.removeAll { $0.id == task.id }
        
        firebaseService.deleteTask(task) { [weak self] result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    self?.handleError(error)
                    self?.allTasks.append(task)
                }
            }
        }
    }
    
    func delete(at offsets: IndexSet, from tasks: [Task]) {
        let tasksToDelete = offsets.map { tasks[$0] }
        
        allTasks.removeAll { task in
            tasksToDelete.contains(where: { $0.id == task.id })
        }
        
        firebaseService.deleteTasks(tasksToDelete) { [weak self] result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    self?.handleError(error)
                    self?.allTasks.append(contentsOf: tasksToDelete)
                }
            }
        }
    }
    
    // MARK: - Edit Operations
    
    func startEditing(_ task: Task) {
        editingTask = task
        showEditSheet = true
    }
    
    func cancelEditing() {
        editingTask = nil
        showEditSheet = false
    }
    
    // MARK: - Computed Properties
    
    var sortedTasks: [Task] {
        if autoSortEnabled {
            return allTasks.sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted {
                    return !lhs.isCompleted
                }
                
                let leftScore = strategyService.getCachedScore(for: lhs)
                let rightScore = strategyService.getCachedScore(for: rhs)
                
                return leftScore > rightScore
            }
        } else {
            return allTasks.sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
                if lhs.priority != rhs.priority { return lhs.priority.rawValue > rhs.priority.rawValue }
                return lhs.title.localizedCompare(rhs.title) == .orderedAscending
            }
        }
    }
    
    var filteredTasks: [Task] {
        let filtered = filterTasksByPeriod()
        
        if autoSortEnabled {
            if !lastTaskScores.isEmpty {
                return filtered.sorted { a, b in
                    let sa = lastTaskScores[a.id] ?? strategyService.calculateScore(for: a)
                    let sb = lastTaskScores[b.id] ?? strategyService.calculateScore(for: b)
                    if sa != sb { return sa > sb }
                    if a.isCompleted != b.isCompleted { return !a.isCompleted }
                    return a.title.localizedCompare(b.title) == .orderedAscending
                }
            } else {
                return filtered.sorted { lhs, rhs in
                    let leftScore = strategyService.calculateScore(for: lhs)
                    let rightScore = strategyService.calculateScore(for: rhs)
                    if leftScore != rightScore { return leftScore > rightScore }
                    if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
                    return lhs.title.localizedCompare(rhs.title) == .orderedAscending
                }
            }
        }
        
        return filtered.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
            if lhs.priority != rhs.priority { return lhs.priority.rawValue > rhs.priority.rawValue }
            return lhs.title.localizedCompare(rhs.title) == .orderedAscending
        }
    }
    
    var completionRate: Double {
        guard !allTasks.isEmpty else { return 0 }
        let completed = allTasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(allTasks.count)
    }
    
    // MARK: - AI Operations

    func aiPrioritize() {
        print(" AI ile önceliklendirme başlatılıyor...")
        print(" Kullanılan strateji: \(currentStrategy.title)")

        let taskScores = strategyService.calculateAndCacheScores(for: allTasks)

        withAnimation(.spring()) {
            autoSortEnabled = true
            allTasks.sort { a, b in
                let sa = taskScores[a.id] ?? 0
                let sb = taskScores[b.id] ?? 0
                if sa != sb { return sa > sb }
                if a.isCompleted != b.isCompleted { return !a.isCompleted }
                return a.title.localizedCompare(b.title) == .orderedAscending
            }
        }
        
        print("\n Görevler sıralandı - YENİ SIRA:")
        for (index, task) in filteredTasks.enumerated() {
            let score = lastTaskScores[task.id] ?? strategyService.calculateScore(for: task)
            print("  \(index + 1). \(task.title) - \(String(format: "%.1f", score))")
        }
    }
    

    func suggestPriorityForNewTask() -> Task.Priority {
        strategyService.suggestPriority(for: newTitle, note: newNote)
    }

    func suggestOptimalStrategy() -> TaskStrategy {
        strategyService.suggestOptimalStrategy(basedOn: allTasks)
    }

    func debugPrintScores() {
        strategyService.debugPrintScores(for: filteredTasks)
    }
    
    // MARK: - Task Count
    
    func taskCount(on date: Date) -> Int {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return allTasks.filter { task in
            isTask(task, visibleOn: targetDay, calendar: calendar)
        }.count
    }
    
    // MARK: - Private Helpers
    
    private func validateNewTask() -> Bool {
        !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func createTaskFromForm() -> Task {
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let estimatedMinutes = Int(newEstimatedMinutes)
        
        return Task(
            title: trimmedTitle,
            note: newNote.isEmpty ? nil : newNote,
            priority: newPriority,
            isCompleted: false,
            dueDate: newDueDate,
            iconName: newIcon,
            estimatedMinutes: estimatedMinutes,
            effort: newEffort,
            createdAt: Calendar.current.startOfDay(for: selectedDate)
        )
    }
    
    private func optimisticallyAddTask(_ task: Task) {
        allTasks.append(task)
    }
    
    private func handleAddTaskResult(_ result: Result<Void, Error>, task: Task) {
        DispatchQueue.main.async { [weak self] in
            switch result {
            case .success():
                print(" Görev Firebase'e kaydedildi: \(task.title)")
                
            case .failure(let error):
                self?.handleError(error)
                self?.allTasks.removeAll { $0.id == task.id }
            }
        }
    }
    
    private func handleUpdateTaskResult(_ result: Result<Void, Error>, oldTask: Task, index: Int) {
        DispatchQueue.main.async { [weak self] in
            switch result {
            case .success():
                print(" Görev güncellendi: \(oldTask.title)")
                
            case .failure(let error):
                self?.handleError(error)
                if let idx = self?.allTasks.firstIndex(where: { $0.id == oldTask.id }) {
                    self?.allTasks[idx] = oldTask
                }
            }
        }
    }
    
    private func resetForm() {
        newTitle = ""
        newNote = ""
        newPriority = .normal
        newDueDate = nil
        newIcon = "book.fill"
        newEstimatedMinutes = ""
        newEffort = .medium
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        print(" Hata: \(error.localizedDescription)")
    }
    
    // MARK: - Filtering Logic
    
    private func filterTasksByPeriod() -> [Task] {
        let calendar = Calendar.current
        
        return allTasks.filter { task in
            guard let dueDate = task.dueDate else {
                return isTaskCreatedOnSelectedDate(task, calendar: calendar)
            }
            
            return isTask(task, visibleInPeriod: period, calendar: calendar)
        }
    }
    
    private func isTaskCreatedOnSelectedDate(_ task: Task, calendar: Calendar) -> Bool {
        let taskCreatedDay = calendar.startOfDay(for: task.createdAt)
        let selectedDay = calendar.startOfDay(for: selectedDate)
        return taskCreatedDay == selectedDay
    }
    
    private func isTask(_ task: Task, visibleInPeriod period: Period, calendar: Calendar) -> Bool {
        guard let dueDate = task.dueDate else { return false }
        
        let taskCreatedDay = calendar.startOfDay(for: task.createdAt)
        let taskDueDay = calendar.startOfDay(for: dueDate)
        let selectedDay = calendar.startOfDay(for: selectedDate)
        
        switch period {
        case .day:
            return selectedDay >= taskCreatedDay && selectedDay <= taskDueDay
            
        case .month:
            return isTaskVisibleInMonth(
                taskCreated: task.createdAt,
                taskDue: dueDate,
                selected: selectedDate,
                calendar: calendar
            )
            
        case .year:
            return isTaskVisibleInYear(
                taskCreated: task.createdAt,
                taskDue: dueDate,
                selected: selectedDate,
                calendar: calendar
            )
        }
    }
    
    private func isTask(_ task: Task, visibleOn date: Date, calendar: Calendar) -> Bool {
        let taskCreatedDay = calendar.startOfDay(for: task.createdAt)
        
        if let dueDate = task.dueDate {
            let taskDueDay = calendar.startOfDay(for: dueDate)
            return date >= taskCreatedDay && date <= taskDueDay
        } else {
            return date == taskCreatedDay
        }
    }
    
    private func isTaskVisibleInMonth(
        taskCreated: Date,
        taskDue: Date,
        selected: Date,
        calendar: Calendar
    ) -> Bool {
        let selectedComponents = calendar.dateComponents([.year, .month], from: selected)
        let createdComponents = calendar.dateComponents([.year, .month], from: taskCreated)
        let dueComponents = calendar.dateComponents([.year, .month], from: taskDue)
        
        guard let selectedYear = selectedComponents.year,
              let selectedMonth = selectedComponents.month,
              let createdYear = createdComponents.year,
              let createdMonth = createdComponents.month,
              let dueYear = dueComponents.year,
              let dueMonth = dueComponents.month else {
            return false
        }
        
        let selectedValue = selectedYear * 12 + selectedMonth
        let createdValue = createdYear * 12 + createdMonth
        let dueValue = dueYear * 12 + dueMonth
        
        return selectedValue >= createdValue && selectedValue <= dueValue
    }
    
    private func isTaskVisibleInYear(
        taskCreated: Date,
        taskDue: Date,
        selected: Date,
        calendar: Calendar
    ) -> Bool {
        let selectedYear = calendar.component(.year, from: selected)
        let createdYear = calendar.component(.year, from: taskCreated)
        let dueYear = calendar.component(.year, from: taskDue)
        
        return selectedYear >= createdYear && selectedYear <= dueYear
    }
}
