#!/usr/bin/env bash
# Joho Design System linter.
#
# Enforces house rules from JDS-MAN-SFW-001 §10 against the Vecka/ and
# VeckaWidget/ source trees. Three rules in v1:
#
#   1. No hardcoded SF Symbol strings outside Vecka/JohoSymbols.swift.
#      Bad:  Image(systemName: "star.fill")
#      Good: Image(systemName: IconCatalog.star)
#
#   2. No hardcoded Color(hex:) literals outside Vecka/JohoFoundations.swift.
#      Bad:  Color(hex: "FFE566")
#      Good: JohoColors.yellow
#      (Per-file allowance lives in scripts/lint-allowlist.txt — a ratchet:
#       counts can only go down. Adding a new literal in an existing file
#       fails the lint until the allowlist is updated.)
#
#   3. No gradients (LinearGradient, RadialGradient, AngularGradient,
#      MeshGradient). The design system forbids gradients.
#
# Content inside #Preview { ... } blocks is exempt from all three rules —
# previews are scaffolding, not production.
#
# Usage:
#   scripts/lint-design-system.sh           # check, exit 1 on violations
#   scripts/lint-design-system.sh --regen   # regenerate the allowlist from
#                                           # current violations (cleanup pass)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ALLOWLIST="scripts/lint-allowlist.txt"
SCAN_DIRS=("Vecka" "VeckaWidget")
REGEN=0

if [[ "${1:-}" == "--regen" ]]; then
  REGEN=1
fi

# --- Stage 1: produce a stream of "file:line:content" with #Preview blocks stripped.
strip_previews() {
  find "${SCAN_DIRS[@]}" -name '*.swift' -print0 | xargs -0 awk '
    FNR == 1 { in_preview = 0; depth = 0 }
    {
      line = $0
      if (in_preview == 0) {
        if (line ~ /#Preview/) {
          in_preview = 1
          n_open = gsub(/\{/, "{", line)
          n_close = gsub(/\}/, "}", line)
          depth = n_open - n_close
          if (depth == 0 && n_open > 0) in_preview = 0
          next
        }
        print FILENAME ":" FNR ":" $0
      } else {
        n_open = gsub(/\{/, "{", line)
        n_close = gsub(/\}/, "}", line)
        depth += n_open - n_close
        if (depth <= 0) in_preview = 0
      }
    }
  '
}

STREAM="$(strip_previews)"

# --- Rule 1: no hardcoded Image(systemName: "literal")
rule1_violations() {
  printf '%s\n' "$STREAM" \
    | grep -E 'Image\(systemName: *"' \
    | grep -v '^Vecka/JohoSymbols\.swift:' || true
}

# --- Rule 2: no hardcoded Color(hex: "literal")
rule2_violations() {
  printf '%s\n' "$STREAM" \
    | grep -E 'Color\(hex: *"' \
    | grep -v '^Vecka/JohoFoundations\.swift:' || true
}

# --- Rule 3: no gradients
rule3_violations() {
  printf '%s\n' "$STREAM" \
    | grep -E '\b(Linear|Radial|Angular|Mesh)Gradient\b' || true
}

# Count violations per file, output "<file> <count>" lines sorted by file.
count_per_file() {
  awk -F: 'NF >= 2 { print $1 }' \
    | sort \
    | uniq -c \
    | awk '{ print $2, $1 }' \
    | sort
}

# --- Regen mode: rewrite the allowlist from current rule-2 violations.
if [[ "$REGEN" -eq 1 ]]; then
  {
    cat <<'HEADER'
# Per-file Color(hex:) allowance — a RATCHET.
#
# Each line: <relative-path> <max-violations-allowed-in-file>
# Counts can only go DOWN. Adding a new literal in any listed file fails the
# lint until the count here is bumped (don't bump it; fix the literal instead
# by moving the color into JohoColors or JohoScheme).
#
# Regenerate from the current source tree:
#     scripts/lint-design-system.sh --regen
HEADER
    echo ""
    rule2_violations | count_per_file
  } > "$ALLOWLIST"
  echo "Regenerated $ALLOWLIST with current Rule #2 violations."
  exit 0
fi

# --- Normal check mode.

EXIT_CODE=0

# Rule 1: any violation fails (no allowlist).
R1="$(rule1_violations)"
if [[ -n "$R1" ]]; then
  echo "✗ Rule #1: hardcoded SF Symbol strings (use IconCatalog.* instead)"
  printf '%s\n' "$R1" | sed 's/^/    /'
  EXIT_CODE=1
fi

# Rule 3: any violation fails (no allowlist).
R3="$(rule3_violations)"
if [[ -n "$R3" ]]; then
  echo "✗ Rule #3: gradients are forbidden by the Joho Design System"
  printf '%s\n' "$R3" | sed 's/^/    /'
  EXIT_CODE=1
fi

# Rule 2: allowlist-based.
if [[ ! -f "$ALLOWLIST" ]]; then
  echo "✗ Allowlist $ALLOWLIST missing — run with --regen to create it."
  exit 1
fi

CURRENT_R2="$(rule2_violations | count_per_file)"

# Compare current counts against allowlist.
declare -A ALLOWED
while read -r path max; do
  [[ -z "${path:-}" || "${path:0:1}" == "#" ]] && continue
  ALLOWED["$path"]="$max"
done < <(grep -v '^#' "$ALLOWLIST" | grep -v '^[[:space:]]*$')

RULE2_FAIL=0
RULE2_DECREASED=()
while read -r path count; do
  [[ -z "${path:-}" ]] && continue
  max="${ALLOWED[$path]:-0}"
  if [[ "$count" -gt "$max" ]]; then
    if [[ "$RULE2_FAIL" -eq 0 ]]; then
      echo "✗ Rule #2: hardcoded Color(hex:) literals exceeded the allowlist"
      RULE2_FAIL=1
      EXIT_CODE=1
    fi
    echo "    $path: $count violations (allowed: $max)"
    printf '%s\n' "$STREAM" \
      | grep -E '^'"$path"': ' \
      | grep -E 'Color\(hex: *"' \
      | sed 's/^/        /'
  elif [[ "$count" -lt "$max" ]]; then
    RULE2_DECREASED+=("$path: $count (allowed: $max) — bump the allowlist down")
  fi
  unset "ALLOWED[$path]"
done <<< "$CURRENT_R2"

# Files in allowlist with zero current violations — clean them up.
for path in "${!ALLOWED[@]}"; do
  RULE2_DECREASED+=("$path: 0 (allowed: ${ALLOWED[$path]}) — remove from allowlist")
done

if [[ "${#RULE2_DECREASED[@]}" -gt 0 ]]; then
  echo "ℹ Rule #2: some files have fewer violations than the allowlist permits."
  echo "  Run 'scripts/lint-design-system.sh --regen' to retighten the ratchet."
  for entry in "${RULE2_DECREASED[@]}"; do
    echo "    $entry"
  done
fi

if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "✓ Design system lint passed."
fi

exit "$EXIT_CODE"
