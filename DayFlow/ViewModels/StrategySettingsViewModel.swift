
import Foundation
import Combine

final class StrategySettingsViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let strategyService = StrategyService.shared
    private let tasksViewModel: TasksViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var selectedStrategy: TaskStrategy
    @Published var autoSortEnabled: Bool
    @Published var showingSuggestion = false
    
    // MARK: - Computed Properties
    
    var suggestedStrategy: TaskStrategy {
        strategyService.suggestOptimalStrategy(basedOn: tasksViewModel.allTasks)
    }
    
    // MARK: - Initialization
    
    init(tasksViewModel: TasksViewModel) {
        self.tasksViewModel = tasksViewModel
        self.selectedStrategy = strategyService.currentStrategy
        self.autoSortEnabled = strategyService.autoSortEnabled
        
        observeStrategyService()
    }
    
    // MARK: - Public Methods

    func saveStrategy() {
        strategyService.currentStrategy = selectedStrategy
        strategyService.autoSortEnabled = autoSortEnabled

        if autoSortEnabled {
            tasksViewModel.aiPrioritize()
        }
        
        print(" Strateji kaydedildi: \(selectedStrategy.title)")
        print(" Otomatik sıralama: \(autoSortEnabled ? "Açık" : "Kapalı")")
    }
    
    func applySuggestedStrategy() {
        selectedStrategy = suggestedStrategy
        showingSuggestion = false
    }
    
    func showSuggestion() {
        showingSuggestion = true
    }
    
    // MARK: - Private Methods
    
    private func observeStrategyService() {
        strategyService.$currentStrategy
            .sink { [weak self] newStrategy in
                self?.selectedStrategy = newStrategy
            }
            .store(in: &cancellables)
        
        strategyService.$autoSortEnabled
            .sink { [weak self] enabled in
                self?.autoSortEnabled = enabled
            }
            .store(in: &cancellables)
    }
}
