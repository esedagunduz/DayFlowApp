

//
//  NoteDetailView.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 29.10.2025.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct NoteDetailView: View {
    
    // MARK: - Properties
    @ObservedObject private var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let note: JournalNote?
    
    // MARK: - State
    @State private var text: String = ""
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isRecording = false
    @State private var recordedAudioURL: URL?
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var showPermissionAlert = false
    @State private var showSaveSuccess = false
    @State private var isPlayingAudio = false
    @State private var currentAudioURL: URL?
    @FocusState private var isTextEditorFocused: Bool
    
    // MARK: - Computed Properties
    private var isEditing: Bool {
        note == nil
    }
    
    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var hasAttachments: Bool {
        selectedImage != nil || recordedAudioURL != nil || note?.hasMedia == true
    }
    
    // MARK: - Init
    init(viewModel: NotesViewModel, note: JournalNote? = nil) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.note = note
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    mainEditorSection
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle(isEditing ? "New Note" : note?.text.prefix(20) ?? "Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    handleDismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text(isEditing ? "Cancel" : "Back")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveNote) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!canSave || viewModel.isLoading)
                }
            }
        }
        .onAppear(perform: setupView)
        .onDisappear {
            cleanupOnDisappear()
        }
        .alert("Microphone Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings", action: openSettings)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Microphone access is required to record audio")
        }
        .alert("Success!", isPresented: $showSaveSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your note has been saved successfully.")
        }
    }
    
    // MARK: - Main Editor Section
    private var mainEditorSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                VStack(spacing: 0) {
                    textEditorView
                    
                    if hasAttachments || isEditing {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    
                    if isEditing {
                        editModeAttachmentsSection
                    } else if let note = note, note.hasMedia {
                        viewModeAttachmentsSection(note: note)
                    }
                    
                    if isEditing {
                        editorToolbar
                    }
                }
            }
        }
    }
    
    // MARK: - Text Editor View
    private var textEditorView: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty && isEditing {
                Text("Write your note...")
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
            
            if isEditing {
                TextEditor(text: $text)
                    .focused($isTextEditorFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 200)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            } else {
                ScrollView {
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .foregroundColor(.primary)
                }
                .frame(minHeight: 200)
            }
        }
    }
    
    // MARK: - Edit Mode Attachments
    private var editModeAttachmentsSection: some View {
        VStack(spacing: 12) {
            if let image = selectedImage {
                imageAttachmentCard(image: image, isEditing: true)
            }
            
            if let audioURL = recordedAudioURL {
                audioAttachmentCard(
                    duration: MediaService.shared.getAudioDuration(from: audioURL),
                    isRecording: false,
                    isPlaying: false,
                    isEditing: true
                )
            }
            
            if isRecording {
                audioAttachmentCard(
                    duration: recordingDuration,
                    isRecording: true,
                    isPlaying: false,
                    isEditing: true
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - View Mode Attachments
    private func viewModeAttachmentsSection(note: JournalNote) -> some View {
        VStack(spacing: 12) {
            if let image = note.decodedImage {
                imageAttachmentCard(image: image, isEditing: false)
            }
            
            if note.hasAudio {
                Button(action: { playAudioFromNote(note) }) {
                    audioAttachmentCard(
                        duration: nil,
                        isRecording: false,
                        isPlaying: isPlayingAudio,
                        isEditing: false
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Image Attachment Card
        private func imageAttachmentCard(image: UIImage, isEditing: Bool) -> some View {
            VStack(spacing: 0) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if isEditing {
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            
                            Text("Image")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        if let imageData = image.jpegData(compressionQuality: 1.0) {
                            Text(formatFileSize(imageData.count))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { selectedImage = nil }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                Text("Remove")
                                    .font(.caption)
                            }
                            .foregroundColor(.red.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    
    // MARK: - Audio Attachment Card
    private func audioAttachmentCard(duration: TimeInterval?, isRecording: Bool, isPlaying: Bool, isEditing: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        isRecording ? Color.red.opacity(0.1) :
                        isPlaying ? Color.green.opacity(0.1) :
                        Color.blue.opacity(0.1)
                    )
                    .frame(width: 40, height: 40)
                
                if isRecording {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .scaleEffect(isRecording ? 1.0 : 0.7)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecording)
                } else {
                    Image(systemName: isPlaying ? "stop.fill" : "waveform")
                        .font(.system(size: 16))
                        .foregroundColor(isPlaying ? .green : .blue)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isRecording ? "Recording..." : isPlaying ? "Playing..." : "Audio Note")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                if let duration = duration {
                    Text(formatDuration(duration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isEditing && !isRecording {
                Button(action: {
                    recordedAudioURL = nil
                    MediaService.shared.cancelRecording()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(
            isRecording ? Color.red.opacity(0.05) :
            isPlaying ? Color.green.opacity(0.05) :
            Color.gray.opacity(0.05)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - Editor Toolbar
    private var editorToolbar: some View {
        HStack(spacing: 16) {
            PhotosPicker(
                selection: $selectedImageItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                toolbarButton(
                    icon: "photo",
                    color: .blue,
                    isDisabled: selectedImage != nil
                )
            }
            .disabled(selectedImage != nil)
            .onChange(of: selectedImageItem) { newItem in
                loadSelectedImage(newItem)
            }
            
            Button(action: toggleRecording) {
                toolbarButton(
                    icon: isRecording ? "stop.circle" : "mic",
                    color: isRecording ? .red : .green,
                    isDisabled: recordedAudioURL != nil && !isRecording
                )
            }
            .disabled(recordedAudioURL != nil && !isRecording)
            
            Spacer()
            
            Text("\(text.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.02))
    }
    
    private func toolbarButton(icon: String, color: Color, isDisabled: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isDisabled ? Color.gray.opacity(0.1) : color.opacity(0.1))
                .frame(width: 40, height: 40)
            
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isDisabled ? .gray : color)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatFileSize(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.1f MB", mb)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Actions
    
    private func setupView() {
        if let note = note {
            text = note.text
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextEditorFocused = true
            }
        }
        checkMicrophonePermission()
    }
    
    private func handleDismiss() {
        if isPlayingAudio {
            MediaService.shared.stopAudio()
        }
        if isRecording {
            stopRecording()
        }
        dismiss()
    }
    
    private func cleanupOnDisappear() {
        if isPlayingAudio {
            MediaService.shared.stopAudio()
        }
        if isRecording {
            stopRecording()
        }
        recordingTimer?.invalidate()
        cleanupTempFiles()
    }
    
    private func checkMicrophonePermission() {
        MediaService.shared.requestAudioRecordingPermission { granted in
            if !granted {
                print("Mikrofon izni verilmedi")
            }
        }
    }
    
    private func loadSelectedImage(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        _Concurrency.Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.selectedImage = image
                    }
                }
            } catch {
                print("Fotoğraf yüklenemedi: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        do {
            try MediaService.shared.startRecording()
            isRecording = true
            recordingDuration = 0

            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordingDuration += 0.1
                if recordingDuration >= 30 {
                    stopRecording()
                }
            }
            
            print("Kayıt başladı")
        } catch {
            print("Kayıt başlatılamadı: \(error.localizedDescription)")
            showPermissionAlert = true
        }
    }
    
    private func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        if let url = MediaService.shared.stopRecording() {
            recordedAudioURL = url
            isRecording = false
            print("Kayıt durduruldu: \(url.path)")
        }
    }
    
    private func playAudioFromNote(_ note: JournalNote) {
        if isPlayingAudio {
            MediaService.shared.stopAudio()
            isPlayingAudio = false
            cleanupTempFiles()
            return
        }
        
        guard let audioData = note.decodedAudioData else {
            print("Ses verisi decode edilemedi")
            return
        }
        
        do {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("m4a")
            
            try audioData.write(to: tempURL)
            currentAudioURL = tempURL
            
            try MediaService.shared.playAudio(from: tempURL)
            isPlayingAudio = true
            
            checkAudioPlaybackStatus()
            
        } catch {
            print("Ses oynatılamadı: \(error.localizedDescription)")
            cleanupTempFiles()
        }
    }
    
    private func checkAudioPlaybackStatus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !MediaService.shared.isPlaying && self.isPlayingAudio {
                self.isPlayingAudio = false
                self.cleanupTempFiles()
            } else if self.isPlayingAudio {
                self.checkAudioPlaybackStatus()
            }
        }
    }
    
    private func cleanupTempFiles() {
        if let url = currentAudioURL {
            try? FileManager.default.removeItem(at: url)
            currentAudioURL = nil
        }
    }
    
    private func saveNote() {
        _Concurrency.Task {
            let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
            
            await viewModel.addNote(
                text: text,
                imageData: imageData,
                audioURL: recordedAudioURL
            )
            
            if viewModel.errorMessage == nil {
                showSaveSuccess = true
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        NoteDetailView(viewModel: NotesViewModel())
    }
}
