#!/usr/bin/env bash
# JDS-MAN-SFW-001 source-of-truth validator.
#
# Parses the design-system manual at docs/JDS-MAN-SFW-001_joho-design-system.md
# and cross-checks its claims against the Swift source. Catches drift when the
# code changes but the manual doesn't (or vice versa).
#
# What it checks:
#
#   §1 — File inventory.
#     For each "| `Vecka/...swift` | role |" row, verify the file exists.
#
#   §2.1, §2.2, §2.3, §2.4 — JohoColors token tables.
#     For each "| `TOKEN` | `#HEX` |" row, verify Swift source has
#     "static let TOKEN = Color(hex: \"HEX\")" in Vecka/JohoFoundations.swift.
#
#   §2.6 — PageHeaderColor accent table.
#     For each "| `case` | `#HEX` (...) |" row, verify the enum case
#     resolves to that hex inside Vecka/JohoFoundations.swift.
#
#   §2.7 — SystemUIAccent table.
#     Same pattern as §2.6.
#
#   §6.2 — IconCatalog key constants.
#     For each "| `.NAME` | `SYMBOL` |" row, verify
#     "static let NAME = \"SYMBOL\"" or "static var NAME" exists in
#     Vecka/JohoSymbols.swift. Rows with multiple constants
#     separated by " / " are paired with their respective symbol values.
#     Rows with non-literal values (e.g. ".expense" → "locale-aware")
#     are checked only for the constant existing.
#
#   §7.1–§7.11 — Component tables.
#     For each PascalCase identifier in the first cell, verify a
#     `struct NAME` definition exists somewhere under Vecka/.
#     (§7.12 Shapes uses a different schema and is skipped here.)
#
#   §8 — View modifiers.
#     For each "| `.johoFoo(...)` | … |" row, verify a
#     `func johoFoo(` definition exists somewhere under Vecka/.
#
# Usage:
#   scripts/validate-docs.sh          # check, exit 1 on drift
#   scripts/validate-docs.sh --quiet  # only print on failure

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MANUAL="docs/JDS-MAN-SFW-001_joho-design-system.md"
JOHO_FOUNDATIONS="Vecka/JohoFoundations.swift"
JOHO_SYMBOLS="Vecka/JohoSymbols.swift"

QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

if [[ ! -f "$MANUAL" ]]; then
  echo "✗ Manual not found at $MANUAL"
  exit 1
fi

TOTAL=0
FAILED=0
declare -a FAILURES

assert() {
  local label="$1"
  local cond="$2"
  TOTAL=$((TOTAL + 1))
  if eval "$cond"; then
    if [[ "$QUIET" -eq 0 ]]; then echo "  ✓ $label"; fi
  else
    FAILED=$((FAILED + 1))
    FAILURES+=("$label")
    echo "  ✗ $label"
  fi
}

# Extract table rows between a section header and the next blank-line gap or
# next section. Strips backticks from cells. The section number must be
# followed by whitespace or end-of-line so that querying "7.1" does not
# also match "7.10" / "7.11" / "7.12".
extract_section_rows() {
  local section="$1"
  awk -v section="$section" '
    $0 ~ ("^### " section "( |$)") { in_section = 1; next }
    in_section && /^### / { in_section = 0 }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$MANUAL"
}

