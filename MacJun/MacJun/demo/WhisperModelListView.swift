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
    
    var body: some View {
        List(models) { model in
            WhisperModelRowView(model: model, downloader: downloader)
        }
        .onAppear {
            if models.isEmpty {
                // Initialize models if none exist
                for modelName in downloader.availableModels {
                    let model = WhisperModel(name: modelName)
                    modelContext.insert(model)
                }
            }
        }
    }
}

#Preview {
    WhisperModelListView()
}
