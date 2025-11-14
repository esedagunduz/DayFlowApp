
import SwiftUI

struct StrategySettingsView: View {
    
    // MARK: - Dependencies
    @StateObject private var viewModel: StrategySettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(tasksViewModel: TasksViewModel) {
        _viewModel = StateObject(wrappedValue: StrategySettingsViewModel(tasksViewModel: tasksViewModel))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    strategyCardsSection
                    autoSortSection
                    infoNote
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color(hex: "F8F9FA").ignoresSafeArea())
            .navigationTitle("Task Prioritization Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                saveButton
            }
            .sheet(isPresented: $viewModel.showingSuggestion) {
                suggestionSheet
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            VStack(spacing: 8) {
                Text("Choose Your Work Style")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("3 different prioritization methods")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Strategy Cards Section
    
    private var strategyCardsSection: some View {
        VStack(spacing: 16) {
            ForEach(TaskStrategy.allCases) { strategy in
                StrategyCard(
                    strategy: strategy,
                    isSelected: viewModel.selectedStrategy == strategy,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedStrategy = strategy
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Auto Sort Section
    
    private var autoSortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.purple)
                Text("Auto Sorting")
                    .font(.headline)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.autoSortEnabled)
                    .labelsHidden()
            }
            
            Text("Tasks will be sorted by priority score")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Info Note
    
    private var infoNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Info")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Your strategy choice affects task priority scores. You can change it anytime.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Toolbar Buttons
    
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.secondary)
        }
    }
    
    private var saveButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                viewModel.saveStrategy()
                dismiss()
            }
            .fontWeight(.semibold)
        }
    }
    
    // MARK: - Suggestion Sheet
    
    private var suggestionSheet: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                suggestionHeader
                suggestionContent
                suggestionAction
                
                Spacer()
            }
            .padding(20)
            .background(Color(hex: "F8F9FA").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { viewModel.showingSuggestion = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
        }
    }
    
    private var suggestionHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
            }
            
            Text("Suggested Strategy")
                .font(.system(size: 28, weight: .bold, design: .rounded))
        }
    }
    
    private var suggestionContent: some View {
        let suggested = viewModel.suggestedStrategy
        
        return VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text(suggested.icon)
                    .font(.system(size: 64))
                
                Text(suggested.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(suggested.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Based on your completed tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }
    
    private var suggestionAction: some View {
        Button(action: viewModel.applySuggestedStrategy) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                
                Text("Use This Strategy")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Strategy Card

struct StrategyCard: View {
    let strategy: TaskStrategy
    let isSelected: Bool
    let onTap: () -> Void
    
    private var cardColor: Color {
        switch strategy {
        case .quickWins:
            return Color.cardGreen
        case .balanced:
            return Color.cardYellow
        case .eatTheFrog:
            return Color.cardPink
        }
    }
    
    private var subtitle: String {
        switch strategy {
        case .quickWins:
            return "Easy tasks first"
        case .balanced:
            return "Balanced approach"
        case .eatTheFrog:
            return "Hard tasks first"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 64, height: 64)
                        
                        Text(strategy.icon)
                            .font(.system(size: 36))
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(strategy.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.6))
                    
                    Text(strategy.description)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(20)
            .background(cardColor)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? Color.black : Color.clear, lineWidth: 3)
            )
            .shadow(
                color: isSelected ? Color.black.opacity(0.2) : cardColor.opacity(0.3),
                radius: isSelected ? 12 : 8,
                x: 0,
                y: isSelected ? 6 : 4
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
    }
}

// MARK: - Preview

struct StrategySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        StrategySettingsView(tasksViewModel: TasksViewModel())
    }
}
