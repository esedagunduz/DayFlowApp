//
//  EditTaskView.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 21.10.2025.
//

import SwiftUI

struct EditTaskView: View {
    let task: Task
    @ObservedObject var viewModel: TasksViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title: String
    @State private var note: String
    @State private var priority: Task.Priority
    @State private var dueDate: Date?
    @State private var icon: String
    @State private var estimatedMinutes: String
    @State private var effort: Task.Effort
    @State private var hasDueDate: Bool
    @State private var enableReminder: Bool = false
    @State private var selectedReminderOption: NotificationService.ReminderOption = .at_time
    
    init(task: Task, viewModel: TasksViewModel) {
        self.task = task
        self.viewModel = viewModel
        
        _title = State(initialValue: task.title)
        _note = State(initialValue: task.note ?? "")
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate)
        _icon = State(initialValue: task.iconName)
        _estimatedMinutes = State(initialValue: task.estimatedMinutes.map { String($0) } ?? "")
        _effort = State(initialValue: task.effort)
        _hasDueDate = State(initialValue: task.dueDate != nil)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    titleSection

                    iconSection

                    dateTimeSection

                    reminderSection

                    priorityEffortSection
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color(red: 250/255, green: 250/255, blue: 250/255).ignoresSafeArea())
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Task Name")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                TextField("Task Name", text: $title)
                    .font(.body)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Note (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                TextField("Add description...", text: $note, axis: .vertical)
                    .font(.body)
                    .lineLimit(3...5)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Icon Section
    
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(iconList, id: \.self) { iconName in
                        IconButton(
                            icon: iconName,
                            isSelected: icon == iconName,
                            action: { icon = iconName }
                        )
                    }
                }
            }
        }
    }
    
    private var iconList: [String] {
        ["book.fill", "pencil", "briefcase.fill", "cart.fill", "heart.fill",
         "star.fill", "flag.fill", "bell.fill", "calendar", "clock.fill",
         "dumbbell.fill", "fork.knife", "film.fill", "gamecontroller.fill",
         "brain.head.profile", "laptopcomputer", "wallet.pass.fill"]
    }
    
    // MARK: - Date & Time Section
    
    private var dateTimeSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("Due Date")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Toggle("", isOn: $hasDueDate)
                        .labelsHidden()
                        .onChange(of: hasDueDate) { enabled in
                            if enabled && dueDate == nil {
                                dueDate = Date()
                            } else if !enabled {
                                dueDate = nil
                            }
                        }
                }
                
                if hasDueDate {
                    DatePicker(
                        "Date and Time",
                        selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                Text("Estimated Time")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                TextField("30", text: $estimatedMinutes)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text("min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Reminder Section
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.purple)
                Text("Reminder")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Toggle("", isOn: $enableReminder)
                    .labelsHidden()
            }
            
            if enableReminder && hasDueDate {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(NotificationService.ReminderOption.allCases, id: \.self) { option in
                            ReminderOptionButton(
                                option: option,
                                isSelected: selectedReminderOption == option,
                                action: { selectedReminderOption = option }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Priority & Effort Section
    
    private var priorityEffortSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Priority")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack(spacing: 10) {
                    ForEach(Task.Priority.allCases, id: \.self) { p in
                        PriorityButton(
                            priority: p,
                            isSelected: priority == p,
                            action: { priority = p }
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.green)
                    Text("Difficulty")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack(spacing: 10) {
                    ForEach(Task.Effort.allCases, id: \.self) { e in
                        EffortButton(
                            effort: e,
                            isSelected: effort == e,
                            action: { effort = e }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helpers
    
    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        NotificationService.shared.cancelNotification(for: task)

        var updatedTask = task
        updatedTask.title = trimmedTitle
        updatedTask.note = note.isEmpty ? nil : note
        updatedTask.priority = priority
        updatedTask.dueDate = hasDueDate ? dueDate : nil
        updatedTask.iconName = icon
        updatedTask.estimatedMinutes = Int(estimatedMinutes)
        updatedTask.effort = effort
        
        viewModel.updateTask(updatedTask)

        if enableReminder, let taskDueDate = updatedTask.dueDate {
            NotificationService.shared.scheduleQuickReminder(for: updatedTask, option: selectedReminderOption)
        }
        
        viewModel.cancelEditing()
        dismiss()
    }
}

struct EditTaskView_Previews: PreviewProvider {
    static var previews: some View {
        EditTaskView(
            task: Task(
                title: "Test görevi",
                note: "Not",
                priority: .high,
                estimatedMinutes: 30,
                effort: .medium
            ),
            viewModel: TasksViewModel()
        )
    }
}
