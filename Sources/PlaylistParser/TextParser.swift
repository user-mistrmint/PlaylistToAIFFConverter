import Foundation

// MARK: - Text Parser

/// Parser for text-based playlist files exported from iTunes
public class TextParser: PlaylistParserProtocol {
    public let supportedFormats: [PlaylistFormat] = [.txt]
    
    public func canParse(url: URL) -> Bool {
        return url.pathExtension.lowercased() == "txt"
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
            return parseTextContent(content, options: options, sourceURL: url)
        } catch {
            // Try alternative encodings
            for encoding in [String.Encoding.utf8, .utf16, .isoLatin1, .windowsCP1252] {
                if encoding != options.encoding {
                    do {
                        let content = try String(contentsOf: url, encoding: encoding)
                        let result = parseTextContent(content, options: options, sourceURL: url)
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
    
    private func parseTextContent(_ content: String, options: PlaylistParseOptions, sourceURL: URL) -> PlaylistParseResult {
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            return PlaylistParseResult(
                playlist: nil,
                errors: [.corruptedData("Empty text file")]
            )
        }
        
        // Detect format by analyzing the first few lines
        let format = detectTextFormat(lines: lines)
        
        switch format {
        case .tabDelimited:
            return parseTabDelimitedText(lines: lines, options: options, sourceURL: sourceURL)
        case .commaSeparated:
            return parseCommaSeparatedText(lines: lines, options: options, sourceURL: sourceURL)
        case .simpleList:
            return parseSimpleList(lines: lines, options: options, sourceURL: sourceURL)
        }
    }
    
    private enum TextFormat {
        case tabDelimited
        case commaSeparated
        case simpleList
    }
    
    private func detectTextFormat(lines: [String]) -> TextFormat {
        let sampleLines = Array(lines.prefix(5))
        
        // Check for tab-delimited format (iTunes export format)
        let tabCount = sampleLines.map { $0.components(separatedBy: "\t").count }.max() ?? 1
        if tabCount > 3 {
            return .tabDelimited
        }
        
        // Check for comma-separated format
        let commaCount = sampleLines.map { $0.components(separatedBy: ",").count }.max() ?? 1
        if commaCount > 3 {
            return .commaSeparated
        }
        
        // Default to simple list
        return .simpleList
    }
    
    private func parseTabDelimitedText(lines: [String], options: PlaylistParseOptions, sourceURL: URL) -> PlaylistParseResult {
        var tracks: [Track] = []
        var warnings: [String] = []
        var headerMapping: [String: Int] = [:]
        
        // Parse header line if present
        if let firstLine = lines.first, firstLine.contains("\t") {
            let headers = firstLine.components(separatedBy: "\t")
            for (index, header) in headers.enumerated() {
                let normalizedHeader = header.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                headerMapping[normalizedHeader] = index
            }
            
            // Skip header line for track parsing
            let trackLines = Array(lines.dropFirst())
            tracks = parseTrackLines(trackLines, headerMapping: headerMapping, separator: "\t", options: options, warnings: &warnings)
        } else {
            // No header, assume standard order: Name, Artist, Album, Time, etc.
            tracks = parseTrackLines(lines, headerMapping: [:], separator: "\t", options: options, warnings: &warnings)
        }
        
        if tracks.isEmpty {
            return PlaylistParseResult(
                playlist: nil,
                errors: [.corruptedData("No valid tracks found in text file")]
            )
        }
        
        let playlistName = sourceURL.deletingPathExtension().lastPathComponent
        let playlist = Playlist(name: playlistName, tracks: tracks)
        
        return PlaylistParseResult(
            playlist: playlist,
            warnings: warnings
        )
    }
    
    private func parseCommaSeparatedText(lines: [String], options: PlaylistParseOptions, sourceURL: URL) -> PlaylistParseResult {
        var tracks: [Track] = []
        var warnings: [String] = []
        var headerMapping: [String: Int] = [:]
        
        // Parse header line if present
        if let firstLine = lines.first {
            let headers = parseCSVLine(firstLine)
            for (index, header) in headers.enumerated() {
                let normalizedHeader = header.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                headerMapping[normalizedHeader] = index
            }
            
            // Skip header line for track parsing
            let trackLines = Array(lines.dropFirst())
            tracks = parseCSVTrackLines(trackLines, headerMapping: headerMapping, options: options, warnings: &warnings)
        } else {
            tracks = parseCSVTrackLines(lines, headerMapping: [:], options: options, warnings: &warnings)
        }
        
        if tracks.isEmpty {
            return PlaylistParseResult(
                playlist: nil,
                errors: [.corruptedData("No valid tracks found in CSV file")]
            )
        }
        
        let playlistName = sourceURL.deletingPathExtension().lastPathComponent
        let playlist = Playlist(name: playlistName, tracks: tracks)
        
        return PlaylistParseResult(
            playlist: playlist,
            warnings: warnings
        )
    }
    
    private func parseSimpleList(lines: [String], options: PlaylistParseOptions, sourceURL: URL) -> PlaylistParseResult {
        var tracks: [Track] = []
        var warnings: [String] = []
        
        for (index, line) in lines.enumerated() {
            // Try to extract track info from various formats
            let track = parseSimpleTrackLine(line, index: index)
            tracks.append(track)
            
            if let maxCount = options.maxTrackCount, tracks.count >= maxCount {
                warnings.append("Reached maximum track limit of \(maxCount)")
                break
            }
        }
        
        let playlistName = sourceURL.deletingPathExtension().lastPathComponent
        let playlist = Playlist(name: playlistName, tracks: tracks)
        
        return PlaylistParseResult(
            playlist: playlist,
            warnings: warnings
        )
    }
    
    private func parseTrackLines(_ lines: [String], headerMapping: [String: Int], separator: String, options: PlaylistParseOptions, warnings: inout [String]) -> [Track] {
        var tracks: [Track] = []
        
        for line in lines {
            let components = line.components(separatedBy: separator)
            guard components.count > 1 else {
                warnings.append("Skipping malformed line: \(line)")
                continue
            }
            
            let name = getComponent(components, for: "name", headerMapping: headerMapping, defaultIndex: 0) ?? "Unknown Track"
            let artist = getComponent(components, for: "artist", headerMapping: headerMapping, defaultIndex: 1) ?? "Unknown Artist"
            let album = getComponent(components, for: "album", headerMapping: headerMapping, defaultIndex: 2) ?? "Unknown Album"
            let timeString = getComponent(components, for: "time", headerMapping: headerMapping, defaultIndex: 3)
            let location = getComponent(components, for: "location", headerMapping: headerMapping, defaultIndex: components.count - 1)
            
            let duration = parseTimeString(timeString)
            let path = location ?? ""
            
            let track = Track(
                id: UUID().uuidString,
                name: name,
                artist: artist,
                album: album,
                duration: duration,
                originalPath: path
            )
            
            tracks.append(track)
            
            if let maxCount = options.maxTrackCount, tracks.count >= maxCount {
                warnings.append("Reached maximum track limit of \(maxCount)")
                break
            }
        }
        
        return tracks
    }
    
    private func parseCSVTrackLines(_ lines: [String], headerMapping: [String: Int], options: PlaylistParseOptions, warnings: inout [String]) -> [Track] {
        var tracks: [Track] = []
        
        for line in lines {
            let components = parseCSVLine(line)
            guard components.count > 1 else {
                warnings.append("Skipping malformed CSV line: \(line)")
                continue
            }
            
            let name = getComponent(components, for: "name", headerMapping: headerMapping, defaultIndex: 0) ?? "Unknown Track"
            let artist = getComponent(components, for: "artist", headerMapping: headerMapping, defaultIndex: 1) ?? "Unknown Artist"
            let album = getComponent(components, for: "album", headerMapping: headerMapping, defaultIndex: 2) ?? "Unknown Album"
            let timeString = getComponent(components, for: "time", headerMapping: headerMapping, defaultIndex: 3)
            let location = getComponent(components, for: "location", headerMapping: headerMapping, defaultIndex: components.count - 1)
            
            let duration = parseTimeString(timeString)
            let path = location ?? ""
            
            let track = Track(
                id: UUID().uuidString,
                name: name,
                artist: artist,
                album: album,
                duration: duration,
                originalPath: path
            )
            
            tracks.append(track)
            
            if let maxCount = options.maxTrackCount, tracks.count >= maxCount {
                warnings.append("Reached maximum track limit of \(maxCount)")
                break
            }
        }
        
        return tracks
    }
    
    private func parseSimpleTrackLine(_ line: String, index: Int) -> Track {
        // Try to parse "Artist - Track" format
        if line.contains(" - ") {
            let components = line.components(separatedBy: " - ")
            if components.count >= 2 {
                let artist = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let title = components.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
                
                return Track(
                    id: UUID().uuidString,
                    name: title,
                    artist: artist,
                    album: "Unknown Album",
                    originalPath: ""
                )
            }
        }
        
        // Default: treat entire line as track name
        return Track(
            id: UUID().uuidString,
            name: line.trimmingCharacters(in: .whitespacesAndNewlines),
            artist: "Unknown Artist",
            album: "Unknown Album",
            originalPath: ""
        )
    }
    
    private func getComponent(_ components: [String], for key: String, headerMapping: [String: Int], defaultIndex: Int) -> String? {
        if let index = headerMapping[key], index < components.count {
            return components[index].trimmingCharacters(in: .whitespacesAndNewlines)
        } else if defaultIndex < components.count {
            return components[defaultIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    
    private func parseTimeString(_ timeString: String?) -> TimeInterval? {
        guard let timeString = timeString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !timeString.isEmpty else { return nil }
        
        // Try to parse MM:SS or HH:MM:SS format
        let components = timeString.components(separatedBy: ":")
        
        switch components.count {
        case 2: // MM:SS
            if let minutes = Double(components[0]),
               let seconds = Double(components[1]) {
                return minutes * 60 + seconds
            }
        case 3: // HH:MM:SS
            if let hours = Double(components[0]),
               let minutes = Double(components[1]),
               let seconds = Double(components[2]) {
                return hours * 3600 + minutes * 60 + seconds
            }
        default:
            // Try to parse as seconds
            return Double(timeString)
        }
        
        return nil
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var components: [String] = []
        var currentComponent = ""
        var insideQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                components.append(currentComponent)
                currentComponent = ""
            } else {
                currentComponent.append(char)
            }
            
            i = line.index(after: i)
        }
        
        components.append(currentComponent)
        return components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

