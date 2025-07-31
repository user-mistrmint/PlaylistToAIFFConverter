# iTunes Playlist to AIFF Converter - Makefile
# Provides convenient commands for development and building

# Configuration
PROJECT_NAME = PlaylistToAIFFConverter
SCHEME_NAME = PlaylistToAIFFConverter
CONFIGURATION = Release
BUILD_DIR = build
DERIVED_DATA_PATH = $(BUILD_DIR)/DerivedData

# Colors
BLUE = \033[0;34m
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)iTunes Playlist to AIFF Converter - Development Commands$(NC)"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Examples:"
	@echo "  make build          # Build the application"
	@echo "  make clean build    # Clean and build"
	@echo "  make test           # Run tests"
	@echo "  make release        # Build release with DMG"

# Clean targets
.PHONY: clean
clean: ## Clean build artifacts and derived data
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)
	@xcodebuild clean -project $(PROJECT_NAME).xcodeproj -scheme $(SCHEME_NAME) -configuration $(CONFIGURATION) > /dev/null 2>&1 || true
	@echo "$(GREEN)Clean completed$(NC)"

.PHONY: clean-all
clean-all: clean ## Clean everything including Xcode caches
	@echo "$(YELLOW)Cleaning Xcode caches...$(NC)"
	@rm -rf ~/Library/Developer/Xcode/DerivedData/$(PROJECT_NAME)-*
	@rm -rf ~/.swiftpm
	@echo "$(GREEN)Deep clean completed$(NC)"

# Build targets
.PHONY: build
build: ## Build the application
	@echo "$(BLUE)Building $(PROJECT_NAME)...$(NC)"
	@./build.sh
	@echo "$(GREEN)Build completed$(NC)"

.PHONY: build-debug
build-debug: ## Build debug version
	@echo "$(BLUE)Building debug version...$(NC)"
	@xcodebuild build \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME_NAME) \
		-configuration Debug \
		-derivedDataPath $(DERIVED_DATA_PATH)
	@echo "$(GREEN)Debug build completed$(NC)"

.PHONY: archive
archive: ## Create application archive
	@echo "$(BLUE)Creating archive...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@xcodebuild archive \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME_NAME) \
		-configuration $(CONFIGURATION) \
		-archivePath $(BUILD_DIR)/$(PROJECT_NAME).xcarchive \
		-derivedDataPath $(DERIVED_DATA_PATH)
	@echo "$(GREEN)Archive created$(NC)"

.PHONY: release
release: ## Build release version with DMG
	@echo "$(BLUE)Building release with DMG...$(NC)"
	@./build.sh --clean --dmg
	@echo "$(GREEN)Release build completed$(NC)"

# Test targets
.PHONY: test
test: ## Run unit tests
	@echo "$(BLUE)Running tests...$(NC)"
	@xcodebuild test \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME_NAME) \
		-destination "platform=macOS" \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		| grep -E "(Test Suite|Test Case|error|warning|PASS|FAIL)" || true
	@echo "$(GREEN)Tests completed$(NC)"

.PHONY: test-verbose
test-verbose: ## Run tests with verbose output
	@echo "$(BLUE)Running tests with verbose output...$(NC)"
	@xcodebuild test \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME_NAME) \
		-destination "platform=macOS" \
		-derivedDataPath $(DERIVED_DATA_PATH)

# Development targets
.PHONY: open
open: ## Open project in Xcode
	@echo "$(BLUE)Opening project in Xcode...$(NC)"
	@open $(PROJECT_NAME).xcodeproj

.PHONY: run
run: ## Build and run the application
	@echo "$(BLUE)Building and running $(PROJECT_NAME)...$(NC)"
	@xcodebuild build \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME_NAME) \
		-configuration Debug \
		-derivedDataPath $(DERIVED_DATA_PATH)
	@echo "$(GREEN)Launching application...$(NC)"
	@open $(DERIVED_DATA_PATH)/Build/Products/Debug/$(PROJECT_NAME).app

