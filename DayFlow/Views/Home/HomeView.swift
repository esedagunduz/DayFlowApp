//
//  HomeView.swift
//  DayFlow
//
//  Views/Home/HomeView.swift
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let tasksViewModel: TasksViewModel
    
    init(tasksViewModel: TasksViewModel) {
        self.tasksViewModel = tasksViewModel
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hi,")
                            .font(.system(size: 20, weight: .heavy))
                        
                        Text(userName)
                            .font(.system(size: 48, weight: .heavy))
                            .tracking(-1.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    HomeProgressCard(viewModel: viewModel)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    
                    QuickStatsRow(viewModel: viewModel)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                
                    TasksListHeader(viewModel: viewModel)
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
    
                    HomeTaskList(viewModel: viewModel)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "F8F9FA"),
                        Color(hex: "FFFFFF")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
        }
    }
}

// MARK: - HomeView Extensions
extension HomeView {
    private var userName: String {
        authViewModel.user?.displayName ?? ""
    }
}

// MARK: - Quick Stats Row (FILTER ONLY)

struct QuickStatsRow: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                    icon: "calendar.badge.clock",
                    count: viewModel.upcomingCount,
                    label: "Upcoming",
                    color: Color(hex: "6B7FFF"),
                    isSelected: viewModel.selectedFilter == .upcoming
                ) {
                    viewModel.selectFilter(.upcoming)
                }
            QuickStatCard(
                icon: "exclamationmark.triangle.fill",
                count: viewModel.overdueCount,
                label: "Overdue",
                color: Color.cardPink,
                isSelected: viewModel.selectedFilter == .overdue
            ) {
                viewModel.selectFilter(.overdue)
            }

            QuickStatCard(
                icon: "checkmark.circle.fill",
                count: viewModel.completedCount,
                label: "Completed",
                color: Color.cardGreen,
                isSelected: viewModel.selectedFilter == .completed
            ) {
                viewModel.selectFilter(.completed)
            }
        }
    }
}

struct QuickStatCard: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isSelected ? .white : color)
                    .frame(height: 30)
                
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? color : Color.white)
                    .shadow(color: isSelected ? color.opacity(0.3) : .black.opacity(0.04), radius: isSelected ? 12 : 8, x: 0, y: isSelected ? 6 : 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Tasks List Header

struct TasksListHeader: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.selectedFilter.rawValue)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("\(viewModel.filteredTasks.count) task")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(tasksViewModel: TasksViewModel())
            .environmentObject(AuthViewModel())
    }
}
