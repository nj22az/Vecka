#!/bin/bash
# Build script for Information Design book
# Converts manuscript/*.md → book/index.html

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANUSCRIPT_DIR="$SCRIPT_DIR/manuscript"
BOOK_DIR="$SCRIPT_DIR/book"
OUTPUT="$BOOK_DIR/index.html"

echo "Building Information Design book..."

# Check pandoc is available
if ! command -v pandoc &> /dev/null; then
    echo "Error: pandoc is required but not installed."
    echo "Install with: brew install pandoc"
    exit 1
fi

# Create book directory if needed
mkdir -p "$BOOK_DIR/images"

# Build chapter list in order
CHAPTERS=$(ls "$MANUSCRIPT_DIR"/*.md | sort)

# Create temporary combined markdown
TEMP_MD=$(mktemp).md
trap "rm -f $TEMP_MD" EXIT

# Add front matter
cat > "$TEMP_MD" << 'FRONTMATTER'
---
title: "INFORMATION DESIGN"
subtitle: "Joho Dezain"
author: "As Interpreted by Nils Johansson"
---

FRONTMATTER

# Concatenate all chapters
for chapter in $CHAPTERS; do
    cat "$chapter" >> "$TEMP_MD"
    echo -e "\n\n" >> "$TEMP_MD"
done

# Convert to HTML with pandoc
pandoc "$TEMP_MD" \
    --standalone \
    --toc \
    --toc-depth=2 \
    --css="styles.css" \
    --metadata title="Information Design" \
    --variable=lang:en \
    -o "$BOOK_DIR/content.html"

# Create the final HTML with export bar and proper structure
cat > "$OUTPUT" << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Information Design - As Interpreted by Nils Johansson</title>
    <link rel="stylesheet" href="styles.css">
    <style>
        /* Image fallback system */
        .img-container {
            position: relative;
            margin: 1.5em 0;
        }
        .img-container img {
            max-width: 100%;
            height: auto;
            border: 2pt solid #000;
        }
        figure {
            margin: 1.5em 0;
            text-align: center;
            page-break-inside: avoid;
        }
        figcaption {
            font-size: 10pt;
            font-style: italic;
            color: #555;
            margin-top: 0.5em;
        }
        /* TOC styling */
        #TOC {
            background: #f9f9f9;
            border: 2px solid #000;
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
            page-break-after: always;
        }
        #TOC ul {
            list-style: none;
            padding-left: 0;
        }
        #TOC li {
            margin: 0.5em 0;
        }
        #TOC a {
            color: #000;
            text-decoration: none;
        }
        #TOC a:hover {
            text-decoration: underline;
        }
        /* Chapter breaks */
        h1 {
            page-break-before: always;
        }
        h1:first-of-type {
            page-break-before: avoid;
        }
    </style>
</head>
<body>
    <div class="export-bar">
        <button onclick="window.print()">Print / Save as PDF</button>
        <span style="color: #fff; margin-left: 20px;">6" x 9" KDP Format</span>
        <a href="admin.html" style="color: #fff; margin-left: auto; text-decoration: none;">Image Manager →</a>
    </div>

    <!-- TITLE PAGE -->
    <div class="title-page">
        <h1>INFORMATION DESIGN</h1>
        <p class="subtitle">Joho Dezain</p>
        <p class="author">As Interpreted by Nils Johansson</p>
    </div>

    <!-- GENERATED CONTENT -->
HTMLHEAD

# Extract body content from pandoc output and append
sed -n '/<body>/,/<\/body>/p' "$BOOK_DIR/content.html" | sed '1d;$d' >> "$OUTPUT"

# Close HTML
cat >> "$OUTPUT" << 'HTMLFOOT'

</body>
</html>
HTMLFOOT

# Clean up temp file
rm -f "$BOOK_DIR/content.html"

# Count stats
WORD_COUNT=$(cat "$MANUSCRIPT_DIR"/*.md | wc -w | tr -d ' ')
CHAPTER_COUNT=$(ls "$MANUSCRIPT_DIR"/*.md | wc -l | tr -d ' ')

echo ""
echo "✓ Book built successfully!"
echo "  Output: $OUTPUT"
echo "  Chapters: $CHAPTER_COUNT"
echo "  Words: ~$WORD_COUNT"
echo ""
echo "Next steps:"
echo "  1. Open book/index.html in browser"
echo "  2. Use admin.html to add images"
echo "  3. Print → Save as PDF for KDP"
