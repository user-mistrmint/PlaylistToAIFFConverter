# iTunes Playlist to AIFF Converter - User Manual

## Table of Contents

1. [Getting Started](#getting-started)
2. [Step-by-Step Tutorial](#step-by-step-tutorial)
3. [Understanding the Interface](#understanding-the-interface)
4. [Advanced Features](#advanced-features)
5. [Troubleshooting Guide](#troubleshooting-guide)
6. [Tips and Best Practices](#tips-and-best-practices)
7. [Frequently Asked Questions](#frequently-asked-questions)

## Getting Started

### What This Application Does

The iTunes Playlist to AIFF Converter helps DJs and music professionals convert their iTunes playlists to AIFF format, which is optimized for use with Traktor Pro 4 and other professional DJ software. The application:

- Reads playlist files from iTunes, Music app, or other sources
- Locates the actual audio files on your computer
- Converts them to high-quality AIFF format
- Organizes the converted files for easy import into DJ software

### Before You Begin

**System Requirements Check:**
- Ensure you're running macOS 12.0 (Monterey) or later
- Have at least 4 GB of available RAM
- Ensure sufficient disk space (AIFF files are larger than MP3s)

**Prepare Your Files:**
- Export your playlist from iTunes or Music app
- Know the location of your music files
- Choose a destination folder for converted files

## Step-by-Step Tutorial

### Step 1: Launch the Application

1. Open the iTunes Playlist to AIFF Converter application
2. You'll see the main window with several sections:
   - Header with application title
   - Playlist Import area
   - File Discovery section (appears after loading a playlist)
   - Conversion Settings
   - Progress and Results area

### Step 2: Import Your Playlist

**Method 1: Drag and Drop**
1. Open Finder and locate your playlist file
2. Drag the playlist file into the "Drop playlist file here" area
3. The file will be automatically processed

**Method 2: File Browser**
1. Click anywhere in the import area
2. A file browser will open
3. Navigate to your playlist file and select it
4. Click "Open"

**Supported File Types:**
- `.xml` - iTunes XML Library or Playlist export
- `.m3u` - Standard M3U playlist
- `.m3u8` - Extended M3U playlist with metadata
- `.txt` - Text-based playlist export

### Step 3: Review Playlist Information

After importing, you'll see:
- Playlist name
- Number of tracks found
- Basic playlist information

If there are any errors, they'll be displayed with suggestions for resolution.

### Step 4: Locate Audio Files

1. Click the "Locate Files" button
2. The application will search for your audio files using multiple strategies:
   - Checking exact file paths from the playlist
   - Searching common music directories
   - Using intelligent path translation
   - Matching by filename and metadata

3. Review the results:
   - ✅ Green checkmark: File found successfully
   - ⚠️ Orange warning: File found with lower confidence
   - ❌ Red X: File not found

### Step 5: Handle Missing Files (If Needed)

If some files aren't found automatically:

1. **Review Alternative Locations**: Check if the application found alternative file locations
2. **Manual Location**: Click on missing files to manually locate them
3. **Add Search Paths**: Add custom directories where your music might be stored
4. **Learn from Corrections**: The app will remember your corrections for future use

### Step 6: Configure Conversion Settings

**Output Format:**
- Choose "AIFF (Recommended for Traktor)" for best compatibility
- WAV is also supported if preferred

**Quality Settings:**
- **High (Recommended)**: Best balance of quality and speed
- **Maximum**: Highest quality, slower conversion
- **Medium**: Faster conversion, good quality
- **Low**: Fastest conversion, adequate quality

**Output Directory:**
- Click "Choose..." to select where converted files will be saved
- Default location is `~/Music/Converted`
- Ensure the directory has sufficient free space

### Step 7: Start Conversion

1. Click "Start Conversion" button
2. Monitor progress in real-time:
   - Overall progress bar
   - Current file being processed
   - Files completed vs. total files

3. **During Conversion:**
   - You can cancel at any time by clicking "Cancel"
   - The application will show which files are being processed
   - Errors are reported immediately with details

### Step 8: Review Results

After conversion completes:

1. **Check the Results List**: Review successful and failed conversions
2. **Handle Errors**: Address any files that failed to convert
3. **Open Output Folder**: Click to view your converted files
4. **Generate Report**: Export a detailed conversion report if needed

## Understanding the Interface

### Main Window Sections

**Header Section**
- Application title and description
- Quick access to help and settings

**Playlist Import Section**
- Large drop zone for playlist files
- File browser access
- Supported format indicators
- Current playlist information display

**File Discovery Section**
- File location results with status indicators
- Manual file location options
- Search path management
- Location method descriptions

**Conversion Settings Section**
- Output format selection
- Quality settings
- Output directory selection
- Advanced options (expandable)

**Progress and Results Section**
- Conversion progress indicators
- Real-time status updates
- Results list with success/failure status
- Action buttons for post-conversion tasks

### Status Indicators

**File Location Status:**
- 🟢 **Found (Exact Path)**: File exists at original location
- 🟢 **Found (Path Translation)**: File found after path correction
- 🟡 **Found (Filename Search)**: File found by searching directories
- 🟡 **Found (Metadata Match)**: File identified by audio metadata
- 🔴 **Not Found**: File could not be located

**Conversion Status:**
- ✅ **Success**: File converted successfully
- ❌ **Failed**: Conversion failed (see error details)
- ⏸️ **Cancelled**: Conversion was cancelled by user
- ⏳ **In Progress**: Currently being converted

## Advanced Features

### Custom Search Paths

Add directories where your music files might be located:

1. Go to application preferences
2. Click "Add Search Path"
3. Select directories to include in file searches
4. The application will remember these for future sessions

### Learning from Corrections

When you manually locate files:

1. The application learns common path patterns
2. Future file location becomes more accurate
3. Path mappings are saved between sessions
4. You can review and edit learned patterns

### Batch Processing Options

Configure how multiple files are processed:

1. **Concurrent Operations**: Set how many files to convert simultaneously
2. **Priority Settings**: Choose speed vs. quality preferences
3. **Error Handling**: Configure how to handle conversion failures
4. **Resume Capability**: Resume interrupted conversion sessions

### Metadata Preservation

Control how audio metadata is handled:

1. **Preserve All Metadata**: Keep all original tags and information
2. **Selective Preservation**: Choose which metadata to keep
3. **Metadata Cleanup**: Remove or modify specific tags
4. **Custom Tagging**: Add new metadata for DJ software compatibility

## Troubleshooting Guide

### Common Issues and Solutions

**Problem: Playlist Won't Load**

*Symptoms:* Error message when trying to import playlist file

*Solutions:*
1. Verify the file format is supported (XML, M3U, M3U8, TXT)
2. Check that the file isn't corrupted by opening it in a text editor
3. Ensure you have read permissions for the file
4. Try exporting the playlist again from iTunes/Music app

**Problem: Many Files Not Found**

*Symptoms:* Most tracks show "File not found" status

*Solutions:*
1. Check if your music library has been moved or reorganized
2. Add the current location of your music as a custom search path
3. Use the manual file location feature for a few files to help the app learn
4. Verify that the playlist file paths are correct

**Problem: Conversion Fails**

*Symptoms:* Files are found but conversion fails with errors

*Solutions:*
1. Check available disk space in the output directory
2. Verify that source files aren't corrupted or DRM-protected
3. Try converting a single file to isolate the issue
4. Reduce the number of concurrent operations
5. Check that you have write permissions to the output directory

**Problem: Poor Performance**

*Symptoms:* Conversion is very slow or system becomes unresponsive

*Solutions:*
1. Reduce the number of concurrent operations in settings
2. Close other applications to free up system resources
3. Choose a lower quality setting for faster conversion
4. Process smaller batches of files
5. Ensure adequate free RAM and disk space

**Problem: Audio Quality Issues**

*Symptoms:* Converted files sound different or lower quality

*Solutions:*
1. Use "High" or "Maximum" quality settings
2. Verify that source files are high quality
3. Check that AIFF format settings match your requirements
4. Compare file sizes to ensure conversion completed properly

### Error Messages Explained

**"File not found at specified location"**
- The playlist references a file that doesn't exist at the given path
- Use file location features or manually locate the file

**"Unsupported audio format"**
- The source file format isn't supported for conversion
- Check the list of supported input formats in the documentation

**"Conversion failed: insufficient disk space"**
- Not enough free space in the output directory
- Free up disk space or choose a different output location

**"Permission denied"**
- The application doesn't have permission to read source files or write to output directory
- Check file and folder permissions in Finder

**"Corrupted source file"**
- The source audio file is damaged or incomplete
- Try playing the file in another application to verify it works

## Tips and Best Practices

### Before Converting

1. **Organize Your Music Library**: Ensure your music files are well-organized and accessible
2. **Clean Up Playlists**: Remove duplicate or unwanted tracks before exporting
3. **Check File Formats**: Verify that your source files are in supported formats
4. **Backup Important Files**: Always backup your original music library

### During Conversion

1. **Monitor Progress**: Keep an eye on the conversion process for any errors
2. **Don't Interrupt**: Avoid force-quitting the application during conversion
3. **System Resources**: Close unnecessary applications for better performance
4. **Power Management**: Ensure your Mac won't go to sleep during long conversions

### After Conversion

1. **Verify Results**: Spot-check a few converted files to ensure quality
2. **Organize Output**: Create folders or naming schemes for easy DJ software import
3. **Test in Traktor**: Import a few files into Traktor Pro 4 to verify compatibility
4. **Keep Records**: Save conversion reports for future reference

### Optimization Tips

1. **Use SSD Storage**: Store output files on SSD for better performance
2. **Batch Similar Files**: Group files by format or quality for more efficient processing
3. **Regular Maintenance**: Periodically clean up temporary files and caches
4. **Update Regularly**: Keep the application updated for best performance and compatibility

## Frequently Asked Questions

### General Questions

**Q: What's the difference between AIFF and WAV formats?**
A: Both are uncompressed audio formats. AIFF uses big-endian byte order and is preferred by Traktor Pro 4, while WAV uses little-endian and has broader compatibility with other software.

**Q: Will converting to AIFF improve audio quality?**
A: Converting from lossy formats (like MP3) to AIFF won't improve quality, but it provides a consistent, uncompressed format that's optimal for DJ software performance.

**Q: How much disk space will I need?**
A: AIFF files are typically 3-4 times larger than 320kbps MP3 files. A 4-minute MP3 (about 10MB) becomes roughly 40MB as AIFF.

**Q: Can I convert protected/DRM files?**
A: No, the application cannot convert DRM-protected files. You'll need to use DRM-free versions of your music.

### Technical Questions

**Q: Why does file location sometimes fail?**
A: File paths in playlists can become outdated when files are moved, renamed, or when switching between different computers or user accounts.

**Q: Can I customize the AIFF format settings?**
A: The application uses Traktor Pro 4 optimized settings (44.1kHz, 16-bit, stereo) by default, which provides the best compatibility and performance.

**Q: What happens to metadata during conversion?**
A: The application preserves important metadata like track name, artist, album, and BPM information that's useful for DJ software.

**Q: Can I pause and resume conversions?**
A: You can cancel conversions and restart them later. The application will skip files that have already been successfully converted.

### Workflow Questions

**Q: How do I get my playlists from iTunes/Music app?**
A: Use File > Library > Export Playlist in iTunes/Music app and choose XML format for best compatibility.

**Q: Can I convert multiple playlists at once?**
A: Currently, the application processes one playlist at a time, but you can quickly switch between playlists and the app remembers your settings.

**Q: How do I import converted files into Traktor Pro 4?**
A: In Traktor, go to File > Import Music Folders and select your output directory. Traktor will analyze and import the AIFF files.

**Q: What if I have a very large playlist?**
A: The application handles large playlists efficiently, but you may want to process them in smaller batches for easier management and faster troubleshooting if issues arise.

---

For additional support, please refer to the main README file or create an issue on the project's GitHub repository.