# Utility targets
.PHONY: info
info: ## Show project information
	@echo "$(BLUE)Project Information$(NC)"
	@echo "Name: $(PROJECT_NAME)"
	@echo "Scheme: $(SCHEME_NAME)"
	@echo "Configuration: $(CONFIGURATION)"
	@echo "Build Directory: $(BUILD_DIR)"
	@echo ""
	@echo "$(BLUE)Xcode Information$(NC)"
	@xcodebuild -version 2>/dev/null || echo "Xcode not found"
	@echo ""
	@echo "$(BLUE)Swift Information$(NC)"
	@swift --version 2>/dev/null || echo "Swift not found"

.PHONY: check
check: ## Check project health and dependencies
	@echo "$(BLUE)Checking project health...$(NC)"
	@echo ""
	
	@echo "$(YELLOW)Checking Xcode project...$(NC)"
	@if [ -f "$(PROJECT_NAME).xcodeproj/project.pbxproj" ]; then \
		echo "✅ Xcode project file exists"; \
	else \
		echo "❌ Xcode project file missing"; \
	fi
	
	@echo ""
	@echo "$(YELLOW)Checking source files...$(NC)"
	@if [ -f "$(PROJECT_NAME)/main.swift" ]; then \
		echo "✅ Main source file exists"; \
	else \
		echo "❌ Main source file missing"; \
	fi
	
	@echo ""
	@echo "$(YELLOW)Checking build script...$(NC)"
	@if [ -x "build.sh" ]; then \
		echo "✅ Build script is executable"; \
	else \
		echo "❌ Build script missing or not executable"; \
	fi
	
	@echo ""
	@echo "$(YELLOW)Checking documentation...$(NC)"
	@for doc in README.md USER_MANUAL.md TECHNICAL_DOCUMENTATION.md INSTALLATION_GUIDE.md; do \
		if [ -f "$$doc" ]; then \
			echo "✅ $$doc exists"; \
		else \
			echo "❌ $$doc missing"; \
		fi; \
	done

.PHONY: format
format: ## Format Swift source code
	@echo "$(BLUE)Formatting Swift code...$(NC)"
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat Sources/ --swiftversion 5.9; \
		echo "$(GREEN)Code formatting completed$(NC)"; \
	else \
		echo "$(YELLOW)SwiftFormat not installed. Install with: brew install swiftformat$(NC)"; \
	fi

.PHONY: lint
lint: ## Lint Swift source code
	@echo "$(BLUE)Linting Swift code...$(NC)"
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
		echo "$(GREEN)Linting completed$(NC)"; \
	else \
		echo "$(YELLOW)SwiftLint not installed. Install with: brew install swiftlint$(NC)"; \
	fi

# Package targets
.PHONY: package
package: release ## Create distribution packages
	@echo "$(BLUE)Creating distribution packages...$(NC)"
	@mkdir -p $(BUILD_DIR)/packages
	
	@if [ -d "$(BUILD_DIR)/Export/$(PROJECT_NAME).app" ]; then \
		echo "$(YELLOW)Creating ZIP package...$(NC)"; \
		cd $(BUILD_DIR)/Export && zip -r ../packages/$(PROJECT_NAME)-v1.0.zip $(PROJECT_NAME).app; \
	fi
	
	@if [ -f "$(BUILD_DIR)/$(PROJECT_NAME)-v1.0.dmg" ]; then \
		echo "$(YELLOW)Copying DMG package...$(NC)"; \
		cp $(BUILD_DIR)/$(PROJECT_NAME)-v1.0.dmg $(BUILD_DIR)/packages/; \
	fi
	
	@echo "$(YELLOW)Creating checksums...$(NC)"
	@cd $(BUILD_DIR)/packages && for file in *; do \
		if [ -f "$$file" ]; then \
			shasum -a 256 "$$file" > "$$file.sha256"; \
		fi; \
	done
	
	@echo "$(GREEN)Distribution packages created in $(BUILD_DIR)/packages/$(NC)"
	@ls -la $(BUILD_DIR)/packages/

