#!/usr/bin/env bash
# Joho Design System linter.
#
# Enforces the mechanizable house rules from JDS-MAN-SFW-001 §10 against the
# Vecka/ and VeckaWidget/ source trees.
#
# STRICT rules (any violation fails; no allowlist):
#   symbols   §10.1  No Image(systemName: "literal") outside JohoSymbols.swift.
#   gradient  §10.6  No LinearGradient/RadialGradient/AngularGradient/MeshGradient.
#   glass     §10.6  No .ultraThinMaterial/.thinMaterial/…/.blur( materials.
#
# RATCHET rules (per-file allowance in scripts/lint-allowlist.txt; counts may
# only go DOWN — a new violation in a tracked file fails until fixed):
#   colorhex  §10.2  No Color(hex: "…") outside JohoFoundations.swift.
#   colorraw  §10.2  No raw SwiftUI colors (Color.red, Color(.systemX),
#                    Color(red:/white:/uiColor:/cgColor:), .background(.gray)…).
#   corners   §10.3  No .circular / .cornerRadius( / RoundedRectangle without
#                    style: .continuous.
#   fonts     §10.4  .system(…) must set design: .rounded (or .monospaced for
#                    mono variants); no raw text styles (.font(.headline) etc.).
#   weights   §10.7  No font weight below .medium (.thin/.light/.ultraLight).
#
# Preprocessing: #Preview { … } blocks, /* … */ block comments, and full-line
# // / /// comments are stripped before scanning (scaffolding and prose, not
# shipped UI). Inline // comments are NOT stripped (would corrupt "https://…").
#
# Usage:
#   scripts/lint-design-system.sh           # check, exit 1 on violations
#   scripts/lint-design-system.sh --regen   # regenerate the ratchet allowlist

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ALLOWLIST="scripts/lint-allowlist.txt"
SCAN_DIRS=("Vecka" "VeckaWidget")
STRICT_RULES=(symbols gradient glass)
RATCHET_RULES=(colorhex colorraw corners fonts weights)
REGEN=0

if [[ "${1:-}" == "--regen" ]]; then
  REGEN=1
fi

# --- Stage 1: stream of "file:line:content" with #Preview blocks and comments
# stripped. FNR resets per-file so state never leaks across files.
strip_noise() {
  find "${SCAN_DIRS[@]}" -name '*.swift' -print0 | xargs -0 awk '
    FNR == 1 { in_preview = 0; depth = 0; in_block = 0 }
    {
      line = $0

      # --- continue an open /* block comment ---
      if (in_block) {
        if (line ~ /\*\//) { in_block = 0; sub(/^.*\*\//, "", line) }
        else next
      }
      # --- strip self-contained /* ... */ spans on this line ---
      while (match(line, /\/\*.*\*\//)) {
        line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
      }
      # --- open a /* block that has no close on this line ---
      if (match(line, /\/\*/)) { line = substr(line, 1, RSTART - 1); in_block = 1 }

      # --- drop full-line // or /// comments (after leading whitespace) ---
      tmp = line; sub(/^[[:space:]]+/, "", tmp)
      if (tmp ~ /^\/\//) next

      # --- #Preview { ... } block stripping ---
      if (in_preview == 0) {
        if (line ~ /#Preview/) {
          in_preview = 1
          n_open = gsub(/\{/, "{", line); n_close = gsub(/\}/, "}", line)
          depth = n_open - n_close
          if (depth == 0 && n_open > 0) in_preview = 0
          next
        }
        if (line != "") print FILENAME ":" FNR ":" line
      } else {
        n_open = gsub(/\{/, "{", line); n_close = gsub(/\}/, "}", line)
        depth += n_open - n_close
        if (depth <= 0) in_preview = 0
      }
    }
  '
}

STREAM="$(strip_noise)"

NAMED_COLORS='red|blue|green|yellow|orange|purple|pink|gray|grey|black|white|primary|secondary|teal|indigo|mint|cyan|brown|accentColor'

# Emit "file:line:content" violation lines for a given rule id.
violations_for_rule() {
  case "$1" in
    symbols)
      printf '%s\n' "$STREAM" \
        | grep -E '\bImage\(systemName: *"' \
        | grep -v '^Vecka/JohoSymbols\.swift:' || true ;;
    gradient)
      printf '%s\n' "$STREAM" \
        | grep -E '\b(Linear|Radial|Angular|Mesh)Gradient\b' || true ;;
    glass)
      printf '%s\n' "$STREAM" \
        | grep -E '\.(ultraThin|thin|regular|thick|ultraThick)Material\b|\.background\(\.bar\)|\bMaterial\.|\.blur\(' || true ;;
    colorhex)
      printf '%s\n' "$STREAM" \
        | grep -E '\bColor\(hex: *"' \
        | grep -v '^Vecka/JohoFoundations\.swift:' || true ;;
    colorraw)
      printf '%s\n' "$STREAM" \
        | grep -E "\bColor\((red:|white:|uiColor:|cgColor:)|\bColor\(\.(system|dynamic)|\bColor\.($NAMED_COLORS)\b|\.(foregroundStyle|foregroundColor|fill|tint|background|stroke|overlay|border)\(\.($NAMED_COLORS)\b" || true ;;
    corners)
      printf '%s\n' "$STREAM" \
        | grep -E '\.circular\b|\.cornerRadius\(|RoundedRectangle\(cornerRadius:' \
        | grep -v '\.continuous' || true ;;
    fonts)
      { printf '%s\n' "$STREAM" \
          | grep -E '\.system\(' \
          | grep -v 'design: *\.rounded' \
          | grep -v 'design: *\.monospaced'
        printf '%s\n' "$STREAM" \
          | grep -E '\.font\(\.(body|headline|subheadline|caption|caption2|title|title2|title3|largeTitle|callout|footnote)\b'
      } | sort -u || true ;;
    weights)
      printf '%s\n' "$STREAM" \
        | grep -E 'weight: *\.(thin|light|ultraLight)\b|\.fontWeight\(\.(thin|light|ultraLight)\)' || true ;;
    *) return 1 ;;
  esac
}

