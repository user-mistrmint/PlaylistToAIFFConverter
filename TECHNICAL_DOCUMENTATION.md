# Technical Documentation - iTunes Playlist to AIFF Converter

## Architecture Overview

### System Design Principles

The application follows a modular, layered architecture designed for maintainability, testability, and performance. The design emphasizes separation of concerns, dependency injection, and reactive programming patterns.

#### Core Design Patterns

1. **Model-View-ViewModel (MVVM)**: SwiftUI views bind to observable view models
2. **Repository Pattern**: Data access abstracted through repository interfaces
3. **Strategy Pattern**: Multiple playlist parsing and file location strategies
4. **Command Pattern**: Conversion operations as cancellable commands
5. **Observer Pattern**: Reactive updates using Combine framework

### Module Structure

```
PlaylistToAIFFConverter/
├── Sources/
│   ├── PlaylistToAIFFConverter/     # Main application and UI
│   ├── PlaylistParser/              # Playlist parsing module
│   ├── AudioConverter/              # Audio conversion module
│   └── FileLocator/                 # File location module
├── Tests/                           # Unit and integration tests
└── Documentation/                   # Additional documentation
```

## Module Details

### PlaylistParser Module

**Purpose**: Parse various playlist formats and extract track information

**Key Components**:
- `PlaylistParserProtocol`: Common interface for all parsers
- `PlaylistParser`: Main coordinator that delegates to specific parsers
- `iTunesXMLParser`: Handles iTunes XML library/playlist files
- `M3UParser`: Processes M3U and M3U8 playlist files
- `TextParser`: Handles text-based playlist exports

**Data Models**:
```swift
struct Track {
    let id: String
    let name: String
    let artist: String
    let album: String
    let duration: TimeInterval?
    let originalPath: String
    // Additional metadata fields...
}

struct Playlist {
    let name: String
    let tracks: [Track]
    let totalDuration: TimeInterval
    // Additional playlist metadata...
}
```

**Implementation Details**:

*iTunes XML Parser*:
- Uses `XMLParser` with custom delegate for streaming parsing
- Handles nested dictionary structures in iTunes XML format
- Supports both library exports and individual playlist exports
- Decodes URL-encoded file paths and handles various path formats

*M3U Parser*:
- Supports both simple M3U and extended M3U8 formats
- Parses `#EXTINF` directives for track metadata
- Handles relative and absolute file paths
- Supports various text encodings with fallback detection

*Text Parser*:
- Detects format automatically (tab-delimited, CSV, simple list)
- Flexible column mapping with header detection
- Handles various iTunes text export formats
- Supports custom delimiter detection

### FileLocator Module

**Purpose**: Locate audio files when playlist references are outdated or incorrect

**Key Components**:
- `FileLocator`: Main file location coordinator
- `FileLocationResult`: Encapsulates location results with confidence scores
- `LocationMethod`: Enumeration of location strategies used

**Location Strategies**:

1. **Exact Path Matching**: Direct file existence check
2. **Path Translation**: Common path transformations
3. **Filename Search**: Directory traversal with filename matching
4. **Metadata Matching**: Audio metadata comparison (future enhancement)
5. **User Learning**: Pattern recognition from manual corrections

**Implementation Details**:

*Path Translation*:
```swift
private func translatePath(_ originalPath: String) -> String? {
    // Handle common path transformations
    let commonTranslations = [
        ("file://localhost", ""),
        ("file://", ""),
        ("/Volumes/", "/"),
        ("\\", "/"), // Windows to Unix
    ]
    // Apply transformations and URL decoding
}
```

*Search Algorithm*:
- Concurrent directory traversal using `FileManager.enumerator`
- Fuzzy filename matching with confidence scoring
- Metadata-based matching using audio file properties
- Learning system that improves accuracy over time

### AudioConverter Module

**Purpose**: Convert audio files to AIFF format with high quality and performance

**Key Components**:
- `AudioConverter`: Main conversion coordinator
- `AudioConversionSettings`: Configuration for conversion parameters
- `AudioConversionResult`: Detailed conversion results
- `AsyncSemaphore`: Concurrency control for batch operations

**Conversion Pipeline**:

1. **Input Validation**: File existence and format detection
2. **Output Preparation**: Directory creation and path validation
3. **Format Conversion**: AVFoundation-based audio processing
4. **Metadata Preservation**: Copy relevant metadata to output files
5. **Quality Verification**: Validate conversion results

