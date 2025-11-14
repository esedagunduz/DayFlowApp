//
//  NotesListView.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 29.10.2025.
//

import SwiftUI

struct NotesListView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var showAddNote = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection

                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    }

                    if viewModel.notes.isEmpty && !viewModel.isLoading {
                        emptyState
                    } else {
                        notesGrid
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.appBackground.ignoresSafeArea())

            floatingButton
        }
        .sheet(isPresented: $showAddNote) {
            NavigationView {
                NoteDetailView(viewModel: viewModel)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            await viewModel.loadNotes()
        }
        .refreshable {
            await viewModel.loadNotes()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Notes")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("\(viewModel.notes.count) notes")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("You haven't added any notes yet")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Start by adding voice or image notes")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Notes Grid
    private var notesGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(Array(viewModel.notes.enumerated()), id: \.element.id) { index, note in
                ModernNoteCard(note: note, viewModel: viewModel, colorIndex: index)
            }
        }
    }
    
    // MARK: - Floating Add Button
    private var floatingButton: some View {
        Button {
            showAddNote = true
        } label: {
            ZStack {
                // Mavi daire
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

// MARK: - Modern Note Card
struct ModernNoteCard: View {
    let note: JournalNote
    @ObservedObject var viewModel: NotesViewModel
    let colorIndex: Int
    @State private var showDetail = false
    @State private var showDeleteAlert = false
    
    private var cardColor: Color {
        let colors: [Color] = [.cardYellow, .cardGreen, .cardGray, .cardPink, .cardBlue]
        return colors[colorIndex % colors.count]
    }
    
    private var hasMedia: Bool {
        note.hasImage != nil || note.hasAudio != nil
    }
    
    var body: some View {
        Button(action: { showDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {

                HStack {
                    HStack(spacing: 8) {
                        if note.hasImage {
                            Image(systemName: "photo.fill")
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.6))
                        }
                        
                        if note.hasAudio {
                            Image(systemName: "waveform")
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.6))
                        }
                    }
                    
                    Spacer()

                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash.fill")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Text(note.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.black.opacity(0.5))

                Text(note.text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(6)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(16)
            .frame(height: 180)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardColor)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: cardColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
       
        .sheet(isPresented: $showDetail) {
            NavigationView {
                NoteDetailView(viewModel: viewModel, note: note)
            }
        }
        .alert("Delete Note", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                _Concurrency.Task {
                    await viewModel.deleteNote(note)
                }
            }
        } message: {
            Text("Are you sure you want to delete this note?")
        }
    }
}

// MARK: - Preview
struct NotesListView_Previews: PreviewProvider {
    static var previews: some View {
        NotesListView()
    }
}
