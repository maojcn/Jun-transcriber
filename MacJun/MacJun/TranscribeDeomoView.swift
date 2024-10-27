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
                    Button("Transcribe", action: {
                        Task {
                            await whisperState.transcribeSample()
                        }
                    })
                    .buttonStyle(.bordered)
                    .disabled(!whisperState.isModelLoaded) // Bind the disabled state to isModelLoaded
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
}

#Preview {
    TranscribeDeomoView(whisperState: WhisperState(modelName: "tiny.en"), selectedModelName: .constant("tiny.en"), downloader: WhisperModelDownloader())
}
