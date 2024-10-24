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
    
    init() {
        do {
            try loadResources()
            try loadModel()
            canTranscribe = true
        } catch {
            print(error.localizedDescription)
            messageLog += "\(error.localizedDescription)\n"
        }
    }
    
    private func loadResources() throws {
        modelUrl = Bundle.main.url(forResource: "ggml-base.en", withExtension: "bin")
        sampleUrl = Bundle.main.url(forResource: "jfk", withExtension: "wav")
        
        if modelUrl == nil {
            throw LoadError.couldNotLocateModel
        }
        if sampleUrl == nil {
            throw LoadError.couldNotLocateSample
        }
    }
    
    private func loadModel() throws {
        guard let modelUrl = modelUrl else {
            throw LoadError.couldNotLocateModel
        }
        
        messageLog += "Loading model...\n"
        whisperContext = try WhisperContext.createContext(path: modelUrl.path())
        messageLog += "Loaded model \(modelUrl.lastPathComponent)\n"
        isModelLoaded = true
    }
    
    func transcribeSample() async {
        guard let sampleUrl = sampleUrl else {
            messageLog += "Could not locate sample\n"
            return
        }
        
        await transcribeAudio(sampleUrl)
    }
    
    private func transcribeAudio(_ url: URL) async {
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
        } catch {
            print(error.localizedDescription)
            messageLog += "\(error.localizedDescription)\n"
        }
        
        canTranscribe = true
    }
    
    private func readAudioSamples(_ url: URL) throws -> [Float] {
        return try decodeWaveFile(url)
    }
}
