//
//  WhisperModelRowView.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/24.
//

import SwiftUI

struct WhisperModelRowView: View {
    let model: WhisperModel
    let downloader: WhisperModelDownloader
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(model.name)
                    .font(.headline)
                if model.downloadStatus == .downloading {
                    ProgressView(value: model.downloadProgress)
                        .progressViewStyle(.linear)
                }
            }
            
            Spacer()
            
            switch model.downloadStatus {
            case .notStarted:
                Button("Download") {
                    downloader.downloadModel(model)
                }
            case .downloading:
                Button("Cancel") {
                    downloader.cancelDownload(model)
                }
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Button("Retry") {
                    downloader.downloadModel(model)
                }
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WhisperModelRowView(model: WhisperModel(name: "Tiny"), downloader: WhisperModelDownloader())
}
