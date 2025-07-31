# Build and Distribution Guide

This guide provides comprehensive instructions for building, testing, and distributing the iTunes Playlist to AIFF Converter application.

## Table of Contents

1. [Development Environment Setup](#development-environment-setup)
2. [Building the Application](#building-the-application)
3. [Testing](#testing)
4. [Distribution](#distribution)
5. [Continuous Integration](#continuous-integration)
6. [Release Process](#release-process)
7. [Troubleshooting](#troubleshooting)

## Development Environment Setup

### Prerequisites

**Required Software:**
- macOS 12.0 (Monterey) or later
- Xcode 14.0 or later
- Swift 5.9 or later
- Git (for version control)

**Optional Tools:**
- SwiftLint (code linting): `brew install swiftlint`
- SwiftFormat (code formatting): `brew install swiftformat`
- swift-doc (documentation): `brew install swiftdocorg/formulae/swift-doc`

### Initial Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/user-mistrmint/PlaylistToAIFFConverter.git
   cd PlaylistToAIFFConverter
   ```

2. **Set Up Development Environment**
   ```bash
   make setup
   ```

3. **Verify Setup**
   ```bash
   make check
   ```

## Building the Application

### Quick Build Commands

**Using Make (Recommended):**
```bash
# Build the application
make build

# Clean and build
make clean build

# Build debug version
make build-debug

# Build release with DMG
make release
```

**Using Build Script:**
```bash
# Basic build
./build.sh

# Clean build
./build.sh --clean

# Build with DMG
./build.sh --dmg

# Verbose output
./build.sh --verbose
```

**Using Xcode:**
```bash
# Open in Xcode
make open

# Or manually
open PlaylistToAIFFConverter.xcodeproj
```

### Build Configurations

**Debug Configuration:**
- Optimizations disabled
- Debug symbols included
- Assertions enabled
- Suitable for development and debugging

**Release Configuration:**
- Full optimizations enabled
- Debug symbols stripped
- Assertions disabled
- Suitable for distribution

### Build Outputs

After a successful build, you'll find:

```
build/
├── Export/
│   └── PlaylistToAIFFConverter.app    # Application bundle
├── PlaylistToAIFFConverter.xcarchive  # Xcode archive
├── PlaylistToAIFFConverter-v1.0.dmg   # DMG installer (if created)
└── ExportOptions.plist                # Export configuration
```

## Testing

### Running Tests

**Unit Tests:**
```bash
# Run all tests
make test

# Run tests with verbose output
make test-verbose

# Run specific test suite
xcodebuild test \
  -project PlaylistToAIFFConverter.xcodeproj \
  -scheme PlaylistToAIFFConverter \
  -destination "platform=macOS" \
  -only-testing:PlaylistToAIFFConverterTests/PlaylistParserTests
```

**Manual Testing:**
```bash
# Build and run the application
make run

# Or build and open manually
make build
open build/Export/PlaylistToAIFFConverter.app
```

### Test Coverage

The project includes tests for:
- Playlist parsing functionality
- Data model validation
- Error handling scenarios
- File format detection

To add new tests:
1. Create test files in `Tests/PlaylistToAIFFConverterTests/`
2. Follow the existing test patterns
3. Run tests to verify functionality

## Distribution

### Creating Distribution Packages

**Complete Distribution Package:**
```bash
make package
```

This creates:
- ZIP archive of the application
- DMG installer
- SHA256 checksums for verification

**Manual Distribution Steps:**

1. **Build Release Version:**
   ```bash
   make release
   ```

2. **Create ZIP Archive:**
   ```bash
   cd build/Export
   zip -r PlaylistToAIFFConverter-v1.0.zip PlaylistToAIFFConverter.app
   ```

3. **Create DMG (if not already created):**
   ```bash
   hdiutil create -volname "Playlist to AIFF Converter" \
     -srcfolder build/Export/PlaylistToAIFFConverter.app \
     -ov -format UDZO \
     build/PlaylistToAIFFConverter-v1.0.dmg
   ```

4. **Generate Checksums:**
   ```bash
   cd build
   shasum -a 256 *.dmg *.zip > checksums.sha256
   ```

### Code Signing and Notarization

**For Distribution Outside the App Store:**

1. **Configure Code Signing:**
   - Obtain a Developer ID certificate from Apple
   - Update the Xcode project with your team ID
   - Configure entitlements appropriately

2. **Sign the Application:**
   ```bash
   codesign --force --deep --sign "Developer ID Application: Your Name" \
     build/Export/PlaylistToAIFFConverter.app
   ```

3. **Create Signed DMG:**
   ```bash
   codesign --sign "Developer ID Application: Your Name" \
     build/PlaylistToAIFFConverter-v1.0.dmg
   ```

4. **Notarize with Apple:**
   ```bash
   xcrun notarytool submit build/PlaylistToAIFFConverter-v1.0.dmg \
     --keychain-profile "notarytool-profile" \
     --wait
   ```

5. **Staple Notarization:**
   ```bash
   xcrun stapler staple build/PlaylistToAIFFConverter-v1.0.dmg
   ```

## Continuous Integration

### GitHub Actions Workflow

The project includes a comprehensive GitHub Actions workflow (`.github/workflows/build-and-release.yml`) that:

- Builds the application on every push and pull request
- Runs automated tests
- Creates release artifacts for tagged commits
- Generates DMG installers for releases
- Uploads build artifacts

**Triggering a Release:**

1. **Create and Push a Tag:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Monitor the Build:**
   - Visit the Actions tab in your GitHub repository
   - Watch the build and release process
   - Download artifacts when complete

### Local CI Simulation

**Run the Complete CI Pipeline Locally:**
```bash
# Clean everything
make clean-all

# Check project health
make check

# Run linting (if available)
make lint

# Format code (if available)
make format

# Build and test
make build test

# Create distribution packages
make package
```

## Release Process

### Version Management

**Update Version Number:**
```bash
make update-version VERSION=1.1.0
```

This updates:
- `distribution.json` configuration
- Version references in documentation

**Manual Version Updates:**
1. Update `CFBundleShortVersionString` in Info.plist
2. Update `CFBundleVersion` in Info.plist
3. Update version in `distribution.json`
4. Update version references in documentation
5. Create changelog entry

### Release Checklist

**Pre-Release:**
- [ ] Update version numbers
- [ ] Update changelog
- [ ] Run full test suite
- [ ] Test on multiple macOS versions
- [ ] Verify all documentation is current
- [ ] Test installation process

**Release:**
- [ ] Create and push version tag
- [ ] Monitor GitHub Actions build
- [ ] Verify release artifacts
- [ ] Test downloaded packages
- [ ] Update release notes

**Post-Release:**
- [ ] Announce release
- [ ] Update documentation links
- [ ] Monitor for issues
- [ ] Plan next release

### Release Artifacts

Each release should include:
- **DMG Installer**: For easy installation
- **ZIP Archive**: Alternative distribution method
- **SHA256 Checksums**: For verification
- **Release Notes**: Detailed changelog
- **Documentation**: Updated user guides

## Troubleshooting

### Common Build Issues

**"No such file or directory" Error:**
```bash
# Ensure you're in the project root
pwd
ls -la PlaylistToAIFFConverter.xcodeproj

# Clean and rebuild
make clean build
```

**Code Signing Issues:**
```bash
# Check available signing identities
security find-identity -v -p codesigning

# Build without code signing for testing
xcodebuild build \
  -project PlaylistToAIFFConverter.xcodeproj \
  -scheme PlaylistToAIFFConverter \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

**Swift Package Manager Issues:**
```bash
# Reset package cache
rm -rf ~/.swiftpm
swift package reset

# Update packages
swift package update
```

### Build Performance

**Improve Build Times:**
- Use Xcode's derived data caching
- Enable parallel builds in Xcode
- Use incremental builds during development
- Consider using a build cache system

**Monitor Build Performance:**
```bash
# Time the build process
time make build

# Use Xcode's build timing
xcodebuild build \
  -project PlaylistToAIFFConverter.xcodeproj \
  -scheme PlaylistToAIFFConverter \
  -showBuildTimingSummary
```

### Distribution Issues

**DMG Creation Fails:**
```bash
# Check available disk space
df -h

# Manually create DMG
hdiutil create -help
```

**Notarization Issues:**
```bash
# Check notarization status
xcrun notarytool history --keychain-profile "notarytool-profile"

# Get detailed notarization info
xcrun notarytool info <submission-id> --keychain-profile "notarytool-profile"
```

## Advanced Topics

### Custom Build Configurations

**Creating Custom Configurations:**
1. Open Xcode project
2. Go to Project Settings > Configurations
3. Duplicate existing configuration
4. Modify build settings as needed

**Using Custom Configurations:**
```bash
xcodebuild build \
  -project PlaylistToAIFFConverter.xcodeproj \
  -scheme PlaylistToAIFFConverter \
  -configuration CustomRelease
```

### Build Optimization

**Optimizing for Size:**
- Enable dead code stripping
- Use link-time optimization
- Strip debug symbols in release builds

**Optimizing for Speed:**
- Enable whole module optimization
- Use aggressive optimization levels
- Profile and optimize hot paths

### Debugging Build Issues

**Verbose Build Output:**
```bash
xcodebuild build \
  -project PlaylistToAIFFConverter.xcodeproj \
  -scheme PlaylistToAIFFConverter \
  -verbose
```

**Build Log Analysis:**
```bash
# Save build log for analysis
xcodebuild build \
  -project PlaylistToAIFFConverter.xcodeproj \
  -scheme PlaylistToAIFFConverter \
  > build.log 2>&1
```

## Maintenance

### Regular Maintenance Tasks

**Weekly:**
- Update dependencies
- Run full test suite
- Check for security updates

**Monthly:**
- Review and update documentation
- Analyze build performance
- Update development tools

**Before Each Release:**
- Full security audit
- Performance testing
- Compatibility testing
- Documentation review

### Monitoring

**Build Health:**
- Monitor CI/CD pipeline success rates
- Track build times and performance
- Monitor test coverage

**Distribution Health:**
- Monitor download statistics
- Track user feedback and issues
- Monitor compatibility reports

---

This build guide provides comprehensive instructions for maintaining and distributing the iTunes Playlist to AIFF Converter application. For additional support, refer to the project documentation or create an issue in the GitHub repository.

