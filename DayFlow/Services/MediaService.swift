//
//  MediaService.swift
//  DayFlow
//
//  Created by ebrar seda gündüz on 29.10.2025.
//

import Foundation
import AVFoundation
import SwiftUI

final class MediaService: NSObject, ObservableObject {
    static let shared = MediaService()
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var currentRecordingURL: URL?
    
    @Published private(set) var isRecording = false
    @Published private(set) var isPlaying = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - Permission
    func requestAudioRecordingPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            DispatchQueue.main.async {
                completion(allowed)
            }
        }
    }
    
    // MARK: - Recording Setup
    func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
    }
    
    private func createRecordingURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = UUID().uuidString + ".m4a"
        return documentsPath.appendingPathComponent(fileName)
    }
    
    private func getRecordingSettings() -> [String: Any] {
        return [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
    }
    
    // MARK: - Recording Control
    func startRecording() throws {
        try setupAudioSession()
        
        let recordingURL = createRecordingURL()
        currentRecordingURL = recordingURL
        
        let recorder = try AVAudioRecorder(url: recordingURL, settings: getRecordingSettings())
        recorder.delegate = self
        recorder.prepareToRecord()
        
        guard recorder.record() else {
            throw RecordingError.failedToStart
        }
        
        audioRecorder = recorder
        isRecording = true
        
    }
    
    func stopRecording() -> URL? {
        guard let recorder = audioRecorder, isRecording else {
            return nil
        }
        
        recorder.stop()
        isRecording = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print(" Audio session deaktif edilemedi: \(error.localizedDescription)")
        }
        
        let url = currentRecordingURL
        if let url = url, FileManager.default.fileExists(atPath: url.path) {
            print("Kayıt durduruldu ve dosya mevcut: \(url.path)")
        } else {
            print("Kayıt dosyası bulunamadı!")
            return nil
        }
        
        audioRecorder = nil
        currentRecordingURL = nil
        
        return url
    }
    
    func cancelRecording() {
        guard let recorder = audioRecorder else { return }
        
        recorder.stop()
        recorder.deleteRecording()
        isRecording = false
        
        audioRecorder = nil
        currentRecordingURL = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print(" Audio session deaktif edilemedi: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Audio Playback
    func playAudio(from url: URL) throws {
        if isPlaying {
            stopAudio()
            return
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)

        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        player.prepareToPlay()
        
        guard player.play() else {
            throw RecordingError.failedToStart
        }
        
        audioPlayer = player
        isPlaying = true
        
        print("Ses oynatılıyor: \(url.path)")
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session deaktif edilemedi: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    func audioExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func getAudioDuration(from url: URL) -> TimeInterval? {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            return player.duration
        } catch {
            print("Ses süresi alınamadı: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Errors
    enum RecordingError: LocalizedError {
        case recorderNotInitialized
        case failedToStart
        case permissionDenied
        case fileNotFound
        
        var errorDescription: String? {
            switch self {
            case .recorderNotInitialized:
                return "Audio recorder could not be initialized"
            case .failedToStart:
                return "Failed to start recording"
            case .permissionDenied:
                return "Microphone permission was denied"
            case .fileNotFound:
                return "Audio file not found"
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension MediaService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Kayıt başarıyla tamamlandı")
        } else {
            print("Kayıt başarısız oldu")
        }
        isRecording = false
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Kayıt encode hatası: \(error?.localizedDescription ?? "bilinmeyen")")
        isRecording = false
    }
}

// MARK: - AVAudioPlayerDelegate
extension MediaService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Ses oynatma tamamlandı")
        isPlaying = false
        audioPlayer = nil
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Ses decode hatası: \(error?.localizedDescription ?? "bilinmeyen")")
        isPlaying = false
        audioPlayer = nil
    }
}
