import Foundation
import CoreML


enum TaskStrategy: Double, CaseIterable, Identifiable {
    case quickWins = 0.0
    case balanced = 1.0
    case eatTheFrog = 2.0
    
    var id: Double { rawValue }
    
    var title: String {
        switch self {
        case .quickWins: return "Quick Wins"
        case .balanced: return "Balanced"
        case .eatTheFrog: return "Eat the Frog"
        }
    }
    
    var icon: String {
        switch self {
        case .quickWins: return "🎯"
        case .balanced: return "⚖️"
        case .eatTheFrog: return "🐸"
        }
    }
    
    var description: String {
        switch self {
        case .quickWins:
            return "Start your day with easy and short tasks. Gain momentum and boost motivation."
        case .balanced:
            return "A balanced approach between urgency, importance, and difficulty. Suitable for most users."
        case .eatTheFrog:
            return "Start your morning with the hardest and most important task. Increase productivity throughout the day."
        }
    }
}

final class CoreMLPriorityScorer {
    private var model: MLModel?
    private let calendar = Calendar.current
    
    var userStrategy: TaskStrategy {
        get {
            let rawValue = UserDefaults.standard.double(forKey: "taskStrategy")
            return TaskStrategy(rawValue: rawValue) ?? .balanced
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "taskStrategy")
            print("Strategy updated: \(newValue.title)")
        }
    }
    
    init() {
        if let url = Bundle.main.url(forResource: "PriorityModel", withExtension: "mlmodelc") {
            model = try? MLModel(contentsOf: url)
            print(" Core ML model yüklendi (Pure ML v4.0)")
            print("  • 100% Makine Öğrenmesi - Manuel boost YOK")
        }

        else if let url = Bundle.main.url(forResource: "PriorityModel", withExtension: "mlmodel") {
            if let compiled = try? MLModel.compileModel(at: url) {
                model = try? MLModel(contentsOf: compiled)
                print("Core ML model runtime'da compile edildi")
            }
        } else {
            print(" Core ML model bulunamadı, fallback kullanılacak")
        }
    }
    
    func score(for task: Task, now: Date = Date()) -> Double? {
        guard let model = model else { return nil }

        let daysTodue = calculateDaysToDue(for: task, now: now)
        let estimatedMinutes = Double(task.estimatedMinutes ?? 30)
        let effortLevel = Double(task.effort.rawValue)
        let userPriority = Double(task.priority.rawValue)
        let strategyPref = userStrategy.rawValue
        
        #if DEBUG
        print("""
         \(task.title):
           • days_to_due: \(daysTodue)
           • estimated_minutes: \(estimatedMinutes)
           • effort_level: \(effortLevel) (\(task.effort.title))
           • user_priority: \(userPriority) (\(task.priority.title))
           • strategy: \(strategyPref) (\(userStrategy.title))
        """)
        #endif
        
        let inputs: [String: Any] = [
            "days_to_due": daysTodue,
            "estimated_minutes": estimatedMinutes,
            "effort_level": effortLevel,
            "user_priority": userPriority,
            "strategy_preference": strategyPref
        ]
        

        guard let provider = try? MLDictionaryFeatureProvider(dictionary: inputs),
              let output = try? model.prediction(from: provider),
              let score = output.featureValue(for: "priority_score")?.doubleValue else {
            print("Model tahmini yapılamadı: \(task.title)")
            return nil
        }
        
        #if DEBUG
        print("   → Skor: \(String(format: "%.1f", score))\n")
        #endif
        
        return score
    }
    
    // MARK: - Yardımcı Fonksiyonlar
    
    private func calculateDaysToDue(for task: Task, now: Date) -> Double {
        guard let dueDate = task.dueDate else { return 30.0 }
        let components = calendar.dateComponents([.day], from: now, to: dueDate)
        return Double(components.day ?? 30)
    }
    
    // MARK: - Strateji Önerileri
    
    func suggestStrategy(basedOnHistory tasks: [Task]) -> TaskStrategy {
        let completedTasks = tasks.filter { $0.isCompleted }
        guard completedTasks.count >= 10 else { return .balanced }
        
        let easyTasksCompleted = completedTasks.filter { $0.effort == .low }.count
        let hardTasksCompleted = completedTasks.filter { $0.effort == .high }.count
        
        let easyRatio = Double(easyTasksCompleted) / Double(completedTasks.count)
        let hardRatio = Double(hardTasksCompleted) / Double(completedTasks.count)
        
        if easyRatio > 0.6 {
            return .quickWins
        } else if hardRatio > 0.4 {
            return .eatTheFrog
        } else {
            return .balanced
        }
    }
    
    func strategyRecommendation() -> String {
        let strategy = userStrategy
        return "\(strategy.icon) \(strategy.title)\n\n\(strategy.description)"
    }
}

// MARK: - Debug Extension

extension CoreMLPriorityScorer {
    func debugScores(for tasks: [Task]) {
        print("\n" + String(repeating: "=", count: 70))
        print(" SAF ML SKORLARI (\(userStrategy.title))")
        print("Model: Pure ML v4.0 | R² = 0.9902 | MAE = 1.65")
        print(String(repeating: "=", count: 70))
        
        var taskScores: [(Task, Double)] = []
        
        for task in tasks {
            if let score = score(for: task) {
                taskScores.append((task, score))
            }
        }
        taskScores.sort { $0.1 > $1.1 }
        
        print("\n GÖREV SIRALAMA:")
        for (index, (task, score)) in taskScores.enumerated() {
            let daysTodue = calculateDaysToDue(for: task, now: Date())
            let urgencyEmoji = daysTodue <= 0 ? "🔴" : daysTodue <= 1 ? "🟠" : "🟢"
            
            print("""
            \(index + 1). \(task.title)
               \(urgencyEmoji) Skor: \(String(format: "%.1f", score))/120
                Gün: \(Int(daysTodue)) |  Süre: \(task.estimatedMinutes ?? 0)dk
                Zorluk: \(task.effort.title) |  Öncelik: \(task.priority.title)
            """)
        }
        
        print(String(repeating: "=", count: 70))
        print(" Not: Bu skorlar 100% makine öğrenmesiyle hesaplandı.")
        print("  Model 8000 görevden öğrendi, manuel kural YOK!\n")
    }
    

    func compareStrategies(for tasks: [Task]) {
        print("\n" + String(repeating: "=", count: 70))
        print(" STRATEJİ KARŞILAŞTIRMASI")
        print(String(repeating: "=", count: 70))
        
        for strategy in TaskStrategy.allCases {
            let originalStrategy = userStrategy
            userStrategy = strategy
            
            print("\n\(strategy.icon) \(strategy.title.uppercased())")
            print(String(repeating: "-", count: 70))
            
            var taskScores: [(Task, Double)] = []
            for task in tasks {
                if let score = score(for: task) {
                    taskScores.append((task, score))
                }
            }
            
            taskScores.sort { $0.1 > $1.1 }
            
            for (index, (task, score)) in taskScores.prefix(5).enumerated() {
                print("  \(index + 1). \(task.title.padding(toLength: 30, withPad: " ", startingAt: 0)) → \(String(format: "%.1f", score))")
            }
            
            userStrategy = originalStrategy
        }
        
        print(String(repeating: "=", count: 70) + "\n")
    }
}
