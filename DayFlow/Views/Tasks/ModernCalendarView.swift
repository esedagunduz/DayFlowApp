
import SwiftUI

struct CalendarSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TasksViewModel
    @StateObject private var calendarVM: CalendarViewModel
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    init(viewModel: TasksViewModel) {
        self.viewModel = viewModel
        _calendarVM = StateObject(wrappedValue: CalendarViewModel(tasksViewModel: viewModel))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    monthNavigator

                    weekdayHeaders

                    calendarGrid
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
        }
    }
    
    // MARK: - Month Navigator
    private var monthNavigator: some View {
        HStack {
            Button(action: { calendarVM.previousMonth() }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(calendarVM.monthYearString())
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("\(calendarVM.totalTasksInMonth()) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { calendarVM.nextMonth() }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Weekday Headers
    private var weekdayHeaders: some View {
        HStack(spacing: 8) {
            ForEach(calendarVM.weekdaySymbols(), id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(calendarVM.daysInMonth().enumerated()), id: \.offset) { index, date in
                if let date = date {
                    DayCell(
                        date: date,
                        taskCount: calendarVM.taskCount(for: date),
                        isSelected: calendarVM.isDateInToday(date),
                        isCurrentMonth: calendarVM.isDateInCurrentMonth(date)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedDate = date
                            viewModel.period = .day
                            dismiss()
                        }
                    }
                } else {
                    Color.clear
                        .frame(height: 60)
                }
            }
        }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let taskCount: Int
    let isSelected: Bool
    let isCurrentMonth: Bool
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var heatmapColor: Color {
        guard taskCount > 0 else { return Color.white }

        let base1 = Color(hex: "6B7FFF")
        let base2 = Color(hex: "5A67E8")     

        switch taskCount {
        case 1:
            return base1.opacity(0.30)
        case 2:
            return base1.opacity(0.55)
        case 3:
            return base2.opacity(0.75)
        case 4...6:
            return base2.opacity(0.90)
        default:
            return base2
        }
    }

    private var textColor: Color {
        if !isCurrentMonth {
            return .gray.opacity(0.3)
        } else if isSelected {
            return .white
        } else if taskCount >= 3 {
            return .white
        } else {
            return .primary
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.black : heatmapColor)
                .shadow(
                    color: isSelected ? Color.black.opacity(0.2) : Color.clear,
                    radius: 4,
                    x: 0,
                    y: 2
                )
            
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(textColor)

                if taskCount > 0 {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.2) : Color.black.opacity(0.15))
                            .frame(width: 22, height: 22)
                        
                        Text("\(taskCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isSelected ? .white : (taskCount >= 3 ? .white : .primary))
                    }
                } else {

                    Color.clear.frame(width: 22, height: 22)
                }
            }
        }
        .frame(height: 60)
        .opacity(isCurrentMonth ? 1.0 : 0.4)
    }
}

// MARK: - Preview
struct CalendarSheetView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarSheetView(viewModel: TasksViewModel())
    }
}
