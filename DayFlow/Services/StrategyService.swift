

import Foundation
import Combine

final class StrategyService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = StrategyService()
    
    // MARK: - Dependencies
    private let coreMLScorer = CoreMLPriorityScorer()
    private let pfScorer = PriorityFallbackScorer()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Published Properties
    @Published var currentStrategy: TaskStrategy {
        didSet {
            saveStrategy(currentStrategy)
            coreMLScorer.userStrategy = currentStrategy
            NotificationCenter.default.post(
                name: .strategyDidChange,
                object: currentStrategy
            )
        }
    }
    
    @Published var autoSortEnabled: Bool {
        didSet {
            userDefaults.set(autoSortEnabled, forKey: Keys.autoSortEnabled)
        }
    }
    @Published private(set) var cachedScores: [UUID: Double] = [:]
    
    // MARK: - Private Properties
    private enum Keys {
        static let selectedStrategy = "taskStrategy"
        static let autoSortEnabled = "autoSortEnabled"
    }
    
    // MARK: - Initialization
    private init() {
        self.currentStrategy = Self.loadStrategy()
        self.autoSortEnabled = userDefaults.bool(forKey: Keys.autoSortEnabled)
        self.coreMLScorer.userStrategy = self.currentStrategy
    }
    
    // MARK: - Public Methods

    func calculateScore(for task: Task) -> Double {
        coreMLScorer.score(for: task) ?? pfScorer.score(for: task)
    }

    func calculateAndCacheScores(for tasks: [Task]) -> [UUID: Double] {
        var scores: [UUID: Double] = [:]
        
        for task in tasks {
            let score = calculateScore(for: task)
            scores[task.id] = score
            print(" \(task.title): \(String(format: "%.1f", score))")
        }
        
        cachedScores = scores
        return scores
    }

    func getCachedScore(for task: Task) -> Double {
        if let cached = cachedScores[task.id] {
            return cached
        }
        let score = calculateScore(for: task)
        cachedScores[task.id] = score
        return score
    }
    
    func clearCache() {
        cachedScores.removeAll()
    }
    func sortTasks(_ tasks: [Task], useCache: Bool = true) -> [Task] {
        return tasks.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            
            let leftScore = useCache ? getCachedScore(for: lhs) : calculateScore(for: lhs)
            let rightScore = useCache ? getCachedScore(for: rhs) : calculateScore(for: rhs)
            
            if leftScore != rightScore {
                return leftScore > rightScore
            }
            
            return lhs.title.localizedCompare(rhs.title) == .orderedAscending
        }
    }

    func suggestOptimalStrategy(basedOn tasks: [Task]) -> TaskStrategy {
        coreMLScorer.suggestStrategy(basedOnHistory: tasks)
    }

    func suggestPriority(for title: String, note: String?) -> Task.Priority {
        let text = (title + " " + (note ?? "")).lowercased()
        
        let urgentKeywords = ["today", "urgent", "deadline", "immediately", "now"]
        let highKeywords = ["important", "finance", "health", "critical"]

        
        if urgentKeywords.contains(where: { text.contains($0) }) {
            return .urgent
        }
        
        if highKeywords.contains(where: { text.contains($0) }) {
            return .high
        }
        
        return .normal
    }

    func debugPrintScores(for tasks: [Task]) {
        print(" Strateji: \(currentStrategy.title)")
        print(" Görev Skorları:")
        
        for task in tasks {
            let score = getCachedScore(for: task)
            print(" \(task.title): \(String(format: "%.1f", score))")
        }
    }
    
    // MARK: - Private Methods
    
    private func saveStrategy(_ strategy: TaskStrategy) {
        userDefaults.set(strategy.rawValue, forKey: Keys.selectedStrategy)
        clearCache()
    }
    
    private static func loadStrategy() -> TaskStrategy {
        let defaults = UserDefaults.standard
        let rawValue = defaults.double(forKey: Keys.selectedStrategy)
        return TaskStrategy(rawValue: rawValue) ?? .balanced
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let strategyDidChange = Notification.Name("strategyDidChange")
}
