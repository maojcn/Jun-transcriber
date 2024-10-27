//
//  WhisperState.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import Foundation
import SwiftUI

@MainActor
class WhisperState: ObservableObject {
    @Published var isModelLoaded = false
    @Published var messageLog = ""
    @Published var canTranscribe = false
    
    private var whisperContext: WhisperContext?
    private var modelUrl: URL?
    private var sampleUrl: URL?
    
    private enum LoadError: Error {
        case couldNotLocateModel
        case couldNotLocateSample
    }
    
    init(modelName: String) {
        do {
            try loadResources()
            try loadModel(modelName: modelName)
            canTranscribe = true
        } catch {
            print(error.localizedDescription)
            messageLog += "\(error.localizedDescription)\n"
        }
    }
    
    private func loadResources() throws {
        sampleUrl = Bundle.main.url(forResource: "jfk", withExtension: "wav")
        
        if sampleUrl == nil {
            throw LoadError.couldNotLocateSample
        }
    }
    
    func loadModel(modelName: String) {
        guard let modelStoragePath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("WhisperModels", isDirectory: true) else {
            messageLog += "Could not locate model storage path\n"
            return
        }
        
        let modelPath = modelStoragePath.appendingPathComponent("ggml-\(modelName).bin")
        if !FileManager.default.fileExists(atPath: modelPath.path) {
            messageLog += "Model \(modelName) not found\n"
            return
        }
        
        do {
            messageLog += "Loading model...\n"
            whisperContext = try WhisperContext.createContext(path: modelPath.path)
            messageLog += "Loaded model \(modelName)\n"
            isModelLoaded = true
        } catch {
            print(error.localizedDescription)
            messageLog += "\(error.localizedDescription)\n"
        }
    }
    
    func transcribeSample() async {
        guard let sampleUrl = sampleUrl else {
            messageLog += "Could not locate sample\n"
            return
        }
        
        await transcribeAudio(sampleUrl)
    }
    
    func transcribeAudio(_ url: URL) async {
        guard canTranscribe, let whisperContext = whisperContext else {
            return
        }
        
        do {
            canTranscribe = false
            messageLog += "Reading wave samples...\n"
            let data = try readAudioSamples(url)
            messageLog += "Transcribing data...\n"
            await whisperContext.fullTranscribe(samples: data)
            let text = await whisperContext.getTranscription()
            messageLog += "Done: \(text)\n"
            
            // Save the transcription to the Downloads folder
            await saveTranscription(text, audioFileName: url.lastPathComponent)
        } catch {
            print(error.localizedDescription)
            messageLog += "\(error.localizedDescription)\n"
        }
        
        canTranscribe = true
    }
    
    private func readAudioSamples(_ url: URL) throws -> [Float] {
        return try decodeWaveFile(url)
    }
    
    private func saveTranscription(_ transcription: String, audioFileName: String) async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        
        let fileName = "\(audioFileName)_\(dateString).txt"
        let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let fileURL = downloadsDirectory.appendingPathComponent(fileName)
        
        do {
            try transcription.write(to: fileURL, atomically: true, encoding: .utf8)
            messageLog += "Transcription saved to \(fileURL.path)\n"
        } catch {
            print("Failed to save transcription: \(error.localizedDescription)")
            messageLog += "Failed to save transcription: \(error.localizedDescription)\n"
        }
    }
}
