//
//  TranscribeDeomoView.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/27.
//

import SwiftUI

struct TranscribeDeomoView: View {
    @StateObject var whisperState: WhisperState
    @Binding var selectedModelName: String
    let downloader: WhisperModelDownloader
    
    @State private var inputFiles: [URL] = []
    @State private var message: String?
    @State private var loading = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Select Model", selection: $selectedModelName) {
                    ForEach(downloader.availableModels, id: \.self) { modelName in
                        if downloader.isModelDownloaded(modelName) {
                            Text(modelName).tag(modelName)
                        }
                    }
                }
                .pickerStyle(.menu)
                .padding(.bottom)
                
                HStack {
                    Button("Select Files", action: {
                        self.selectFiles()
                    })
                    .buttonStyle(.bordered)
                    
                    Button("Transcribe", action: {
                        Task {
                            await self.transcribeFiles()
                        }
                    })
                    .buttonStyle(.bordered)
                    .disabled(!whisperState.isModelLoaded || inputFiles.isEmpty)
                }
                
                if let message = self.message {
                    Text("\(message)")
                        .foregroundColor(Color.red)
                }
                
                ScrollView {
                    Text(verbatim: whisperState.messageLog)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Whisper SwiftUI Demo")
            .padding()
        }
    }
    
    func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio]
        
        if panel.runModal() == .OK {
            self.inputFiles = panel.urls
        }
    }
    
    func transcribeFiles() async {
        self.loading = true
        self.message = "Converting and transcribing files..."
        
        let totalCount = self.inputFiles.count
        var finishedCount = 0
        
        for url in inputFiles {
            if !self.loading {
                break
            }
            
            // Convert file to .wav
            let convertedURL = await convertFile(url)
            if let convertedURL = convertedURL {
                // Transcribe the converted file
                await whisperState.transcribeAudio(convertedURL)
            }
            
            finishedCount += 1
            self.message = "Converting and transcribing \(finishedCount)/\(totalCount) ..."
        }
        
        self.loading = false
        self.message = "Done"
    }
    
    func convertFile(_ url: URL) async -> URL? {
        let ffmpegPath = Bundle.main.url(forResource: "ffmpeg", withExtension: "")!.path
        let downloadFolderURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        
        var outputFile = url.lastPathComponent
        let index = outputFile.index(outputFile.endIndex, offsetBy: -3)
        outputFile = outputFile[..<index] + "wav"
        let outputPath = downloadFolderURL.appendingPathComponent(outputFile).path
        
        let result = shell(ffmpegPath, ["-y", "-i", url.path, "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", outputPath])
        
        if result != nil {
            return URL(fileURLWithPath: outputPath)
        } else {
            return nil
        }
    }
    
    func shell(_ launchPath: String, _ arguments: [String]) -> String? {
        print("\(launchPath) \(arguments.joined(separator: " "))")
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        return output
    }
}

#Preview {
    TranscribeDeomoView(whisperState: WhisperState(modelName: "tiny.en"), selectedModelName: .constant("tiny.en"), downloader: WhisperModelDownloader())
}
