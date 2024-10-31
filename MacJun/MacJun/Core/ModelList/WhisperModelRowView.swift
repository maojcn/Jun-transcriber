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
        HStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.blue.gradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.system(.body, design: .rounded))
                
                if model.downloadStatus == .downloading {
                    HStack {
                        ProgressView(value: model.downloadProgress)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 120)
                        Text("\(Int(model.downloadProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                switch model.downloadStatus {
                case .notStarted:
                    Button(action: { downloader.downloadModel(model) }) {
                        Label("Download", systemImage: "arrow.down.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                case .downloading:
                    Button(action: { downloader.cancelDownload(model) }) {
                        Label("Cancel", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.orange)
                    
                case .completed:
                    HStack {
                        Button(action: { downloader.deleteModel(model) }) {
                            Image(systemName: "trash.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.red)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                    
                case .failed:
                    Button(action: { downloader.downloadModel(model) }) {
                        Label("Retry", systemImage: "arrow.clockwise.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.controlBackgroundColor))
                    .shadow(radius: 1))
        .help("Model: \(model.name)")
    }
}

#Preview {
    WhisperModelRowView(model: WhisperModel(name: "Tiny"), downloader: WhisperModelDownloader())
}
