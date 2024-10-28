import SwiftUI
import UniformTypeIdentifiers

struct TranscriptionView: View {
    @State private var selectedModelPath: String?
    @State private var selectedLanguage: String = "en"
    @State private var audioFileURL: URL?
    @State private var isTranscribing = false
    @State private var segments: [(Int, String)] = []
    @State private var showFileChooser = false
    @State private var errorMessage: String?
    @State private var transcriptionProgress: Double = 0
    
    private let downloader = WhisperModelDownloader()
    private var whisperWrapper: WhisperWrapper?
    
    private let languages = [
        "en": "English",
        "zh": "Chinese",
        "ja": "Japanese",
        "ko": "Korean",
        "fr": "French",
        "de": "German",
        "es": "Spanish",
        "ru": "Russian"
        // Add more languages as needed
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Model Selection
            HStack {
                Text("Model:")
                Picker("Model", selection: $selectedModelPath) {
                    Text("Select Model").tag(nil as String?)
                    ForEach(downloader.getDownloadedModels(), id: \.self) { model in
                        if let path = getModelPath(for: model) {
                            Text(model).tag(path as String?)
                        }
                    }
                }
            }
            
            // Language Selection
            HStack {
                Text("Language:")
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(languages.sorted(by: { $0.value < $1.value }), id: \.key) { key, value in
                        Text(value).tag(key)
                    }
                }
            }
            
            // Audio File Selection
            HStack {
                Text("Audio File:")
                if let url = audioFileURL {
                    Text(url.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("No file selected")
                }
                Button("Choose File") {
                    showFileChooser = true
                }
            }
            
            // Transcription Controls
            HStack {
                Button(isTranscribing ? "Stop" : "Start Transcription") {
                    if isTranscribing {
                        stopTranscription()
                    } else {
                        startTranscription()
                    }
                }
                .disabled(selectedModelPath == nil || audioFileURL == nil)
                
                if isTranscribing {
                    ProgressView(value: transcriptionProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 100)
                }
            }
            
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            // Segments List
            List(segments, id: \.0) { index, text in
                Text(text)
                    .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .fileImporter(
            isPresented: $showFileChooser,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    audioFileURL = url
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func getModelPath(for modelName: String) -> String? {
        let modelPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("WhisperModels")
            .appendingPathComponent("ggml-\(modelName).bin")
        return modelPath?.path
    }
    
    private func startTranscription() {
        guard let modelPath = selectedModelPath,
              let audioURL = audioFileURL else {
            errorMessage = "Please select both a model and an audio file"
            return
        }
        
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
                let whisper = try WhisperWrapper(modelPath: modelPath)
                whisper.delegate = self
                
                // Start transcription
                whisper.transcribe(samples, language: selectedLanguage)
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    isTranscribing = false
                }
            }
        }
    }
    
    private func stopTranscription() {
        // Implement stop functionality
        whisperWrapper?.stopTranscription()
        isTranscribing = false
    }
}

// Extend TranscriptionView to conform to WhisperDelegate
extension TranscriptionView: WhisperDelegate {
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

#Preview {
    TranscriptionView()
}