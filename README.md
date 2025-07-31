# iTunes Playlist to AIFF Converter

A native macOS application that converts iTunes playlist files to AIFF format for compatibility with Traktor Pro 4 and other professional DJ software.

## Features

### Core Functionality
- **Multiple Playlist Formats**: Supports iTunes XML, M3U, M3U8, and text-based playlist files
- **Intelligent File Location**: Automatically locates audio files even when playlist references are outdated
- **High-Quality Conversion**: Converts audio files to AIFF format optimized for Traktor Pro 4
- **Batch Processing**: Efficiently processes multiple files with configurable concurrency
- **Progress Tracking**: Real-time progress updates and detailed conversion reports

### Advanced Features
- **Smart Path Resolution**: Handles moved or renamed files using multiple location strategies
- **Metadata Preservation**: Maintains audio metadata during conversion
- **Error Recovery**: Comprehensive error handling with retry mechanisms
- **User Learning**: Learns from manual file corrections to improve future accuracy
- **Customizable Settings**: Configurable quality settings and output formats

## System Requirements

- **Operating System**: macOS 12.0 (Monterey) or later
- **Architecture**: Compatible with both Intel and Apple Silicon Macs
- **Memory**: 4 GB RAM minimum, 8 GB recommended for large playlists
- **Storage**: Sufficient free space for converted files (AIFF files are typically larger than compressed formats)
- **Permissions**: File system access permissions for reading playlists and audio files

## Installation

### Option 1: Build from Source

1. **Clone the Repository**
   ```bash
   git clone https://github.com/user-mistrmint/PlaylistToAIFFConverter.git
   cd PlaylistToAIFFConverter
   ```

2. **Build the Application**
   ```bash
   swift build -c release
   ```

3. **Run the Application**
   ```bash
   swift run PlaylistToAIFFConverter
   ```

### Option 2: Xcode Development

1. Open the project directory in Xcode
2. Select the PlaylistToAIFFConverter scheme
3. Build and run the application (⌘R)

## Usage Guide

### Basic Workflow

1. **Import Playlist**
   - Drag and drop a playlist file into the import area
   - Or click "Browse" to select a file manually
   - Supported formats: XML (iTunes), M3U, M3U8, TXT

2. **Locate Audio Files**
   - Click "Locate Files" to find referenced audio files
   - The app will attempt to locate files automatically
   - Missing files will be highlighted for manual location

3. **Configure Settings**
   - Choose output format (AIFF recommended for Traktor Pro 4)
   - Select conversion quality (High recommended)
   - Set output directory for converted files

4. **Start Conversion**
   - Click "Start Conversion" to begin processing
   - Monitor progress in real-time
   - Review results and handle any errors

### Supported Input Formats

The application can convert from the following audio formats:
- MP3 (MPEG Audio Layer III)
- M4A/AAC (MPEG-4 Audio)
- WAV (Waveform Audio File Format)
- FLAC (Free Lossless Audio Codec)
- OGG (Ogg Vorbis)
- Existing AIFF files (for quality standardization)

### Output Specifications

**AIFF Format (Recommended for Traktor Pro 4)**
- Sample Rate: 44.1 kHz
- Bit Depth: 16-bit
- Channels: Stereo (2 channels)
- Encoding: Uncompressed PCM
- Byte Order: Big-endian (AIFF standard)

**Alternative WAV Format**
- Same specifications as AIFF
- Little-endian byte order
- Broader compatibility with other software

## Advanced Features

### File Location Strategies

The application uses multiple strategies to locate audio files:

1. **Exact Path Matching**: Checks if files exist at their original locations
2. **Path Translation**: Handles common path changes (volume mounts, user directories)
3. **Filename Search**: Searches common music directories for matching filenames
4. **Metadata Matching**: Uses audio metadata to identify files that may have been renamed
5. **User Learning**: Remembers manual corrections to improve future accuracy

### Batch Processing

- **Concurrent Operations**: Configurable number of simultaneous conversions
- **Progress Tracking**: Individual file progress and overall completion status
- **Error Handling**: Failed conversions don't stop the entire batch
- **Resume Capability**: Can resume interrupted conversion sessions

### Quality Settings

- **Maximum**: Highest quality, slower conversion
- **High**: Recommended balance of quality and speed
- **Medium**: Faster conversion with good quality
- **Low**: Fastest conversion, adequate quality

## Troubleshooting

### Common Issues

**Playlist Not Loading**
- Verify the file format is supported (XML, M3U, M3U8, TXT)
- Check file permissions and ensure the file isn't corrupted
- Try opening the playlist in iTunes/Music app to verify it's valid

**Files Not Found**
- Use the manual file location feature for missing files
- Add custom search paths in preferences
- Check if files have been moved or renamed since playlist creation

**Conversion Failures**
- Ensure sufficient disk space for output files
- Verify input files aren't corrupted or DRM-protected
- Check that output directory has write permissions

**Performance Issues**
- Reduce concurrent operations for older Macs
- Close other applications to free up system resources
- Consider converting smaller batches for very large playlists

### Error Messages

**"File not found"**
- The referenced audio file doesn't exist at the specified location
- Use the file location feature or manually locate the file

**"Unsupported format"**
- The audio file format isn't supported for conversion
- Check the list of supported input formats

**"Conversion failed"**
- Generic conversion error, check the detailed error message
- May indicate corrupted source file or insufficient system resources

**"Insufficient disk space"**
- Not enough free space for the converted files
- Free up disk space or choose a different output directory

## Technical Details

### Architecture

The application follows a modular architecture with clear separation of concerns:

- **PlaylistParser**: Handles parsing of different playlist formats
- **FileLocator**: Manages file location and path resolution
- **AudioConverter**: Performs audio format conversion
- **UI Layer**: SwiftUI-based user interface with reactive data binding

### Dependencies

- **AVFoundation**: Core audio processing and conversion
- **SwiftUI**: Modern declarative user interface
- **Combine**: Reactive programming for data flow
- **Foundation**: Core system integration

### Performance Optimizations

- **Streaming Processing**: Handles large audio files without loading entirely into memory
- **Concurrent Operations**: Parallel processing with configurable limits
- **Intelligent Caching**: Caches metadata and file information for improved performance
- **Background Processing**: Long operations don't block the user interface

## Contributing

### Development Setup

1. Clone the repository
2. Open in Xcode 14.0 or later
3. Ensure macOS 12.0+ deployment target
4. Run tests with ⌘U

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting
- Include unit tests for new functionality
- Document public APIs with Swift documentation comments

### Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Make your changes with appropriate tests
4. Submit a pull request with detailed description

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Support

### Getting Help

- Check the troubleshooting section above
- Review existing GitHub issues
- Create a new issue with detailed information about your problem

### Feature Requests

Feature requests are welcome! Please create an issue with:
- Clear description of the requested feature
- Use case and benefits
- Any relevant technical considerations

### Bug Reports

When reporting bugs, please include:
- macOS version and hardware details
- Steps to reproduce the issue
- Expected vs. actual behavior
- Any error messages or logs
- Sample playlist files (if relevant and not containing personal information)

## Acknowledgments

- Apple's AVFoundation framework for audio processing
- The open-source community for inspiration and best practices
- Native Instruments for Traktor Pro 4 specifications
- Beta testers and early adopters for feedback and bug reports

---

**Note**: This application is not affiliated with Apple Inc. or Native Instruments. iTunes and Traktor Pro are trademarks of their respective owners.