**Implementation Details**:

*AVFoundation Integration*:
```swift
private func convertWithAVFoundation(
    inputURL: URL,
    outputURL: URL,
    settings: AudioConversionSettings,
    progressHandler: @escaping (Double) -> Void
) async throws {
    let asset = AVAsset(url: inputURL)
    let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
    
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .aiff
    
    // Configure audio settings for AIFF output
    let audioSettings = createAudioSettings(settings)
    // ... conversion logic
}
```

*Batch Processing*:
- Configurable concurrency using `AsyncSemaphore`
- Progress reporting with per-file and overall progress
- Error isolation - failed conversions don't stop the batch
- Memory-efficient streaming for large files

### Main Application Module

**Purpose**: User interface and application coordination

**Key Components**:
- `ConversionViewModel`: Main application state management
- `ContentView`: Primary SwiftUI interface
- Specialized views for each workflow step
- Error handling and user feedback systems

**State Management**:

The application uses `@StateObject` and `@ObservedObject` for reactive state management:

```swift
@MainActor
class ConversionViewModel: ObservableObject {
    @Published var playlist: Playlist?
    @Published var fileResults: [FileLocationResult] = []
    @Published var conversionResults: [AudioConversionResult] = []
    @Published var isConverting = false
    // ... additional state properties
}
```

**Async Operations**:
- All long-running operations use Swift's async/await
- Progress reporting through closure-based callbacks
- Cancellation support using `Task` cancellation
- Error handling with typed error enums

## Data Flow Architecture

### Import Workflow

1. **File Selection**: User selects playlist file via drag-drop or file browser
2. **Format Detection**: Application determines playlist format
3. **Parsing**: Appropriate parser extracts track information
4. **Validation**: Track data is validated and errors reported
5. **UI Update**: Playlist information displayed to user

### File Location Workflow

1. **Strategy Selection**: Multiple location strategies attempted in order
2. **Concurrent Search**: Parallel execution of search operations
3. **Confidence Scoring**: Results ranked by confidence level
4. **User Feedback**: Results presented with clear status indicators
5. **Learning Integration**: User corrections improve future accuracy

### Conversion Workflow

1. **Pre-flight Checks**: Validate inputs and outputs
2. **Batch Preparation**: Organize files for efficient processing
3. **Concurrent Conversion**: Process multiple files simultaneously
4. **Progress Reporting**: Real-time updates to user interface
5. **Result Aggregation**: Collect and present conversion results

## Performance Optimizations

### Memory Management

**Streaming Processing**: Large audio files are processed in chunks rather than loading entirely into memory:

```swift
// Pseudo-code for streaming audio processing
func processAudioStream(inputURL: URL, outputURL: URL) async throws {
    let reader = try AVAssetReader(asset: AVAsset(url: inputURL))
    let writer = try AVAssetWriter(outputURL: outputURL, fileType: .aiff)
    
    // Process audio in chunks to minimize memory usage
    while let sampleBuffer = reader.copyNextSampleBuffer() {
        writer.append(sampleBuffer)
        // Memory is released automatically for each chunk
    }
}
```

**Intelligent Caching**: Metadata and file information cached with automatic cleanup:

```swift
private var metadataCache: [String: AudioMetadata] = [:]
private let cacheQueue = DispatchQueue(label: "metadata.cache", qos: .utility)

func getCachedMetadata(for path: String) -> AudioMetadata? {
    return cacheQueue.sync { metadataCache[path] }
}
```

### Concurrency Control

**Adaptive Concurrency**: System automatically adjusts concurrent operations based on available resources:

```swift
private func calculateOptimalConcurrency() -> Int {
    let processorCount = ProcessInfo.processInfo.processorCount
    let availableMemory = ProcessInfo.processInfo.physicalMemory
    
    // Adjust based on system capabilities
    return min(processorCount, max(2, Int(availableMemory / (1024 * 1024 * 512))))
}
```

**Resource Monitoring**: Track system resource usage and adjust operations accordingly:

```swift
private func monitorSystemResources() {
    // Monitor CPU usage, memory pressure, and disk I/O
    // Adjust concurrency and processing parameters dynamically
}
```

### I/O Optimization

