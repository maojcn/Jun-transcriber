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
    
    var body: some View {
        VStack(spacing: 24) {
            // Model & Language Selection Group
            GroupBox {
                VStack(spacing: 16) {
                    HStack {
                        Text("Model:")
                            .frame(width: 80, alignment: .trailing)
                        Picker("Model", selection: $selectedModelPath) {
                            Text("Select Model").tag(nil as String?)
                            ForEach(downloader.getDownloadedModels(), id: \.self) { model in
                                if let path = getModelPath(for: model) {
                                    Text(model).tag(path as String?)
                                }
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    }
                    
                    HStack {
                        Text("Language:")
                            .frame(width: 80, alignment: .trailing)
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(languages.sorted(by: { $0.value < $1.value }), id: \.key) { key, value in
                                Text(value).tag(key)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(8)
            } label: {
                Label("Configuration", systemImage: "gearshape")
            }
            
            // Audio File Selection Group
            GroupBox {
                HStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        if let url = audioFileURL {
                            Text(url.lastPathComponent)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            Text("No file selected")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Choose File") {
                        showFileChooser = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(8)
            } label: {
                Label("Audio File", systemImage: "music.note")
            }
            
            // Transcription Controls
            GroupBox {
                VStack(spacing: 16) {
                    HStack {
                        if isConverting || coordinator.isTranscribing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(isConverting ? "Converting..." : "\(Int(coordinator.transcriptionProgress * 100))%")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(coordinator.isTranscribing ? "Stop" : "Start Transcription") {
                            if coordinator.isTranscribing {
                                coordinator.stopTranscription()
                            } else {
                                startTranscription()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedModelPath == nil || audioFileURL == nil)
                    }
                    
                    if let errorMessage = coordinator.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(8)
            } label: {
                Label("Controls", systemImage: "play.circle")
            }
            
            // Results Section
            GroupBox {
                HStack {
                    Text("Transcription Results")
                        .font(.headline)
                    Spacer()
                    Button("Download") {
                        downloadSegments()
                    }
                    .disabled(coordinator.segments.isEmpty)
                }
                
                ScrollViewReader { proxy in
                    List(coordinator.segments) { segment in
                        Text(segment.text)
                            .textSelection(.enabled)
                            .padding(.vertical, 4)
                            .id(segment.id)
                    }
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(6)
                    .onChange(of: coordinator.segments) { old, segments in
                        if let lastSegment = segments.last {
                            withAnimation {
                                proxy.scrollTo(lastSegment.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .padding(8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                message: Text("Transcription saved to the Downloads folder. \n You can find it in Finder under the Downloads section."),
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
        let segmentsText = coordinator.segments.map { $0.text }.joined(separator: "\n")
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
