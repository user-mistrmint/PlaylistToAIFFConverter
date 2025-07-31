import Foundation
import AVFoundation

// MARK: - Audio Conversion Models

/// Configuration for audio conversion
public struct AudioConversionSettings {
    public let outputFormat: AudioFormat
    public let sampleRate: Double
    public let bitDepth: Int
    public let channels: Int
    public let quality: ConversionQuality
    public let preserveMetadata: Bool
    
    public init(
        outputFormat: AudioFormat = .aiff,
        sampleRate: Double = 44100.0,
        bitDepth: Int = 16,
        channels: Int = 2,
        quality: ConversionQuality = .high,
        preserveMetadata: Bool = true
    ) {
        self.outputFormat = outputFormat
        self.sampleRate = sampleRate
        self.bitDepth = bitDepth
        self.channels = channels
        self.quality = quality
        self.preserveMetadata = preserveMetadata
    }
    
    /// Traktor Pro 4 optimized settings
    public static let traktorOptimized = AudioConversionSettings(
        outputFormat: .aiff,
        sampleRate: 44100.0,
        bitDepth: 16,
        channels: 2,
        quality: .high,
        preserveMetadata: true
    )
}

/// Supported audio formats
public enum AudioFormat: String, CaseIterable {
    case aiff = "aiff"
    case wav = "wav"
    case mp3 = "mp3"
    case m4a = "m4a"
    case flac = "flac"
    
    public var fileExtension: String {
        return rawValue
    }
    
    public var description: String {
        switch self {
        case .aiff:
            return "AIFF (Audio Interchange File Format)"
        case .wav:
            return "WAV (Waveform Audio File Format)"
        case .mp3:
            return "MP3 (MPEG Audio Layer III)"
        case .m4a:
            return "M4A (MPEG-4 Audio)"
        case .flac:
            return "FLAC (Free Lossless Audio Codec)"
        }
    }
}

/// Conversion quality settings
public enum ConversionQuality {
    case low
    case medium
    case high
    case maximum
    
    public var description: String {
        switch self {
        case .low:
            return "Low (Fast conversion)"
        case .medium:
            return "Medium (Balanced)"
        case .high:
            return "High (Recommended)"
        case .maximum:
            return "Maximum (Slow but best quality)"
        }
    }
}

/// Result of audio conversion
public struct AudioConversionResult {
    public let inputPath: String
    public let outputPath: String?
    public let success: Bool
    public let error: AudioConversionError?
    public let duration: TimeInterval
    public let inputFormat: String?
    public let outputSize: Int64?
    
    public init(
        inputPath: String,
        outputPath: String? = nil,
        success: Bool,
        error: AudioConversionError? = nil,
        duration: TimeInterval = 0,
        inputFormat: String? = nil,
        outputSize: Int64? = nil
    ) {
        self.inputPath = inputPath
        self.outputPath = outputPath
        self.success = success
        self.error = error
        self.duration = duration
        self.inputFormat = inputFormat
        self.outputSize = outputSize
    }
}

/// Errors that can occur during audio conversion
public enum AudioConversionError: Error, LocalizedError {
    case fileNotFound(String)
    case unsupportedFormat(String)
    case conversionFailed(String)
    case outputPathError(String)
    case metadataError(String)
    case insufficientSpace
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Audio file not found: \(path)"
        case .unsupportedFormat(let format):
            return "Unsupported audio format: \(format)"
        case .conversionFailed(let reason):
            return "Conversion failed: \(reason)"
        case .outputPathError(let path):
            return "Cannot write to output path: \(path)"
        case .metadataError(let details):
            return "Metadata processing error: \(details)"
        case .insufficientSpace:
            return "Insufficient disk space for conversion"
        case .cancelled:
            return "Conversion was cancelled"
        }
    }
}

// MARK: - Audio Converter

/// Main audio converter class
public class AudioConverter {
    private let fileManager = FileManager.default
    private var activeConversions: [String: Task<AudioConversionResult, Never>] = [:]
    
    public init() {}
    
