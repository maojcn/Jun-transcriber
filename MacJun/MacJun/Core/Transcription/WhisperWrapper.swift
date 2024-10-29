//
//  WhisperWrapper.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/28.
//

import Foundation
import whisper

/// Errors that can occur when using WhisperKit
public enum WhisperError: Error {
    case modelLoadFailed
    case transcriptionFailed
    case invalidState
    case initializationFailed
}

/// Delegate protocol for receiving transcription updates
protocol WhisperDelegate: AnyObject {
    func whisper(_ whisper: WhisperWrapper, didUpdateSegment text: String, at index: Int)
    func whisper(_ whisper: WhisperWrapper, didCompleteWithSuccess: Bool)
    func whisper(_ whisper: WhisperWrapper, didUpdateProgress progress: Double)
}

/// A Swift wrapper for Whisper speech-to-text
final class WhisperWrapper {
    private var ctx: OpaquePointer?
    private var state: OpaquePointer?
    private var shouldTerminate: Bool = false
    private var isProcessing: Bool = false
    weak var delegate: WhisperDelegate?
    
    /// property to store progress and progress callback
    private var progress: Int32 = 0
    
    /// Initialize with a model file path
    /// - Parameter modelPath: Path to the Whisper model file
    init(modelPath: String) throws {
        let params = whisper_context_default_params()
        guard let ctx = whisper_init_from_file_with_params(modelPath, params) else {
            throw WhisperError.modelLoadFailed
        }
        self.ctx = ctx
        guard let state = whisper_init_state(ctx) else {
            throw WhisperError.invalidState
        }
        self.state = state
    }
    
    deinit {
        if let state = state {
            whisper_free_state(state)
        }
        if let ctx = ctx {
            whisper_free(ctx)
        }
    }
    
    /// Stop the ongoing transcription
    func stopTranscription() {
        shouldTerminate = true
    }
    
    /// Check if transcription is in progress
    var isTranscribing: Bool {
        isProcessing
    }
    
    /// Transcribe audio data
    /// - Parameters:
    ///   - samples: Array of audio samples (16kHz, mono, 32-bit float)
    ///   - language: Optional language code (e.g., "en" for English)
    func transcribe(_ samples: [Float], language: String? = nil) {
        guard !isProcessing else { return }
        isProcessing = true
        shouldTerminate = false
        
        // Run transcription in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
            
            // Set language if specified
            if let language = language {
                let languageCString = strdup(language)
                params.language = UnsafePointer(languageCString)
            }
            
            // Configure callbacks
            params.new_segment_callback = { (ctx, state, n_new, user_data) in
                let instance = Unmanaged<WhisperWrapper>.fromOpaque(user_data!).takeUnretainedValue()
                
                // Get the latest segment
                let segmentCount = whisper_full_n_segments_from_state(state)
                if segmentCount > 0 {
                    let latestSegmentIndex = segmentCount - 1
                    if let text = whisper_full_get_segment_text_from_state(state, latestSegmentIndex) {
                        let segmentText = String(cString: text)
                        
                        // Dispatch to main thread for UI updates
                        DispatchQueue.main.async {
                            instance.delegate?.whisper(instance, didUpdateSegment: segmentText, at: Int(latestSegmentIndex))
                        }
                    }
                }
            }
            
            // Set up abort callback for interruption
            params.abort_callback = { (user_data) -> Bool in
                let instance = Unmanaged<WhisperWrapper>.fromOpaque(user_data!).takeUnretainedValue()
                return instance.shouldTerminate
            }
            
            // Set up progress callback
            params.progress_callback = { (ctx, state, progress, user_data) in
                let instance = Unmanaged<WhisperWrapper>.fromOpaque(user_data!).takeUnretainedValue()
                
                // Dispatch to main thread for UI updates
                DispatchQueue.main.async {
                    instance.delegate?.whisper(instance, didUpdateProgress: Double(progress) / 100.0)
                }
            }
            
            // Pass self as user data for callbacks
            let userDataPtr = Unmanaged.passUnretained(self).toOpaque()
            params.progress_callback_user_data = userDataPtr
            params.new_segment_callback_user_data = userDataPtr
            params.abort_callback_user_data = userDataPtr
            
            // Perform transcription
            let result = whisper_full_with_state(
                self.ctx,
                self.state,
                params,
                samples,
                Int32(samples.count)
            )
            
            // Clean up allocated memory
            if let languageCString = params.language {
                free(UnsafeMutableRawPointer(mutating: languageCString))
            }
            
            // Report completion
            let success = result == 0
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isProcessing = false
                self.delegate?.whisper(self, didCompleteWithSuccess: success)
            }
        }
    }
    
    /// Configure transcription parameters
    /// - Returns: Configured parameters for full transcription
    private func configureFullParams() -> whisper_full_params {
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_progress = false
        params.print_realtime = false
        params.print_timestamps = true
        params.translate = false
        params.language = nil
        params.n_threads = Int32(max(1, ProcessInfo.processInfo.processorCount - 1))
        return params
    }
    
    /// Get transcription segments from the current state
    /// - Returns: Array of transcription segments
    private func getTranscriptionSegments() throws -> [TranscriptionSegment] {
        guard let state = state else {
            throw WhisperError.invalidState
        }
        
        let segmentCount = whisper_full_n_segments_from_state(state)
        var segments: [TranscriptionSegment] = []
        
        for i in 0..<segmentCount {
            let start = whisper_full_get_segment_t0_from_state(state, i)
            let end = whisper_full_get_segment_t1_from_state(state, i)
            guard let text = whisper_full_get_segment_text_from_state(state, i) else {
                continue
            }
            
            segments.append(TranscriptionSegment(
                text: String(cString: text),
                startTime: Double(start) / 100.0,
                endTime: Double(end) / 100.0
            ))
        }
        
        return segments
    }
}

/// Represents a segment of transcribed text with timing information
public struct TranscriptionSegment: Codable {
    /// The transcribed text
    public let text: String
    
    /// Start time in seconds
    public let startTime: Double
    
    /// End time in seconds
    public let endTime: Double
}

// MARK: - Convenience Methods

extension WhisperWrapper {
    /// Convert audio file to samples
    /// - Parameter url: URL of the audio file
    /// - Returns: Array of audio samples
    static func loadAudio(from url: URL) throws -> [Float] {
        // Note: Implement audio file loading and conversion to proper format
        // This is a placeholder - you'll need to implement actual audio loading
        // using AVFoundation or another audio framework
        let data = try Data(contentsOf: url)
        let floats = stride(from: 44, to: data.count, by: 2).map {
            return data[$0..<$0 + 2].withUnsafeBytes {
                let short = Int16(littleEndian: $0.load(as: Int16.self))
                return max(-1.0, min(Float(short) / 32767.0, 1.0))
            }
        }
        return floats
    }
    
    /// Get all available text segments
    /// - Returns: Array of text segments
    func getAllSegments() -> [String] {
        guard let state = state else { return [] }
        
        let segmentCount = whisper_full_n_segments_from_state(state)
        var segments: [String] = []
        
        for i in 0..<segmentCount {
            if let text = whisper_full_get_segment_text_from_state(state, i) {
                segments.append(String(cString: text))
            }
        }
        
        return segments
    }
}