# Install targets
.PHONY: install
install: build ## Install the application to /Applications
	@echo "$(BLUE)Installing $(PROJECT_NAME) to /Applications...$(NC)"
	@if [ -d "$(BUILD_DIR)/Export/$(PROJECT_NAME).app" ]; then \
		sudo cp -R $(BUILD_DIR)/Export/$(PROJECT_NAME).app /Applications/; \
		echo "$(GREEN)Application installed successfully$(NC)"; \
	else \
		echo "$(RED)Application bundle not found. Run 'make build' first.$(NC)"; \
		exit 1; \
	fi

.PHONY: uninstall
uninstall: ## Uninstall the application from /Applications
	@echo "$(BLUE)Uninstalling $(PROJECT_NAME) from /Applications...$(NC)"
	@if [ -d "/Applications/$(PROJECT_NAME).app" ]; then \
		sudo rm -rf /Applications/$(PROJECT_NAME).app; \
		echo "$(GREEN)Application uninstalled successfully$(NC)"; \
	else \
		echo "$(YELLOW)Application not found in /Applications$(NC)"; \
	fi

# Development setup
.PHONY: setup
setup: ## Set up development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@echo "$(YELLOW)Checking prerequisites...$(NC)"
	
	@if ! command -v xcodebuild >/dev/null 2>&1; then \
		echo "$(RED)Xcode not found. Please install Xcode from the App Store.$(NC)"; \
		exit 1; \
	fi
	
	@echo "$(YELLOW)Making build script executable...$(NC)"
	@chmod +x build.sh
	
	@echo "$(YELLOW)Creating build directory...$(NC)"
	@mkdir -p $(BUILD_DIR)
	
	@echo "$(GREEN)Development environment setup completed$(NC)"
	@echo ""
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "1. Run 'make build' to build the application"
	@echo "2. Run 'make test' to run tests"
	@echo "3. Run 'make open' to open in Xcode"

# Maintenance targets
.PHONY: update-version
update-version: ## Update version number (requires VERSION variable)
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)Please specify VERSION. Example: make update-version VERSION=1.1.0$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Updating version to $(VERSION)...$(NC)"
	@sed -i '' 's/"version": "[^"]*"/"version": "$(VERSION)"/' distribution.json
	@echo "$(GREEN)Version updated to $(VERSION)$(NC)"

# Documentation targets
.PHONY: docs
docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@if command -v swift-doc >/dev/null 2>&1; then \
		swift-doc generate Sources/ --output docs/; \
		echo "$(GREEN)Documentation generated in docs/$(NC)"; \
	else \
		echo "$(YELLOW)swift-doc not installed. Install with: brew install swiftdocorg/formulae/swift-doc$(NC)"; \
	fi

# Show build status
.PHONY: status
status: ## Show current build status
	@echo "$(BLUE)Build Status$(NC)"
	@echo ""
	
	@if [ -d "$(BUILD_DIR)/Export/$(PROJECT_NAME).app" ]; then \
		echo "✅ Application bundle exists"; \
		APP_PATH="$(BUILD_DIR)/Export/$(PROJECT_NAME).app"; \
		if [ -f "$$APP_PATH/Contents/Info.plist" ]; then \
			VERSION=$$(defaults read "$$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Unknown"); \
			BUILD=$$(defaults read "$$APP_PATH/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "Unknown"); \
			echo "📋 Version: $$VERSION"; \
			echo "🔢 Build: $$BUILD"; \
			echo "📦 Size: $$(du -sh "$$APP_PATH" | cut -f1)"; \
		fi; \
	else \
		echo "❌ Application bundle not found"; \
	fi
	
	@echo ""
	@if [ -f "$(BUILD_DIR)/$(PROJECT_NAME)-v1.0.dmg" ]; then \
		echo "✅ DMG installer exists"; \
		echo "💿 Size: $$(du -sh $(BUILD_DIR)/$(PROJECT_NAME)-v1.0.dmg | cut -f1)"; \
	else \
		echo "❌ DMG installer not found"; \
	fi