    /// Convert a single audio file
    public func convertFile(
        inputPath: String,
        outputPath: String,
        settings: AudioConversionSettings = .traktorOptimized,
        progressHandler: @escaping (Double) -> Void = { _ in }
    ) async -> AudioConversionResult {
        let startTime = Date()
        
        // Validate input file
        guard fileManager.fileExists(atPath: inputPath) else {
            return AudioConversionResult(
                inputPath: inputPath,
                success: false,
                error: .fileNotFound(inputPath)
            )
        }
        
        // Create output directory if needed
        let outputDir = URL(fileURLWithPath: outputPath).deletingLastPathComponent().path
        do {
            try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
        } catch {
            return AudioConversionResult(
                inputPath: inputPath,
                success: false,
                error: .outputPathError("Cannot create output directory: \(error.localizedDescription)")
            )
        }
        
        // Perform conversion
        do {
            let result = try await performConversion(
                inputPath: inputPath,
                outputPath: outputPath,
                settings: settings,
                progressHandler: progressHandler
            )
            
            let duration = Date().timeIntervalSince(startTime)
            let outputSize = try? fileManager.attributesOfItem(atPath: outputPath)[.size] as? Int64
            
            return AudioConversionResult(
                inputPath: inputPath,
                outputPath: outputPath,
                success: true,
                duration: duration,
                outputSize: outputSize
            )
        } catch let error as AudioConversionError {
            return AudioConversionResult(
                inputPath: inputPath,
                success: false,
                error: error,
                duration: Date().timeIntervalSince(startTime)
            )
        } catch {
            return AudioConversionResult(
                inputPath: inputPath,
                success: false,
                error: .conversionFailed(error.localizedDescription),
                duration: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    /// Convert multiple files with batch processing
    public func convertFiles(
        conversions: [(input: String, output: String)],
        settings: AudioConversionSettings = .traktorOptimized,
        maxConcurrentOperations: Int = 4,
        progressHandler: @escaping (Int, Int, Double) -> Void = { _, _, _ in }
    ) async -> [AudioConversionResult] {
        var results: [AudioConversionResult] = []
        let semaphore = AsyncSemaphore(value: maxConcurrentOperations)
        
        await withTaskGroup(of: (Int, AudioConversionResult).self) { group in
            for (index, conversion) in conversions.enumerated() {
                group.addTask {
                    await semaphore.wait()
                    defer { semaphore.signal() }
                    
                    let result = await self.convertFile(
                        inputPath: conversion.input,
                        outputPath: conversion.output,
                        settings: settings
                    ) { fileProgress in
                        progressHandler(index, conversions.count, fileProgress)
                    }
                    
                    return (index, result)
                }
            }
            
            for await (index, result) in group {
                results.append(result)
                progressHandler(index + 1, conversions.count, 1.0)
            }
        }
        
        return results.sorted { $0.inputPath < $1.inputPath }
    }
    
    /// Cancel all active conversions
    public func cancelAllConversions() {
        for (_, task) in activeConversions {
            task.cancel()
        }
        activeConversions.removeAll()
    }
    
    /// Get supported input formats
    public var supportedInputFormats: [String] {
        return ["mp3", "m4a", "aac", "wav", "aiff", "aif", "flac", "ogg"]
    }
    
    // MARK: - Private Methods
    
    private func performConversion(
        inputPath: String,
        outputPath: String,
        settings: AudioConversionSettings,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> Void {
        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath)
        
        // Try AVFoundation first (native macOS)
        do {
            try await convertWithAVFoundation(
                inputURL: inputURL,
                outputURL: outputURL,
                settings: settings,
                progressHandler: progressHandler
            )
            return
        } catch {
            // Fall back to FFmpeg if available
            try await convertWithFFmpeg(
                inputURL: inputURL,
                outputURL: outputURL,
                settings: settings,
                progressHandler: progressHandler
            )
        }
    }
    
    private func convertWithAVFoundation(
        inputURL: URL,
        outputURL: URL,
        settings: AudioConversionSettings,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        let asset = AVAsset(url: inputURL)
        
        // Check if asset is readable
        guard await asset.load(.isReadable) else {
            throw AudioConversionError.unsupportedFormat("Cannot read input file")
        }
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw AudioConversionError.conversionFailed("Cannot create export session")
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .aiff
        
        // Configure audio settings
        let audioSettings = createAudioSettings(settings)
        exportSession.audioMix = nil // Use default audio mix
        
        // Start export
        await exportSession.export()
        
        switch exportSession.status {
        case .completed:
            // Copy metadata if requested
            if settings.preserveMetadata {
                try await copyMetadata(from: inputURL, to: outputURL)
            }
        case .failed:
            throw AudioConversionError.conversionFailed(exportSession.error?.localizedDescription ?? "Unknown error")
        case .cancelled:
            throw AudioConversionError.cancelled
        default:
            throw AudioConversionError.conversionFailed("Export session failed with status: \(exportSession.status)")
        }
    }
    
    private func convertWithFFmpeg(
        inputURL: URL,
        outputURL: URL,
        settings: AudioConversionSettings,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        // This would use FFmpeg for conversion
        // For now, we'll throw an error indicating FFmpeg is not available
        throw AudioConversionError.conversionFailed("FFmpeg conversion not implemented in this demo")
    }
    
    private func createAudioSettings(_ settings: AudioConversionSettings) -> [String: Any] {
        var audioSettings: [String: Any] = [:]
        
        audioSettings[AVFormatIDKey] = kAudioFormatLinearPCM
        audioSettings[AVSampleRateKey] = settings.sampleRate
        audioSettings[AVNumberOfChannelsKey] = settings.channels
        audioSettings[AVLinearPCMBitDepthKey] = settings.bitDepth
        audioSettings[AVLinearPCMIsFloatKey] = false
        audioSettings[AVLinearPCMIsBigEndianKey] = true // AIFF uses big-endian
        audioSettings[AVLinearPCMIsNonInterleaved] = false
        
        return audioSettings
    }
    
    private func copyMetadata(from inputURL: URL, to outputURL: URL) async throws {
        let inputAsset = AVAsset(url: inputURL)
        let metadata = await inputAsset.load(.metadata)
        
        // This is a simplified metadata copy
        // In a full implementation, you would use AVAssetWriter to embed metadata
        // For now, we'll just log that metadata would be copied
        print("Would copy \(metadata.count) metadata items from \(inputURL.lastPathComponent)")
    }
}

// MARK: - Async Semaphore

/// Simple async semaphore implementation
private actor AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        self.value = value
    }
    
    func wait() async {
        if value > 0 {
            value -= 1
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }
    
    func signal() {
        if waiters.isEmpty {
            value += 1
        } else {
            let waiter = waiters.removeFirst()
            waiter.resume()
        }
    }
}

