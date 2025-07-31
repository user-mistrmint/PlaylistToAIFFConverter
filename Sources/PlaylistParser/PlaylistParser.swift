import Foundation

// MARK: - Playlist Parser Protocol

/// Protocol for parsing different playlist formats
public protocol PlaylistParserProtocol {
    func parse(from url: URL, options: PlaylistParseOptions) async throws -> PlaylistParseResult
    func canParse(url: URL) -> Bool
    var supportedFormats: [PlaylistFormat] { get }
}

// MARK: - Main Playlist Parser

/// Main playlist parser that delegates to format-specific parsers
public class PlaylistParser {
    private let parsers: [PlaylistParserProtocol]
    
    public init() {
        self.parsers = [
            iTunesXMLParser(),
            M3UParser(),
            TextParser()
        ]
    }
    
    /// Parse a playlist file automatically detecting the format
    public func parse(from url: URL, options: PlaylistParseOptions = .default) async throws -> PlaylistParseResult {
        // Find appropriate parser for the file
        guard let parser = findParser(for: url) else {
            return PlaylistParseResult(
                playlist: nil,
                errors: [.invalidFormat("No parser found for file: \(url.lastPathComponent)")]
            )
        }
        
        return try await parser.parse(from: url, options: options)
    }
    
    /// Find the appropriate parser for a given file
    private func findParser(for url: URL) -> PlaylistParserProtocol? {
        return parsers.first { $0.canParse(url: url) }
    }
    
    /// Get all supported file extensions
    public var supportedExtensions: [String] {
        return PlaylistFormat.allCases.flatMap { $0.fileExtensions }
    }
}

// MARK: - iTunes XML Parser

/// Parser for iTunes XML playlist files
public class iTunesXMLParser: PlaylistParserProtocol {
    public let supportedFormats: [PlaylistFormat] = [.xml]
    
    public func canParse(url: URL) -> Bool {
        return url.pathExtension.lowercased() == "xml"
    }
    
    public func parse(from url: URL, options: PlaylistParseOptions) async throws -> PlaylistParseResult {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return PlaylistParseResult(
                playlist: nil,
                errors: [.fileNotFound(url.path)]
            )
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try await parseXMLData(data, options: options, sourceURL: url)
        } catch {
            return PlaylistParseResult(
                playlist: nil,
                errors: [.corruptedData("Failed to read file: \(error.localizedDescription)")]
            )
        }
    }
    
    private func parseXMLData(_ data: Data, options: PlaylistParseOptions, sourceURL: URL) async throws -> PlaylistParseResult {
        let parser = XMLParser(data: data)
        let delegate = iTunesXMLParserDelegate(options: options)
        parser.delegate = delegate
        
        guard parser.parse() else {
            return PlaylistParseResult(
                playlist: nil,
                errors: [.corruptedData("XML parsing failed")]
            )
        }
        
        if let error = delegate.parseError {
            return PlaylistParseResult(
                playlist: nil,
                errors: [error]
            )
        }
        
        let playlistName = sourceURL.deletingPathExtension().lastPathComponent
        let playlist = Playlist(
            name: playlistName,
            tracks: delegate.tracks,
            creationDate: delegate.creationDate,
            modificationDate: delegate.modificationDate
        )
        
        return PlaylistParseResult(
            playlist: playlist,
            warnings: delegate.warnings
        )
    }
}

// MARK: - iTunes XML Parser Delegate

private class iTunesXMLParserDelegate: NSObject, XMLParserDelegate {
    private let options: PlaylistParseOptions
    private var currentElement = ""
    private var currentTrack: [String: String] = [:]
    private var currentKey = ""
    private var isInTrackDict = false
    private var isInPlaylistArray = false
    
    var tracks: [Track] = []
    var warnings: [String] = []
    var parseError: PlaylistParseError?
    var creationDate: Date?
    var modificationDate: Date?
    
    init(options: PlaylistParseOptions) {
        self.options = options
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        switch elementName {
        case "dict":
            if !isInPlaylistArray {
                currentTrack = [:]
                isInTrackDict = true
            }
        case "array":
            isInPlaylistArray = true
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return }
        
        switch currentElement {
        case "key":
            currentKey = trimmedString
        case "string", "integer", "date":
            if isInTrackDict && !currentKey.isEmpty {
                currentTrack[currentKey] = trimmedString
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "dict":
            if isInTrackDict && !currentTrack.isEmpty {
                if let track = createTrack(from: currentTrack) {
                    tracks.append(track)
                }
                currentTrack = [:]
                isInTrackDict = false
            }
        case "array":
            isInPlaylistArray = false
        default:
            break
        }
        
        currentElement = ""
    }
    
    private func createTrack(from dict: [String: String]) -> Track? {
        guard let name = dict["Name"],
              let artist = dict["Artist"] ?? dict["Album Artist"],
              let location = dict["Location"] else {
            warnings.append("Skipping track with missing required fields")
            return nil
        }
        
        // Decode URL-encoded file path
        let decodedPath = location.removingPercentEncoding ?? location
        let filePath = decodedPath.hasPrefix("file://") ? 
            String(decodedPath.dropFirst(7)) : decodedPath
        
        let id = dict["Track ID"] ?? UUID().uuidString
        let album = dict["Album"] ?? ""
        let duration = dict["Total Time"].flatMap { Double($0) }.map { $0 / 1000.0 }
        let fileSize = dict["Size"].flatMap { Int64($0) }
        let bitRate = dict["Bit Rate"].flatMap { Int($0) }
        let sampleRate = dict["Sample Rate"].flatMap { Int($0) }
        let kind = dict["Kind"]
        
        return Track(
            id: id,
            name: name,
            artist: artist,
            album: album,
            duration: duration,
            originalPath: filePath,
            fileSize: fileSize,
            bitRate: bitRate,
            sampleRate: sampleRate,
            kind: kind
        )
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = .corruptedData("XML parse error: \(parseError.localizedDescription)")
    }
}

