//
//  HomeProgressCard.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 1.11.2025.
//
import SwiftUI

struct HomeProgressCard: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: "F0F0F0"), lineWidth: 14)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: viewModel.todayCompletionRate)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "B8E986"),
                                    Color(hex: "A8DF76")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: viewModel.todayCompletionRate)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.todayCompletionRate * 100))%")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("completed")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Tasks")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("\(viewModel.todayCompletedCount) / \(viewModel.todayTotalCount) completed")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
 
                    HStack(spacing: 6) {
                        Image(systemName: motivationIcon)
                            .font(.system(size: 18))
                            .foregroundColor(motivationColor)
                        
                        Text(motivationText)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(motivationColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(motivationColor.opacity(0.15))
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
        )
    }
    
    private var motivationIcon: String {
        let rate = viewModel.todayCompletionRate
        if viewModel.todayTotalCount == 0 { return "calendar" }
        else if rate >= 0.8 { return "star.fill" }
        else if rate >= 0.5 { return "hand.thumbsup.fill" }
        else { return "flame.fill" }
    }
    
    private var motivationColor: Color {
        let rate = viewModel.todayCompletionRate
        if viewModel.todayTotalCount == 0 { return Color(hex: "6B7FFF") }
        else if rate >= 0.8 { return Color.cardGreen }
        else if rate >= 0.5 { return Color.cardYellow }
        else { return Color.cardPink }
    }
    
    private var motivationText: String {
        let rate = viewModel.todayCompletionRate
        if viewModel.todayTotalCount == 0 { return "No tasks today" }
        else if rate == 1.0 { return "Perfect!" }
        else if rate >= 0.8 { return "You're doing great!" }
        else if rate >= 0.5 { return "Keep going!" }
        else { return "You can do it!" }
    }
}

// MARK: - Preview
struct HomeProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        let tasksVM = TasksViewModel()
        let homeVM = HomeViewModel(tasksViewModel: tasksVM)
        
        HomeProgressCard(viewModel: homeVM)
            .padding()
            .background(Color(red: 0.98, green: 0.97, blue: 0.95))
    }
}
