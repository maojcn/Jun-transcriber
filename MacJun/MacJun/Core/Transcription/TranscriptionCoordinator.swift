//
//  TranscriptionCoordinator.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/28.
//


import Foundation

class TranscriptionCoordinator: ObservableObject, WhisperDelegate {
    @Published var segments: [(Int, String)] = []
    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0
    @Published var errorMessage: String?
    
    private var whisperWrapper: WhisperWrapper?
    
    func startTranscription(modelPath: String, audioURL: URL, language: String?) {
        isTranscribing = true
        segments = []
        errorMessage = nil
        
        Task {
            do {
                // Convert audio file
                let convertedURL = try AudioConverter.convert(audioFile: audioURL)
                
                // Load audio samples
                let samples = try WhisperWrapper.loadAudio(from: convertedURL)
                
                // Initialize Whisper
                whisperWrapper = try WhisperWrapper(modelPath: modelPath)
                whisperWrapper?.delegate = self
                
                // Start transcription
                whisperWrapper?.transcribe(samples, language: language)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isTranscribing = false
                }
            }
        }
    }
    
    func stopTranscription() {
        whisperWrapper?.stopTranscription()
    }
    
    // MARK: - WhisperDelegate
    
    func whisper(_ whisper: WhisperWrapper, didUpdateSegment text: String, at index: Int) {
        segments.append((index, text))
    }
    
    func whisper(_ whisper: WhisperWrapper, didCompleteWithSuccess success: Bool) {
        isTranscribing = false
        if !success {
            errorMessage = "Transcription failed"
        }
    }
    
    func whisper(_ whisper: WhisperWrapper, didUpdateProgress progress: Double) {
        transcriptionProgress = progress
    }
}
