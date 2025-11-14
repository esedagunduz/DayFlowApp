//
//  ContentView.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 30.09.2025.
//

import SwiftUI

// MARK: - Renkler

    extension Color {
        init(hex: String) {
            let scanner = Scanner(string: hex)
            _ = scanner.scanString("#")
            var rgb: UInt64 = 0
            scanner.scanHexInt64(&rgb)
            
            let r = Double((rgb >> 16) & 0xFF) / 255
            let g = Double((rgb >> 8) & 0xFF) / 255
            let b = Double(rgb & 0xFF) / 255
            
            self.init(red: r, green: g, blue: b)
        }
    }

    // MARK: - ContentView

    struct ContentView: View {
        @EnvironmentObject var authViewModel: AuthViewModel
        @StateObject private var tasksViewModel: TasksViewModel
        @StateObject private var notesViewModel = NotesViewModel()
        @StateObject private var homeViewModel: HomeViewModel
        @State private var selectedTab = 0
        
        init() {
            let tasksVM = TasksViewModel()
            _tasksViewModel = StateObject(wrappedValue: tasksVM)
            _homeViewModel = StateObject(wrappedValue: HomeViewModel(tasksViewModel: tasksVM))
        }
        
        var body: some View {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    HomeView(tasksViewModel: tasksViewModel)
                        .environmentObject(homeViewModel)
                        .tabItem { EmptyView() }
                        .tag(0)
                    
                    TasksListView()
                        .environmentObject(tasksViewModel)
                        .tabItem { EmptyView() }
                        .tag(1)
                    
                    NotesListView()
                        .environmentObject(notesViewModel)
                        .tabItem { EmptyView() }
                        .tag(2)
                    
                    ProfileView()
                        .tabItem { EmptyView() }
                        .tag(3)
                }


                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.black)
                        .frame(height: 70)
                        .padding(.horizontal, 20)
                        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: -5)
                    
                    HStack(spacing: 0) {
                        Spacer()
                        tabButton(icon: "house.fill", index: 0)
                        Spacer()
                        tabButton(icon: "checkmark.square.fill", index: 1)
                        Spacer()
                        tabButton(icon: "book.fill", index: 2)
                        Spacer()
                        tabButton(icon: "person.fill", index: 3)
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                }
                .frame(height: 90)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        
        // MARK: - Custom Tab Button
        private func tabButton(icon: String, index: Int) -> some View {
            Button {
                selectedTab = index
            } label: {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(selectedTab == index ? .white : .white.opacity(0.4))
                    .frame(width: 44, height: 44)
                    .scaleEffect(selectedTab == index ? 1.2 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
            }
        }
    }


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