# Strip all backticks and surrounding whitespace from a cell value.
# Markdown rows can mix multiple inline-code segments per cell
# (e.g. `.clock` / `.clockOutline`), so we drop every backtick.
clean_cell() {
  echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/`//g'
}

# Verify a JohoColors-style token: TOKEN with expected hex EXPECTED.
# Accepts both "JohoColors.foo" and "foo" forms.
verify_color_token() {
  local token="$1"
  local expected="$2"
  local section="$3"

  # Strip optional JohoColors. prefix.
  local name="${token#JohoColors.}"

  # Strip leading "#" from expected.
  local hex="${expected#\#}"

  # Look up in Swift source.
  local actual_line
  actual_line=$(grep -E "^[[:space:]]*static let $name = Color\(hex: \"[A-Fa-f0-9]+\"\)" "$JOHO_FOUNDATIONS" | head -1 || true)

  if [[ -z "$actual_line" ]]; then
    assert "$section: $token — token missing from $JOHO_FOUNDATIONS" 'false'
    return
  fi

  local actual_hex
  actual_hex=$(echo "$actual_line" | sed -E 's/.*Color\(hex: "([A-Fa-f0-9]+)"\).*/\1/' | tr 'a-f' 'A-F')

  if [[ "$(echo "$hex" | tr 'a-f' 'A-F')" == "$actual_hex" ]]; then
    assert "$section: $token = #$actual_hex" 'true'
  else
    assert "$section: $token — manual claims #$hex, source has #$actual_hex" 'false'
  fi
}

# Verify a PageHeaderColor or SystemUIAccent case has the expected hex
# in the enum's switch over `var accent: Color` / `var color: Color`.
verify_enum_case_hex() {
  local case_name="$1"
  local expected="$2"
  local section="$3"

  local hex="${expected#\#}"

  # Find "case .case_name:  return Color(hex: \"HEX\")"
  local actual_line
  actual_line=$(grep -E "case \.$case_name:[[:space:]]+return Color\(hex: \"[A-Fa-f0-9]+\"\)" "$JOHO_FOUNDATIONS" | head -1 || true)

  if [[ -z "$actual_line" ]]; then
    assert "$section: case .$case_name — not found in $JOHO_FOUNDATIONS" 'false'
    return
  fi

  local actual_hex
  actual_hex=$(echo "$actual_line" | sed -E 's/.*Color\(hex: "([A-Fa-f0-9]+)"\).*/\1/' | tr 'a-f' 'A-F')

  if [[ "$(echo "$hex" | tr 'a-f' 'A-F')" == "$actual_hex" ]]; then
    assert "$section: .$case_name = #$actual_hex" 'true'
  else
    assert "$section: .$case_name — manual claims #$hex, source has #$actual_hex" 'false'
  fi
}

# Verify IconCatalog constant exists with expected SF Symbol value.
# Accepts non-literal expected values (e.g. "locale-aware") — those check
# only that the constant exists as a static let OR static var.
verify_icon_constant() {
  local name="$1"
  local expected_symbol="$2"
  local section="$3"

  # Strip leading "." from name.
  name="${name#.}"

  # Skip empty
  [[ -z "$name" ]] && return

  # Check existence first (static let with literal, or static var).
  local def_line
  def_line=$(grep -E "^[[:space:]]*static (let|var) $name(\b| =|:)" "$JOHO_SYMBOLS" | head -1 || true)

  if [[ -z "$def_line" ]]; then
    assert "$section: IconCatalog.$name — constant missing from $JOHO_SYMBOLS" 'false'
    return
  fi

  # Trim expected.
  expected_symbol="$(echo "$expected_symbol" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  # If expected isn't a literal symbol (e.g. "locale-aware"), existence is enough.
  if [[ "$expected_symbol" == "locale-aware" || -z "$expected_symbol" ]]; then
    assert "$section: IconCatalog.$name (computed/locale-aware)" 'true'
    return
  fi

  # For literal symbols, look for: static let name = "symbol"
  local actual_line
  actual_line=$(grep -E "^[[:space:]]*static let $name = \"[^\"]+\"" "$JOHO_SYMBOLS" | head -1 || true)

  if [[ -z "$actual_line" ]]; then
    # Constant exists but isn't a static-let-with-literal (it's a var/computed).
    # Existence-only check passes.
    assert "$section: IconCatalog.$name (non-literal)" 'true'
    return
  fi

  local actual_symbol
  actual_symbol=$(echo "$actual_line" | sed -E 's/.*= "([^"]+)".*/\1/')

  if [[ "$expected_symbol" == "$actual_symbol" ]]; then
    assert "$section: IconCatalog.$name = $actual_symbol" 'true'
  else
    assert "$section: IconCatalog.$name — manual claims \"$expected_symbol\", source has \"$actual_symbol\"" 'false'
  fi
}

echo "Validating $MANUAL against Swift source..."
echo ""

# ── §1: File inventory ────────────────────────────────────────────────────
if [[ "$QUIET" -eq 0 ]]; then echo "§1"; fi
while IFS= read -r row; do
  IFS='|' read -r _ path_cell _ <<< "$row"
  path="$(clean_cell "$path_cell")"
  [[ "$path" =~ ^Vecka/ ]] || continue
  if [[ -f "$path" ]]; then
    assert "§1: $path exists" 'true'
  else
    assert "§1: $path — file missing" 'false'
  fi
done < <(awk '/^## 1\./ { f=1; next } f && /^## 2\./ { exit } f' "$MANUAL")

# ── §2.1–§2.4: JohoColors hex tables ───────────────────────────────────────
for section_id in "2.1" "2.2" "2.3" "2.4"; do
  if [[ "$QUIET" -eq 0 ]]; then echo "§$section_id"; fi
  while IFS= read -r row; do
    # Skip header rows and separators
    [[ "$row" =~ ^\|[[:space:]]*Token[[:space:]]*\| ]] && continue
    [[ "$row" =~ ^\|[[:space:]]*-+ ]] && continue
    [[ -z "$row" ]] && continue
    # Parse: | `TOKEN` | `#HEX` | ...
    IFS='|' read -r _ token hex _ <<< "$row"
    token="$(clean_cell "$token")"
    hex="$(clean_cell "$hex")"
    [[ -z "$token" || -z "$hex" ]] && continue
    [[ "$hex" =~ ^# ]] || continue  # only hex-value rows
    verify_color_token "$token" "$hex" "§$section_id"
  done < <(extract_section_rows "$section_id")
done

# ── §2.6: PageHeaderColor ──────────────────────────────────────────────────
if [[ "$QUIET" -eq 0 ]]; then echo "§2.6"; fi
while IFS= read -r row; do
  [[ "$row" =~ ^\| ]] || continue                                     # skip non-table rows
  [[ "$row" =~ ^\|[[:space:]]*Case[[:space:]]*\| ]] && continue
  [[ "$row" =~ ^\|[[:space:]]*-+ ]] && continue
  IFS='|' read -r _ case_name accent _ <<< "$row"
  case_name="$(clean_cell "$case_name")"
  accent="$(clean_cell "$accent")"
  # Extract hex from "#XXXXXX (description)" or just "#XXXXXX"
  hex=$(echo "$accent" | grep -oE '#[A-Fa-f0-9]+' | head -1 || true)
  [[ -z "$case_name" || -z "$hex" ]] && continue
  verify_enum_case_hex "$case_name" "$hex" "§2.6"
done < <(extract_section_rows "2.6")

# ── §2.7: SystemUIAccent ──────────────────────────────────────────────────
if [[ "$QUIET" -eq 0 ]]; then echo "§2.7"; fi
while IFS= read -r row; do
  [[ "$row" =~ ^\| ]] || continue
  [[ "$row" =~ ^\|[[:space:]]*Case[[:space:]]*\| ]] && continue
  [[ "$row" =~ ^\|[[:space:]]*-+ ]] && continue
  IFS='|' read -r _ case_name hex _ <<< "$row"
  case_name="$(clean_cell "$case_name")"
  hex="$(clean_cell "$hex")"
  [[ "$hex" =~ ^# ]] || continue
  verify_enum_case_hex "$case_name" "$hex" "§2.7"
done < <(extract_section_rows "2.7")

# ── §6.2: IconCatalog key constants ────────────────────────────────────────
if [[ "$QUIET" -eq 0 ]]; then echo "§6.2"; fi
while IFS= read -r row; do
  [[ "$row" =~ ^\| ]] || continue
  [[ "$row" =~ ^\|[[:space:]]*Constant[[:space:]]*\| ]] && continue
  [[ "$row" =~ ^\|[[:space:]]*-+ ]] && continue
  IFS='|' read -r _ constant symbol _ <<< "$row"
  constant="$(clean_cell "$constant")"
  symbol="$(clean_cell "$symbol")"
  [[ -z "$constant" ]] && continue
  # Skip non-row content (e.g. note paragraphs after the table)
  [[ "$constant" =~ ^\. ]] || continue

  # Handle slash-separated constants (e.g. ".clock / .clockOutline")
  if [[ "$constant" == *" / "* ]]; then
    IFS=' / ' read -ra constants <<< "$constant"
    IFS=' / ' read -ra symbols <<< "$symbol"
    for i in "${!constants[@]}"; do
      verify_icon_constant "${constants[i]}" "${symbols[i]:-}" "§6.2"
    done
  else
    verify_icon_constant "$constant" "$symbol" "§6.2"
  fi
done < <(extract_section_rows "6.2")

# ── §7.1–§7.11: Component struct existence ────────────────────────────────
# Precompute the set of all `struct NAME` definitions under Vecka/ (any
# access level). Cross-check each PascalCase identifier appearing in the
# first cell of each §7.x table against this set.
VECKA_STRUCTS=$(grep -rhE "^[[:space:]]*(public |private |internal |fileprivate )?struct [A-Z][A-Za-z0-9]+" Vecka --include="*.swift" \
  | sed -E 's/.*struct ([A-Z][A-Za-z0-9]+).*/\1/' | sort -u)

for sub in "7.1" "7.2" "7.3" "7.4" "7.5" "7.6" "7.7" "7.8" "7.9" "7.10" "7.11"; do
  if [[ "$QUIET" -eq 0 ]]; then echo "§$sub"; fi
  while IFS= read -r row; do
    [[ "$row" =~ ^\| ]] || continue
    [[ "$row" =~ ^\|[[:space:]]*Component[[:space:]]*\| ]] && continue
    [[ "$row" =~ ^\|[[:space:]]*-+ ]] && continue
    IFS='|' read -r _ name_cell _ <<< "$row"
    name_cell="$(clean_cell "$name_cell")"
    # Cells may list multiple identifiers separated by commas.
    IFS=',' read -ra parts <<< "$name_cell"
    for raw_name in "${parts[@]}"; do
      n="$(echo "$raw_name" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      # Only check bare PascalCase identifiers — skip modifier names,
      # parenthesised forms, and descriptive prose.
      [[ "$n" =~ ^[A-Z][A-Za-z0-9]+$ ]] || continue
      if echo "$VECKA_STRUCTS" | grep -qx "$n"; then
        assert "§$sub: struct $n exists" 'true'
      else
        assert "§$sub: struct $n — not found in Vecka/" 'false'
      fi
    done
  done < <(extract_section_rows "$sub")
done

# ── §8: View modifier existence ───────────────────────────────────────────
# Precompute the set of `func johoFoo(` definitions under Vecka/, then for
# each "| `.johoFoo(...)` | … |" row, verify the modifier function exists.
VECKA_JOHO_FUNCS=$(grep -rhE "^[[:space:]]*func joho[A-Za-z0-9]+\(" Vecka --include="*.swift" \
  | sed -E 's/.*func (joho[A-Za-z0-9]+)\(.*/\1/' | sort -u)

if [[ "$QUIET" -eq 0 ]]; then echo "§8"; fi
while IFS= read -r row; do
  [[ "$row" =~ ^\| ]] || continue
  IFS='|' read -r _ mod_cell _ <<< "$row"
  mod_cell="$(clean_cell "$mod_cell")"
  # Strip leading "." and trim from "(" onward → function name.
  fn_name="${mod_cell#.}"
  fn_name="${fn_name%%\(*}"
  [[ "$fn_name" =~ ^joho[A-Za-z0-9]+$ ]] || continue
  if echo "$VECKA_JOHO_FUNCS" | grep -qx "$fn_name"; then
    assert "§8: .$fn_name() exists" 'true'
  else
    assert "§8: .$fn_name() — function missing from Vecka/" 'false'
  fi
done < <(awk '/^## 8\./ { f=1; next } f && /^## 9\./ { exit } f' "$MANUAL")

echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo "✓ Doc validation passed: $TOTAL/$TOTAL assertions OK."
  exit 0
else
  echo "✗ Doc validation failed: $FAILED/$TOTAL assertions failed."
  for f in "${FAILURES[@]}"; do
    echo "    $f"
  done
  exit 1
fi
