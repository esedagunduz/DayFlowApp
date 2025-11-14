
import SwiftUI

struct AddTaskView: View {
    @ObservedObject var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var enableReminder: Bool = false
    @State private var selectedReminderOption: NotificationService.ReminderOption = .at_time
    
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
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(isAddDisabled)
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
                
                TextField("e.g., Read book", text: $viewModel.newTitle)
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
                
                TextField("Add description...", text: $viewModel.newNote, axis: .vertical)
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
                    ForEach(iconList, id: \.self) { icon in
                        IconButton(
                            icon: icon,
                            isSelected: viewModel.newIcon == icon,
                            action: { viewModel.newIcon = icon }
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
                    
                    Toggle("", isOn: Binding(
                        get: { viewModel.newDueDate != nil },
                        set: { enabled in
                            viewModel.newDueDate = enabled ? Date() : nil
                        }
                    ))
                    .labelsHidden()
                }
                
                if viewModel.newDueDate != nil {
                    DatePicker(
                        "Date and Time",
                        selection: Binding(
                            get: { viewModel.newDueDate ?? Date() },
                            set: { viewModel.newDueDate = $0 }
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
                
                TextField("30", text: $viewModel.newEstimatedMinutes)
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
            
            if enableReminder && viewModel.newDueDate != nil {
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
                    ForEach(Task.Priority.allCases, id: \.self) { priority in
                        PriorityButton(
                            priority: priority,
                            isSelected: viewModel.newPriority == priority,
                            action: { viewModel.newPriority = priority }
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
                    ForEach(Task.Effort.allCases, id: \.self) { effort in
                        EffortButton(
                            effort: effort,
                            isSelected: viewModel.newEffort == effort,
                            action: { viewModel.newEffort = effort }
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
    
    private var isAddDisabled: Bool {
        viewModel.newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveTask() {
        viewModel.addTask()

        if enableReminder, let lastTask = viewModel.allTasks.last, let dueDate = lastTask.dueDate {
            NotificationService.shared.scheduleQuickReminder(for: lastTask, option: selectedReminderOption)
        }
        
        dismiss()
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Reminder Option Button

struct ReminderOptionButton: View {
    let option: NotificationService.ReminderOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.caption)
                Text(option.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Priority Button

struct PriorityButton: View {
    let priority: Task.Priority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(priority.tint)
                    .frame(width: 8, height: 8)
                
                Text(priority.title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? priority.tint.opacity(0.15) : Color.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Effort Button

struct EffortButton: View {
    let effort: Task.Effort
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(effort.title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.green.opacity(0.15) : Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .foregroundColor(.primary)
    }
}

struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView(viewModel: TasksViewModel())
    }
}
