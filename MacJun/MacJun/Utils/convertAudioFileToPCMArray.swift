//
//  convertAudioFileToPCMArray.swift
//  Jun
//
//  Created by Jiacheng Mao on 2024/11/3.
//

import Foundation
import AudioKit

enum AudioConversionError: Error {
    case dataReadError
    case conversionFailed(Error)
    case tempFileCreationError
}

func convertAudioFileToPCMArray(fileURL: URL) async throws -> [Float] {
    var options = FormatConverter.Options()
    options.format = .wav
    options.sampleRate = 16000
    options.bitDepth = 16
    options.channels = 1
    options.isInterleaved = false
    
    // Add .wav extension to temp file
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("wav")
    
    return try await withCheckedThrowingContinuation { continuation in
        let converter = FormatConverter(inputURL: fileURL, outputURL: tempURL, options: options)
        
        Task.detached {
            defer {
                // Ensure cleanup happens even if there's an error
                try? FileManager.default.removeItem(at: tempURL)
            }
            
            do {
                try await withCheckedThrowingContinuation { (innerContinuation: CheckedContinuation<Void, Error>) in
                    converter.start { error in
                        if let error = error {
                            innerContinuation.resume(throwing: AudioConversionError.conversionFailed(error))
                        } else {
                            innerContinuation.resume()
                        }
                    }
                }
                
                guard let data = try? Data(contentsOf: tempURL) else {
                    throw AudioConversionError.dataReadError
                }
                
                let floats = stride(from: 44, to: data.count, by: 2).map {
                    return data[$0..<$0 + 2].withUnsafeBytes {
                        let short = Int16(littleEndian: $0.load(as: Int16.self))
                        return max(-1.0, min(Float(short) / 32767.0, 1.0))
                    }
                }
                
                continuation.resume(returning: floats)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
