# Content Blueprint: 情報デザイン - The Japanese Art of Information Design

**Phase 2: Product Design Director Output**
**Date:** January 8, 2026

---

## LOCKED TECHNICAL SPECIFICATIONS

| Specification | Value | Status |
|---------------|-------|--------|
| **Title** | 情報デザイン: The Japanese Art of Information Design | LOCKED |
| **Subtitle** | A Practical Guide with iOS App Case Study | LOCKED |
| **Trim Size** | 8" × 10" (design book standard) | LOCKED |
| **Page Count** | 176 pages | LOCKED |
| **Interior** | Premium Color | LOCKED |
| **Binding** | Perfect Bound Paperback | LOCKED |
| **Paper** | 70# white | LOCKED |
| **Bleed** | 0.125" all sides | LOCKED |
| **Resolution** | 300 DPI minimum | LOCKED |
| **Color Mode** | CMYK | LOCKED |

### Spine Width Calculation
```
176 pages × 0.002347" (premium color) = 0.413"
Full cover width = 8" + 0.413" + 8" + 0.25" = 16.663"
Full cover height = 10" + 0.25" = 10.25"
```

---

## BOOK STRUCTURE OVERVIEW

```
┌────────────────────────────────────────────────────────────────┐
│                    情報デザイン                                 │
│         The Japanese Art of Information Design                 │
├────────────────────────────────────────────────────────────────┤
│  PART 1: PHILOSOPHY (pp. 1-30)                                │
│  ├── Ch 1: What is 情報デザイン?                               │
│  ├── Ch 2: Origins & Influences                               │
│  └── Ch 3: Core Principles                                    │
├────────────────────────────────────────────────────────────────┤
│  PART 2: THE DESIGN SYSTEM (pp. 31-80)                        │
│  ├── Ch 4: Color Semantics                                    │
│  ├── Ch 5: Border Language                                    │
│  ├── Ch 6: Typography                                         │
│  ├── Ch 7: Spacing & Layout                                   │
│  └── Ch 8: Japanese Symbol Language                           │
├────────────────────────────────────────────────────────────────┤
│  PART 3: COMPONENT LIBRARY (pp. 81-120)                       │
│  ├── Ch 9: Containers & Cards                                 │
│  ├── Ch 10: Interactive Elements                              │
│  ├── Ch 11: Navigation Patterns                               │
│  └── Ch 12: Data Display                                      │
├────────────────────────────────────────────────────────────────┤
│  PART 4: CASE STUDY - WEEKGRID (pp. 121-156)                  │
│  ├── Ch 13: App Architecture                                  │
│  ├── Ch 14: Calendar Design                                   │
│  ├── Ch 15: The "Star Page" Golden Standard                   │
│  └── Ch 16: Before & After Transformations                    │
├────────────────────────────────────────────────────────────────┤
│  PART 5: IMPLEMENTATION (pp. 157-176)                         │
│  ├── Ch 17: SwiftUI Code Patterns                             │
│  ├── Ch 18: Design Audit Checklist                            │
│  └── Appendix: Quick Reference Cards                          │
└────────────────────────────────────────────────────────────────┘
```

---

## CHAPTER-BY-CHAPTER CONTENT

### PART 1: PHILOSOPHY (30 pages)

---

#### Chapter 1: What is 情報デザイン? (pp. 1-10)

**Opening Spread (pp. 1-2)**
- Full-page image: Japanese OTC medicine packaging (Muhi, Rohto, Salonpas)
- Pull quote: "Every visual element must serve a clear informational purpose. Nothing is decorative—everything communicates."

**Content Pages (pp. 3-10)**

| Page | Content | Visuals |
|------|---------|---------|
| 3 | Definition of 情報デザイン (Jōhō Dezain) | Kanji breakdown diagram |
| 4 | Western vs Japanese information design | Side-by-side comparison |
| 5 | The Bento Box principle | Bento photo + UI mapping |
| 6 | Why borders matter in Japan | Train signage examples |
| 7 | High contrast philosophy | Before/after low-contrast vs high-contrast |
| 8 | Purposeful color - every color has ONE meaning | Color wheel with labels |
| 9 | Squircle geometry explained | Corner radius comparison |
| 10 | Chapter summary with key takeaways | Quick reference box |

**AI Image Prompts:**

