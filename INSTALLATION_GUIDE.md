# Installation Guide - iTunes Playlist to AIFF Converter

## System Requirements

### Minimum Requirements
- **Operating System**: macOS 12.0 (Monterey) or later
- **Architecture**: Intel x64 or Apple Silicon (M1/M2/M3)
- **Memory**: 4 GB RAM
- **Storage**: 1 GB free space for application + space for converted files
- **Permissions**: File system access for reading playlists and audio files

### Recommended Requirements
- **Operating System**: macOS 13.0 (Ventura) or later
- **Memory**: 8 GB RAM or more
- **Storage**: SSD with ample free space for AIFF files
- **Audio Files**: High-quality source files for best conversion results

## Installation Methods

### Method 1: Build from Source (Recommended for Developers)

**Prerequisites:**
- Xcode 14.0 or later
- Swift 5.9 or later
- macOS development environment

**Steps:**

1. **Clone the Repository**
   ```bash
   git clone https://github.com/user-mistrmint/PlaylistToAIFFConverter.git
   cd PlaylistToAIFFConverter
   ```

2. **Open in Xcode**
   ```bash
   open PlaylistToAIFFConverter.xcodeproj
   ```
   
   Or double-click the `.xcodeproj` file in Finder

3. **Configure Signing**
   - Select the project in Xcode navigator
   - Go to "Signing & Capabilities" tab
   - Select your development team
   - Ensure "Automatically manage signing" is checked

4. **Build and Run**
   - Select the PlaylistToAIFFConverter scheme
   - Press ⌘R to build and run
   - Or use Product > Run from the menu

### Method 2: Swift Package Manager (Command Line)

**Prerequisites:**
- Xcode Command Line Tools installed
- Swift toolchain available

**Steps:**

1. **Navigate to Project Directory**
   ```bash
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

### Method 3: Pre-built Application Bundle (Recommended for End Users)

**Prerequisites:**
- macOS 12.0 (Monterey) or later
- Intel x64 or Apple Silicon Mac

**Steps:**

1. **Download the Application**
   - Visit the [Releases page](https://github.com/user-mistrmint/PlaylistToAIFFConverter/releases)
   - Download the latest `.dmg` file or `.zip` archive
   - Choose the appropriate version for your system

2. **Install from DMG (Recommended)**
   - Double-click the downloaded `.dmg` file to mount it
   - A window will open showing the application and Applications folder
   - Drag "Playlist to AIFF Converter" to the Applications folder
   - Eject the disk image when installation is complete

3. **Install from ZIP Archive**
   - Double-click the downloaded `.zip` file to extract it
   - Move the extracted "PlaylistToAIFFConverter.app" to your Applications folder
   - Delete the ZIP file if desired

4. **First Launch Security Steps**
   - Navigate to Applications folder in Finder
   - Right-click "Playlist to AIFF Converter" and select "Open"
   - Click "Open" in the security dialog (required only on first launch)
   - The application will remember this permission for future launches

5. **Grant File Access Permissions**
   - When prompted, allow access to your music directories
   - Go to System Preferences > Security & Privacy > Privacy
   - Under "Files and Folders", ensure the app has access to:
     - Music folder
     - Downloads folder (if playlists are stored there)
     - Any custom music directories

## Post-Installation Setup

### Grant Necessary Permissions

**File System Access:**
1. Launch the application
2. When prompted, grant access to your music directories
3. The application will remember these permissions

**Security Settings:**
1. Go to System Preferences > Security & Privacy
2. Under "Privacy" tab, ensure the application has access to:
   - Files and Folders (for playlist and music file access)
   - Full Disk Access (if needed for system-wide music searches)

### Configure Default Settings

**Music Library Locations:**
1. Open the application preferences
2. Add your music library directories:
   - `~/Music/iTunes/iTunes Music`
   - `~/Music/Music/Media`
   - Any custom music directories

**Output Settings:**
1. Set default output directory (e.g., `~/Music/Converted`)
2. Choose default quality settings (High recommended)
3. Configure concurrent conversion limits based on your system

## Verification

### Test Installation

1. **Launch the Application**
   - The main window should appear without errors
   - All interface elements should be visible and responsive

2. **Test with Sample Files**
   - Use the provided `sample_playlist.xml` or `sample_playlist.m3u`
   - Import the sample playlist
   - Verify that the interface responds correctly

3. **Check System Integration**
   - Test drag-and-drop functionality
   - Verify file browser integration
   - Confirm output directory creation

### Performance Check

1. **Memory Usage**
   - Monitor memory usage in Activity Monitor
   - Should be under 200MB for normal operation

2. **CPU Usage**
   - CPU usage should be minimal when idle
   - During conversion, usage should scale with concurrent operations

3. **Disk I/O**
   - Verify that temporary files are cleaned up
   - Check that output files are created correctly

## Troubleshooting Installation Issues

### Common Problems

**"Application cannot be opened because it is from an unidentified developer"**

*Solution:*
1. Right-click the application
2. Select "Open" from the context menu
3. Click "Open" in the security dialog
4. The application will be remembered as safe for future launches

**"No such file or directory" when building from source**

*Solution:*
1. Ensure Xcode Command Line Tools are installed:
   ```bash
   xcode-select --install
   ```
2. Verify Swift is available:
   ```bash
   swift --version
   ```
3. Check that you're in the correct directory

**Build errors in Xcode**

*Solution:*
1. Clean the build folder (Product > Clean Build Folder)
2. Ensure you're using a compatible Xcode version
3. Check that all dependencies are resolved
4. Verify your development team is selected for signing

**Permission denied errors**

*Solution:*
1. Check file permissions on the project directory
2. Ensure you have write access to the build output directory
3. Run with appropriate permissions if needed

### Advanced Troubleshooting

**Enable Debug Logging:**
1. Build with debug configuration:
   ```bash
   swift build -c debug
   ```
2. Run with verbose output:
   ```bash
   swift run PlaylistToAIFFConverter --verbose
   ```

**Check System Compatibility:**
1. Verify macOS version:
   ```bash
   sw_vers
   ```
2. Check architecture:
   ```bash
   uname -m
   ```
3. Confirm available memory:
   ```bash
   system_profiler SPHardwareDataType | grep Memory
   ```

## Uninstallation

### Remove Application

**If installed via Applications folder:**
1. Drag the application to Trash
2. Empty the Trash

**If built from source:**
1. Delete the project directory
2. Remove any build artifacts

### Clean Up Application Data

**Remove preferences and caches:**
```bash
rm -rf ~/Library/Preferences/com.yourcompany.PlaylistToAIFFConverter.plist
rm -rf ~/Library/Caches/com.yourcompany.PlaylistToAIFFConverter
rm -rf ~/Library/Application\ Support/PlaylistToAIFFConverter
```

**Remove temporary files:**
```bash
rm -rf /tmp/PlaylistToAIFFConverter*
```

## Getting Help

### Documentation Resources
- **README.md**: General overview and basic usage
- **USER_MANUAL.md**: Comprehensive user guide
- **TECHNICAL_DOCUMENTATION.md**: Developer and technical details

### Support Channels
- **GitHub Issues**: Report bugs and request features
- **Discussions**: Community support and questions
- **Email Support**: Direct support for critical issues

### Before Seeking Help
1. Check the troubleshooting section above
2. Review the user manual for common solutions
3. Search existing GitHub issues for similar problems
4. Gather system information and error messages

---

**Note**: This installation guide assumes you have basic familiarity with macOS and development tools. If you encounter issues not covered here, please refer to the support resources or create a detailed issue report.

