//
//  WhisperModelDownloader.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import Foundation

class WhisperModelDownloader: ObservableObject {
    private let baseURL = "https://huggingface.co/ggerganov/whisper.cpp"
    private let tinyDiarizeURL = "https://huggingface.co/akashmjn/tinydiarize-whisper.cpp"
    private let urlPrefix = "resolve/main/ggml"
    
    var availableModels = [
        "tiny", "tiny.en", "tiny-q5_1", "tiny.en-q5_1",
        "base", "base.en", "base-q5_1", "base.en-q5_1",
        "small", "small.en", "small.en-tdrz", "small-q5_1", "small.en-q5_1",
        "medium", "medium.en", "medium-q5_0", "medium.en-q5_0",
        "large-v1", "large-v2", "large-v2-q5_0", "large-v3",
        "large-v3-q5_0", "large-v3-turbo", "large-v3-turbo-q5_0"
    ]
    
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var progressObservers: [String: NSKeyValueObservation] = [:]
    private let modelStoragePath: URL
    
    init() {
        // Get the application support directory for storing models
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            modelStoragePath = appSupport.appendingPathComponent("WhisperModels", isDirectory: true)
            try? FileManager.default.createDirectory(at: modelStoragePath, withIntermediateDirectories: true)
        } else {
            fatalError("Cannot access application support directory")
        }
    }
    
    func downloadModel(_ model: WhisperModel) {
        guard model.downloadStatus != .downloading else { return }
        
        let baseURLString = model.name.contains("tdrz") ? tinyDiarizeURL : baseURL
        guard let url = URL(string: "\(baseURLString)/\(urlPrefix)-\(model.name).bin") else { return }
        
        let session = URLSession(configuration: .default)
        let task = session.downloadTask(with: url) { [weak self] tempURL, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Download error: \(error.localizedDescription)")
                    model.downloadStatus = .failed
                    return
                }
                
                guard let tempURL = tempURL else {
                    model.downloadStatus = .failed
                    return
                }
                
                let destinationURL = self?.modelStoragePath.appendingPathComponent("ggml-\(model.name).bin")
                guard let destinationURL = destinationURL else {
                    model.downloadStatus = .failed
                    return
                }
                
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    model.downloadStatus = .completed
                    model.localPath = destinationURL.path
                } catch {
                    print("File error: \(error.localizedDescription)")
                    model.downloadStatus = .failed
                }
            }
        }
        
        // Add progress observation
        let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                model.downloadProgress = progress.fractionCompleted
            }
        }
        progressObservers[model.name] = observation
        
        model.downloadStatus = .downloading
        downloadTasks[model.name] = task
        task.resume()
    }
    
    func cancelDownload(_ model: WhisperModel) {
        downloadTasks[model.name]?.cancel()
        downloadTasks[model.name] = nil
        progressObservers[model.name]?.invalidate()
        progressObservers[model.name] = nil
        model.downloadStatus = .notStarted
        model.downloadProgress = 0
    }
    
    func deleteModel(_ model: WhisperModel) {
        guard let localPath = model.localPath else { return }
        let modelPath = modelStoragePath.appendingPathComponent("ggml-\(model.name).bin")
        do {
            try FileManager.default.removeItem(at: modelPath)
            model.downloadStatus = .notStarted
            model.localPath = nil
        } catch {
            print("Delete error: \(error.localizedDescription)")
        }
    }
    
    func isModelDownloaded(_ modelName: String) -> Bool {
        let modelPath = modelStoragePath.appendingPathComponent("ggml-\(modelName).bin")
        return FileManager.default.fileExists(atPath: modelPath.path)
    }
}
