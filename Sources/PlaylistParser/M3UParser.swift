import Foundation

// MARK: - M3U Parser

/// Parser for M3U and M3U8 playlist files
public class M3UParser: PlaylistParserProtocol {
    public let supportedFormats: [PlaylistFormat] = [.m3u, .m3u8]
    
    public func canParse(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "m3u" || ext == "m3u8"
    }
    
    public func parse(from url: URL, options: PlaylistParseOptions) async throws -> PlaylistParseResult {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return PlaylistParseResult(
                playlist: nil,
                errors: [.fileNotFound(url.path)]
            )
        }
        
        do {
            let content = try String(contentsOf: url, encoding: options.encoding)
            return parseM3UContent(content, baseURL: url.deletingLastPathComponent(), options: options, sourceURL: url)
        } catch {
            // Try alternative encodings if the specified one fails
            for encoding in [String.Encoding.utf8, .utf16, .isoLatin1, .windowsCP1252] {
                if encoding != options.encoding {
                    do {
                        let content = try String(contentsOf: url, encoding: encoding)
                        let result = parseM3UContent(content, baseURL: url.deletingLastPathComponent(), options: options, sourceURL: url)
                        return PlaylistParseResult(
                            playlist: result.playlist,
                            errors: result.errors,
                            warnings: result.warnings + ["Used \(encoding) encoding instead of \(options.encoding)"]
                        )
                    } catch {
                        continue
                    }
                }
            }
            
            return PlaylistParseResult(
                playlist: nil,
                errors: [.encodingError("Failed to read file with any supported encoding")]
            )
        }
    }
    
    private func parseM3UContent(_ content: String, baseURL: URL, options: PlaylistParseOptions, sourceURL: URL) -> PlaylistParseResult {
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var tracks: [Track] = []
        var warnings: [String] = []
        var currentTrackInfo: [String: String] = [:]
        var isExtendedM3U = false
        
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("#EXTM3U") {
                isExtendedM3U = true
                continue
            }
            
            if line.hasPrefix("#EXTINF:") {
                // Extended M3U track info: #EXTINF:duration,artist - title
                let info = String(line.dropFirst(8)) // Remove "#EXTINF:"
                let components = info.components(separatedBy: ",")
                
                if components.count >= 2 {
                    let duration = Double(components[0].trimmingCharacters(in: .whitespacesAndNewlines))
                    let titleInfo = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Try to parse "artist - title" format
                    let titleComponents = titleInfo.components(separatedBy: " - ")
                    if titleComponents.count >= 2 {
                        currentTrackInfo["artist"] = titleComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        currentTrackInfo["title"] = titleComponents.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        currentTrackInfo["title"] = titleInfo
                        currentTrackInfo["artist"] = "Unknown Artist"
                    }
                    
                    if let duration = duration {
                        currentTrackInfo["duration"] = String(duration)
                    }
                }
                continue
            }
            
            if line.hasPrefix("#") {
                // Skip other comments
                continue
            }
            
            // This should be a file path
            let filePath = resolveFilePath(line, baseURL: baseURL)
            
            let track = Track(
                id: UUID().uuidString,
                name: currentTrackInfo["title"] ?? extractFilename(from: line),
                artist: currentTrackInfo["artist"] ?? "Unknown Artist",
                album: "Unknown Album",
                duration: currentTrackInfo["duration"].flatMap { Double($0) },
                originalPath: filePath
            )
            
            tracks.append(track)
            currentTrackInfo.removeAll()
            
            // Check track limit
            if let maxCount = options.maxTrackCount, tracks.count >= maxCount {
                warnings.append("Reached maximum track limit of \(maxCount)")
                break
            }
        }
        
        if tracks.isEmpty {
            return PlaylistParseResult(
                playlist: nil,
                errors: [.corruptedData("No valid tracks found in M3U file")]
            )
        }
        
        let playlistName = sourceURL.deletingPathExtension().lastPathComponent
        let playlist = Playlist(name: playlistName, tracks: tracks)
        
        return PlaylistParseResult(
            playlist: playlist,
            warnings: warnings
        )
    }
    
    private func resolveFilePath(_ path: String, baseURL: URL) -> String {
        // Handle different path formats
        if path.hasPrefix("file://") {
            return path.removingPercentEncoding ?? path
        }
        
        if path.hasPrefix("/") {
            // Absolute path
            return path
        }
        
        // Relative path - resolve against base URL
        let resolvedURL = baseURL.appendingPathComponent(path)
        return resolvedURL.path
    }
    
    private func extractFilename(from path: String) -> String {
        let url = URL(fileURLWithPath: path)
        return url.deletingPathExtension().lastPathComponent
    }
}

