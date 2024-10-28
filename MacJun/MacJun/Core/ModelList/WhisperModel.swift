//
//  WhisperModel.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import SwiftData
import Foundation

@Model
final class WhisperModel {
    var id: String
    var name: String
    var size: Int64
    var downloadStatus: DownloadStatus
    var downloadProgress: Double
    var localPath: String?
    
    init(name: String, isDownloaded: Bool = false) {
        self.id = UUID().uuidString
        self.name = name
        self.size = 0
        self.downloadStatus = isDownloaded ? .completed : .notStarted
        self.downloadProgress = isDownloaded ? 1.0 : 0.0
        self.localPath = isDownloaded ? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("WhisperModels/ggml-\(name).bin").path : nil
    }
}

enum DownloadStatus: String, Codable {
    case notStarted
    case downloading
    case completed
    case failed
}