**Sequential Access Patterns**: Organize file operations to minimize disk seek times
**Asynchronous I/O**: Use async file operations to prevent UI blocking
**Batch Operations**: Group related file operations for efficiency

## Error Handling Strategy

### Error Classification

Errors are classified by type and severity to enable appropriate handling:

```swift
public enum PlaylistParseError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)
    case corruptedData(String)
    case unsupportedVersion(String)
    case missingRequiredField(String)
    case encodingError(String)
}

public enum AudioConversionError: Error, LocalizedError {
    case fileNotFound(String)
    case unsupportedFormat(String)
    case conversionFailed(String)
    case outputPathError(String)
    case metadataError(String)
    case insufficientSpace
    case cancelled
}
```

### Recovery Mechanisms

**Automatic Retry**: Transient errors trigger automatic retry with exponential backoff
**Graceful Degradation**: Partial failures don't prevent overall operation completion
**User Guidance**: Clear error messages with actionable resolution steps

### Error Reporting

**Detailed Logging**: Comprehensive error information for debugging
**User-Friendly Messages**: Technical details hidden from end users
**Context Preservation**: Error context maintained for troubleshooting

## Testing Strategy

### Unit Testing

Each module includes comprehensive unit tests:

```swift
final class PlaylistParserTests: XCTestCase {
    func testTrackCreation() {
        let track = Track(
            id: "123",
            name: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            originalPath: "/path/to/song.mp3"
        )
        
        XCTAssertEqual(track.name, "Test Song")
        XCTAssertEqual(track.duration, 180.0)
    }
}
```

### Integration Testing

Tests verify module interactions and data flow:

```swift
func testPlaylistToConversionWorkflow() async throws {
    // Test complete workflow from playlist import to conversion
    let parser = PlaylistParser()
    let locator = FileLocator()
    let converter = AudioConverter()
    
    // Verify each step of the workflow
}
```

### Performance Testing

Automated tests verify performance characteristics:

```swift
func testLargePlaylistPerformance() {
    measure {
        // Test parsing performance with large playlists
        // Verify memory usage stays within bounds
        // Check conversion speed meets requirements
    }
}
```

## Security Considerations

### File System Access

**Sandboxing Compliance**: Application respects macOS sandboxing requirements
**Permission Management**: Minimal required permissions requested
**Security-Scoped Bookmarks**: Persistent file access without broad permissions

### Data Protection

**Local Processing**: All operations performed locally, no data transmission
**Temporary File Cleanup**: Automatic cleanup of temporary files
**Metadata Privacy**: User control over metadata preservation and removal

### Input Validation

**File Format Validation**: Strict validation of input file formats
**Path Sanitization**: Prevention of directory traversal attacks
**Resource Limits**: Protection against resource exhaustion attacks

## Deployment and Distribution

### Build Configuration

**Release Optimization**: Compiler optimizations for production builds
**Code Signing**: Proper code signing for macOS distribution
**Notarization**: Apple notarization for security compliance

### Packaging

**Bundle Structure**: Standard macOS application bundle
**Dependencies**: All dependencies included or statically linked
**Compatibility**: Support for multiple macOS versions

### Update Mechanism

**Version Checking**: Automatic update availability detection
**Incremental Updates**: Efficient update delivery
**Rollback Capability**: Safe update rollback if issues occur

## Future Enhancements

### Planned Features

1. **Enhanced Metadata Support**: More comprehensive metadata preservation
2. **Additional Formats**: Support for more input and output formats
3. **Cloud Integration**: Support for cloud-based music libraries
4. **Batch Playlist Processing**: Handle multiple playlists simultaneously
5. **Advanced Audio Analysis**: Audio fingerprinting for better file matching

### Architecture Improvements

1. **Plugin System**: Extensible architecture for new parsers and converters
2. **Distributed Processing**: Support for distributed conversion across multiple machines
3. **Machine Learning**: AI-powered file location and quality optimization
4. **Real-time Processing**: Live conversion during playlist playback

### Performance Optimizations

1. **GPU Acceleration**: Leverage GPU for audio processing where applicable
2. **Advanced Caching**: More sophisticated caching strategies
3. **Predictive Loading**: Anticipate user actions for better responsiveness
4. **Resource Scheduling**: Advanced resource management and scheduling

---

This technical documentation provides a comprehensive overview of the application's architecture, implementation details, and design decisions. For specific implementation questions or contributions, please refer to the source code and inline documentation.

