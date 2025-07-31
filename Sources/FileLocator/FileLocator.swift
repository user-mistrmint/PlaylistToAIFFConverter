import Foundation
import PlaylistParser

// MARK: - File Location Result

/// Result of attempting to locate a file
public struct FileLocationResult {
    public let originalPath: String
    public let resolvedPath: String?
    public let confidence: Double // 0.0 to 1.0
    public let method: LocationMethod
    public let alternatives: [String] // Alternative paths found
    
    public init(originalPath: String, resolvedPath: String?, confidence: Double, method: LocationMethod, alternatives: [String] = []) {
        self.originalPath = originalPath
        self.resolvedPath = resolvedPath
        self.confidence = confidence
        self.method = method
        self.alternatives = alternatives
    }
    
    public var isFound: Bool {
        return resolvedPath != nil && confidence > 0.5
    }
}

/// Methods used to locate files
public enum LocationMethod {
    case exactPath
    case pathTranslation
    case filenameSearch
    case metadataMatch
    case userProvided
    case notFound
    
    public var description: String {
        switch self {
        case .exactPath:
            return "Found at exact path"
        case .pathTranslation:
            return "Found using path translation"
        case .filenameSearch:
            return "Found by filename search"
        case .metadataMatch:
            return "Found by metadata matching"
        case .userProvided:
            return "Manually located by user"
        case .notFound:
            return "File not found"
        }
    }
}

// MARK: - File Locator

/// Locates audio files referenced in playlists
public class FileLocator {
    private let fileManager = FileManager.default
    private var pathMappings: [String: String] = [:]
    private var searchPaths: [String] = []
    
    public init() {
        setupDefaultSearchPaths()
    }
    
    /// Locate a single file
    public func locateFile(for track: Track) async -> FileLocationResult {
        // Try exact path first
        if fileManager.fileExists(atPath: track.originalPath) {
            return FileLocationResult(
                originalPath: track.originalPath,
                resolvedPath: track.originalPath,
                confidence: 1.0,
                method: .exactPath
            )
        }
        
        // Try path translation
        if let translatedPath = translatePath(track.originalPath),
           fileManager.fileExists(atPath: translatedPath) {
            return FileLocationResult(
                originalPath: track.originalPath,
                resolvedPath: translatedPath,
                confidence: 0.9,
                method: .pathTranslation
            )
        }
        
        // Try filename search
        let filenameResult = await searchByFilename(track: track)
        if filenameResult.isFound {
            return filenameResult
        }
        
        // Try metadata matching
        let metadataResult = await searchByMetadata(track: track)
        if metadataResult.isFound {
            return metadataResult
        }
        
        return FileLocationResult(
            originalPath: track.originalPath,
            resolvedPath: nil,
            confidence: 0.0,
            method: .notFound,
            alternatives: filenameResult.alternatives + metadataResult.alternatives
        )
    }
    
    /// Locate multiple files with progress reporting
    public func locateFiles(for tracks: [Track], progressHandler: @escaping (Int, Int) -> Void) async -> [FileLocationResult] {
        var results: [FileLocationResult] = []
        
        for (index, track) in tracks.enumerated() {
            let result = await locateFile(for: track)
            results.append(result)
            progressHandler(index + 1, tracks.count)
        }
        
        return results
    }
    
    /// Add a custom search path
    public func addSearchPath(_ path: String) {
        if !searchPaths.contains(path) {
            searchPaths.append(path)
        }
    }
    
    /// Add a path mapping for translation
    public func addPathMapping(from oldPath: String, to newPath: String) {
        pathMappings[oldPath] = newPath
    }
    
