//
//  TranscriptionView.swift
//  Jun
//
//  Created by Jiacheng Mao on 2024/11/3.
//


//
//  TranscriptionView.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/28.
//

import SwiftUI
import UniformTypeIdentifiers

private let supportedAudioTypes: [UTType] = [
    .mp3,          // .mp3
    .wav,          // .wav
    .mpeg4Audio,   // .m4a, .aac
    .aiff,         // .aif, .aiff
    .midi,         // .mid
    .audiovisualContent, // .caf
]

private enum UserDefaultsKeys {
    static let selectedLanguage = "selectedTranscriptionLanguage"
}

struct TranscriptionView: View {
    @StateObject private var coordinator = TranscriptionCoordinator()
    @State private var selectedModelPath: String?
    @State private var selectedLanguage: String = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedLanguage) ?? "en"
    @State private var audioFileURL: URL?
    @State private var showFileChooser = false
    @State private var showDownloadAlert = false
    @State private var downloadAlertMessage = ""
    @State private var isConverting = false // New state variable for conversion status
    @State private var isDragTargeted = false
    
    private let downloader = WhisperModelDownloader()
    
    var body: some View {
        VStack(spacing: 24) {
            // Model & Language Selection Group
            GroupBox {
                HStack(spacing: 16) {
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
                        .onChange(of: selectedLanguage) {oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.selectedLanguage)
                        }
                    }
                }
                .padding(8)
            } label: {
                Label("Configuration", systemImage: "gearshape")
            }
            
            // Audio File Selection Group
            GroupBox {
                VStack(spacing: 16) {
                    let dropDelegate = AudioDropDelegate(audioFileBinding: $audioFileURL, isTargeted: $isDragTargeted)
                    
                    if let url = audioFileURL {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundStyle(.blue)
                                
                            Text(url.lastPathComponent)
                            Spacer()
                            Button(action: { audioFileURL = nil }) {
                                Image(systemName: "xmark.circle.fill")
                            }
                        }
                        .padding(.top, 8)
                    }else{
                        ZStack {
                            VStack {
                                Image(systemName: "arrow.down.doc")
                                    .font(.largeTitle)
                                    .padding(.bottom, 4)
                                Text("Drop audio file here")
                                    .font(.headline)
                                Text("or")
                                Button("Choose File") {
                                    showFileChooser = true
                                }
                                .padding(.top, 1)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity)
                        }
                        .modifier(DragDropStyle(isTargeted: isDragTargeted))
                        .onDrop(
                            of: supportedAudioTypes,
                            delegate: AudioDropDelegate(
                                audioFileBinding: $audioFileURL,
                                isTargeted: $isDragTargeted
                            )
                        )
                    }
                }
            }
            
            // Transcription Controls
            GroupBox {
                VStack(spacing: 16) {
                    HStack {
                        if isConverting || coordinator.isTranscribing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .help("Processing in progress...")
                                    
                                Text(isConverting ? "Converting..." : "\(Int(coordinator.transcriptionProgress * 100))%")
                                    .foregroundColor(.secondary)
                                    .help("Current progress")
                            }
                        }else {
                            Text("Tips: Select a model and audio file, then click 'Start Transcription' to begin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 4)
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
                        .help(selectedModelPath == nil ? "Please select a model first" :
                            audioFileURL == nil ? "Please select an audio file first" :
                            coordinator.isTranscribing ? "Click to stop transcription" : "Click to start transcription")
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
                    .help("Transcription control options")
            }
            
            // Results Section
            GroupBox {
                VStack(spacing: 16){
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
        
        isConverting = true
        
        Task {
            do {
                let pcmArray = try await convertAudioFileToPCMArray(fileURL: audioURL)
                
                await MainActor.run {
                    isConverting = false
                    coordinator.startTranscription(
                        modelPath: modelPath,
                        audioData: pcmArray,
                        language: selectedLanguage
                    )
                }
            } catch {
                await MainActor.run {
                    isConverting = false
                    coordinator.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func downloadSegments() {
        let segmentsText = coordinator.segments.map { $0.text }.joined(separator: "\n")
        let fileName = audioFileURL?.lastPathComponent.replacingOccurrences(of: ".", with: "_") ?? "Transcription"
        let fileName = "\(fileName)_transcription.txt"
        
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
