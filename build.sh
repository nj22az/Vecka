#!/bin/bash

# Vecka iOS App Build Script
# Comprehensive build script for main app, widget extension, and shared framework
# Author: DevOps Engineer
# Usage: ./build.sh [clean|build|test|archive|widget-test]

set -e  # Exit on any error

# Configuration
PROJECT_NAME="Vecka"
SCHEME_NAME="Vecka"
PROJECT_FILE="Vecka.xcodeproj"
BUILD_CONFIG="Debug"
DESTINATION='platform=iOS Simulator,name=iPhone 16'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Function to display usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  clean          Clean build directories"
    echo "  build          Build all targets (Debug)"
    echo "  build-release  Build all targets (Release)"
    echo "  test           Run unit tests"
    echo "  widget-test    Test widget extension specifically"
    echo "  archive        Create archive build"
    echo "  validate       Validate project configuration"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 clean"
    echo "  $0 build"
    echo "  $0 test"
    echo "  $0 widget-test"
}

# Function to validate project setup
validate_project() {
    log_info "Validating project configuration..."
    
    # Check if project file exists
    if [ ! -d "$PROJECT_FILE" ]; then
        log_error "Project file $PROJECT_FILE not found!"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -d "Vecka" ] || [ ! -d "VeckaWidget" ] || [ ! -d "VeckaShared" ]; then
        log_error "Missing required directories. Please run from project root."
        exit 1
    fi
    
    # Check Xcode version
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    log_info "Using $XCODE_VERSION"
    
    log_success "Project validation passed"
}

# Function to clean build
clean_build() {
    log_info "Cleaning build directories..."
    
    xcodebuild clean \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -destination "$DESTINATION"
    
    # Clean derived data
    if [ -n "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        log_info "Cleaned derived data directory"
    fi
    
    log_success "Clean completed"
}

# Function to build all targets
build_project() {
    local config=${1:-$BUILD_CONFIG}
    log_info "Building project with configuration: $config"
    
    xcodebuild build \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -destination "$DESTINATION" \
        -configuration "$config" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
    
    log_success "Build completed successfully"
}

# Function to run tests
run_tests() {
    log_info "Running unit tests..."
    
    xcodebuild test \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -destination "$DESTINATION" \
        -configuration "$BUILD_CONFIG" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
    
    log_success "Tests completed"
}

# Function to test widget specifically
test_widget() {
    log_info "Testing widget extension build..."
    
    # Build just the widget extension
    xcodebuild build \
        -project "$PROJECT_FILE" \
        -target "VeckaWidget" \
        -destination "$DESTINATION" \
        -configuration "$BUILD_CONFIG" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
    
    log_success "Widget extension build test completed"
}

# Function to create archive
archive_project() {
    log_info "Creating archive build..."
    
    xcodebuild archive \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -configuration "Release" \
        -archivePath "./build/Vecka.xcarchive" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
    
    log_success "Archive created at ./build/Vecka.xcarchive"
}

# Function to show build summary
show_build_summary() {
    log_info "Build Summary:"
    echo "  Project: $PROJECT_NAME"
    echo "  Targets: Main App (Vecka), Widget Extension (VeckaWidget), Shared Framework (VeckaShared)"
    echo "  Bundle IDs:"
    echo "    - Main App: Johansson.Vecka"
    echo "    - Widget: Johansson.Vecka.VeckaWidget"
    echo "    - Shared: Johansson.VeckaShared"
    echo "  Deployment Target: iOS 17.0+ (Widget), iOS 18.0+ (Main App)"
    echo "  Configuration: $BUILD_CONFIG"
    echo "  Destination: $DESTINATION"
}

# Main script logic
main() {
    local command=${1:-help}
    
    case "$command" in
        clean)
            validate_project
            clean_build
            ;;
        build)
            validate_project
            clean_build
            build_project "Debug"
            show_build_summary
            ;;
        build-release)
            validate_project
            clean_build
            build_project "Release"
            show_build_summary
            ;;
        test)
            validate_project
            run_tests
            ;;
        widget-test)
            validate_project
            test_widget
            ;;
        archive)
            validate_project
            clean_build
            archive_project
            ;;
        validate)
            validate_project
            log_success "Project validation completed"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"