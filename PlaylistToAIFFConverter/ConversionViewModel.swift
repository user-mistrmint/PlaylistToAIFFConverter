import Foundation
import SwiftUI
import PlaylistParser
import AudioConverter
import FileLocator

@MainActor
class ConversionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var playlist: Playlist?
    @Published var fileResults: [FileLocationResult] = []
    @Published var conversionResults: [AudioConversionResult] = []
    
    @Published var isLoadingPlaylist = false
    @Published var isLocatingFiles = false
    @Published var isConverting = false
    
    @Published var conversionProgress: Double = 0.0
    @Published var completedConversions = 0
    @Published var totalConversions = 0
    @Published var currentConversionStatus = ""
    
    @Published var outputFormat: AudioFormat = .aiff
    @Published var quality: ConversionQuality = .high
    @Published var outputDirectory = NSHomeDirectory() + "/Music/Converted"
    
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // MARK: - Private Properties
    
    private let playlistParser = PlaylistParser()
    private let fileLocator = FileLocator()
    private let audioConverter = AudioConverter()
    
    private var conversionTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    var hasPlaylist: Bool {
        return playlist != nil
    }
    
    var canStartConversion: Bool {
        return hasPlaylist && !fileResults.isEmpty && !isConverting && fileResults.contains { $0.isFound }
    }
    
    // MARK: - Public Methods
    
    func loadPlaylist(from url: URL) {
        isLoadingPlaylist = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await playlistParser.parse(from: url)
                
                if result.isSuccessful, let playlist = result.playlist {
                    self.playlist = playlist
                    self.fileResults = []
                    self.conversionResults = []
                } else {
                    let errorMessages = result.errors.map { $0.localizedDescription }.joined(separator: "\n")
                    self.errorMessage = "Failed to parse playlist:\n\(errorMessages)"
                    self.showingError = true
                }
            } catch {
                self.errorMessage = "Error loading playlist: \(error.localizedDescription)"
                self.showingError = true
            }
            
            self.isLoadingPlaylist = false
        }
    }
    
    func locateFiles() {
        guard let playlist = playlist else { return }
        
        isLocatingFiles = true
        fileResults = []
        
        Task {
            let results = await fileLocator.locateFiles(for: playlist.tracks) { completed, total in
                // Update progress if needed
            }
            
            self.fileResults = results
            self.isLocatingFiles = false
        }
    }
    
    func startConversion() {
        guard canStartConversion else { return }
        
        isConverting = true
        conversionProgress = 0.0
        completedConversions = 0
        conversionResults = []
        
        let foundFiles = fileResults.compactMap { result -> (String, String)? in
            guard let resolvedPath = result.resolvedPath else { return nil }
            
            let inputPath = resolvedPath
            let filename = URL(fileURLWithPath: inputPath).deletingPathExtension().lastPathComponent
            let outputPath = "\(outputDirectory)/\(filename).\(outputFormat.fileExtension)"
            
            return (inputPath, outputPath)
        }
        
        totalConversions = foundFiles.count
        
        conversionTask = Task {
            let settings = AudioConversionSettings(
                outputFormat: outputFormat,
                quality: quality
            )
            
            let results = await audioConverter.convertFiles(
                conversions: foundFiles,
                settings: settings,
                maxConcurrentOperations: 2
            ) { completed, total, fileProgress in
                self.completedConversions = completed
                self.conversionProgress = Double(completed) / Double(total)
                self.currentConversionStatus = "Converting file \(completed) of \(total)..."
            }
            
            self.conversionResults = results
            self.isConverting = false
            self.currentConversionStatus = "Conversion completed"
            
            // Show summary
            let successful = results.filter { $0.success }.count
            let failed = results.count - successful
            
            if failed == 0 {
                self.currentConversionStatus = "Successfully converted \(successful) files"
            } else {
                self.currentConversionStatus = "Converted \(successful) files, \(failed) failed"
            }
        }
    }
    
    func cancelConversion() {
        conversionTask?.cancel()
        audioConverter.cancelAllConversions()
        isConverting = false
        currentConversionStatus = "Conversion cancelled"
    }
    
    func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url.path
        }
    }
    
    func retryFailedConversions() {
        let failedResults = conversionResults.filter { !$0.success }
        guard !failedResults.isEmpty else { return }
        
        // Implement retry logic for failed conversions
        // This would re-attempt conversion for files that failed
    }
    
    func openOutputDirectory() {
        let url = URL(fileURLWithPath: outputDirectory)
        NSWorkspace.shared.open(url)
    }
    
    func exportConversionReport() {
        let report = generateConversionReport()
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "conversion_report.txt"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try report.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                errorMessage = "Failed to save report: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func generateConversionReport() -> String {
        var report = "iTunes Playlist to AIFF Conversion Report\n"
        report += "Generated: \(Date())\n\n"
        
        if let playlist = playlist {
            report += "Playlist: \(playlist.name)\n"
            report += "Total tracks: \(playlist.tracks.count)\n"
            report += "Total duration: \(formatDuration(playlist.totalDuration))\n\n"
        }
        
        report += "File Location Results:\n"
        for result in fileResults {
            report += "- \(URL(fileURLWithPath: result.originalPath).lastPathComponent): "
            if result.isFound {
                report += "Found (\(result.method.description))\n"
            } else {
                report += "Not found\n"
            }
        }
        
        report += "\nConversion Results:\n"
        let successful = conversionResults.filter { $0.success }
        let failed = conversionResults.filter { !$0.success }
        
        report += "Successful: \(successful.count)\n"
        report += "Failed: \(failed.count)\n\n"
        
        if !failed.isEmpty {
            report += "Failed conversions:\n"
            for result in failed {
                report += "- \(URL(fileURLWithPath: result.inputPath).lastPathComponent): "
                report += result.error?.localizedDescription ?? "Unknown error"
                report += "\n"
            }
        }
        
        return report
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Extensions

extension ConversionViewModel {
    func addCustomSearchPath(_ path: String) {
        fileLocator.addSearchPath(path)
    }
    
    func learnFromFileCorrection(originalPath: String, correctedPath: String) {
        fileLocator.learnFromCorrection(originalPath: originalPath, correctedPath: correctedPath)
    }
}

