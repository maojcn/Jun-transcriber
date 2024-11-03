//
//  TranscriptionCoordinator.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/28.
//


import Foundation

struct TransSegment: Identifiable, Equatable {
    let id: Int
    let text: String
}

class TranscriptionCoordinator: ObservableObject, WhisperDelegate {
    @Published var segments: [TransSegment] = []
    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0
    @Published var errorMessage: String?
    
    private var whisperWrapper: WhisperWrapper?
    
    func startTranscription(modelPath: String, audioData: [Float], language: String?) {
        isTranscribing = true
        segments = []
        errorMessage = nil
        
        Task {
            do {
                // Initialize Whisper
                whisperWrapper = try WhisperWrapper(modelPath: modelPath)
                whisperWrapper?.delegate = self
                
                // Start transcription with PCM array directly
                whisperWrapper?.transcribe(audioData, language: language)
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
        DispatchQueue.main.async {
            if let lastSegment = self.segments.last {
                if lastSegment.text == text {
                    return // Skip duplicate text
                }
            }
            self.segments.append(TransSegment(id: index, text: text))
        }
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
