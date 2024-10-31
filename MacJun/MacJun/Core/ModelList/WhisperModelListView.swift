//
//  WhisperModelListView.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import SwiftUI
import SwiftData

extension View {
    func customSectionHeader() -> some View {
        self
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.6))
            )
    }
}

struct WhisperModelListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var models: [WhisperModel]
    @State private var downloader = WhisperModelDownloader()
    
    // Define model order within each section
    private let modelOrders: [String: [String]] = [
        "Tiny": ["tiny", "tiny.en", "tiny-q5_1", "tiny.en-q5_1"],
        "Base": ["base", "base.en", "base-q5_1", "base.en-q5_1"],
        "Small": ["small", "small.en", "small.en-tdrz", "small-q5_1", "small.en-q5_1"],
        "Medium": ["medium", "medium.en", "medium-q5_0", "medium.en-q5_0"],
        "Large": ["large-v1", "large-v2", "large-v2-q5_0", "large-v3", "large-v3-q5_0", "large-v3-turbo", "large-v3-turbo-q5_0"]
    ]
    
    var orderedSections: [String] {
        ["Tiny", "Base", "Small", "Medium", "Large"]
    }
    
    var groupedModels: [String: [WhisperModel]] {
        let grouped = Dictionary(grouping: models) { model in
            switch model.name {
            case let name where modelOrders["Tiny"]?.contains(name) ?? false:
                return "Tiny"
            case let name where modelOrders["Base"]?.contains(name) ?? false:
                return "Base"
            case let name where modelOrders["Small"]?.contains(name) ?? false:
                return "Small"
            case let name where modelOrders["Medium"]?.contains(name) ?? false:
                return "Medium"
            case let name where modelOrders["Large"]?.contains(name) ?? false:
                return "Large"
            default:
                return "Other"
            }
        }
        
        // Sort models within each group
        return grouped.mapValues { modelsInGroup in
            modelsInGroup.sorted { model1, model2 in
                // Get the category for the current model
                let category = grouped.first { $0.value.contains(model1) }?.key ?? ""
                // Get the ordering array for that category
                if let orderArray = modelOrders[category],
                   let index1 = orderArray.firstIndex(of: model1.name),
                   let index2 = orderArray.firstIndex(of: model2.name) {
                    return index1 < index2
                }
                return model1.name < model2.name
            }
        }
    }
    
    var body: some View {
       ScrollView {
            LazyVStack(spacing: 16) {
                // First show ordered sections
                ForEach(orderedSections, id: \.self) { group in
                    if let models = groupedModels[group] {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group)
                                .customSectionHeader()
                            
                            ForEach(models, id: \.id) { model in
                                WhisperModelRowView(model: model, downloader: downloader)
                                    .contextMenu {
                                        Button(action: {
                                            downloader.deleteModel(model)
                                        }) {
                                            Label("Delete Model", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                
                // Then show any remaining "Other" models
                if let otherModels = groupedModels["Other"] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Other")
                            .customSectionHeader()
                        
                        ForEach(otherModels, id: \.id) { model in
                            WhisperModelRowView(model: model, downloader: downloader)
                                .contextMenu {
                                    Button(action: {
                                        downloader.deleteModel(model)
                                    }) {
                                        Label("Delete Model", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.textBackgroundColor).opacity(0.5))
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
