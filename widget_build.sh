#!/bin/bash

# Focused widget extension build helper for Vecka.

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_FILE="$PROJECT_DIR/Vecka.xcodeproj"
WIDGET_SCHEME_NAME="VeckaWidgetExtension"
DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro'

echo "Building VeckaWidgetExtension..."

xcodebuild build \
    -project "$PROJECT_FILE" \
    -scheme "$WIDGET_SCHEME_NAME" \
    -destination "$DESTINATION" \
    -configuration "Debug" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

echo "VeckaWidgetExtension build completed."