# Count violations per file: "<file> <count>" sorted by file.
count_per_file() {
  awk -F: 'NF >= 2 { print $1 }' | sort | uniq -c | awk '{ print $2, $1 }' | sort
}

# --- Regen mode: rewrite the allowlist from current ratchet-rule violations.
if [[ "$REGEN" -eq 1 ]]; then
  {
    cat <<'HEADER'
# Per-file violation allowance — a RATCHET.
#
# Each line: <rule> <relative-path> <max-violations-allowed>
# Counts can only go DOWN. Adding a new violation in any listed file fails the
# lint until fixed (don't bump the count; fix the violation by moving the value
# into JohoColors / JohoFont / Squircle etc.).
#
# Rules tracked here: colorhex, colorraw, corners, fonts, weights.
# (symbols, gradient, glass are STRICT — never allowlisted.)
#
# Regenerate from the current source tree:
#     scripts/lint-design-system.sh --regen
HEADER
    echo ""
    for rule in "${RATCHET_RULES[@]}"; do
      while read -r path count; do
        [[ -z "${path:-}" ]] && continue
        echo "$rule $path $count"
      done < <(violations_for_rule "$rule" | count_per_file)
    done
  } > "$ALLOWLIST"
  echo "Regenerated $ALLOWLIST from current violations."
  exit 0
fi

# --- Check mode.
EXIT_CODE=0

# Strict rules: any violation fails.
for rule in "${STRICT_RULES[@]}"; do
  V="$(violations_for_rule "$rule")"
  if [[ -n "$V" ]]; then
    echo "✗ [$rule] forbidden by JDS-MAN-SFW-001 §10:"
    printf '%s\n' "$V" | sed 's/^/    /'
    EXIT_CODE=1
  fi
done

# Ratchet rules: compare per-file counts against the allowlist.
if [[ ! -f "$ALLOWLIST" ]]; then
  echo "✗ Allowlist $ALLOWLIST missing — run with --regen to create it."
  exit 1
fi

declare -A ALLOWED
while read -r rule path max; do
  [[ -z "${rule:-}" || "${rule:0:1}" == "#" ]] && continue
  ALLOWED["$rule:$path"]="$max"
done < <(grep -v '^#' "$ALLOWLIST" | grep -v '^[[:space:]]*$')

DECREASED=()
for rule in "${RATCHET_RULES[@]}"; do
  rule_failed=0
  while read -r path count; do
    [[ -z "${path:-}" ]] && continue
    max="${ALLOWED[$rule:$path]:-0}"
    if [[ "$count" -gt "$max" ]]; then
      if [[ "$rule_failed" -eq 0 ]]; then
        echo "✗ [$rule] hardcoded values exceeded the ratchet allowlist:"
        rule_failed=1
        EXIT_CODE=1
      fi
      echo "    $path: $count (allowed: $max)"
      violations_for_rule "$rule" \
        | grep -E '^'"$path"': ' \
        | sed 's/^/        /'
    elif [[ "$count" -lt "$max" ]]; then
      DECREASED+=("$rule $path: $count (allowed: $max) — tighten")
    fi
    unset "ALLOWED[$rule:$path]"
  done < <(violations_for_rule "$rule" | count_per_file)
done

# Allowlist entries with zero current violations — fully cleaned, can be removed.
for key in "${!ALLOWED[@]}"; do
  DECREASED+=("${key/:/ }: 0 (allowed: ${ALLOWED[$key]}) — remove from allowlist")
done

if [[ "${#DECREASED[@]}" -gt 0 ]]; then
  echo "ℹ Some files have fewer violations than the allowlist permits."
  echo "  Run 'scripts/lint-design-system.sh --regen' to retighten the ratchet."
  for entry in "${DECREASED[@]}"; do echo "    $entry"; done
fi

if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "✓ Design system lint passed."
fi

exit "$EXIT_CODE"