```
IMAGE_1_1: "Flat lay photography of Japanese OTC medicine boxes (Muhi cream, Rohto eye drops, Salonpas patches) arranged on white background, showing compartmentalized packaging design with thick black borders and high contrast colors, clean studio lighting, top-down view"

IMAGE_1_2: "Diagram showing Western information design (dense, data-heavy, Tufte-style) on left versus Japanese information design (minimal, bordered, semantic color) on right, flat graphic style, black outlines"

IMAGE_1_3: "Traditional Japanese bento box from above showing compartments with different foods, next to a mobile app UI wireframe with similar compartmentalized layout, split image, clean minimal style"

IMAGE_1_4: "Tokyo train station signage showing clear wayfinding with thick borders and high contrast colors, documentary photography style, emphasizing the bold line work and color coding"

IMAGE_1_5: "Technical diagram comparing standard corner radius (sharp mathematical curve) versus squircle/continuous corner radius (smooth Apple-style curve), with measurement annotations, flat technical illustration"
```

---

#### Chapter 2: Origins & Influences (pp. 11-20)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 11 | Japanese train system design history | JR logo evolution |
| 12 | Post-war industrial standardization (JIS) | JIS symbol sheet |
| 13 | Influence of German design (Bauhaus → Japan) | Historical comparison |
| 14 | Muji and the "no-brand" aesthetic | Muji product lineup |
| 15 | OTC medicine packaging as information design | Packaging dissection |
| 16 | Wayfinding in Japanese cities | Tokyo Metro map |
| 17 | The rise of mobile-first Japan | i-mode to iPhone |
| 18 | Information design in Japanese games (Nintendo) | UI examples |
| 19 | Modern Japanese app design trends | Contemporary app screenshots |
| 20 | How 情報デザイン differs from minimalism | Comparison diagram |

**AI Image Prompts:**

```
IMAGE_2_1: "Evolution of JR (Japan Railways) logo from 1987 to present, showing simplification over time, flat graphic timeline, white background"

IMAGE_2_2: "Japanese Industrial Standards (JIS) safety symbol sheet showing standardized warning signs and map symbols, technical document style, grid layout"

IMAGE_2_3: "Side-by-side comparison of 1920s Bauhaus typography poster and 1960s Japanese industrial design poster, showing design influence migration"

IMAGE_2_4: "Muji product photography showing packaging and products with minimal branding, clean white background, emphasizing the 'no-brand' aesthetic"

IMAGE_2_5: "Technical dissection of Japanese medicine box packaging, with callouts showing information hierarchy: product name, dosage, warnings, ingredients, all within bordered compartments"

IMAGE_2_6: "Tokyo Metro subway map showing the distinctive color-coding system and clear line identification, full map view"
```

---

#### Chapter 3: Core Principles (pp. 21-30)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 21 | Principle 1: Everything has a border | Border examples |
| 22 | Principle 2: Color is semantic, not decorative | Semantic color chart |
| 23 | Principle 3: Black text on white backgrounds | Readability comparison |
| 24 | Principle 4: Continuous corners (squircle) | Shape comparison |
| 25 | Principle 5: Compartmentalized layouts | Bento layout patterns |
| 26 | Principle 6: Typography is rounded | Font comparison |
| 27 | Principle 7: Maximum 8pt top padding | Spacing demonstration |
| 28 | The "Forbidden Patterns" | Anti-patterns gallery |
| 29 | Design audit methodology | Checklist introduction |
| 30 | Part 1 Summary | Key principles card |

**AI Image Prompts:**

```
IMAGE_3_1: "Diagram showing hierarchy of border widths in UI design: 1pt for cells, 1.5pt for rows, 2pt for buttons, 2.5pt for selected items, 3pt for containers, flat technical illustration with labels"

IMAGE_3_2: "Semantic color chart showing: Yellow=#FFE566 (Now/Present), Cyan=#A5F3FC (Events), Pink=#FECDD3 (Holidays), Orange=#FED7AA (Trips), Green=#BBF7D0 (Money), Purple=#E9D5FF (People), Red=#E53935 (Alerts), clean swatch design with hex codes"

IMAGE_3_3: "Before/after comparison of UI with low contrast gray text on dark background (marked with X) versus high contrast black text on white background (marked with checkmark), split screen"

IMAGE_3_4: "Grid of anti-patterns in information design: glass/blur effects (X), gradients (X), missing borders (X), non-continuous corners (X), excessive padding (X), raw system colors (X), each in a small box with red X overlay"
```

---

### PART 2: THE DESIGN SYSTEM (50 pages)

---

#### Chapter 4: Color Semantics (pp. 31-42)

