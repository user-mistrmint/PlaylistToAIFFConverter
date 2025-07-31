#!/bin/bash

# iTunes Playlist to AIFF Converter - Build Script
# This script builds the macOS application bundle

set -e  # Exit on any error

# Configuration
PROJECT_NAME="PlaylistToAIFFConverter"
SCHEME_NAME="PlaylistToAIFFConverter"
CONFIGURATION="Release"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"
APP_NAME="$PROJECT_NAME.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Xcode is installed
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode command line tools not found. Please install Xcode."
        exit 1
    fi
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script must be run on macOS."
        exit 1
    fi
    
    # Check if project file exists
    if [ ! -f "$PROJECT_NAME.xcodeproj/project.pbxproj" ]; then
        log_error "Xcode project file not found. Please run this script from the project root directory."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Clean previous builds
clean_build() {
    log_info "Cleaning previous builds..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    # Clean Xcode build cache
    xcodebuild clean -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME_NAME" -configuration "$CONFIGURATION" > /dev/null 2>&1 || true
    
    log_success "Clean completed"
}

# Build the application
build_app() {
    log_info "Building $PROJECT_NAME..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    # Build and archive the project
    log_info "Creating archive..."
    xcodebuild archive \
        -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=macOS" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        | grep -E "(error|warning|note|Archive succeeded)" || true
    
    if [ ! -d "$ARCHIVE_PATH" ]; then
        log_error "Archive creation failed"
        exit 1
    fi
    
    log_success "Archive created successfully"
}

# Export the application
export_app() {
    log_info "Exporting application..."
    
    # Create export options plist
    cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>destination</key>
    <string>export</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string></string>
</dict>
</plist>
EOF

    # Export the archive
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
        | grep -E "(error|warning|note|Export succeeded)" || true
    
    if [ ! -d "$EXPORT_PATH/$APP_NAME" ]; then
        log_error "Export failed"
        exit 1
    fi
    
    log_success "Application exported successfully"
}

# Create DMG (optional)
create_dmg() {
    log_info "Creating DMG installer..."
    
    DMG_NAME="$PROJECT_NAME-v1.0.dmg"
    DMG_PATH="$BUILD_DIR/$DMG_NAME"
    
    # Create temporary DMG directory
    DMG_TEMP_DIR="$BUILD_DIR/dmg_temp"
    mkdir -p "$DMG_TEMP_DIR"
    
    # Copy application to DMG directory
    cp -R "$EXPORT_PATH/$APP_NAME" "$DMG_TEMP_DIR/"
    
    # Create Applications symlink
    ln -s /Applications "$DMG_TEMP_DIR/Applications"
    
    # Create DMG
    hdiutil create -volname "$PROJECT_NAME" \
        -srcfolder "$DMG_TEMP_DIR" \
        -ov -format UDZO \
        "$DMG_PATH" > /dev/null 2>&1
    
    if [ -f "$DMG_PATH" ]; then
        log_success "DMG created: $DMG_PATH"
    else
        log_warning "DMG creation failed, but application bundle is available"
    fi
    
    # Clean up temporary directory
    rm -rf "$DMG_TEMP_DIR"
}

# Verify the build
verify_build() {
    log_info "Verifying build..."
    
    APP_PATH="$EXPORT_PATH/$APP_NAME"
    
    # Check if app bundle exists
    if [ ! -d "$APP_PATH" ]; then
        log_error "Application bundle not found"
        exit 1
    fi
    
    # Check if executable exists
    EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/$PROJECT_NAME"
    if [ ! -f "$EXECUTABLE_PATH" ]; then
        log_error "Application executable not found"
        exit 1
    fi
    
    # Check if executable is valid
    if ! file "$EXECUTABLE_PATH" | grep -q "Mach-O"; then
        log_error "Invalid executable format"
        exit 1
    fi
    
    # Get app info
    APP_VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Unknown")
    APP_BUILD=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "Unknown")
    
    log_success "Build verification passed"
    log_info "Application: $PROJECT_NAME"
    log_info "Version: $APP_VERSION"
    log_info "Build: $APP_BUILD"
    log_info "Location: $APP_PATH"
}

# Print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --clean     Clean build directory before building"
    echo "  -d, --dmg       Create DMG installer"
    echo "  -h, --help      Show this help message"
    echo "  -v, --verbose   Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0              Build the application"
    echo "  $0 --clean     Clean and build"
    echo "  $0 --dmg       Build and create DMG"
}

# Main execution
main() {
    local clean_first=false
    local create_dmg_flag=false
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--clean)
                clean_first=true
                shift
                ;;
            -d|--dmg)
                create_dmg_flag=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Enable verbose output if requested
    if [ "$verbose" = true ]; then
        set -x
    fi
    
    log_info "Starting build process for $PROJECT_NAME"
    
    # Execute build steps
    check_prerequisites
    
    if [ "$clean_first" = true ]; then
        clean_build
    fi
    
    build_app
    export_app
    verify_build
    
    if [ "$create_dmg_flag" = true ]; then
        create_dmg
    fi
    
    log_success "Build completed successfully!"
    log_info "Application bundle: $EXPORT_PATH/$APP_NAME"
    
    if [ "$create_dmg_flag" = true ] && [ -f "$BUILD_DIR/$PROJECT_NAME-v1.0.dmg" ]; then
        log_info "DMG installer: $BUILD_DIR/$PROJECT_NAME-v1.0.dmg"
    fi
}

# Run main function with all arguments
main "$@"

