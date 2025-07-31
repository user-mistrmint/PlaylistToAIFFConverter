import Foundation

// MARK: - Core Data Models

/// Represents a single track in a playlist
public struct Track {
    public let id: String
    public let name: String
    public let artist: String
    public let album: String
    public let duration: TimeInterval?
    public let originalPath: String
    public let fileSize: Int64?
    public let bitRate: Int?
    public let sampleRate: Int?
    public let kind: String?
    
    public init(
        id: String,
        name: String,
        artist: String,
        album: String,
        duration: TimeInterval? = nil,
        originalPath: String,
        fileSize: Int64? = nil,
        bitRate: Int? = nil,
        sampleRate: Int? = nil,
        kind: String? = nil
    ) {
        self.id = id
        self.name = name
        self.artist = artist
        self.album = album
        self.duration = duration
        self.originalPath = originalPath
        self.fileSize = fileSize
        self.bitRate = bitRate
        self.sampleRate = sampleRate
        self.kind = kind
    }
}

/// Represents a playlist containing multiple tracks
public struct Playlist {
    public let name: String
    public let tracks: [Track]
    public let totalDuration: TimeInterval
    public let creationDate: Date?
    public let modificationDate: Date?
    
    public init(
        name: String,
        tracks: [Track],
        creationDate: Date? = nil,
        modificationDate: Date? = nil
    ) {
        self.name = name
        self.tracks = tracks
        self.totalDuration = tracks.compactMap { $0.duration }.reduce(0, +)
        self.creationDate = creationDate
        self.modificationDate = modificationDate
    }
}

/// Represents the result of parsing a playlist file
public struct PlaylistParseResult {
    public let playlist: Playlist?
    public let errors: [PlaylistParseError]
    public let warnings: [String]
    
    public init(playlist: Playlist?, errors: [PlaylistParseError] = [], warnings: [String] = []) {
        self.playlist = playlist
        self.errors = errors
        self.warnings = warnings
    }
    
    public var isSuccessful: Bool {
        return playlist != nil && errors.isEmpty
    }
}

/// Errors that can occur during playlist parsing
public enum PlaylistParseError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)
    case corruptedData(String)
    case unsupportedVersion(String)
    case missingRequiredField(String)
    case encodingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Playlist file not found at path: \(path)"
        case .invalidFormat(let format):
            return "Invalid or unsupported playlist format: \(format)"
        case .corruptedData(let details):
            return "Corrupted playlist data: \(details)"
        case .unsupportedVersion(let version):
            return "Unsupported playlist version: \(version)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .encodingError(let details):
            return "Text encoding error: \(details)"
        }
    }
}

/// Supported playlist file formats
public enum PlaylistFormat: String, CaseIterable {
    case xml = "xml"
    case m3u = "m3u"
    case m3u8 = "m3u8"
    case txt = "txt"
    
    public var fileExtensions: [String] {
        switch self {
        case .xml:
            return ["xml"]
        case .m3u:
            return ["m3u"]
        case .m3u8:
            return ["m3u8"]
        case .txt:
            return ["txt"]
        }
    }
    
    public var description: String {
        switch self {
        case .xml:
            return "iTunes XML Playlist"
        case .m3u:
            return "M3U Playlist"
        case .m3u8:
            return "M3U8 Extended Playlist"
        case .txt:
            return "Text Playlist"
        }
    }
}

/// Configuration options for playlist parsing
public struct PlaylistParseOptions {
    public let encoding: String.Encoding
    public let strictMode: Bool
    public let maxTrackCount: Int?
    public let skipMissingFiles: Bool
    
    public init(
        encoding: String.Encoding = .utf8,
        strictMode: Bool = false,
        maxTrackCount: Int? = nil,
        skipMissingFiles: Bool = true
    ) {
        self.encoding = encoding
        self.strictMode = strictMode
        self.maxTrackCount = maxTrackCount
        self.skipMissingFiles = skipMissingFiles
    }
    
    public static let `default` = PlaylistParseOptions()
}

