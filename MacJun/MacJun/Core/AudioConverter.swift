import Foundation

class AudioConverter {
    static func convert(audioFile url: URL) throws -> URL {
        let ffmpegPath = Bundle.main.url(forResource: "ffmpeg", withExtension: "")!.path
        let tempDir = FileManager.default.temporaryDirectory
        let outputFileName = url.deletingPathExtension().appendingPathExtension("wav").lastPathComponent
        let outputURL = tempDir.appendingPathComponent(outputFileName)
        
        // Remove existing file if any
        try? FileManager.default.removeItem(at: outputURL)
        
        // Convert audio using ffmpeg
        let arguments = [
            "-y",
            "-i", url.path,
            "-ar", "16000",
            "-ac", "1",
            "-c:a", "pcm_s16le",
            outputURL.path
        ]
        
        let task = Process()
        task.launchPath = ffmpegPath
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        try task.run()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            throw NSError(domain: "AudioConverter", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to convert audio file"
            ])
        }
        
        return outputURL
    }
}