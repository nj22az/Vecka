#!/bin/bash

# Widget Configuration Validator and Fixer
# This script helps identify and document Xcode project configuration issues

set -e

PROJECT_DIR="/Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka"
cd "$PROJECT_DIR"

echo "==================================="
echo "Widget Configuration Validator"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "📋 Checking Widget Files..."
echo ""

# Check if localization files exist
echo "✓ Localization Files:"
if [ -d "VeckaWidget/en.lproj" ]; then
    echo "  ${GREEN}✓${NC} English localization exists"
    if [ -f "VeckaWidget/en.lproj/Localizable.strings" ]; then
        echo "    ${GREEN}✓${NC} Localizable.strings found"
    else
        echo "    ${RED}✗${NC} Localizable.strings missing"
    fi
else
    echo "  ${RED}✗${NC} English localization directory missing"
fi

if [ -d "VeckaWidget/sv.lproj" ]; then
    echo "  ${GREEN}✓${NC} Swedish localization exists"
    if [ -f "VeckaWidget/sv.lproj/Localizable.strings" ]; then
        echo "    ${GREEN}✓${NC} Localizable.strings found"
    else
        echo "    ${RED}✗${NC} Localizable.strings missing"
    fi
else
    echo "  ${RED}✗${NC} Swedish localization directory missing"
fi

echo ""

# Check entitlements
echo "✓ Entitlements Files:"
if [ -f "Vecka/Vecka.entitlements" ]; then
    echo "  ${GREEN}✓${NC} Main app entitlements exists"
    if grep -q "group.Johansson.Vecka" "Vecka/Vecka.entitlements"; then
        echo "    ${GREEN}✓${NC} App Group configured: group.Johansson.Vecka"
    else
        echo "    ${YELLOW}⚠${NC} App Group not found in entitlements"
    fi
else
    echo "  ${RED}✗${NC} Main app entitlements missing"
fi

if [ -f "VeckaWidget/VeckaWidget.entitlements" ]; then
    echo "  ${GREEN}✓${NC} Widget entitlements exists"
    if grep -q "group.Johansson.Vecka" "VeckaWidget/VeckaWidget.entitlements"; then
        echo "    ${GREEN}✓${NC} App Group configured: group.Johansson.Vecka"
    else
        echo "    ${YELLOW}⚠${NC} App Group not found in entitlements"
    fi
else
    echo "  ${RED}✗${NC} Widget entitlements missing"
fi

echo ""

# Check Swift files
echo "✓ Widget Swift Files:"
WIDGET_FILES=(
    "VeckaWidget/VeckaWidget.swift"
    "VeckaWidget/Provider.swift"
    "VeckaWidget/Theme.swift"
    "VeckaWidget/HolidayHelper.swift"
    "VeckaWidget/Views/SmallWidgetView.swift"
    "VeckaWidget/Views/MediumWidgetView.swift"
    "VeckaWidget/Views/LargeWidgetView.swift"
)

for file in "${WIDGET_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ${GREEN}✓${NC} $file"
    else
        echo "  ${RED}✗${NC} $file (missing)"
    fi
done

echo ""
echo "==================================="
echo "📝 XCODE CONFIGURATION CHECKLIST"
echo "==================================="
echo ""
echo "You need to configure these settings in Xcode:"
echo ""
echo "1️⃣  ${YELLOW}VeckaWidgetExtension Target${NC}"
echo "   ────────────────────────────────"
echo "   Go to: Build Phases → Copy Bundle Resources"
echo "   "
echo "   ${GREEN}REMOVE these (they should NOT be here):${NC}"
echo "   ❌ VeckaWidget.entitlements"
echo "   ❌ WidgetInfo.plist"
echo "   ❌ All .swift files (VeckaWidget.swift, Provider.swift, etc.)"
echo "   ❌ Components/*.swift"
echo "   ❌ Views/*.swift"
echo ""
echo "   ${GREEN}KEEP these (localization files):${NC}"
echo "   ✓ en.lproj/Localizable.strings"
echo "   ✓ sv.lproj/Localizable.strings"
echo "   ✓ Any other .lproj folders"
echo ""
echo "2️⃣  ${YELLOW}VeckaWidgetExtension Target${NC}"
echo "   ────────────────────────────────"
echo "   Go to: Build Settings"
echo "   Search for: 'Code Signing Entitlements'"
echo "   Set to: ${GREEN}VeckaWidget/VeckaWidget.entitlements${NC}"
echo ""
echo "3️⃣  ${YELLOW}VeckaWidgetExtension Target${NC}"
echo "   ────────────────────────────────"
echo "   Go to: Signing & Capabilities"
echo "   Click: + Capability"
echo "   Add: ${GREEN}App Groups${NC}"
echo "   Enable: ${GREEN}group.Johansson.Vecka${NC}"
echo ""
echo "4️⃣  ${YELLOW}Vecka Target (Main App)${NC}"
echo "   ────────────────────────────────"
echo "   Go to: Signing & Capabilities"
echo "   Click: + Capability (if not already added)"
echo "   Add: ${GREEN}App Groups${NC}"
echo "   Enable: ${GREEN}group.Johansson.Vecka${NC}"
echo ""
echo "==================================="
echo "🔍 VERIFICATION STEPS"
echo "==================================="
echo ""
echo "After making changes in Xcode:"
echo ""
echo "1. Clean build folder: ${YELLOW}Cmd+Shift+K${NC}"
echo "2. Build project: ${YELLOW}Cmd+B${NC}"
echo "3. Verify no warnings about:"
echo "   - Copy Bundle Resources"
echo "   - .swift files in wrong build phase"
echo "   - .entitlements files in resources"
echo ""
echo "4. Test widget localization:"
echo "   - English device: Should show '${GREEN}Week${NC}'"
echo "   - Swedish device: Should show '${GREEN}Vecka${NC}'"
echo ""
echo "==================================="
echo "📄 File Structure Summary"
echo "==================================="
echo ""
echo "Project structure:"
tree -L 2 -I 'build|DerivedData' VeckaWidget/ 2>/dev/null || ls -R VeckaWidget/ | head -30
echo ""
echo "==================================="
echo "✅ Script Complete"
echo "==================================="
echo ""
echo "Next step: Open Vecka.xcodeproj in Xcode and follow the checklist above."
echo ""
