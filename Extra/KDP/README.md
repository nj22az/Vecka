# KDP Book Creation Pipeline

Multi-agent pipeline for Amazon KDP book creation, powered by Claude Code.

## Overview

Three specialized Claude agents work sequentially to take a book idea from market research to ready-to-publish assets, targeting both **Amazon.com (US)** and **Amazon.it (IT)** markets simultaneously.

```
┌─────────────────────────┐     ┌─────────────────────────┐     ┌─────────────────────────┐
│   Market Intelligence   │     │    Product Design       │     │     Publishing          │
│      Architect          │────▶│       Director          │────▶│   Optimization          │
│      (Phase 1)          │     │      (Phase 2)          │     │    Specialist           │
└─────────────────────────┘     └─────────────────────────┘     └─────────────────────────┘
         │                               │                               │
         ▼                               ▼                               ▼
   NICHE_REPORT_*.md            CONTENT_BLUEPRINT_*.md         PUBLISHING_PACKAGE_*.md
```

## Agents

| Agent | Phase | Output |
|-------|-------|--------|
| Market Intelligence Architect | 1 | `NICHE_REPORT_*.md` |
| Product Design Director | 2 | `CONTENT_BLUEPRINT_*.md` |
| Publishing Optimization Specialist | 3 | `PUBLISHING_PACKAGE_*.md` |

## Quick Start

### Phase 1: Market Research
```
Analyze the "[Your Niche]" niche for an adult coloring book,
8.5x8.5 inches, 104 pages, targeting US and IT markets at $9.99/€9.99
```

### Phase 2: Product Design (after GO decision)
```
Based on NICHE_REPORT_[BookName].md, create a complete content blueprint
for this book project.
```

### Phase 3: Publishing Package
```
Based on the niche report and content blueprint, create the complete
publishing package for US and IT markets.
```

## Standard Specifications

| Spec | Value |
|------|-------|
| Trim Size | 8.5" x 8.5" |
| Pages | 104 |
| Bleed | 0.125" |
| Resolution | 300 DPI |
| US Price | $9.99 (60% royalty) |
| IT Price | €9.99 (60% royalty) |

## Directory Structure

```
KDP/
├── .claude/
│   └── agents/
│       ├── market-intelligence-architect.md
│       ├── product-design-director.md
│       └── publishing-optimization-specialist.md
├── output/                    # Generated reports go here
│   ├── NICHE_REPORT_*.md
│   ├── CONTENT_BLUEPRINT_*.md
│   └── PUBLISHING_PACKAGE_*.md
├── templates/                 # Reusable templates
└── README.md
```

## Features

- **Dual Market Strategy** - Simultaneous optimization for US and IT with native Italian copywriting
- **Market Intelligence** - Competitor analysis, BSR rankings, Google Trends, Go/No-Go decision
- **Product Design** - Technical specs, AI image prompts, cover briefs, Canva workflow
- **Publishing Optimization** - HTML descriptions, backend keywords, A+ Content briefs
- **KDP Compliance** - Accurate spine calculations, bleed specs, PDF requirements
- **SEO Optimization** - Backend keyword validation with byte-count verification

## License

Based on [claude-kdp-agents](https://github.com/fracabu/claude-kdp-agents) by fracabu - MIT License
