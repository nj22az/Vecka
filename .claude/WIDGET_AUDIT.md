# 情報デザイン Widget Audit Report

## Audit Methodology
Each widget audited against these 情報デザイン principles:
1. **Function over form** - Every element must serve a purpose
2. **Semantic colors** - Colors have MEANING, never decorative
3. **Strong borders** - BLACK, visible, consistent
4. **White backgrounds** - Content areas are WHITE
5. **Uniform design** - All widgets share consistent visual language
6. **Complete information** - Day, Week, Month, Year visible
7. **Touch targets** - Minimum 44pt
8. **Typography** - SF Pro Rounded, weight ≥ medium
9. **Squircle corners** - `style: .continuous`
10. **No decoration** - No gradients, blur, shadows

---

# SMALL WIDGET AUDIT

## Current State Analysis
```
┌─────────────────────┐
│    JAN 2026         │  <- Month/Year header
│                     │
│        2            │  <- Week number (hero)
│       WEEK          │  <- Label
│                     │
│   (11) SUN          │  <- Today circle + weekday
└─────────────────────┘
```

## FAULTS (40 identified)

### Border Issues (1-10)
1. **Outer border not visible on iOS** - iOS clips widget content, 2pt border rendered inside is partially hidden
2. **Border radius mismatch** - Outer 18pt, inner 16pt, creates uneven visual
3. **Border uses padding(1) hack** - Non-standard approach, may render inconsistently
4. **No outer container shadow** - Other iOS widgets have subtle depth
5. **Border doesn't reach edges** - Content area slightly inset from widget bounds
6. **Circle border 1.5pt inconsistent** - Should match widget border weight (2pt)
7. **Today circle border thinner than container** - Visual hierarchy broken
8. **No inner content border** - Main content area floats without definition
9. **cornerRadius 18/16 arbitrary** - Not from Theme.Corners specification
10. **Border color pure black** - On OLED screens may cause "black smearing"

### Typography Issues (11-20)
11. **Header size 11pt** - Below Theme.Typography.small.caption (10pt) threshold
12. **Month/Year opacity 0.7** - Still too faint for elderly/accessibility
13. **Week number 56pt** - Theme specifies 48pt for small widget
14. **"WEEK" label opacity 0.6** - Inconsistent with header 0.7
15. **"WEEK" tracking 2** - Excessive letter spacing
16. **Day number 16pt in 32pt circle** - Ratio too small, should be 20pt
17. **Weekday 12pt** - Disproportionate to day number
18. **No dynamic type support** - Fixed sizes don't scale with accessibility settings
19. **Font weight inconsistency** - Header .bold, week .black, day .black, weekday .bold
20. **No font fallback** - If rounded unavailable, defaults to system

### Color Issues (21-30)
21. **Yellow #FFE566 too bright** - Poor contrast ratio on white
22. **No dark mode adaptation** - Same colors in dark/light mode
23. **Alert red for Sunday** - Sunday isn't an "alert", semantically wrong
24. **Text opacity variations** - 0.7, 0.6 create inconsistent visual
25. **Circle fill vs stroke colors** - Both use JohoWidget.Colors but different opacity
26. **No color for holidays shown** - Holiday indicator not visible in small widget
27. **White background too stark** - Could use cream/off-white
28. **No color accessibility check** - Colors may fail WCAG contrast
29. **sundayOrHolidayColor returns same for both** - No distinction
30. **Black text on yellow** - Contrast ratio needs verification

### Layout Issues (31-40)
31. **VStack spacing: 0** - No rhythm, uses Spacers instead
32. **Spacer(minLength: 4) arbitrary** - Not from Theme.Spacing
33. **Uneven vertical distribution** - Top padding 8pt, bottom 8pt, but content not centered
34. **HStack spacing: 4** - For footer, doesn't match Theme.Spacing
35. **Circle 32pt** - Theme.CellSize.small specifies 18pt
36. **No horizontal padding on content** - Text may touch edges
37. **Weekday text not vertically aligned** - Sits lower than circle center
38. **Content not truly centered** - Week number shifted by asymmetric spacers
39. **No responsive layout** - Same layout regardless of widget size variations
40. **GeometryReader not used** - Can't adapt to actual widget dimensions

