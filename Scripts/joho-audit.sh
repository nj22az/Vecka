#!/bin/bash
# 情報デザイン Audit Script
# Run this to find potential design system violations

echo "═══════════════════════════════════════════════════════════"
echo "         情報デザイン (Jōhō Dezain) AUDIT REPORT"
echo "═══════════════════════════════════════════════════════════"
echo ""

PROJECT_DIR="${1:-.}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

violation_count=0

echo "📁 Scanning: $PROJECT_DIR"
echo ""

# 1. Check for forbidden glass/blur materials
echo "─────────────────────────────────────────────────────────────"
echo "🔍 CHECK 1: Glass/Blur Materials (FORBIDDEN)"
echo "─────────────────────────────────────────────────────────────"
results=$(grep -rn "ultraThinMaterial\|thinMaterial\|regularMaterial\|thickMaterial\|\.bar\b" --include="*.swift" "$PROJECT_DIR" 2>/dev/null)
if [ -n "$results" ]; then
    echo -e "${RED}❌ VIOLATIONS FOUND:${NC}"
    echo "$results"
    violation_count=$((violation_count + $(echo "$results" | wc -l)))
else
    echo -e "${GREEN}✅ No glass/blur materials found${NC}"
fi
echo ""

# 2. Check for non-continuous corner radius
echo "─────────────────────────────────────────────────────────────"
echo "🔍 CHECK 2: Non-Continuous Corners"
echo "─────────────────────────────────────────────────────────────"
results=$(grep -rn "\.cornerRadius(" --include="*.swift" "$PROJECT_DIR" 2>/dev/null | grep -v "style: .continuous")
if [ -n "$results" ]; then
    echo -e "${YELLOW}⚠️  POTENTIAL ISSUES (verify .continuous is used):${NC}"
    echo "$results"
else
    echo -e "${GREEN}✅ No simple cornerRadius calls found${NC}"
fi
echo ""

# 3. Check for raw system colors (should use JohoColors)
echo "─────────────────────────────────────────────────────────────"
echo "🔍 CHECK 3: Raw System Colors (Should use JohoColors)"
echo "─────────────────────────────────────────────────────────────"
results=$(grep -rn "Color\.blue\|Color\.red\|Color\.green\|Color\.orange\|Color\.purple\|Color\.pink\|Color\.cyan\|Color\.yellow" --include="*.swift" "$PROJECT_DIR" 2>/dev/null | grep -v "JohoDesignSystem")
if [ -n "$results" ]; then
    echo -e "${RED}❌ VIOLATIONS FOUND:${NC}"
    echo "$results"
    violation_count=$((violation_count + $(echo "$results" | wc -l)))
else
    echo -e "${GREEN}✅ No raw system colors found${NC}"
fi
echo ""

# 4. Check for gradients
echo "─────────────────────────────────────────────────────────────"
echo "🔍 CHECK 4: Gradients (FORBIDDEN)"
echo "─────────────────────────────────────────────────────────────"
results=$(grep -rn "LinearGradient\|RadialGradient\|AngularGradient" --include="*.swift" "$PROJECT_DIR" 2>/dev/null)
if [ -n "$results" ]; then
    echo -e "${RED}❌ VIOLATIONS FOUND:${NC}"
    echo "$results"
    violation_count=$((violation_count + $(echo "$results" | wc -l)))
else
    echo -e "${GREEN}✅ No gradients found${NC}"
fi
echo ""

# 5. Check for heavy shadows
echo "─────────────────────────────────────────────────────────────"
echo "🔍 CHECK 5: Heavy Shadows (Discouraged)"
echo "─────────────────────────────────────────────────────────────"
results=$(grep -rn "\.shadow(" --include="*.swift" "$PROJECT_DIR" 2>/dev/null)
if [ -n "$results" ]; then
    echo -e "${YELLOW}⚠️  SHADOWS FOUND (verify they're subtle):${NC}"
    echo "$results"
else
    echo -e "${GREEN}✅ No shadows found${NC}"
fi
echo ""

# 6. Check for missing .design(.rounded)
echo "─────────────────────────────────────────────────────────────"
echo "🔍 CHECK 6: Typography (should use .rounded)"
echo "─────────────────────────────────────────────────────────────"
results=$(grep -rn "\.font(.system(" --include="*.swift" "$PROJECT_DIR" 2>/dev/null | grep -v "\.rounded")
if [ -n "$results" ]; then
    echo -e "${YELLOW}⚠️  FONTS WITHOUT .rounded:${NC}"
    echo "$results"
else
    echo -e "${GREEN}✅ All system fonts use .rounded${NC}"
fi
echo ""

# 7. Check for excessive top padding
echo "─────────────────────────────────────────────────────────────"
echo "🔍 CHECK 7: Excessive Top Padding (max 8pt allowed)"
echo "─────────────────────────────────────────────────────────────"
results=$(grep -rn "\.padding(.top," --include="*.swift" "$PROJECT_DIR" 2>/dev/null | grep -E "\.(padding\(.top, [2-9][0-9]|padding\(.top, [1-9][0-9][0-9])")
if [ -n "$results" ]; then
    echo -e "${RED}❌ EXCESSIVE TOP PADDING:${NC}"
    echo "$results"
    violation_count=$((violation_count + $(echo "$results" | wc -l)))
else
    echo -e "${GREEN}✅ No excessive top padding found${NC}"
fi
echo ""

# 8. Check backgrounds have borders
echo "─────────────────────────────────────────────────────────────"
echo "🔍 CHECK 8: Backgrounds (verify all have borders)"
echo "─────────────────────────────────────────────────────────────"
echo -e "${YELLOW}ℹ️  Files with .background() - manually verify borders:${NC}"
grep -rln "\.background(" --include="*.swift" "$PROJECT_DIR" 2>/dev/null | head -10
echo ""

# 9. Check for old color systems
echo "─────────────────────────────────────────────────────────────"
echo "🔍 CHECK 9: Old Color Systems (should be removed)"
echo "─────────────────────────────────────────────────────────────"
results=$(grep -rn "SlateColors\|AppColors\|ThemeColors" --include="*.swift" "$PROJECT_DIR" 2>/dev/null)
if [ -n "$results" ]; then
    echo -e "${RED}❌ OLD COLOR SYSTEM FOUND:${NC}"
    echo "$results"
    violation_count=$((violation_count + $(echo "$results" | wc -l)))
else
    echo -e "${GREEN}✅ No old color systems found${NC}"
fi
echo ""

# Summary
echo "═══════════════════════════════════════════════════════════"
echo "                      AUDIT SUMMARY"
echo "═══════════════════════════════════════════════════════════"
if [ $violation_count -eq 0 ]; then
    echo -e "${GREEN}✅ No critical violations found!${NC}"
else
    echo -e "${RED}❌ Found $violation_count critical violation(s)${NC}"
fi
echo ""
echo "Remember: Every container needs a border. Every color needs meaning."
echo "═══════════════════════════════════════════════════════════"
