
import Foundation

struct PriorityFallbackScorer {

    private let w0: Double = 0.10
    private let wUrgency: Double = 0.45
    private let wShortness: Double = 0.25
    private let wEffort: Double = 0.15
    private let wUserPriority: Double = 0.35

    func score(for task: Task, now: Date = Date()) -> Double {
        let urgency = normalizedUrgency(dueDate: task.dueDate, now: now)
        let shortness = normalizedShortness(minutes: task.estimatedMinutes)
        let effortLow = normalizedEffortLow(task.effort)
        let userPriority = Double(task.priority.rawValue) / 3.0
        let linear = w0 + wUrgency * urgency + wShortness * shortness + wEffort * effortLow + wUserPriority * userPriority
        return sigmoid(linear) * 100.0
    }

    // MARK: - Feature normalizers
    private func normalizedUrgency(dueDate: Date?, now: Date) -> Double {
        guard let due = dueDate else { return 0.2 }
        let days = Calendar.current.dateComponents([.day], from: now, to: due).day ?? 0
        let v = max(0.0, min(1.0, 1.0 - Double(days)/30.0))
        return v
    }

    private func normalizedShortness(minutes: Int?) -> Double {
        guard let m = minutes else { return 0.5 }
        let v = max(0.0, min(1.0, 1.0 - (Double(m) - 15.0)/45.0))
        return v
    }

    private func normalizedEffortLow(_ effort: Task.Effort) -> Double {
        switch effort {
        case .low: return 1.0
        case .medium: return 0.5
        case .high: return 0.0
        }
    }

    private func sigmoid(_ x: Double) -> Double { 1.0 / (1.0 + exp(-x)) }
}