## IMPROVEMENTS (100 proposed)

### Border Improvements (1-20)
1. Use `ignoresSafeArea()` to extend border to true edges
2. Apply `containerBackground` border directly to widget view
3. Increase outer border to 3pt for visibility on iOS
4. Use single cornerRadius value (18pt) for consistency
5. Add subtle 1pt white inner stroke for depth
6. Match all circle borders to 2pt
7. Consider dark gray (#1A1A1A) instead of pure black
8. Add `clipToBounds: false` equivalent for border rendering
9. Use Theme.Borders.small.widget (2pt) consistently
10. Test border rendering on multiple iOS versions
11. Add subtle shadow for depth without breaking 情報デザイン
12. Consider border animation for "now" state
13. Ensure border visible in both light/dark mode
14. Add border to header section
15. Group content in bordered container
16. Use inset borders to prevent clipping
17. Verify border renders on ProMotion displays
18. Add border to "WEEK" label
19. Consider double-border design (Japanese influence)
20. Test border on different device sizes

### Typography Improvements (21-40)
21. Use Theme.Typography.scale(for: .systemSmall)
22. Implement Dynamic Type with `@ScaledMetric`
23. Increase header opacity to 0.8 minimum
24. Standardize all opacities to 0.5 or 1.0 (no middle values)
25. Match week number to Theme spec (48pt)
26. Increase day number to 18pt minimum
27. Add text shadow for legibility on colored backgrounds
28. Use `.monospacedDigit()` for numbers
29. Standardize tracking across all text
30. Add fallback fonts in font stack
31. Test with VoiceOver and larger text sizes
32. Use `.minimumScaleFactor(0.8)` consistently
33. Add `.lineLimit(1)` to prevent text wrapping
34. Consider uppercase for weekday labels
35. Use weight hierarchy: hero .black, labels .bold, info .medium
36. Test font rendering on non-Retina (if applicable)
37. Add `.baselineOffset()` for vertical alignment
38. Consider custom font metrics for better spacing
39. Use `.fontWeight()` modifier for fine control
40. Add text kerning adjustments for specific characters

### Color Improvements (41-60)
41. Create dark mode color set
42. Use semantic colors from asset catalog
43. Add color contrast verification
44. Use softer yellow (#FFE882) for better contrast
45. Define Sunday as "rest" color (purple) not "alert" (red)
46. Add holiday color indicator
47. Consider cream background (#FFFEF5)
48. Add accessibility color alternatives
49. Create high-contrast mode support
50. Use named colors from JohoWidget.Colors exclusively
51. Add color transition animations
52. Consider color-blind safe palette
53. Test on True Tone displays
54. Add vibrancy support for widget materials
55. Use `.brightness()` modifier for hover states
56. Implement reduced motion color changes
57. Add border color variation for states
58. Consider gradient alternatives for depth (subtle)
59. Use `.saturation()` for emphasis
60. Test colors on E-Ink displays (Watch)

### Layout Improvements (61-80)
61. Use GeometryReader for responsive sizing
62. Implement Theme.Spacing grid system
63. Center content with alignment guides
64. Use `.frame(maxWidth: .infinity, alignment: .center)`
65. Add `Spacer()` with explicit sizing
66. Implement 4pt base grid system
67. Use `ViewThatFits` for adaptive layouts
68. Add horizontal padding (12pt minimum)
69. Align circle center with weekday baseline
70. Use `@Environment(\.widgetFamily)` for family-specific layouts
71. Implement `Layout` protocol for custom arrangement
72. Add `layoutPriority()` for content sizing
73. Use `fixedSize()` for intrinsic content sizing
74. Implement `alignmentGuide()` for precise positioning
75. Add grid overlay for development verification
76. Use `containerRelativeFrame()` for proportional sizing
77. Implement `UnevenRoundsRectangle` for organic shapes
78. Add scroll view for overflow content
79. Use `safeAreaInset()` for edge content
80. Implement responsive breakpoints

### Interaction Improvements (81-90)
81. Add `.widgetURL()` for each tappable area
82. Implement haptic feedback indication
83. Add visual feedback for tap areas
84. Create deep links for week/day navigation
85. Add long-press actions
86. Implement `.accessibilityAddTraits(.isButton)`
87. Add `.accessibilityHint()` for actions
88. Create `.accessibilityLabel()` with full context
89. Implement `.accessibilityValue()` for dynamic content
90. Add `.accessibilityIdentifier()` for testing

### Information Architecture (91-100)
91. Add week range (e.g., "Jan 6-12")
92. Show week progress indicator
93. Add next holiday preview
94. Show days until end of week
95. Add week parity indicator (odd/even)
96. Show month progress bar
97. Add quarter indicator (Q1, Q2, etc.)
98. Show fiscal week if different
99. Add ISO week notation (2026-W02)
100. Implement localized week start (Sunday/Monday)

---

# MEDIUM WIDGET AUDIT

## Current State Analysis
```
┌────────────┬─────────────────────────┐
│            │    JANUARY 2026         │
│     2      │  M  T  W  T  F  S  S   │
│    WEEK    │  6  7  8  9 10(11)12   │
│            │  ★ Holiday Name        │
└────────────┴─────────────────────────┘
```

## FAULTS (40 identified)

### Border Issues (1-10)
1. **2.5pt border not visible** - iOS containerBackground clips content
2. **Vertical divider only 1.5pt** - Should match outer border weight
3. **No internal section borders** - Left/right panels undefined
4. **cornerRadius 20/18 mismatch** - Creates uneven visual
5. **Padding(1) hack unreliable** - May render differently per iOS version
6. **Holiday indicator border 1pt** - Too thin, inconsistent
7. **Day circle border 1.5pt** - Doesn't match container 2.5pt
8. **No week strip container border** - Days float without definition
9. **Birthday indicator same border as holiday** - No distinction
10. **No header border/underline** - Month/Year label floats

### Typography Issues (11-20)
11. **Week number 48pt** - Theme specifies 56pt for medium
12. **"WEEK" opacity 0.6** - Inconsistent with right panel
13. **Month name opacity 0.7** - Right panel uses different opacity
14. **Weekday labels 8pt** - Below minimum readable size
15. **Day numbers 13pt** - Should be 14pt per Theme
16. **Weekday opacity 0.3** - Too faint, accessibility issue
17. **Sunday weekday opacity 0.6** - Different from regular 0.3
18. **Holiday name 12pt** - Could be larger for readability
19. **Event icons 6pt** - Too small to be meaningful
20. **No baseline alignment** - Text elements not vertically aligned

### Layout Issues (21-30)
21. **35% left panel** - Arbitrary, not grid-based
22. **GeometryReader but no responsive logic** - Hardcoded proportions
23. **Week strip spacing: 2** - Too tight for touch targets
24. **Day cell 26x26pt** - Below 44pt touch target minimum
25. **Event indicator height: 6** - May shift layout when present
26. **Holiday padding asymmetric** - 4/8pt vertical, 8pt horizontal
27. **Conditional spacer logic** - Layout jumps when holiday absent
28. **No right panel bottom alignment** - Content floats upward
29. **ForEach with index** - Could cause rendering issues
30. **HStack spacing: 0** - No breathing room between elements

### Color Issues (31-40)
31. **Holiday background 0.2 opacity** - Nearly invisible
32. **Birthday uses same pink** - No distinction from holiday
33. **Bank holiday vs observance same red** - No differentiation
34. **Sunday 0.8 opacity red** - Different from bank holiday 1.0
35. **Today background no opacity** - Could conflict with indicators
36. **Weekday color logic complex** - Multiple conditions
37. **Event star color depends on type** - Inconsistent
38. **dayTextColor function has many branches** - Hard to maintain
39. **dayBackground function unused** - Dead code
40. **No visual hierarchy through color** - Everything same intensity

## IMPROVEMENTS (100 proposed)

### Structure (1-20)
1. Use fixed grid system (8 columns)
2. Implement 40/60 split for panels
3. Add explicit container for each section
4. Use Theme.Borders.medium.widget consistently
5. Add section headers with borders
6. Implement dividers from Theme
7. Group related information visually
8. Add spacing rhythm (4pt, 8pt, 16pt only)
9. Use ZStack for layered content
10. Implement card-based design for indicators
11. Add grid lines for calendar alignment
12. Use alignment guides for columns
13. Implement consistent padding (12pt)
14. Add content insets for edge safety
15. Use VStack with fixed spacing
16. Group week strip in bordered container
17. Add header/body/footer structure
18. Implement responsive panel ratios
19. Use containerRelativeFrame for sizing
20. Add section separators

### Typography (21-40)
21. Scale week number to Theme.Typography.medium.weekNumber (56pt)
22. Use consistent opacity (0.6 or 1.0 only)
23. Increase weekday labels to 9pt minimum
24. Add Dynamic Type support
25. Use monospacedDigit for day numbers
26. Standardize font weights across panels
27. Add text shadows for colored backgrounds
28. Implement text truncation with ...
29. Use minimumScaleFactor(0.9) for labels
30. Add lineLimit(1) to all text
31. Implement baselineOffset for alignment
32. Use fontWeight modifier for fine-tuning
33. Add tracking to labels
34. Implement text kerning
35. Use system font with rounded design
36. Add fall-back font specifications
37. Test with VoiceOver
38. Implement accessibility labels
39. Add text scaling for larger widgets
40. Use @ScaledMetric for responsive sizing

### Color (41-60)
41. Increase holiday background to 0.4 opacity
42. Differentiate birthday (purple) from holiday (pink)
43. Use distinct colors for bank holiday vs observance
44. Standardize Sunday color to alert
45. Add subtle background to today
46. Simplify weekday color logic
47. Use consistent event indicator colors
48. Refactor dayTextColor to single source of truth
49. Remove unused dayBackground
50. Add visual hierarchy through saturation
51. Implement dark mode colors
52. Add color contrast verification
53. Use named colors exclusively
54. Add vibrancy for materials
55. Implement reduced transparency mode
56. Add color-blind safe alternatives
57. Test on various display types
58. Add hover/pressed color states
59. Implement selection colors
60. Add focus ring colors

### Interaction (61-80)
61. Increase day cell to 44pt minimum
62. Add tap areas for each day
63. Implement deep links per day
64. Add haptic feedback
65. Create visual tap states
66. Add long-press context menu
67. Implement accessibility actions
68. Add voiceOver hints
69. Create gesture recognizers
70. Implement swipe actions
71. Add button role to interactive elements
72. Create consistent touch feedback
73. Implement pressed states
74. Add focus navigation
75. Create keyboard shortcuts
76. Implement drag actions
77. Add drop targets
78. Create selection states
79. Implement multi-select
80. Add edit mode

### Information (81-100)
81. Show week range in header
82. Add week progress indicator
83. Display upcoming holidays
84. Show birthday countdown
85. Add event count badge
86. Display weather integration
87. Show next appointment
88. Add task due indicators
89. Display notification badges
90. Show sync status
91. Add last updated timestamp
92. Display timezone info
93. Show week comparison (vs last year)
94. Add goal progress
95. Display streak information
96. Show statistics summary
97. Add quick actions
98. Display reminders
99. Show customization options
100. Add widget configuration link

---

# LARGE WIDGET AUDIT

## Current State Analysis
```
┌─────────────────────────────────────────┐
│  January 2026                      [W2] │
├─────────────────────────────────────────┤
│  W   M   T   W   T   F   S   S         │
│  1       1   2   3  ★4                  │
│  2   5   6★  7   8   9  10 (11)        │
│  3  12  13  14  15  16  17  18         │
│  ...                                    │
└─────────────────────────────────────────┘
```

## FAULTS (40 identified)

### Border Issues (1-10)
1. **Border 2pt** - Theme specifies 3pt for large widget
2. **Week badge has no border** - Capsule floats without definition
3. **No calendar grid borders** - Days not visually grouped
4. **No row separators** - Week rows run together
5. **Day cell has no border** - Only today has circle
6. **Event dots tiny (5pt)** - Nearly invisible
7. **cornerRadius 24/22 mismatch** - Visual inconsistency
8. **Header has no bottom border** - Doesn't separate from calendar
9. **Today circle border 1pt** - Theme specifies 2.5pt selected
10. **Week number column has no border** - Left edge undefined

### Typography Issues (11-20)
11. **Month/Year 18pt** - Theme specifies 20pt for large
12. **Week badge 12pt** - Too small for visibility
13. **Weekday headers 10pt** - Should be 12pt minimum
14. **Week numbers 9pt** - Below readable threshold
15. **Day numbers 14pt** - Theme specifies 16pt
16. **Weekday "W" header same as days** - No hierarchy
17. **No bold for current week row** - No visual distinction
18. **Opacity 0.5 for secondary text** - Too faint
19. **Sunday color 0.7 opacity** - Inconsistent with others
20. **No month name uppercase** - Inconsistent with other widgets

### Layout Issues (21-30)
21. **No GeometryReader** - Can't adapt to actual size
22. **Hardcoded padding 16/12** - Should use Theme.Spacing
23. **VStack spacing: 12** - Creates uneven rhythm
24. **Week column 28pt fixed** - Doesn't scale
25. **Day cells use .infinity width** - Uncontrolled sizing
26. **Empty cells use Color.clear** - Should have placeholder
27. **Event dots overlay causes clipping** - Position may overflow
28. **No row highlight for current week** - Lost visual context
29. **Calendar grid has no outer border** - Floats in container
30. **Horizontal padding inconsistent** - 16pt header, 12pt grid

### Color Issues (31-40)
31. **Sunday same as bank holiday** - No distinction
32. **Event dot cyan vs alert** - Arbitrary choice
33. **Birthday dot pink same as holiday** - No differentiation
34. **Today fills yellow** - No stroke-only option
35. **Week badge yellow background** - Could conflict with today
36. **No alternating row colors** - Hard to track horizontally
37. **No weekend column highlight** - Saturday/Sunday not grouped
38. **Text color doesn't adapt** - Same in light/dark mode
39. **Opacity values inconsistent** - 0.5, 0.7 mixed
40. **No color for empty cells** - Pure transparent

## IMPROVEMENTS (100 proposed)

### Grid System (1-25)
1. Implement 8-column grid
2. Use fixed aspect ratio for cells
3. Add row separators every week
4. Create column headers with borders
5. Implement week column with border
6. Add outer calendar border
7. Use Theme.CellSize.large dimensions
8. Implement cell hover states
9. Add row highlighting for current week
10. Create column alignment guides
11. Implement responsive cell sizing
12. Add touch target padding
13. Create selection states for cells
14. Implement multi-day selection
15. Add range selection visuals
16. Create week-at-a-glance mode
17. Implement month navigation
18. Add mini-month preview
19. Create year view option
20. Implement agenda view alternative
21. Add grid line toggle
22. Create compact/expanded modes
23. Implement density options
24. Add customizable start day
25. Create week number toggle

### Typography (26-45)
26. Scale all text to Theme.Typography.large
27. Use uppercase month name
28. Increase week badge size
29. Add bold weight to weekday headers
30. Increase week column numbers
31. Use monospacedDigit for all numbers
32. Add Dynamic Type support
33. Implement accessibility sizing
34. Create text contrast verification
35. Add font scaling options
36. Implement custom fonts option
37. Create localized date formats
38. Add RTL support
39. Implement vertical text for headers
40. Create condensed number format
41. Add full date on long-press
42. Implement tooltip with details
43. Create abbreviated formats
44. Add time indicators
45. Implement countdown displays

### Visual Design (46-70)
46. Add subtle row alternation
47. Create weekend column tint
48. Implement past day dimming
49. Add future week fade
50. Create month boundary indicators
51. Implement seasonal themes
52. Add holiday decorations
53. Create celebration animations
54. Implement weather icons
55. Add mood indicators
56. Create productivity colors
57. Implement custom color themes
58. Add pattern backgrounds
59. Create texture options
60. Implement gradient options
61. Add depth with shadows
62. Create 3D effect option
63. Implement parallax scrolling
64. Add animated transitions
65. Create morphing animations
66. Implement particle effects
67. Add celebration confetti
68. Create achievement badges
69. Implement streak flames
70. Add milestone markers

### Interaction (71-90)
71. Add day tap navigation
72. Create swipe month navigation
73. Implement pinch-to-zoom
74. Add rotation gestures
75. Create 3D touch shortcuts
76. Implement context menus
77. Add drag-to-select
78. Create double-tap actions
79. Implement long-press details
80. Add shake-to-refresh
81. Create voice commands
82. Implement keyboard navigation
83. Add game controller support
84. Create accessibility gestures
85. Implement switch control
86. Add eye-tracking support
87. Create touch accommodations
88. Implement haptic calendar
89. Add audio feedback
90. Create braille display support

### Data Integration (91-100)
91. Sync with Calendar app
92. Add Reminders integration
93. Import Contacts birthdays
94. Connect to Health data
95. Sync with Weather
96. Add News headlines
97. Connect to Mail counts
98. Import social events
99. Sync with work calendar
100. Add custom data sources

---

# WORLD CLOCK WIDGET AUDIT

## Current State Analysis
```
┌──────┬───────┬───────┬───────┐
│ JAN  │  SE   │  JP   │  US   │
│ 2026 │Stock. │ Tokyo │ NYC   │
│      │ (🕐) │ (🕐) │ (🕐) │
│  2   │14:44  │22:44  │08:44  │
│ WEEK │☀ +8  │🌙 -1 │☀ -6  │
│ (11) │       │       │       │
└──────┴───────┴───────┴───────┘
```

## FAULTS (40 identified)

### Border Issues (1-10)
1. **Clock dividers only 1pt** - Should match 2.5pt outer border
2. **Left panel has no right border** - Only Rectangle divider
3. **Clock cells have no borders** - Content floats
4. **Country pills have 1pt border** - Inconsistent with container
5. **Analog clock stroke too thin** - `size * 0.04` = 1.76pt
6. **No border around clock face** - Only stroke, no visual weight
7. **Day/night icons have no border** - Float without definition
8. **Container border 2.5pt** - May still be clipped by iOS
9. **No internal section separators** - Bento walls too thin
10. **Today badge border only 1pt** - Should be 2pt

### Typography Issues (11-20)
11. **Month 9pt** - Below readable threshold
12. **Year 8pt** - Far too small
13. **Week number 32pt** - Below Theme.medium.weekNumber (56pt)
14. **"WEEK" label 7pt** - Unreadable
15. **Day number 16pt** - Good but weight only .bold not .black
16. **Country code 9pt** - Acceptable but small
17. **City name 9pt** - May truncate
18. **Digital time 12pt** - Could be larger
19. **Offset text 8pt** - Too small
20. **No Dynamic Type scaling** - Fixed sizes throughout

### Layout Issues (21-30)
21. **25% left panel** - Too narrow for content
22. **Vertical spacing 2pt** - Too tight
23. **Clock size 44pt** - Good but may crowd
24. **Day badge 26x26pt** - Below touch target
25. **No horizontal centering** - Content may shift
26. **VStack spacing: 3** - Inconsistent with rest
27. **Country pill padding 6/2pt** - Tight
28. **Analog clock not centered** - May shift with different times
29. **Day/night HStack spacing 2pt** - Too tight
30. **No responsive layout** - Same regardless of clock count

### Color/Visual Issues (31-40)
31. **Regional colors for minute hands** - Inconsistent visual language
32. **Sun orange #F39C12** - Different from JohoWidget colors
33. **Moon purple #6C5CE7** - Not from design system
34. **Today badge uses roundedRectangle** - Should be circle like others
35. **No color for local timezone** - No distinction from others
36. **Country pill colors vary** - Nordic blue, Asian red, etc.
37. **Clock face pure white** - Could use cream
38. **Hour markers pure black** - Could be softer
39. **Center dot black** - No color coordination
40. **No state indication** - No way to show syncing/stale

## IMPROVEMENTS (100 proposed)

### Clock Display (1-25)
1. Increase analog clock to 52pt
2. Add second hand option
3. Create digital-only mode
4. Implement 12/24 hour toggle
5. Add date display per clock
6. Show weekday per timezone
7. Create DST indicator
8. Add timezone abbreviation
9. Implement city search
10. Add custom timezone naming
11. Create clock face options
12. Implement classic/modern styles
13. Add Roman numeral option
14. Create minimalist design
15. Implement color-coded faces
16. Add regional face styles
17. Create animated clock hands
18. Implement smooth second hand
19. Add tick marks customization
20. Create luminous mode
21. Implement night mode
22. Add alarm indicators
23. Create meeting time overlay
24. Implement countdown to event
25. Add business hours indicator

### Layout (26-50)
26. Use 30% left panel
27. Implement 3-clock maximum
28. Add 4-clock layout option
29. Create compact mode
30. Implement expanded details
31. Add scrolling for many clocks
32. Create carousel mode
33. Implement grid layout
34. Add list view option
35. Create map view integration
36. Implement globe visualization
37. Add timeline view
38. Create comparison view
39. Implement overlap indicator
40. Add meeting planner layout
41. Create schedule overlay
42. Implement availability view
43. Add time difference calculator
44. Create call time suggester
45. Implement world clock ring
46. Add polar clock display
47. Create linear timeline
48. Implement day/night terminator
49. Add solar/lunar indicators
50. Create astronomical view

### Interaction (51-75)
51. Add tap to expand clock
52. Create timezone picker
53. Implement city search
54. Add favorites management
55. Create clock reordering
56. Implement swipe to delete
57. Add long-press menu
58. Create share timezone link
59. Implement copy time
60. Add calendar integration
61. Create meeting scheduler
62. Implement availability sharing
63. Add contact timezone lookup
64. Create team time view
65. Implement shift planner
66. Add reminder at timezone
67. Create alarm for timezone
68. Implement sunrise/sunset alerts
69. Add business hours overlay
70. Create working hours indicator
71. Implement focus time zones
72. Add travel planner
73. Create jet lag calculator
74. Implement time offset adjust
75. Add custom offset support

### Visual Design (76-100)
76. Standardize all colors to JohoWidget
77. Remove regional minute hand colors
78. Use consistent day/night icons
79. Implement unified clock face style
80. Add border to all clock faces
81. Create stronger bento dividers (2pt)
82. Standardize country pill style
83. Add black border to all elements
84. Implement consistent typography
85. Create visual rhythm with spacing
86. Add header row for clocks
87. Implement footer status bar
88. Create sync status indicator
89. Add last refresh timestamp
90. Implement error states
91. Add loading indicators
92. Create empty state design
93. Implement placeholder content
94. Add configuration prompt
95. Create onboarding flow
96. Implement tutorial overlays
97. Add feature highlights
98. Create premium indicators
99. Implement subscription badges
100. Add version information

---

# CROSS-WIDGET CONSISTENCY ISSUES

## Critical Inconsistencies

| Issue | Small | Medium | Large | WorldClock |
|-------|-------|--------|-------|------------|
| Outer border | 2pt | 2.5pt | 2pt | 2.5pt |
| Today shape | Circle | Circle | Circle | RoundedRect |
| Week number size | 56pt | 48pt | N/A | 32pt |
| Opacity values | 0.6-0.7 | 0.3-0.7 | 0.5-0.7 | 0.5-0.6 |
| Label font size | 10pt | 9pt | N/A | 7pt |
| Day number size | 16pt | 13pt | 14pt | 16pt |

## Required Standardization
1. **All outer borders: 2.5pt** for medium, 2pt for small, 3pt for large
2. **All today indicators: Circle** with 1.5pt black border
3. **All opacity: 0.6 or 1.0** (no intermediate values)
4. **All label fonts: minimum 9pt**
5. **All day numbers: minimum 14pt**
6. **All touch targets: minimum 44pt**

---

# ACTION ITEMS

## Immediate (P0)
1. Standardize border weights across all widgets
2. Unify today indicator to circle
3. Fix all touch target sizes
4. Remove colored backgrounds
5. Increase minimum font sizes

## Short-term (P1)
6. Implement Theme.Borders consistently
7. Add Dark Mode support
8. Improve accessibility labels
9. Add Dynamic Type support
10. Standardize color usage

## Medium-term (P2)
11. Add widget configuration
12. Implement deep linking
13. Add haptic feedback
14. Create widget gallery preview
15. Add onboarding

## Long-term (P3)
16. Implement advanced features
17. Add data integrations
18. Create premium widgets
19. Add customization options
20. Build widget builder
