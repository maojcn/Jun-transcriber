//
//  AudioConverter.swift
//  MacJun
//
//  Created by Jiacheng Mao on 2024/10/29.
//

import Foundation

class AudioConverter {
    /// Converts an audio file to the desired format using ffmpeg.
    /// - Parameter audioFile: The URL of the input audio file.
    /// - Returns: The URL of the converted audio file.
    /// - Throws: An error if the conversion fails.
    static func convert(audioFile: URL) throws -> URL {
        // Define the output file format and path in the temporary directory
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputFile = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("wav")
        let outputPath = outputFile.path
        
        // Define the ffmpeg command and arguments
        let ffmpegPath = Bundle.main.url(forResource: "ffmpeg", withExtension: "")!.path
        let arguments = ["-y", "-i", audioFile.path, "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", outputPath]
        
        // Execute the ffmpeg command
        let output = shell(ffmpegPath, arguments)
        
        // Check if the output file was created successfully
        if FileManager.default.fileExists(atPath: outputPath) {
            return outputFile
        } else {
            throw AudioConversionError.conversionFailed(message: output ?? "Unknown error")
        }
    }
    
    /// Executes a shell command.
    /// - Parameters:
    ///   - launchPath: The path to the executable.
    ///   - arguments: The arguments to pass to the executable.
    /// - Returns: The output of the command as a string, or nil if the command fails.
    private static func shell(_ launchPath: String, _ arguments: [String]) -> String? {
        print("\(launchPath) \(arguments.joined(separator: " "))")
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        return output
    }
    
    /// Deletes the temporary file after the conversion.
    /// - Parameter fileURL: The URL of the temporary file to delete.
    static func cleanup(fileURL: URL) {
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Failed to delete temporary file: \(error)")
        }
    }
}

/// Errors that can occur during audio conversion.
enum AudioConversionError: Error {
    case conversionFailed(message: String)
}