    /// Learn from user corrections
    public func learnFromCorrection(originalPath: String, correctedPath: String) {
        // Extract common path patterns for future translations
        let originalComponents = originalPath.components(separatedBy: "/")
        let correctedComponents = correctedPath.components(separatedBy: "/")
        
        // Find the divergence point and create a mapping
        for i in 0..<min(originalComponents.count, correctedComponents.count) {
            if originalComponents[i] != correctedComponents[i] {
                let oldPrefix = originalComponents[0...i].joined(separator: "/")
                let newPrefix = correctedComponents[0...i].joined(separator: "/")
                pathMappings[oldPrefix] = newPrefix
                break
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultSearchPaths() {
        // Add common music directories
        if let homeDir = fileManager.homeDirectoryForCurrentUser.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            searchPaths.append("\(homeDir)/Music")
            searchPaths.append("\(homeDir)/iTunes/iTunes Music")
            searchPaths.append("\(homeDir)/Music/iTunes/iTunes Music")
            searchPaths.append("\(homeDir)/Music/Music/Media")
        }
        
        // Add system music directories
        searchPaths.append("/System/Library/Audio")
        searchPaths.append("/Library/Audio")
    }
    
    private func translatePath(_ originalPath: String) -> String? {
        // Try direct mappings first
        for (oldPath, newPath) in pathMappings {
            if originalPath.hasPrefix(oldPath) {
                return originalPath.replacingOccurrences(of: oldPath, with: newPath)
            }
        }
        
        // Try common path translations
        let commonTranslations = [
            ("file://localhost", ""),
            ("file://", ""),
            ("/Volumes/", "/"),
            ("\\", "/"), // Windows to Unix path separator
        ]
        
        var translatedPath = originalPath
        for (old, new) in commonTranslations {
            translatedPath = translatedPath.replacingOccurrences(of: old, with: new)
        }
        
        // URL decode
        translatedPath = translatedPath.removingPercentEncoding ?? translatedPath
        
        return translatedPath != originalPath ? translatedPath : nil
    }
    
    private func searchByFilename(track: Track) async -> FileLocationResult {
        let filename = URL(fileURLWithPath: track.originalPath).lastPathComponent
        let filenameWithoutExtension = URL(fileURLWithPath: track.originalPath).deletingPathExtension().lastPathComponent
        
        var alternatives: [String] = []
        
        for searchPath in searchPaths {
            let foundPaths = await searchDirectory(searchPath, for: filename)
            alternatives.append(contentsOf: foundPaths)
            
            // Also search for filename without extension (in case extension changed)
            let foundPathsWithoutExt = await searchDirectory(searchPath, for: filenameWithoutExtension)
            alternatives.append(contentsOf: foundPathsWithoutExt.filter { isAudioFile($0) })
        }
        
        // Remove duplicates and sort by relevance
        alternatives = Array(Set(alternatives)).sorted { path1, path2 in
            let score1 = calculateFilenameScore(path1, target: filename, track: track)
            let score2 = calculateFilenameScore(path2, target: filename, track: track)
            return score1 > score2
        }
        
        if let bestMatch = alternatives.first {
            let confidence = calculateFilenameScore(bestMatch, target: filename, track: track)
            return FileLocationResult(
                originalPath: track.originalPath,
                resolvedPath: bestMatch,
                confidence: confidence,
                method: .filenameSearch,
                alternatives: Array(alternatives.dropFirst())
            )
        }
        
        return FileLocationResult(
            originalPath: track.originalPath,
            resolvedPath: nil,
            confidence: 0.0,
            method: .notFound,
            alternatives: alternatives
        )
    }
    
    private func searchByMetadata(track: Track) async -> FileLocationResult {
        var alternatives: [String] = []
        
        for searchPath in searchPaths {
            let foundPaths = await searchDirectoryByMetadata(searchPath, track: track)
            alternatives.append(contentsOf: foundPaths)
        }
        
        // Sort by metadata match score
        alternatives = alternatives.sorted { path1, path2 in
            let score1 = calculateMetadataScore(path1, track: track)
            let score2 = calculateMetadataScore(path2, track: track)
            return score1 > score2
        }
        
        if let bestMatch = alternatives.first {
            let confidence = calculateMetadataScore(bestMatch, track: track)
            if confidence > 0.7 {
                return FileLocationResult(
                    originalPath: track.originalPath,
                    resolvedPath: bestMatch,
                    confidence: confidence,
                    method: .metadataMatch,
                    alternatives: Array(alternatives.dropFirst())
                )
            }
        }
        
        return FileLocationResult(
            originalPath: track.originalPath,
            resolvedPath: nil,
            confidence: 0.0,
            method: .notFound,
            alternatives: alternatives
        )
    }
    
    private func searchDirectory(_ directory: String, for filename: String) async -> [String] {
        var results: [String] = []
        
        guard fileManager.fileExists(atPath: directory) else { return results }
        
        let enumerator = fileManager.enumerator(atPath: directory)
        while let file = enumerator?.nextObject() as? String {
            if file.lowercased().contains(filename.lowercased()) && isAudioFile(file) {
                results.append("\(directory)/\(file)")
            }
        }
        
        return results
    }
    
    private func searchDirectoryByMetadata(_ directory: String, track: Track) async -> [String] {
        var results: [String] = []
        
        guard fileManager.fileExists(atPath: directory) else { return results }
        
        let enumerator = fileManager.enumerator(atPath: directory)
        while let file = enumerator?.nextObject() as? String {
            if isAudioFile(file) {
                let fullPath = "\(directory)/\(file)"
                if calculateMetadataScore(fullPath, track: track) > 0.5 {
                    results.append(fullPath)
                }
            }
        }
        
        return results
    }
    
    private func calculateFilenameScore(_ path: String, target: String, track: Track) -> Double {
        let filename = URL(fileURLWithPath: path).lastPathComponent
        let targetFilename = target
        
        // Exact match
        if filename.lowercased() == targetFilename.lowercased() {
            return 1.0
        }
        
        // Partial match
        let normalizedFilename = filename.lowercased().replacingOccurrences(of: " ", with: "")
        let normalizedTarget = targetFilename.lowercased().replacingOccurrences(of: " ", with: "")
        
        if normalizedFilename.contains(normalizedTarget) || normalizedTarget.contains(normalizedFilename) {
            return 0.8
        }
        
        // Check if filename contains track name and artist
        let filenameWords = Set(filename.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted))
        let trackWords = Set(track.name.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted))
        let artistWords = Set(track.artist.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted))
        
        let matchingWords = filenameWords.intersection(trackWords.union(artistWords))
        let totalWords = trackWords.union(artistWords)
        
        if !totalWords.isEmpty {
            return Double(matchingWords.count) / Double(totalWords.count) * 0.7
        }
        
        return 0.0
    }
    
    private func calculateMetadataScore(_ path: String, track: Track) -> Double {
        // This is a simplified metadata comparison
        // In a real implementation, you would use AVFoundation to read audio metadata
        let filename = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        
        let filenameWords = Set(filename.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted))
        let trackWords = Set(track.name.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted))
        let artistWords = Set(track.artist.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted))
        let albumWords = Set(track.album.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted))
        
        let allTrackWords = trackWords.union(artistWords).union(albumWords)
        let matchingWords = filenameWords.intersection(allTrackWords)
        
        if !allTrackWords.isEmpty {
            return Double(matchingWords.count) / Double(allTrackWords.count)
        }
        
        return 0.0
    }
    
    private func isAudioFile(_ path: String) -> Bool {
        let audioExtensions = ["mp3", "m4a", "aac", "wav", "aiff", "aif", "flac", "ogg", "wma"]
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return audioExtensions.contains(ext)
    }
}

