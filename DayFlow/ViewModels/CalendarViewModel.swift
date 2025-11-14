//
//  CalendarViewModel.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 2.11.2025.
//
import Foundation
import SwiftUI

final class CalendarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date = Date()
    
    // MARK: - Dependencies
    private let tasksViewModel: TasksViewModel
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    init(tasksViewModel: TasksViewModel) {
        self.tasksViewModel = tasksViewModel
    }
    
    // MARK: - Navigation
    func previousMonth() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    func nextMonth() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    func goToToday() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentMonth = Date()
            selectedDate = Date()
        }
    }
    
    // MARK: - Task Queries
    

    func taskCount(for date: Date) -> Int {
        let targetDay = calendar.startOfDay(for: date)
        
        let count = tasksViewModel.allTasks.filter { task in
            let taskCreatedDay = calendar.startOfDay(for: task.createdAt)
            
            if let dueDate = task.dueDate {
                let taskDueDay = calendar.startOfDay(for: dueDate)
                return targetDay >= taskCreatedDay && targetDay <= taskDueDay
            } else {
                return targetDay == taskCreatedDay
            }
        }.count
        
        if count > 0 {
            print("\(formatDate(date)): \(count) tasks")
        }
        
        return count
    }
    func totalTasksInMonth() -> Int {
        tasksViewModel.allTasks.filter { task in
            calendar.isDate(task.createdAt, equalTo: currentMonth, toGranularity: .month) ||
            (task.dueDate != nil && calendar.isDate(task.dueDate!, equalTo: currentMonth, toGranularity: .month))
        }.count
    }
    
    // MARK: - Calendar Data
    func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }
        
        let firstDayOfWeek = calendar.firstWeekday
        let paddingDays = (firstWeekday - firstDayOfWeek + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: paddingDays)
        
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        return days
    }
    
    func weekdaySymbols() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        return formatter.shortWeekdaySymbols.map { String($0.prefix(3)) }
    }
    
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    // MARK: - Helpers
    
    func isDateInToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}