**Spread: Color System Reference (pp. 31-32)**
- Full color palette with hex codes
- Semantic meaning chart
- Do's and don'ts

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 33 | Yellow (#FFE566) - NOW/Present | Use cases |
| 34 | Cyan (#A5F3FC) - Scheduled Time | Calendar examples |
| 35 | Pink (#FECDD3) - Special Days | Holiday examples |
| 36 | Orange (#FED7AA) - Movement/Travel | Trip UI examples |
| 37 | Green (#BBF7D0) - Money/Finance | Expense UI examples |
| 38 | Purple (#E9D5FF) - People/Contacts | Contact UI examples |
| 39 | Red (#E53935) - Alerts/Warnings | Alert patterns |
| 40 | Black & White - Definition & Content | Contrast rules |
| 41 | App background options | Dark theme variations |
| 42 | Color accessibility considerations | Contrast ratios |

**AI Image Prompts:**

```
IMAGE_4_1: "Complete color palette card for 情報デザイン showing all 10 colors with hex codes, semantic labels, and sample usage, magazine-quality graphic design, white background"

IMAGE_4_2: "Mobile app calendar UI showing yellow highlight on today's date, cyan for scheduled events, pink for holidays, demonstrating semantic color usage, clean flat design"

IMAGE_4_3: "Expense tracking app UI showing green background for money-related items, with receipts, totals, and currency, demonstrating semantic green usage"

IMAGE_4_4: "Contact list UI showing purple accent for people-related items, with profile pictures, names, and relationship indicators, demonstrating semantic purple usage"

IMAGE_4_5: "Warning and alert UI patterns showing red for destructive actions, delete confirmations, and error states, mobile app style"
```

---

#### Chapter 5: Border Language (pp. 43-52)

**Spread: Border Hierarchy (pp. 43-44)**
- Visual border weight comparison
- When to use each weight

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 45 | 1pt borders - Day cells, small elements | Grid examples |
| 46 | 1.5pt borders - List rows, sections | List examples |
| 47 | 2pt borders - Buttons, interactive | Button examples |
| 48 | 2.5pt borders - Selected/focused state | Selection examples |
| 49 | 3pt borders - Containers, cards | Card examples |
| 50 | Combining border weights | Nested UI examples |
| 51 | Border color rules (always black) | Color comparison |
| 52 | Common border mistakes | Anti-pattern gallery |

**AI Image Prompts:**

```
IMAGE_5_1: "Technical diagram showing border weight hierarchy from 1pt to 3pt, with ruler measurements and example UI elements at each weight, flat technical illustration"

IMAGE_5_2: "Mobile app grid showing small day cells with 1pt borders, clean calendar design, zoomed detail view"

IMAGE_5_3: "List view UI showing rows with 1.5pt borders, demonstrating proper list item separation, mobile app style"

IMAGE_5_4: "Button component showcase showing 2pt borders on interactive elements, various button states (normal, hover, pressed), flat design"

IMAGE_5_5: "Card and container UI showing 3pt borders on outer containers, with nested elements using thinner borders inside, demonstrating hierarchy"
```

---

#### Chapter 6: Typography (pp. 53-60)

**Spread: Typography Scale (pp. 53-54)**
- Complete type scale with sizes and weights
- SF Pro Rounded showcase

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 55 | Why rounded fonts? | Rounded vs sharp comparison |
| 56 | The typography scale (48pt to 10pt) | Scale demonstration |
| 57 | Font weights (medium minimum) | Weight comparison |
| 58 | Labels and pills (UPPERCASE, bold) | Component examples |
| 59 | Numeric typography (monospacedDigit) | Number formatting |
| 60 | Typography in context | Full UI example |

**AI Image Prompts:**

```
IMAGE_6_1: "Typography scale poster showing SF Pro Rounded at 48pt (displayLarge), 32pt (displayMedium), 18pt (headline), 16pt (body), 14pt (bodySmall), 12pt (label), 10pt (labelSmall), with sample text at each size"

IMAGE_6_2: "Side-by-side comparison of sharp geometric font versus rounded font in UI context, showing how rounded feels more approachable and friendly"

IMAGE_6_3: "Component showcase of pills and badges using uppercase 12pt bold text, various colors and states, flat design"

IMAGE_6_4: "Numeric display showing proper monospacedDigit formatting for prices, dates, and statistics, ensuring alignment in columns"
```

---

#### Chapter 7: Spacing & Layout (pp. 61-70)

**Spread: Spacing Grid System (pp. 61-62)**
- 4pt base grid
- Spacing token reference

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 63 | The 4pt base unit | Grid overlay examples |
| 64 | Spacing tokens (xs=4, sm=8, md=12, lg=16) | Token reference |
| 65 | The 8pt maximum top padding rule | Padding examples |
| 66 | Container padding patterns | Nested spacing |
| 67 | Gap spacing in grids and lists | Grid examples |
| 68 | Touch target minimums (44×44pt) | Hit area diagrams |
| 69 | Responsive spacing considerations | Device size comparison |
| 70 | Layout composition examples | Full screen layouts |

**AI Image Prompts:**

```
IMAGE_7_1: "Technical diagram showing 4pt grid overlay on mobile UI, with measurements and spacing tokens labeled, flat technical illustration"

IMAGE_7_2: "Spacing token reference card showing xs=4pt, sm=8pt, md=12pt, lg=16pt with visual examples of each, clean graphic design"

IMAGE_7_3: "Before/after comparison showing UI with excessive top padding (40pt, marked with X) versus proper maximum 8pt top padding (marked with checkmark)"

IMAGE_7_4: "Touch target diagram showing 44×44pt minimum hit area around buttons and interactive elements, with finger illustration for scale"
```

---

#### Chapter 8: Japanese Symbol Language (pp. 71-80)

**Spread: Maru-Batsu System (pp. 71-72)**
- Complete symbol reference
- PlayStation connection

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 73 | ○×△□ - The foundation | Symbol meanings |
| 74 | Filled vs outlined symbols | Intensity comparison |
| 75 | Reference marks (※★☆†) | Usage examples |
| 76 | Calendar symbols (祝休振) | Calendar UI examples |
| 77 | Safety symbols (JIS Z 8210) | Warning hierarchy |
| 78 | Why no emoji in 情報デザイン | Emoji vs SF Symbol comparison |
| 79 | SF Symbol mapping | Translation chart |
| 80 | Symbol implementation guide | Code examples |

**AI Image Prompts:**

```
IMAGE_8_1: "Maru-Batsu symbol chart showing: ◎ (excellent), ○ (good/yes), △ (caution), □ (info), × (no/wrong), with Japanese names and meanings, clean graphic design"

IMAGE_8_2: "PlayStation controller with buttons highlighted, showing connection to Japanese Maru-Batsu system: ○=yes, ×=no, △=view, □=menu"

IMAGE_8_3: "Comparison grid showing emoji (colorful, inconsistent) versus SF Symbols (monochrome, consistent) for the same concepts: fire, warning, star, heart, location"

IMAGE_8_4: "Japanese calendar showing special day markers: 祝 (holiday), 休 (rest day), 振 (substitute holiday), with colored backgrounds"

IMAGE_8_5: "JIS safety symbol hierarchy showing: ℹ (info/cyan), ⚠ (caution/yellow), ！(warning/red), ⊘ (danger/black+red)"
```

---

### PART 3: COMPONENT LIBRARY (40 pages)

---

#### Chapter 9: Containers & Cards (pp. 81-92)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 81-82 | JohoContainer - The base container | Component spec |
| 83-84 | JohoCard - Content cards | Card variations |
| 85-86 | JohoSectionBox - Colored sections | Section examples |
| 87-88 | JohoFormSection - Form containers | Form examples |
| 89-90 | Nesting containers properly | Hierarchy examples |
| 91-92 | Container code patterns | SwiftUI code |

**AI Image Prompts:**

```
IMAGE_9_1: "JohoContainer component specification showing: white background, black 3pt border, 16pt corner radius (continuous), 12pt internal padding, with measurements annotated"

IMAGE_9_2: "JohoCard variations showing different content types: simple text, icon with text, image with text, statistics, each with proper border and spacing"

IMAGE_9_3: "JohoSectionBox examples showing colored header pills (EVENTS, HOLIDAYS, NOTES) with content below, demonstrating the compartmentalized bento style"

IMAGE_9_4: "Nested container diagram showing outer container (3pt border), section (1.5pt border), and inner cards (1pt border), demonstrating proper hierarchy"
```

---

#### Chapter 10: Interactive Elements (pp. 93-102)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 93-94 | JohoActionButton - Buttons | Button states |
| 95-96 | JohoToggle - Switches | Toggle design |
| 97-98 | Swipe actions (Edit/Delete) | Swipe patterns |
| 99-100 | Selection states | Selected/unselected |
| 101-102 | Touch feedback patterns | Animation specs |

**AI Image Prompts:**

```
IMAGE_10_1: "JohoActionButton component showing all states: normal (white background, black border), hover (light gray), pressed (darker), disabled (gray text), with 2pt borders"

IMAGE_10_2: "JohoToggle component showing off state (white track, black border) and on state (semantic color fill, black border), with measurements"

IMAGE_10_3: "Swipe action patterns showing: swipe right reveals cyan Edit action, swipe left reveals red Delete action, with icons and proper border treatment"

IMAGE_10_4: "Selection state comparison showing unselected (1pt border, white background) versus selected (2.5pt border, semantic color background)"
```

---

#### Chapter 11: Navigation Patterns (pp. 103-112)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 103-104 | Page header design | Header anatomy |
| 105-106 | Bento header with controls | Year picker example |
| 107-108 | iPad sidebar navigation | Split view layout |
| 109-110 | iPhone tab bar | Tab view layout |
| 111-112 | Editor sheet headers | Modal patterns |

**AI Image Prompts:**

```
IMAGE_11_1: "JohoPageHeader anatomy showing: icon zone (40pt square, accent color), title text (headline weight), badge/pill, all with proper borders and spacing"

IMAGE_11_2: "Bento header pattern showing compartmentalized layout: [Icon | Title | Year Picker], with stats row below showing colored indicator counts"

IMAGE_11_3: "iPad split view navigation showing thin icon strip sidebar on left edge with page icons, main content area on right with bordered container"

IMAGE_11_4: "iPhone navigation showing bottom tab bar with 3 tabs (Calendar, Library, Settings), proper icon weights, and selection indicator"

IMAGE_11_5: "Editor sheet header showing: back chevron, type icon, title text, and Save button, all properly bordered and spaced"
```

---

#### Chapter 12: Data Display (pp. 113-120)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 113-114 | JohoIndicatorCircle - Type dots | Dot variations |
| 115-116 | JohoPill - Label badges | Pill styles |
| 117-118 | JohoListRow - List items | Row anatomy |
| 119-120 | JohoStatBox - Statistics | Stat display |

**AI Image Prompts:**

```
IMAGE_12_1: "JohoIndicatorCircle component showing all type colors: red (Holiday), orange (Observance), purple (Event), pink (Birthday), yellow (Note), blue (Trip), green (Expense), each with black border"

IMAGE_12_2: "JohoPill variations: black pill with white text, white pill with black text, colored pill with appropriate text, all with 6pt corner radius"

IMAGE_12_3: "JohoListRow anatomy showing: left icon zone (40×40pt, colored background, bordered), center content (title + subtitle), right accessory (chevron or badge)"

IMAGE_12_4: "JohoStatBox examples showing large numbers with labels, proper typography hierarchy, and bordered containers"
```

---

### PART 4: CASE STUDY - WEEKGRID (36 pages)

---

#### Chapter 13: App Architecture (pp. 121-130)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 121-122 | Onsen Planner app overview | App screenshots |
| 123-124 | Manager + Model + View pattern | Architecture diagram |
| 125-126 | SwiftData model structure | Entity diagram |
| 127-128 | Navigation architecture | Navigation flow |
| 129-130 | Widget integration | Widget screenshots |

**AI Image Prompts:**

```
IMAGE_13_1: "Onsen Planner app marketing screenshot showing main calendar view with week numbers, semantic colors for events, and 情報デザイン styling, iPhone 15 Pro frame"

IMAGE_13_2: "Architecture diagram showing Manager + Model + View pattern: User Action → View → Manager.shared (cache check) → SwiftData Query → Cache Update → View Update"

IMAGE_13_3: "SwiftData entity relationship diagram showing: HolidayRule, CalendarRule, CountdownEvent, DailyNote, ExpenseItem, TravelTrip, with relationships"

IMAGE_13_4: "Navigation flow diagram showing iPad (split view with sidebar) and iPhone (tab bar) patterns, with arrows showing transitions"

IMAGE_13_5: "Onsen Planner widget family showing Small (week number only), Medium (week + date range + countdown), Large (7-day calendar with events)"
```

---

#### Chapter 14: Calendar Design (pp. 131-140)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 131-132 | ISO 8601 week numbering | Week calculation diagram |
| 133-134 | Calendar grid composition | Grid anatomy |
| 135-136 | Day cell design | Cell states |
| 137-138 | Week number display | Badge design |
| 139-140 | Month navigation | Navigation patterns |

**AI Image Prompts:**

```
IMAGE_14_1: "ISO 8601 week numbering explanation diagram showing how Week 1 is determined (first week with 4+ days in new year), with calendar visualization"

IMAGE_14_2: "Calendar grid anatomy showing: weekday header row, week number column, day cells with indicators, proper 1pt cell borders"

IMAGE_14_3: "Day cell states: normal (white), today (yellow highlight), selected (2.5pt border), has events (colored indicator dots), Sunday (red text)"

IMAGE_14_4: "JohoWeekBadge large week number display showing the number 42 with semantic color background, bordered container"
```

---

#### Chapter 15: The "Star Page" Golden Standard (pp. 141-150)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 141-142 | Star Page overview | Full page screenshot |
| 143-144 | Bento header breakdown | Header anatomy |
| 145-146 | Stats row design | Indicator counts |
| 147-148 | Bento row pattern | Row anatomy |
| 149-150 | Section organization | Collapsed/expanded |

**AI Image Prompts:**

```
IMAGE_15_1: "Onsen Planner Star Page (Special Days) full screenshot showing: bento header with year picker, stats row with colored indicators, collapsible sections by type, iPhone 15 Pro frame"

IMAGE_15_2: "Star Page header anatomy with annotations: icon zone (40pt), title 'Special Days', year picker (< 2026 >), stats row (●13 ○11 ◆5)"

IMAGE_15_3: "Bento row anatomy showing three compartments: LEFT (type indicator + lock icon, 28pt), CENTER (title text, flexible), RIGHT (country pill + decoration, 72pt), with 1.5pt black dividers"

IMAGE_15_4: "Section states showing: collapsed (header only with count pill) and expanded (header + visible items), with smooth animation indicator"
```

---

#### Chapter 16: Before & After Transformations (pp. 151-156)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 151-152 | Before: Generic iOS styling | Before screenshots |
| 153-154 | After: 情報デザイン transformation | After screenshots |
| 155-156 | Side-by-side comparisons | Split comparisons |

**AI Image Prompts:**

```
IMAGE_16_1: "Before screenshot showing generic iOS app styling: system colors, no borders, thin fonts, blur effects, typical Apple HIG style"

IMAGE_16_2: "After screenshot showing 情報デザイン styling: semantic colors, thick black borders, rounded bold fonts, high contrast, compartmentalized layout"

IMAGE_16_3: "Split comparison showing same content: left side with generic styling (faded, marked with X), right side with 情報デザイン (vivid, marked with checkmark)"

IMAGE_16_4: "Transformation timeline showing progression: Generic iOS → Add Borders → Apply Semantic Colors → Compartmentalize Layout → Final 情報デザイン"
```

---

### PART 5: IMPLEMENTATION (20 pages)

---

#### Chapter 17: SwiftUI Code Patterns (pp. 157-166)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 157-158 | JohoColors struct | Color definitions |
| 159-160 | Squircle shape | Shape code |
| 161-162 | Container components | Component code |
| 163-164 | List row patterns | Row code |
| 165-166 | Animation guidelines | Animation code |

**Code Examples:**

```swift
// Page 157-158: JohoColors
struct JohoColors {
    static let black = Color(hex: "000000")
    static let white = Color(hex: "FFFFFF")
    static let yellow = Color(hex: "FFE566")  // Now
    static let cyan = Color(hex: "A5F3FC")    // Events
    static let pink = Color(hex: "FECDD3")    // Holidays
    static let orange = Color(hex: "FED7AA")  // Trips
    static let green = Color(hex: "BBF7D0")   // Money
    static let purple = Color(hex: "E9D5FF")  // People
    static let red = Color(hex: "E53935")     // Alert
}

// Page 159-160: Squircle
struct Squircle: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect,
             cornerRadius: cornerRadius,
             style: .continuous)
    }
}

// Page 161-162: Container
struct JohoContainer<Content: View>: View {
    let content: Content

    var body: some View {
        content
            .padding(12)
            .background(JohoColors.white)
            .clipShape(Squircle(cornerRadius: 16))
            .overlay(
                Squircle(cornerRadius: 16)
                    .stroke(JohoColors.black, lineWidth: 3)
            )
    }
}
```

---

#### Chapter 18: Design Audit Checklist (pp. 167-172)

**Content Pages:**

| Page | Content | Visuals |
|------|---------|---------|
| 167-168 | Pre-commit checklist | Checkbox list |
| 169-170 | Automated audit commands | Terminal examples |
| 171-172 | Common violations and fixes | Before/after fixes |

**Audit Checklist:**

```
PRE-COMMIT DESIGN AUDIT

□ Every container has a black border
□ Colors match semantic meaning
□ No glass/blur effects (.ultraThinMaterial)
□ No gradients (LinearGradient, RadialGradient)
□ All corners use style: .continuous
□ Typography uses .design(.rounded)
□ Maximum 8pt top padding
□ No raw system colors (Color.blue, etc.)
□ All interactive elements 44×44pt minimum
□ Icons use correct weight (.medium for lists)
□ Labels are UPPERCASE
□ Black text on white backgrounds

AUTOMATED AUDIT COMMANDS:

grep -rn "ultraThinMaterial" --include="*.swift"
grep -rn "\.cornerRadius(" --include="*.swift"
grep -rn "Color\.blue" --include="*.swift"
grep -rn "LinearGradient" --include="*.swift"
grep -rn "\.padding(.top," --include="*.swift"
```

---

#### Appendix: Quick Reference Cards (pp. 173-176)

**Content:**

| Page | Card Content |
|------|--------------|
| 173 | Color Semantics Reference |
| 174 | Border Weights Reference |
| 175 | Typography Scale Reference |
| 176 | Symbol Language Reference |

**AI Image Prompts:**

```
IMAGE_APP_1: "Quick reference card for 情報デザイン colors: Yellow=Now, Cyan=Events, Pink=Holidays, Orange=Trips, Green=Money, Purple=People, Red=Alert, with hex codes and swatches"

IMAGE_APP_2: "Quick reference card for border weights: 1pt=cells, 1.5pt=rows, 2pt=buttons, 2.5pt=selected, 3pt=containers, with visual examples"

IMAGE_APP_3: "Quick reference card for typography: 48pt heavy (hero), 32pt bold (titles), 18pt bold (headlines), 16pt medium (body), 12pt bold UPPERCASE (labels)"

IMAGE_APP_4: "Quick reference card for symbols: ◎=excellent, ○=good, △=caution, □=info, ×=no, ★=important, with SF Symbol equivalents"
```

---

## COVER DESIGN BRIEF

### Front Cover

**Concept:** Clean, high-contrast design demonstrating the 情報デザイン aesthetic

**Layout:**
```
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│        ┌──────────────────────────────────────────┐           │
│        │                                          │           │
│        │           情報デザイン                     │           │
│        │                                          │           │
│        │   The Japanese Art of                    │           │
│        │   Information Design                     │           │
│        │                                          │           │
│        │   ───────────────────────                │           │
│        │                                          │           │
│        │   A Practical Guide with                 │           │
│        │   iOS App Case Study                     │           │
│        │                                          │           │
│        │        ○  ●  ◎  △  □  ×                  │           │
│        │                                          │           │
│        └──────────────────────────────────────────┘           │
│                                                                │
│                                         [Author Name]          │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**Color Palette:**
- Background: Pure Black (#000000)
- Main container: Pure White (#FFFFFF)
- Border: 3pt Black
- Accent colors: Semantic palette (Yellow, Cyan, Pink, Orange, Green, Purple)

**Typography:**
- Title (kanji): 48pt, Bold
- Subtitle: 24pt, Medium
- Tagline: 16pt, Medium

**Elements:**
- Central white container with 3pt black border and squircle corners
- Maru-Batsu symbol row as decorative element
- Small semantic color dots along bottom of container

### Back Cover

**Layout:**
```
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│   ┌────────────────────────────────────────────────────────┐   │
│   │                                                        │   │
│   │  "Every visual element must serve a clear             │   │
│   │   informational purpose. Nothing is decorative—       │   │
│   │   everything communicates."                           │   │
│   │                                                        │   │
│   ├────────────────────────────────────────────────────────┤   │
│   │                                                        │   │
│   │  WHAT YOU'LL LEARN:                                   │   │
│   │                                                        │   │
│   │  ● The philosophy behind Japanese information design  │   │
│   │  ● A complete design system with semantic colors      │   │
│   │  ● Border language and visual hierarchy               │   │
│   │  ● Reusable component patterns                        │   │
│   │  ● Real iOS app case study with SwiftUI code          │   │
│   │                                                        │   │
│   ├────────────────────────────────────────────────────────┤   │
│   │                                                        │   │
│   │  [Small app screenshot]  [QR Code to app/website]     │   │
│   │                                                        │   │
│   └────────────────────────────────────────────────────────┘   │
│                                                                │
│   [Barcode]                                     $24.99 USD     │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Spine

```
情報デザイン │ The Japanese Art of Information Design │ [Author]
```

**AI Image Prompt for Cover:**

```
COVER_MAIN: "Minimalist book cover design with pure black background, centered white rectangle with thick black border (3pt) and continuous rounded corners, large Japanese kanji '情報デザイン' in bold black text, English subtitle 'The Japanese Art of Information Design' below, row of Japanese symbols (○ ● ◎ △ □ ×) as decoration, clean typography, high contrast, no gradients or effects"
```

---

## CANVA ASSEMBLY WORKFLOW

### Step 1: Document Setup
1. Create new design: Custom size 16.663" × 10.25" (full cover with bleed)
2. Set color mode to CMYK if available
3. Enable bleed guides (0.125" all sides)

### Step 2: Background
1. Fill entire canvas with pure black (#000000)
2. This extends to bleed for full edge coverage

### Step 3: Front Cover Container
1. Add rectangle: 6.5" × 8.5"
2. Position: Centered on right half of spread
3. Fill: White (#FFFFFF)
4. Border: 3pt black
5. Corner radius: 0.3" with "smooth corners" if available

### Step 4: Typography
1. Title (情報デザイン):
   - Font: Noto Sans JP Bold or similar
   - Size: 72pt
   - Color: Black
2. English subtitle:
   - Font: SF Pro Rounded Bold or Nunito Bold
   - Size: 36pt
   - Color: Black
3. Tagline:
   - Font: Same as subtitle, Medium weight
   - Size: 18pt

### Step 5: Symbol Row
1. Add text element: ○  ●  ◎  △  □  ×
2. Font: SF Symbols or similar
3. Size: 24pt
4. Color: Black
5. Position: Bottom of container, centered

### Step 6: Back Cover
1. Repeat container pattern on left half
2. Add pull quote, bullet points, screenshots
3. Include QR code linking to app/website

### Step 7: Spine
1. Add vertical text in spine area (0.413" wide)
2. Font: Same as cover
3. Size: 12pt
4. Rotate 90° (readable when book is on shelf)

### Step 8: Export
1. Format: PDF/X-1a (or PDF Print if unavailable)
2. Resolution: 300 DPI
3. Color profile: CMYK
4. Include bleed marks

---

## EXPORT VERIFICATION CHECKLIST

### Pre-Export
- [ ] All text is black (#000000) or white (#FFFFFF)
- [ ] All containers have visible borders
- [ ] No transparency effects used
- [ ] No gradients used
- [ ] Fonts are SF Pro Rounded or equivalent
- [ ] Images are 300 DPI minimum

### PDF Export Settings
- [ ] Format: PDF/X-1a or PDF Print
- [ ] Resolution: 300 DPI
- [ ] Color: CMYK (not RGB)
- [ ] Bleed: 0.125" all sides
- [ ] Crop marks: Enabled
- [ ] Fonts: Embedded

### Post-Export Verification
- [ ] Open PDF and check all pages render correctly
- [ ] Verify colors appear as expected
- [ ] Check spine text is readable
- [ ] Confirm no white edges (bleed extends to edge)
- [ ] Test print a sample page at actual size

---

## LOCALIZATION NOTES

### US Market (Primary)
- All content in English
- Dollar pricing ($24.99)
- "iOS App" terminology

### IT Market (Secondary)
- Translate key sections to Italian
- Euro pricing (€24.99)
- Consider Italian design terminology

### Dual-Language Elements
- 情報デザイン (kanji) remains universal
- Maru-Batsu symbols are universal
- Code examples remain in English

---

## PRODUCTION TIMELINE

| Phase | Deliverable |
|-------|-------------|
| 1 | Final manuscript (text content) |
| 2 | AI-generated illustrations |
| 3 | Layout in Canva/InDesign |
| 4 | Cover design |
| 5 | Interior PDF assembly |
| 6 | Proof review |
| 7 | Final PDF export |
| 8 | KDP upload |

---

## FILE NAMING CONVENTION

```
JohoDesign_Interior_v1.pdf
JohoDesign_Cover_v1.pdf
JohoDesign_Interior_FINAL.pdf
JohoDesign_Cover_FINAL.pdf
```

---

*Content Blueprint Complete*
*Phase 2: Product Design Director*
*Ready for Phase 3: Publishing Optimization*
