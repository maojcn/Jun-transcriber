//
//  TranscriptionView.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/28.
//

import SwiftUI
import UniformTypeIdentifiers

struct TranscriptionView: View {
    @StateObject private var coordinator = TranscriptionCoordinator()
    @State private var selectedModelPath: String?
    @State private var selectedLanguage: String = "en"
    @State private var audioFileURL: URL?
    @State private var showFileChooser = false
    @State private var showDownloadAlert = false
    @State private var downloadAlertMessage = ""
    @State private var isConverting = false // New state variable for conversion status
    
    private let downloader = WhisperModelDownloader()
    
    private let languages = [
        "auto": "Auto-Detect",
        "en": "English",
        "zh": "Chinese",
        "ja": "Japanese",
        "ko": "Korean",
        "fr": "French",
        "de": "German",
        "es": "Spanish",
        "ru": "Russian",
        "pt": "Portuguese",
        "tr": "Turkish",
        "pl": "Polish",
        "ca": "Catalan",
        "nl": "Dutch",
        "ar": "Arabic",
        "sv": "Swedish",
        "it": "Italian",
        "id": "Indonesian",
        "hi": "Hindi",
        "fi": "Finnish",
        "vi": "Vietnamese",
        "he": "Hebrew",
        "uk": "Ukrainian",
        "el": "Greek",
        "ms": "Malay",
        "cs": "Czech",
        "ro": "Romanian",
        "da": "Danish",
        "hu": "Hungarian",
        "ta": "Tamil",
        "no": "Norwegian",
        "th": "Thai",
        "ur": "Urdu",
        "hr": "Croatian",
        "bg": "Bulgarian",
        "lt": "Lithuanian",
        "la": "Latin",
        "mi": "Maori",
        "ml": "Malayalam",
        "cy": "Welsh",
        "sk": "Slovak",
        "te": "Telugu",
        "fa": "Persian",
        "lv": "Latvian",
        "bn": "Bengali",
        "sr": "Serbian",
        "az": "Azerbaijani",
        "sl": "Slovenian",
        "kn": "Kannada",
        "et": "Estonian",
        "mk": "Macedonian",
        "br": "Breton",
        "eu": "Basque",
        "is": "Icelandic",
        "hy": "Armenian",
        "ne": "Nepali",
        "mn": "Mongolian",
        "bs": "Bosnian",
        "kk": "Kazakh",
        "sq": "Albanian",
        "sw": "Swahili",
        "gl": "Galician",
        "mr": "Marathi",
        "pa": "Punjabi",
        "si": "Sinhala",
        "km": "Khmer",
        "sn": "Shona",
        "yo": "Yoruba",
        "so": "Somali",
        "af": "Afrikaans",
        "oc": "Occitan",
        "ka": "Georgian",
        "be": "Belarusian",
        "tg": "Tajik",
        "sd": "Sindhi",
        "gu": "Gujarati",
        "am": "Amharic",
        "yi": "Yiddish",
        "lo": "Lao",
        "uz": "Uzbek",
        "fo": "Faroese",
        "ht": "Haitian Creole",
        "ps": "Pashto",
        "tk": "Turkmen",
        "nn": "Nynorsk",
        "mt": "Maltese",
        "sa": "Sanskrit",
        "lb": "Luxembourgish",
        "my": "Myanmar",
        "bo": "Tibetan",
        "tl": "Tagalog",
        "mg": "Malagasy",
        "as": "Assamese",
        "tt": "Tatar",
        "haw": "Hawaiian",
        "ln": "Lingala",
        "ha": "Hausa",
        "ba": "Bashkir",
        "jw": "Javanese",
        "su": "Sundanese",
        "yue": "Cantonese"
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
                Button(coordinator.isTranscribing ? "Stop" : "Start Transcription") {
                    if coordinator.isTranscribing {
                        coordinator.stopTranscription()
                    } else {
                        startTranscription()
                    }
                }
                .disabled(selectedModelPath == nil || audioFileURL == nil)
                
                if isConverting {
                    Text("Converting...")
                } else if coordinator.isTranscribing {
                    HStack{
                        ProgressView(value: coordinator.transcriptionProgress)
                            .progressViewStyle(.linear)
                            .frame(width: 100)
                        Text("\(Int(coordinator.transcriptionProgress * 100))%")
                    }
                }
            }
            
            Button("Download Transcription") {
                downloadSegments()
            }
            .disabled(coordinator.segments.isEmpty)
            
            // Error Message
            if let errorMessage = coordinator.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            // Segments List
            List(coordinator.segments, id: \.0) { index, text in
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
                    do {
                        // Request access to the file
                        if url.startAccessingSecurityScopedResource() {
                            audioFileURL = url
                        } else {
                            coordinator.errorMessage = "Failed to access file: Permission denied"
                        }
                    }
                }
            case .failure(let error):
                coordinator.errorMessage = error.localizedDescription
            }
        }
        .alert(isPresented: $showDownloadAlert) {
            Alert(
                title: Text("Download Complete"),
                message: Text("Transcription saved to the Downloads folder. You can find it in Finder under the Downloads section."),
                dismissButton: .default(Text("OK"))
            )
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
            coordinator.errorMessage = "Please select both a model and an audio file"
            return
        }
        
        isConverting = true // Set converting state to true
        
        Task {
            do {
                // Convert audio file
                let convertedURL = try AudioConverter.convert(audioFile: audioURL)
                isConverting = false // Set converting state to false after conversion
                
                // Start transcription
                coordinator.startTranscription(modelPath: modelPath, audioURL: convertedURL, language: selectedLanguage)
            } catch {
                isConverting = false // Set converting state to false if conversion fails
                DispatchQueue.main.async {
                    self.coordinator.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func downloadSegments() {
        let segmentsText = coordinator.segments.map { $0.1 }.joined(separator: "\n")
        let fileName = "Transcription_\(Date().timeIntervalSince1970).txt"
        
        if let downloadDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let fileURL = downloadDirectory.appendingPathComponent(fileName)
            
            do {
                try segmentsText.write(to: fileURL, atomically: true, encoding: .utf8)
                showDownloadAlert = true
            } catch {
                coordinator.errorMessage = "Failed to save segments: \(error.localizedDescription)"
            }
        } else {
            coordinator.errorMessage = "Failed to locate download directory"
        }
    }
}

#Preview {
    TranscriptionView()
}
