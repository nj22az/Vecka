#!/bin/bash

# 情報デザイン Compliance Audit Script
# Run: ./audit_joho.sh

PROJECT_DIR="$(dirname "$0")/Vecka"
VIOLATIONS=0
WARNINGS=0

echo "====================================="
echo "情報デザイン COMPLIANCE AUDIT"
echo "====================================="
echo "Project: $PROJECT_DIR"
echo "Date: $(date '+%Y-%m-%d %H:%M')"
echo ""

# Function to check and report errors
check_error() {
    local rule_id="$1"
    local description="$2"
    local pattern="$3"

    local results=$(grep -rn "$pattern" --include="*.swift" "$PROJECT_DIR" 2>/dev/null | grep -v "JohoDesignSystem.swift")

    if [ -n "$results" ]; then
        local count=$(echo "$results" | wc -l | tr -d ' ')
        echo "[ERROR] $rule_id: $description"
        echo "   Found: $count occurrence(s)"
        echo "$results" | head -5 | sed 's/^/   /'
        if [ "$count" -gt 5 ]; then
            echo "   ... and $((count - 5)) more"
        fi
        echo ""
        VIOLATIONS=$((VIOLATIONS + count))
    fi
}

# Function to check and report warnings
check_warning() {
    local rule_id="$1"
    local description="$2"
    local pattern="$3"

    local results=$(grep -rn "$pattern" --include="*.swift" "$PROJECT_DIR" 2>/dev/null | grep -v "JohoDesignSystem.swift")

    if [ -n "$results" ]; then
        local count=$(echo "$results" | wc -l | tr -d ' ')
        echo "[WARN]  $rule_id: $description"
        echo "   Found: $count occurrence(s)"
        echo "$results" | head -3 | sed 's/^/   /'
        if [ "$count" -gt 3 ]; then
            echo "   ... and $((count - 3)) more"
        fi
        echo ""
        WARNINGS=$((WARNINGS + count))
    fi
}

echo "--- ERROR-LEVEL CHECKS ---"
echo ""

# ERROR checks
check_error "RAD-001" "Non-continuous corners (.cornerRadius)" "\.cornerRadius("
check_error "VFX-001" "Glass/blur materials" "ultraThinMaterial\|thinMaterial"
check_error "VFX-002" "Gradient usage" "LinearGradient\|RadialGradient"

echo "--- WARNING-LEVEL CHECKS ---"
echo ""

# WARNING checks
check_warning "COL-001" "Raw system Color usage" "Color\.\(blue\|red\|purple\|gray\)[^A-Za-z]"
check_warning "SPC-001" "Large top padding (>16pt)" "\.padding(\.top, [2-9][0-9]"
check_warning "ANI-001" "Bouncy spring animation" "dampingFraction: 0\.[0-5]"

echo "====================================="
echo "SUMMARY"
echo "====================================="
echo "Errors:   $VIOLATIONS"
echo "Warnings: $WARNINGS"
echo ""

if [ "$VIOLATIONS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo "RESULT: PASS - Fully compliant"
    exit 0
elif [ "$VIOLATIONS" -eq 0 ]; then
    echo "RESULT: PASS with warnings - Review recommended"
    exit 0
else
    echo "RESULT: FAIL - Fix errors before commit"
    exit 1
fi
