//
//  HomeFilterGirid.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 1.11.2025.
//

import Foundation
import SwiftUI

struct HomeFilterGrid: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Categories")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(HomeViewModel.TaskFilter.allCases) { filter in
                    FilterCard(
                        filter: filter,
                        count: filterCount(for: filter),
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectFilter(filter)
                    }
                }
            }
        }
    }
    
    private func filterCount(for filter: HomeViewModel.TaskFilter) -> Int {
        switch filter {
        case .upcoming: return viewModel.upcomingCount
        case .overdue: return viewModel.overdueCount
        case .completed: return viewModel.completedCount
        }
    }
}

// MARK: - Filter Card
struct FilterCard: View {
    let filter: HomeViewModel.TaskFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: filter.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? .white : filter.color)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(count)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(filter.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }
            }
            .padding(20)
            .frame(height: 140)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? filter.color : Color.white)
                    .shadow(color: isSelected ? filter.color.opacity(0.3) : .black.opacity(0.06), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}
