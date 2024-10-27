//
//  WhisperModelListView.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import SwiftUI
import SwiftData

struct WhisperModelListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var models: [WhisperModel]
    @State private var downloader = WhisperModelDownloader()
    
    var groupedModels: [String: [WhisperModel]] {
        Dictionary(grouping: models, by: {
            switch $0.name {
            case "tiny", "tiny.en", "tiny-q5_1", "tiny.en-q5_1":
                return "Tiny"
            case "base", "base.en", "base-q5_1", "base.en-q5_1":
                return "Base"
            case "small", "small.en", "small.en-tdrz", "small-q5_1", "small.en-q5_1":
                return "Small"
            case "medium", "medium.en", "medium-q5_0", "medium.en-q5_0":
                return "Medium"
            case "large-v1", "large-v2", "large-v2-q5_0", "large-v3", "large-v3-q5_0", "large-v3-turbo", "large-v3-turbo-q5_0":
                return "Large"
            default:
                return "Other"
            }
        })
    }
    
    var orderedSections: [String] {
        ["Tiny", "Base", "Small", "Medium", "Large"]
    }
    
    var body: some View {
        List {
            ForEach(orderedSections, id: \.self) { section in
                if let modelsInSection = groupedModels[section] {
                    Section(header: Text(section)) {
                        ForEach(modelsInSection.sorted(by: { downloader.availableModels.firstIndex(of: $0.name)! < downloader.availableModels.firstIndex(of: $1.name)! })) { model in
                            WhisperModelRowView(model: model, downloader: downloader)
                        }
                    }
                }
            }
        }
        .onAppear {
            if models.isEmpty {
                // Initialize models if none exist
                for modelName in downloader.availableModels {
                    let isDownloaded = downloader.isModelDownloaded(modelName)
                    let model = WhisperModel(name: modelName, isDownloaded: isDownloaded)
                    modelContext.insert(model)
                }
            } else {
                // Update existing models with download status and local path
                for model in models {
                    let isDownloaded = downloader.isModelDownloaded(model.name)
                    model.downloadStatus = isDownloaded ? .completed : .notStarted
                    model.downloadProgress = isDownloaded ? 1.0 : 0.0
                    model.localPath = isDownloaded ? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("WhisperModels/ggml-\(model.name).bin").path : nil
                }
            }
        }
    }
}

#Preview {
    WhisperModelListView()
}
