
import SwiftUI

// MARK: - Main View

struct TasksListView: View {
    @EnvironmentObject var viewModel: TasksViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showAdd = false
    @State private var showStrategySettings = false
    @State private var showCalendar = false
    
    private var userName: String {
        authViewModel.user?.displayName ?? "Guest"
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        case 18..<22: return "Good evening"
        default: return "Good night"
        }
    }

    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    dateInfo
                    dateStrip
                    aiButton
                    tasksList
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            
            floatingButton
        }
        .sheet(isPresented: $showAdd) {
            AddTaskView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            if let task = viewModel.editingTask {
                EditTaskView(task: task, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showStrategySettings) {
            StrategySettingsView(tasksViewModel: viewModel)
        }
        .sheet(isPresented: $showCalendar) {
            CalendarSheetView(viewModel: viewModel)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting + ",")
                    .font(.system(size: 20, weight: .heavy))
                
                Text(userName)
                    .font(.system(size: 48, weight: .heavy))
                    .tracking(-1.5)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                IconButton(icon: "calendar", isSelected: false) {
                    showCalendar = true
                }
                IconButton(icon: "brain.head.profile", isSelected: false) {
                    showStrategySettings = true
                }
            }
        }
    }
    
    // MARK: - Date Info
    
    private var dateInfo: some View {
        HStack {
            Text(formatDate(viewModel.selectedDate))
                .font(.system(size: 18, weight: .semibold))
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d, EEEE"
        return formatter.string(from: date)
    }

    
    // MARK: - Date Strip
    
    private var dateStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(getDays(), id: \.self) { date in
                        DateCard(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            taskCount: viewModel.taskCount(on: date)
                        )
                        .id(date)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedDate = date
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(viewModel.selectedDate, anchor: .leading)
                    }
                }
            }
            .onChange(of: viewModel.selectedDate) { newDate in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newDate, anchor: .leading)
                }
            }
        }
    }
    
    private func getDays() -> [Date] {
        let cal = Calendar.current
        let today = Date()
        return (-3...10).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }
    
    // MARK: - AI Button
    
    private var aiButton: some View {
        Button {
            handleAIButtonTap()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: viewModel.autoSortEnabled ? "checkmark.circle.fill" : "wand.and.stars")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.autoSortEnabled ? "Smart Priority " : "Enable Smart Priority")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(viewModel.autoSortEnabled ? "Tasks intelligently prioritized"
                                                   : "Smart task sorting")
                    .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: viewModel.autoSortEnabled
                                ? [Color.green, Color.green.opacity(0.8)]
                                : [Color(red: 107/255, green: 127/255, blue: 255/255),
                                   Color(red: 90/255, green: 103/255, blue: 232/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: (viewModel.autoSortEnabled ? Color.green : Color(red: 107/255, green: 127/255, blue: 255/255)).opacity(0.4),
                        radius: 12,
                        x: 0,
                        y: 8
                    )
            )
        }
    }
    
    // MARK: - AI Button Handler (ESKİ KODUN MANTIĞI)
    
    private func handleAIButtonTap() {
        if viewModel.autoSortEnabled {
            print(" AI sıralaması kapatılıyor...")
            withAnimation(.spring()) {
                viewModel.autoSortEnabled = false
                viewModel.objectWillChange.send()
            }
            print("autoSortEnabled = \(viewModel.autoSortEnabled)")
        } else {
            print("AI sıralaması açılıyor...")
            viewModel.aiPrioritize()
            print("autoSortEnabled = \(viewModel.autoSortEnabled)")
        }
    }
    
    // MARK: - Tasks List (ESKİ KODUN MANTIĞI)
    
    private var tasksList: some View {
        Group {
            if viewModel.autoSortEnabled {
                TasksListSection(viewModel: viewModel)
            } else {
                TasksGridSection(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Floating Button
    
    private var floatingButton: some View {
        Button {
            showAdd = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: "5A67E8"))
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(hex: "5A67E8").opacity(0.4), radius: 12, x: 0, y: 6)
                
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 50)
    }
}

// MARK: - Date Card

struct DateCard: View {
    let date: Date
    let isSelected: Bool
    let taskCount: Int
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isPast: Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }
    
    private var backgroundColor: Color {
        if isSelected { return .black }
        if isToday { return Color.blue.opacity(0.1) }
        if isPast { return Color.gray.opacity(0.15) }
        return .white
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(dayNumber)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(isSelected ? .white : isPast ? .gray : .primary)
            
            Text(dayName)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
        }        .frame(width: 70, height: 90)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: isSelected ? Color.black.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }
}



// MARK: - Section Wrappers

struct TasksGridSection: View {
    @ObservedObject var viewModel: TasksViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            ForEach(Array(viewModel.filteredTasks.enumerated()), id: \.element.id) { index, task in
                TaskCard(task: task, viewModel: viewModel, colorIndex: index)
            }
        }
    }
}

struct TasksListSection: View {
    @ObservedObject var viewModel: TasksViewModel

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.filteredTasks.enumerated()), id: \.element.id) { index, task in
                ModernTaskListRow(
                    task: task,
                    rank: index + 1,
                    score: viewModel.lastTaskScores[task.id] ?? 0,
                    colorIndex: index,
                    onToggle: { viewModel.toggle(task) },
                    onEdit: { viewModel.startEditing(task) },
                    onDelete: { viewModel.deleteTask(task) }
                )
            }
        }
    }
}

// MARK: - Colors

extension Color {
    static let appBackground = Color(red: 250/255, green: 250/255, blue: 250/255)
    static let cardYellow = Color(red: 255/255, green: 215/255, blue: 130/255)
    static let cardGreen = Color(red: 180/255, green: 230/255, blue: 140/255)
    static let cardGray = Color(red: 220/255, green: 220/255, blue: 220/255)
    static let cardPink = Color(red: 255/255, green: 170/255, blue: 200/255)
    static let cardBlue = Color(red: 170/255, green: 210/255, blue: 255/255)
}
