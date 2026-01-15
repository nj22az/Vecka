# 情報デザイン
## The Japanese Art of Information Design

**A Practical Guide to Semantic Colors, Border Systems & UI Components with iOS App Case Study**

---

### About This Book

Every pixel in Japanese design serves a purpose. From Tokyo's legendary train signage to the meticulously organized OTC medicine packaging, Japan has perfected the art of visual communication. This book reveals the complete 情報デザイン (Jōhō Dezain) system and shows you how to apply it to modern app development.

This is not a theoretical design book. It's built around a real production iOS app called Onsen Planner. You'll see exactly how every principle translates to working code, with before-and-after comparisons that demonstrate the dramatic improvement 情報デザイン brings to user interfaces.

---

### How to Read This Book

**Part 1: Philosophy** establishes the foundation. Read this first to understand why 情報デザイン exists and what makes it different from Western design approaches.

**Part 2: The Design System** is your reference manual. Each chapter covers one aspect of the system in detail. You can read sequentially or jump to specific topics.

**Part 3: Component Library** provides production-ready patterns. Use this when building actual interfaces.

**Part 4: Case Study** demonstrates everything in context through the Onsen Planner app. This is where theory becomes practice.

**Part 5: Implementation** gives you the tools to apply 情報デザイン to your own projects, including code patterns and audit checklists.

---

### About the Author

[Author bio placeholder]

---

### Acknowledgments

This book would not exist without the design systems that inspired it: the Tokyo Metro wayfinding system, the packaging designers at Japanese pharmaceutical companies, and the engineers who built iOS and SwiftUI.

---

*First Edition, 2026*


---


# Chapter 1: What is 情報デザイン?

> "Every visual element must serve a clear informational purpose. Nothing is decorative—everything communicates."

---

## The Word Itself

情報デザイン is written with four kanji characters:

- **情** (jō) — emotion, feeling, situation
- **報** (hō) — information, news, report
- **デ** (de) — phonetic "de"
- **ザイン** (zain) — phonetic "sign" (from English "design")

Together, 情報 (jōhō) means "information" and デザイン (dezain) is the Japanese rendering of "design." So 情報デザイン literally translates to "information design."

But the meaning runs deeper than the translation suggests.

In Japan, 情報デザイン isn't just about making information look good. It's about making information *work*. Every visual choice—every color, every border, every piece of spacing—must serve a functional purpose. Decoration for its own sake is not just discouraged; it's considered a design failure.

---

## A Different Philosophy

Western information design, pioneered by Edward Tufte and others, emerged from statistics and academia. Its primary concern is data density—how much information can be communicated accurately in a given space. Tufte famously criticized "chartjunk"—unnecessary visual elements that don't convey data.

Japanese information design shares this hatred of the unnecessary, but approaches the problem differently. Where Tufte's work is cerebral and analytical, 情報デザイン is environmental and intuitive. It evolved not in universities but in train stations, pharmacies, and convenience stores—places where millions of people need to extract critical information in seconds.

Consider the difference:

| Aspect | Western Information Design | 情報デザイン |
|--------|---------------------------|--------------|
| Origin | Academic/Statistical | Environmental/Commercial |
| Goal | Data density | Instant comprehension |
| Aesthetic | Clean, minimal | Bold, compartmentalized |
| Color use | Often monochrome | Semantic (meaning-laden) |
| Borders | Optional | Required |
| Primary medium | Print/Charts | Signage/Packaging |

---

## The Train Station Test

To understand 情報デザイン, stand in Shinjuku Station during rush hour.

Shinjuku is the world's busiest train station. Over 3.5 million passengers pass through daily—more than the entire population of Berlin. Dozens of train lines operated by different companies converge here. Miss your connection and you might be stranded on the wrong side of Tokyo.

In this chaos, there is no time for confusion. The wayfinding system must work instantly, for everyone: commuters who've made this journey a thousand times, tourists who don't speak Japanese, elderly passengers, children traveling alone.

Look at the signage. Notice what you see:

**Thick black borders** surround every piece of information. Each sign is a distinct unit, not bleeding into the next. Your eye knows exactly where one instruction ends and another begins.

**Color is semantic.** The Yamanote Line is always green. The Chuo Line is always orange. The Marunouchi Line is always red. These colors mean something. They're not decorative choices made by a designer who liked green—they're standardized identifiers that work across every map, every sign, every app.

**Compartmentalization.** Information is grouped into clear zones. Platform numbers are separate from line names. Directions are separate from warnings. You don't scan—you locate.

**High contrast.** Black on white. White on colored backgrounds. No subtle grays, no low-contrast combinations that might disappear under harsh fluorescent lighting or in peripheral vision.

This is 情報デザイン at scale. And the remarkable thing is: it works. Despite Shinjuku's complexity, most passengers navigate it successfully. The design doesn't make you think—it makes thinking unnecessary.

---

## The Bento Box Principle

Japanese design loves compartments.

Consider the bento box: a meal divided into distinct sections, each containing a different food. Rice here. Pickles there. Fish in its own space. Nothing touches. Nothing bleeds together.

This isn't just aesthetics—it's functional. A bento box is easy to eat because you always know what you're getting. Chopsticks go into one compartment, retrieve one type of food. No surprises, no mixing unless you choose to mix.

情報デザイン applies this principle to visual information. Every piece of content gets its own compartment. These compartments have visible walls—borders—that separate them from their neighbors.

In Western design, we often let elements float in space, using proximity and alignment to show relationships. This works, but it requires cognitive processing. The viewer must interpret: "These elements are close together, so they're probably related."

In 情報デザイン, relationships are explicit. Elements in the same box are related. Elements in different boxes are different. The border tells you everything.

```
WESTERN APPROACH:
┌────────────────────────────────────────┐
│  Item A                                │
│  Description of item A                 │
│                                        │
│  Item B                                │
│  Description of item B                 │
│                                        │
│  Item C                                │
│  Description of item C                 │
└────────────────────────────────────────┘

情報デザイン APPROACH:
┌────────────────────────────────────────┐
│ ┌────────────────────────────────────┐ │
│ │ Item A                             │ │
│ │ Description of item A              │ │
│ └────────────────────────────────────┘ │
│ ┌────────────────────────────────────┐ │
│ │ Item B                             │ │
│ │ Description of item B              │ │
│ └────────────────────────────────────┘ │
│ ┌────────────────────────────────────┐ │
│ │ Item C                             │ │
│ │ Description of item C              │ │
│ └────────────────────────────────────┘ │
└────────────────────────────────────────┘
```

More lines? Yes. More clarity? Also yes.

---

## The Medicine Cabinet Lesson

Walk into any Japanese pharmacy and examine the OTC medicine packaging. Companies like Muhi, Rohto, and Salonpas have spent decades perfecting information design for their products.

Pick up a box of Salonpas pain relief patches. Notice:

**Compartmentalized information.** The product name is in one zone. The dosage instructions are in another. Warnings occupy their own clearly bordered section. Ingredients are grouped separately.

**Thick black borders.** Every zone has visible walls. Your eye doesn't have to guess where one piece of information ends and another begins.

**Color coding.** Different product lines use different colors consistently. The same colors appear on the box, the interior packaging, and the patches themselves.

**High contrast.** Text is black on white or white on bold colors. No subtle gradients, no text that might become illegible under store lighting.

**Purposeful color.** Red means warning. Yellow means attention. Blue means soothing/cooling. These associations are consistent across the entire product line—and indeed, across competing products. The colors are industry conventions, not brand decisions.

Now compare this to Western medicine packaging. Often beautiful. Often award-winning. Often confusing when you're sick at 3 AM and trying to figure out the correct dosage.

Japanese medicine packaging isn't more beautiful. It's more *usable*. And in design, usable is beautiful.

---

## Why Borders Matter

Borders are non-negotiable in 情報デザイン. This might seem excessive to Western designers trained in minimalism. Why add visual weight when you could use whitespace?

The answer lies in how we process visual information.

When elements have borders, your brain processes them as discrete objects. You don't need to calculate relationships—the borders define them. This is faster and requires less cognitive effort.

When elements float in space, your brain must do more work. You perceive the elements, calculate their proximity, infer their relationships, then interpret them. Each step takes time and mental energy.

In a train station during rush hour, you don't have time for that work. On a medicine box when you're sick, you don't have energy for that work. The borders do the work for you.

There's also a cultural dimension. In Japanese visual culture, boundaries are important. The concept of *ma* (間)—negative space—is meaningful precisely because it exists between defined elements. Without borders, there is no *ma*. There's just... nothing.

---

## Semantic Color

In 情報デザイン, colors have meanings. They're not decorative—they're linguistic.

Consider these associations:

| Color | Meaning |
|-------|---------|
| Yellow | Now, present, attention |
| Red | Warning, danger, Sunday |
| Green | Go, safe, money |
| Blue | Information, calm, water |
| Pink | Celebration, special |
| Orange | Energy, movement |
| Purple | Premium, mysterious |

These aren't arbitrary. They emerge from decades of use in Japanese signage, packaging, and interfaces. A yellow element demands immediate attention. A red element signals danger or prohibition. A green element indicates safety or permission.

When you use color semantically, you're not just styling—you're communicating. Users learn the color language and read your interface faster.

But this only works if you're consistent. The moment yellow sometimes means "now" and sometimes means "decorative highlight," your color language breaks. Users can't trust it, so they stop reading it.

In 情報デザイン, every color has exactly one meaning. Period.

---

## The Squircle

Look at the corners of Japanese interfaces. They're not sharp. They're not circular. They're *continuous*—a shape Apple calls the "squircle."

A squircle is a rounded rectangle where the curve flows smoothly from the straight edge. There's no mathematical discontinuity where the curve meets the line. Your eye follows the contour without interruption.

Compare:

```
STANDARD ROUNDED RECTANGLE:
The curve has a specific radius that meets the straight edge
at a defined point. There's a subtle "kink" at the junction.

SQUIRCLE (CONTINUOUS CORNERS):
The curve gradually transitions from straight to curved.
No junction point. No kink. Smooth the whole way.
```

Why does this matter? Because your eye notices discontinuities. Even tiny ones. A standard rounded rectangle creates four subtle tension points where the curves meet the edges. A squircle has none.

Apple popularized this in iOS, but the shape has deep roots in Japanese industrial design. Look at Japanese cars, appliances, packaging—continuous curves everywhere.

In code, the difference is simple:

```swift
// Standard rounded rectangle
RoundedRectangle(cornerRadius: 12)

// Squircle (continuous corners)
RoundedRectangle(cornerRadius: 12, style: .continuous)
```

One parameter. Enormous difference in feel.

---

## What 情報デザイン Is Not

**It's not minimalism.** Minimalism removes elements. 情報デザイン adds structure—borders, compartments, semantic color. A 情報デザイン interface often has more visual elements than a minimalist one.

**It's not flat design.** Flat design is about aesthetics—removing shadows, gradients, textures. 情報デザイン is about function—ensuring every visual element communicates something.

**It's not Japanese aesthetics.** You don't need cherry blossoms, paper textures, or kanji. 情報デザイン principles work in any visual language.

**It's not a trend.** The principles date back decades. They'll be valid decades from now. This isn't material design or skeuomorphism—it's not a style that will look dated. It's a methodology.

---

## Summary: The Seven Principles

1. **Everything has a border.** Every element is defined, contained, separate.

2. **Color is semantic.** Every color has one meaning. No decorative color.

3. **Compartmentalization.** Information is grouped into visible containers.

4. **High contrast.** Black on white. No subtle grays.

5. **Continuous corners.** Squircles, not rounded rectangles.

6. **Purposeful spacing.** Every gap means something. No arbitrary padding.

7. **Function over decoration.** If it doesn't communicate, remove it.

These principles are simple. Applying them consistently is the challenge. The rest of this book will show you how.

---

*Next: Chapter 2 — Origins & Influences*


---


# Chapter 2: Origins & Influences

> "Design is not just what it looks like and feels like. Design is how it works."
> — Steve Jobs, channeling Japanese design philosophy

---

## The Railroad Revolution

Modern Japanese information design begins with trains.

In 1872, Japan's first railway opened between Tokyo and Yokohama. Within decades, the country built one of the world's most complex rail networks. By the 1960s, millions of passengers were using trains daily, and the challenge of wayfinding became critical.

The problem was unique. Japanese stations served multiple operators, each with different lines, schedules, and fare systems. Passengers transferred between networks constantly. And unlike Western stations designed around central hubs, Japanese stations evolved organically, sprawling underground and above ground in seemingly chaotic patterns.

The solution emerged gradually: a design language so consistent that passengers could navigate any station in the country using the same visual cues.

**Color coding became law.** Each line received a permanent color. The Yamanote Line would always be light green. The Chuo Line would always be orange. These weren't suggestions—they were standards enforced across signage, maps, tickets, and eventually apps.

**Borders became mandatory.** Every sign was framed. Every piece of information occupied a defined space. In the visual noise of a busy station, bordered elements stood out.

**Pictograms replaced words.** Not everyone reads Japanese. But everyone understands a pictogram of stairs, an arrow, a toilet symbol. Japanese transit designers pioneered pictographic communication decades before emoji existed.

The result was a design system so effective that it spread beyond transit. The same principles now appear in Japanese interfaces, packaging, and signage everywhere.

---

## The JIS Standards

In 1921, Japan established the Japanese Industrial Standards (JIS) committee. Over the following century, JIS standardized everything from paper sizes to safety symbols.

JIS Z 8210, the standard for safety signs, is particularly relevant. It defines exactly how warning symbols should look: what colors mean danger, what shapes indicate prohibition, what pictograms represent specific hazards.

These aren't suggestions. They're standards taught in schools, enforced in workplaces, embedded in Japanese visual literacy. When a Japanese person sees a yellow triangle, they know—without reading—that caution is required. When they see a red circle with a diagonal line, they know something is prohibited.

This standardization creates efficiency. Designers don't reinvent warning systems. Users don't learn new visual languages. The cognitive load of interpretation disappears.

情報デザイン inherits this standardization mindset. Colors have defined meanings. Shapes communicate function. Nothing is arbitrary.

---

## The Bauhaus Connection

Japan's embrace of industrial design wasn't indigenous. It was imported.

In the 1920s and 1930s, Japanese designers and architects traveled to Germany to study at the Bauhaus. They brought back principles that would shape Japanese design for a century: form follows function, truth to materials, geometric clarity.

But something changed in translation. German Bauhaus was austere, almost severe. Japanese Bauhaus softened. The sharp angles became continuous curves. The rigid grids became flexible compartments. The mechanical precision became organic flow.

This synthesis—German functional rigor meets Japanese aesthetic sensibility—created something new. Not quite Bauhaus. Not quite traditional Japanese. Something that worked better for Japanese contexts.

You can see this hybrid in Japanese cars of the 1960s and 1970s. The functional clarity of German engineering. The smooth, continuous surfaces of Japanese taste. The attention to interior organization—every control in its logical place.

The same hybrid appears in 情報デザイン. The Western insistence on functional purpose. The Japanese eye for smooth corners and balanced composition. Neither alone. Both together.

---

## Muji and the No-Brand Brand

In 1980, the Seiyu supermarket chain launched a house brand called Mujirushi Ryohin—literally "no-brand quality goods." Today we know it as Muji.

Muji's design philosophy was radical: remove everything unnecessary. No brand names on products. No decorative packaging. Just the object itself, in the simplest possible container.

This sounds like minimalism, but it's different. Minimalism often removes *functional* elements for aesthetic purity. Muji removes *decorative* elements while preserving—even emphasizing—functional ones.

A Muji notebook has no decoration. But it has clear labels indicating paper weight, page count, and binding type. The information you need is present. The information you don't need is absent.

This distinction matters. 情報デザイン isn't about having less. It's about having exactly what's needed.

Muji's influence spread far beyond retail. Its philosophy became a touchstone for Japanese digital design. Apple's Jony Ive cited Muji as an inspiration. The connection between Muji's product design and iOS's interface design is visible to anyone who looks.

---

## OTC Packaging: Design Under Constraint

Japanese pharmaceutical packaging deserves special attention because it operates under extreme constraints.

By law, medicine packaging must include extensive information: ingredients, dosages, warnings, contraindications, manufacturer details. All of this must fit on a small box. All of this must be legible. All of this must be accessible to sick people who may be elderly, visually impaired, or reading in dim light.

The design challenge is immense. Too much information in too little space for too critical an application.

Japanese pharmaceutical designers solved this through ruthless organization:

**Strict hierarchy.** Product name largest. Dosage instructions next. Warnings prominent but not dominant. Fine print for legal requirements.

**Zone-based layout.** Front of box for identification. Side panel for dosage. Back for ingredients and warnings. Every piece of information has a home.

**Color coding.** Product lines use consistent colors across all variants. Nighttime formulas are blue. Daytime formulas are yellow. You can grab the right box in the dark.

**Border separation.** Every zone has visible borders. Your eye doesn't wander. It goes directly to the compartment you need.

The result is packaging that works. Not beautiful by Western design-magazine standards, but profoundly usable. When you're sick at 2 AM, usability is beauty.

---

## Nintendo and Interface Design

Japan's video game industry contributed surprisingly much to 情報デザイン.

Consider the Nintendo Entertainment System's interface conventions. Health displayed as hearts in a bordered zone. Inventory in a clearly framed panel. Score in a defined position. Every piece of game state has a location, a container, a consistent appearance.

These conventions weren't accidental. Nintendo's designers understood that players needed to access information instantly while managing complex inputs. There was no time for visual parsing. The interface had to be readable at a glance.

The same principles apply to PlayStation's button symbols—which are, in fact, Maru-Batsu symbols we'll discuss later. Circle for yes. X for no. Triangle for perspective. Square for menus. A visual language inherited directly from Japanese business and educational traditions.

Game interfaces pushed these principles into the digital realm. They proved that 情報デザイン worked on screens, not just in physical spaces. They trained a generation of users to expect bordered, color-coded, compartmentalized information.

---

## Mobile First: i-mode to iPhone

Japan was mobile-first before the term existed.

In 1999, NTT DoCoMo launched i-mode, a mobile internet service that predated the iPhone by eight years. Within a year, millions of Japanese were browsing the web, sending email, and making purchases on tiny phone screens.

The design constraints were brutal. Screens measured 96×72 pixels. Colors were limited. Bandwidth was expensive. Every element had to earn its place.

i-mode designers responded with extreme information density. Small, bordered zones. Semantic color (when colors were available). Pictographic navigation. Compressed layouts that crammed maximum content into minimum space.

These conventions influenced a generation of Japanese web and app designers. When the iPhone arrived, Japanese developers already understood mobile constraints. They'd been designing for small screens for a decade.

You can see this heritage in Japanese apps today. Dense information layouts. Clear visual hierarchy. Efficient use of space. Not because Japanese designers like cramped interfaces, but because they learned design under extreme constraints.

---

## The Ma (間) Concept

No discussion of Japanese design is complete without *ma*.

Ma (間) is often translated as "negative space," but this misses the point. Ma isn't just empty space. It's meaningful emptiness. The pause between notes that makes music. The silence between words that creates poetry. The space between elements that gives them definition.

In Western design, we often think of empty space as absence—nothing there. In Japanese design, ma is presence—something there, just not visible.

This seems philosophical, but it has practical implications for 情報デザイン.

When you add a border around an element, you create ma. The space between the border and adjacent elements isn't empty—it's separating, defining, organizing. It has a job.

When you use consistent spacing, you're choreographing ma. The rhythm of space creates visual flow, guides the eye, establishes hierarchy.

When you resist the urge to fill every pixel, you're respecting ma. The emptiness makes the content more visible, not less.

情報デザイン without ma would be claustrophobic. Every element jammed against its neighbor. No breathing room. No rhythm. No flow.

Ma is why 情報デザイン interfaces feel organized even when dense. The borders create containers. The containers create ma. The ma creates clarity.

---

## Modern Japanese App Design

Today's Japanese apps inherit all these influences. You can see the train station signage, the pharmaceutical packaging, the Muji philosophy, the game interfaces, the mobile heritage, the ma.

Open a Japanese banking app. Notice the bordered zones, the color-coded categories, the dense but organized layouts.

Open a Japanese transit app. Notice the color coding matching physical signage, the compartmentalized schedules, the clear visual hierarchy.

Open a Japanese e-commerce app. Notice the product zones, the bordered buttons, the semantic color guiding action.

These aren't accidents or coincidences. They're the accumulated wisdom of a century of information design, refined through billions of user interactions, standardized through industrial processes, and embedded in Japanese visual literacy.

情報デザイン isn't a style you adopt. It's a tradition you inherit.

---

## What We Take Forward

From the railroads: **color coding and standardization.**

From JIS: **semantic consistency and universal pictograms.**

From Bauhaus: **functional purpose and geometric clarity.**

From Muji: **removal of decoration, preservation of function.**

From pharmaceuticals: **extreme organization under constraint.**

From games: **real-time readability and visual language.**

From mobile: **density without chaos.**

From ma: **meaningful space.**

These aren't historical curiosities. They're the foundation of the design system we'll build in this book. Every principle has a pedigree. Every rule has a reason.

---

*Next: Chapter 3 — Core Principles*


---


# Chapter 3: Core Principles

> "The seven rules. Memorize them. Apply them. Never break them."

---

This chapter defines the non-negotiable rules of 情報デザイン. These aren't guidelines or suggestions. They're laws. Every principle in this book derives from these seven rules.

---

## Principle 1: Everything Has a Border

The first rule is the most important. It's also the most frequently violated by designers coming from other traditions.

**Every container has a visible border.**

Not most containers. Not important containers. Every container.

```
┌─────────────────────────────────────────┐
│                                         │
│    This element has a border.           │
│    It is a discrete unit.               │
│    Your eye knows where it begins       │
│    and ends.                            │
│                                         │
└─────────────────────────────────────────┘
```

Without borders:

```

    This element has no border.
    It floats in space.
    Your eye must calculate its
    boundaries. That takes effort.

```

See the difference? The bordered element is instantly parseable. The borderless element requires your brain to construct invisible boundaries.

### Border Weights

Not all borders are equal. 情報デザイン uses a specific hierarchy:

| Element Type | Border Width | Example |
|--------------|--------------|---------|
| Cells, small elements | 1pt | Calendar day cells |
| List rows, sections | 1.5pt | Table rows |
| Buttons, interactive | 2pt | Action buttons |
| Selected, focused | 2.5pt | Active states |
| Containers, cards | 3pt | Main content areas |

This hierarchy communicates importance. A 3pt border says "this is a major container." A 1pt border says "this is a small element within a container."

### Border Color

Border color is always black (#000000). No gray. No colored borders. Black.

Why? Because black borders work on any background. They're visible on white. They're visible on colors. They create consistent visual rhythm regardless of content.

The only exception: white borders on dark backgrounds, maintaining the same weight hierarchy.

### Common Mistakes

**Missing borders entirely.** If you can't see where an element ends, it needs a border.

**Inconsistent weights.** If buttons sometimes have 2pt borders and sometimes have 1pt borders, your visual language is broken.

**Colored borders.** Unless you're indicating state (selected, error), stick to black.

**Borders that disappear.** A border that matches its background isn't a border—it's decoration.

---

## Principle 2: Color Is Semantic

In 情報デザイン, colors have meanings. They're not decorative choices. They're vocabulary.

The core palette:

| Color | Hex Code | Meaning | Usage |
|-------|----------|---------|-------|
| Yellow | #FFE566 | NOW / Present | Today, current item, attention |
| Cyan | #A5F3FC | Scheduled Time | Events, appointments, calendar |
| Pink | #FECDD3 | Special Day | Holidays, birthdays, celebrations |
| Orange | #FED7AA | Movement | Trips, travel, locations |
| Green | #BBF7D0 | Money | Expenses, financial items |
| Purple | #E9D5FF | People | Contacts, relationships |
| Red | #E53935 | Alert | Warnings, errors, Sundays |
| Black | #000000 | Definition | Borders, primary text |
| White | #FFFFFF | Content | Backgrounds, containers |

### The One-Meaning Rule

Each color has exactly one meaning. No exceptions.

If yellow means "now," yellow can't also mean "warning." If green means "money," green can't also mean "success."

This seems restrictive, and it is. That's the point. When colors are ambiguous, users can't learn them. When colors are consistent, users read them without thinking.

### How Users Learn Color Language

The first time a user sees yellow highlighting today's date, they notice: "yellow means today."

The second time, they confirm: "yes, yellow means today."

The third time, they stop noticing. Yellow is now unconsciously associated with the present moment. They scan for yellow without thinking.

This is the power of semantic color. Users develop fluency. Your interface becomes faster to read with each use.

But the moment yellow appears for a different reason, fluency breaks. "Wait, does yellow mean today or does it mean... something else?" The user must now actively interpret every yellow element. Speed is lost.

### Using Color

Color goes on backgrounds of containers that represent that concept.

- A today indicator? Yellow background.
- An event item? Cyan background.
- A holiday entry? Pink background.
- A trip card? Orange background.
- An expense row? Green background.
- A contact cell? Purple background.
- A warning banner? Red background.

The color fills the container. Text on top is black (or white if contrast requires).

### Not Using Color

Don't use color for:

- Decoration ("This section needs visual interest")
- Branding ("Our brand color is blue")
- Differentiation without meaning ("Let's make these items different colors")
- Emphasis without semantic meaning ("This is important, make it red")

If the color doesn't mean something, don't use it. Use black and white.

---

## Principle 3: Black Text on White Backgrounds

This rule seems almost insultingly basic. But it's violated constantly.

**Content areas have white backgrounds. Text is black.**

Not gray text. Not light text on dark backgrounds. Black text on white backgrounds.

```
┌─────────────────────────────────────────┐
│                                         │
│   This text is black (#000000)          │
│   This background is white (#FFFFFF)    │
│   Maximum contrast. Maximum legibility. │
│                                         │
└─────────────────────────────────────────┘
```

### The Dark Background Rule

"But my app has a dark theme," you say.

Fine. The dark background is your canvas—the outermost layer. But your content containers are still white (or very light). Text is still black (or very dark).

The dark background should be barely visible. Just thin edges showing between white containers. If you can see more than 8pt of dark background anywhere inside your content area, something is wrong.

```
Dark Background Canvas
┌────────────────────────────────────────────────────────┐
│                                                        │
│   ┌────────────────────────────────────────────────┐   │
│   │                                                │   │
│   │   White container with black text.             │   │
│   │                                                │   │
│   │   The dark background is just a thin          │   │
│   │   edge around this container.                  │   │
│   │                                                │   │
│   └────────────────────────────────────────────────┘   │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### Why High Contrast?

- **Accessibility.** Low contrast fails users with visual impairments.
- **Environmental robustness.** Screens in sunlight, dim rooms, various angles—high contrast works everywhere.
- **Cognitive ease.** Your brain processes high contrast faster.
- **Aging.** Users' vision degrades. High contrast ages well.

"But low contrast looks sophisticated," you say.

Sophistication that reduces usability isn't sophisticated. It's ego.

---

## Principle 4: Continuous Corners (Squircle)

All corners must use continuous curvature.

```swift
// ✅ CORRECT - Continuous corners
RoundedRectangle(cornerRadius: 12, style: .continuous)

// ❌ WRONG - Standard corners
RoundedRectangle(cornerRadius: 12)
.cornerRadius(12)  // This is also wrong
```

The difference is subtle but important. A standard rounded rectangle has a mathematical discontinuity where the curve meets the straight edge. A continuous corner (squircle) transitions smoothly.

### Corner Radius Values

| Element | Radius |
|---------|--------|
| Day cells | 8pt |
| Buttons | 8pt |
| Pills, badges | 6pt |
| Cards | 12pt |
| Containers | 16pt |

Larger elements get larger radii. Small elements get smaller radii. The proportion feels natural.

### Never Use .cornerRadius()

In SwiftUI, the `.cornerRadius()` modifier uses standard (non-continuous) corners. Always use `RoundedRectangle(cornerRadius:style:)` with `.continuous` instead.

---

## Principle 5: Compartmentalized Layouts

Information is grouped into visible containers. Related items share a container. Unrelated items get separate containers.

The bento box layout:

```
┌─────────────────────────────────────────────────────────┐
│ ┌─────────┬─────────────────────────────┬─────────────┐ │
│ │  Icon   │  Title and Description      │  Actions    │ │
│ │  Zone   │  Zone                       │  Zone       │ │
│ └─────────┴─────────────────────────────┴─────────────┘ │
└─────────────────────────────────────────────────────────┘
```

Each zone has:
- A defined purpose
- A visible boundary (even if just a divider line)
- Consistent sizing

### Nesting Containers

Containers can nest, but follow the border hierarchy:

```
Outer container (3pt border)
┌─────────────────────────────────────────────────────┐
│                                                     │
│   Section (1.5pt border)                           │
│   ┌───────────────────────────────────────────┐    │
│   │                                           │    │
│   │   Item (1pt border)                       │    │
│   │   ┌───────────────────────────────────┐   │    │
│   │   │  Content                          │   │    │
│   │   └───────────────────────────────────┘   │    │
│   │                                           │    │
│   └───────────────────────────────────────────┘    │
│                                                     │
└─────────────────────────────────────────────────────┘
```

Outer containers have thicker borders. Inner elements have thinner borders. This creates visual hierarchy without relying on size or position alone.

---

## Principle 6: Rounded Typography

All text uses rounded fonts. In iOS, this means SF Pro Rounded (via `.design(.rounded)`).

```swift
// ✅ CORRECT
.font(.system(size: 16, weight: .medium, design: .rounded))

// ❌ WRONG
.font(.system(size: 16, weight: .medium))  // Missing .rounded
.font(.body)  // System default, not rounded
```

### The Typography Scale

| Name | Size | Weight | Usage |
|------|------|--------|-------|
| displayLarge | 48pt | heavy | Hero numbers |
| displayMedium | 32pt | bold | Section titles |
| headline | 18pt | bold | Card titles |
| body | 16pt | medium | Content |
| bodySmall | 14pt | medium | Secondary content |
| label | 12pt | bold | Pills, badges (UPPERCASE) |
| labelSmall | 10pt | bold | Timestamps |

### Weight Rules

Never use font weights below `.medium`. Light and ultralight weights reduce legibility and contradict the bold aesthetic of 情報デザイン.

### Labels Are Uppercase

Pills, badges, and small labels are always UPPERCASE. This increases legibility at small sizes and creates visual distinction from body text.

---

## Principle 7: Maximum 8pt Top Padding

This rule seems oddly specific. It is. And it's critical.

The top of your content area should have no more than 8pt of padding before the first element.

Why? Because excessive top padding wastes the most valuable screen real estate. Users' eyes start at the top. Make them scroll past empty space and you've already lost them.

```
❌ WRONG - 40pt top padding
┌────────────────────────────────────────┐
│                                        │
│                                        │
│                                        │
│   Finally, content starts here         │
│                                        │
└────────────────────────────────────────┘

✅ CORRECT - 8pt top padding
┌────────────────────────────────────────┐
│   Content starts immediately           │
│                                        │
│   More content below                   │
│                                        │
└────────────────────────────────────────┘
```

---

## The Forbidden Patterns

The following are never acceptable in 情報デザイン:

### Glass/Blur Effects
```swift
// ❌ FORBIDDEN
.background(.ultraThinMaterial)
.background(.thinMaterial)
```
Glass effects reduce contrast and add visual noise. They're decoration, not communication.

### Gradients
```swift
// ❌ FORBIDDEN
LinearGradient(...)
RadialGradient(...)
```
Gradients are decorative. They don't communicate meaning.

### Raw System Colors
```swift
// ❌ FORBIDDEN
Color.blue
Color.red
Color.green
```
System colors have no semantic meaning in your design language. Use your defined palette.

### Missing Borders
```swift
// ❌ FORBIDDEN
.background(Color.white)  // Where's the border?
```
Every colored background needs a border.

### Non-Continuous Corners
```swift
// ❌ FORBIDDEN
.cornerRadius(12)
```
Always use `RoundedRectangle(cornerRadius:style:.continuous)`.

### Bouncy Animations
```swift
// ❌ FORBIDDEN
.spring(response: 0.5, dampingFraction: 0.5)
```
Animations should be quick and functional, not playful.

---

## Summary Card

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           情報デザイン CORE PRINCIPLES                    │
│                                                         │
│   1. Everything has a border                           │
│   2. Color is semantic                                 │
│   3. Black text on white backgrounds                   │
│   4. Continuous corners (squircle)                     │
│   5. Compartmentalized layouts                         │
│   6. Rounded typography                                │
│   7. Maximum 8pt top padding                           │
│                                                         │
│   FORBIDDEN: Glass, gradients, raw colors,             │
│   missing borders, .cornerRadius()                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

These principles are non-negotiable. Every chapter that follows builds on them. Every component implements them. Every line of code respects them.

---

*Next: Chapter 4 — Color Semantics*


---


# Chapter 4: Color Semantics

> "Yellow means now. Cyan means scheduled. Pink means special. No exceptions."

---

Part 2 of this book details the complete 情報デザイン design system. We begin with color—the most powerful tool in the visual communicator's arsenal, and the most frequently misused.

---

## The Complete Color Palette

情報デザイン uses a fixed palette of ten colors. Each has one meaning. The meaning never changes.

### Yellow — NOW / Present
**Hex: #FFE566**

Yellow is the color of the present moment. It demands immediate attention.

**Use for:**
- Today's date in a calendar
- Current step in a process
- Active/live indicators
- "You are here" markers

**Never use for:**
- Warnings (use red)
- Gold/premium (use orange or separate)
- Random highlights

Yellow is loud. It says "look at me right now." Reserve it for elements that genuinely represent the current moment.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   Mon   Tue   Wed   THU   Fri   Sat   Sun              │
│   14    15    16  ┌─17─┐  18    19    20               │
│                   │TODAY│                               │
│                   └────┘                                │
│                   Yellow background = current day       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

### Cyan — Scheduled Time
**Hex: #A5F3FC**

Cyan represents planned events. Calendar appointments. Scheduled meetings. Anything with a time attached.

**Use for:**
- Calendar events
- Appointments
- Scheduled reminders
- Time-bound items

**Never use for:**
- General information
- Water/environmental themes
- Cool/calm aesthetics

Cyan says "this happens at a specific time." When users see cyan, they immediately understand: this is a scheduled event.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ┌───────────────────────────────────────────────┐    │
│   │  ▮ Team standup meeting                       │    │
│   │    9:00 AM - 9:30 AM                          │    │
│   └───────────────────────────────────────────────┘    │
│   Cyan background = scheduled event                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

### Pink — Special Day
**Hex: #FECDD3**

Pink marks celebrations. Holidays. Birthdays. Days that are different from ordinary days.

**Use for:**
- Public holidays
- Birthdays
- Anniversaries
- Celebrations
- Special occasions

**Never use for:**
- Feminine/gendered content
- Romance (unless it's literally a Valentine's event)
- Soft/gentle aesthetics

Pink says "this day is special." The type of special doesn't matter—holiday, birthday, celebration—the color signals distinctiveness.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ┌───────────────────────────────────────────────┐    │
│   │  ★ Christmas Day                              │    │
│   │    December 25                                │    │
│   └───────────────────────────────────────────────┘    │
│   Pink background = special day                        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

### Orange — Movement
**Hex: #FED7AA**

Orange represents travel and physical movement. Trips. Commutes. Location changes.

**Use for:**
- Trip itineraries
- Travel bookings
- Transportation
- Location-based items
- Movement tracking

**Never use for:**
- Energy/excitement
- Autumn themes
- Food

Orange says "this involves going somewhere." A trip card is orange. A flight booking is orange. A hotel reservation is orange.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ┌───────────────────────────────────────────────┐    │
│   │  ✈ Tokyo Business Trip                        │    │
│   │    March 15-22                                │    │
│   └───────────────────────────────────────────────┘    │
│   Orange background = travel/movement                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

### Green — Money
**Hex: #BBF7D0**

Green represents financial matters. Expenses. Income. Budgets. Transactions.

**Use for:**
- Expense entries
- Income tracking
- Budget categories
- Financial summaries
- Price displays

**Never use for:**
- Success states (use checkmarks instead)
- Environmental themes
- Growth/nature

Green says "this involves money." An expense row is green. A budget category is green. A price tag is green.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ┌───────────────────────────────────────────────┐    │
│   │  $ Lunch with client                          │    │
│   │    $45.00 • Business                          │    │
│   └───────────────────────────────────────────────┘    │
│   Green background = financial item                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

### Purple — People
**Hex: #E9D5FF**

Purple represents human relationships. Contacts. People. Social connections.

**Use for:**
- Contact entries
- Team members
- Relationship indicators
- People-related content

**Never use for:**
- Premium/luxury
- Creativity
- Mystery

Purple says "this is about a person." A contact card is purple. A team member badge is purple. A relationship status is purple.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ┌───────────────────────────────────────────────┐    │
│   │  👤 Sarah Chen                                │    │
│   │    Product Manager • Acme Corp                │    │
│   └───────────────────────────────────────────────┘    │
│   Purple background = person/contact                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

### Red — Alert
**Hex: #E53935**

Red signals danger, warning, or critical attention. It's also used for Sundays in calendar contexts (a Japanese convention).

**Use for:**
- Error states
- Delete confirmations
- Warning messages
- Critical alerts
- Sundays (in calendars)

**Never use for:**
- Love/romance (unless warning about it)
- Energy/excitement
- Brand colors

Red says "stop and pay attention." It's the most urgent color. Use it sparingly to maintain its power.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ┌───────────────────────────────────────────────┐    │
│   │  ⚠ Delete this item?                          │    │
│   │    This action cannot be undone.              │    │
│   │                                               │    │
│   │        [Cancel]   [Delete]                    │    │
│   └───────────────────────────────────────────────┘    │
│   Red background = warning/alert                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

### Cream — Personal
**Hex: #FEF3C7**

Cream represents personal annotations. Notes. User-added content. Things that come from the user, not the system.

**Use for:**
- Personal notes
- User annotations
- Custom entries
- Handwritten-style content

**Never use for:**
- Vintage aesthetics
- Paper textures
- Background colors

Cream says "you added this." A personal note is cream. A user annotation is cream.

---

### Black — Definition
**Hex: #000000**

Black defines structure. It's used for borders, primary text, and anything that creates visual boundaries.

**Use for:**
- All borders
- Primary text
- Icons
- Structural elements

**Never use for:**
- Backgrounds (except as thin canvas)
- Decorative elements

Black is the skeleton of 情報デザイン. Everything else hangs on it.

---

### White — Content
**Hex: #FFFFFF**

White is the default background for content areas. It provides maximum contrast for black text.

**Use for:**
- Content backgrounds
- Container fills
- Default states

**Never use for:**
- Emphasis (that's what semantic colors do)
- Purity/cleanliness themes

White is the canvas. Semantic colors are the paint.

---

## App Background Options

The dark background—the outermost canvas—has three acceptable options:

| Option | Hex | Description |
|--------|-----|-------------|
| True Black | #000000 | Maximum AMOLED power savings |
| Dark Navy | #1A1A2E | Warmer, less harsh |
| Near Black | #0A0A0F | Slight warmth, still very dark |

Choose one for your app and use it consistently. True Black is the default recommendation.

---

## Implementing Color in Code

In SwiftUI, define your colors in a single location:

```swift
struct JohoColors {
    // Semantic colors
    static let yellow = Color(hex: "FFE566")   // Now
    static let cyan = Color(hex: "A5F3FC")     // Events
    static let pink = Color(hex: "FECDD3")     // Holidays
    static let orange = Color(hex: "FED7AA")   // Trips
    static let green = Color(hex: "BBF7D0")    // Money
    static let purple = Color(hex: "E9D5FF")   // People
    static let red = Color(hex: "E53935")      // Alert
    static let cream = Color(hex: "FEF3C7")    // Personal

    // Structural colors
    static let black = Color(hex: "000000")
    static let white = Color(hex: "FFFFFF")

    // App background
    static let background = Color(hex: "000000")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
```

**Never reference Color.blue, Color.red, or other system colors.** Always use JohoColors.

---

## Color in Practice

When applying color, follow these patterns:

### Container Background

```swift
VStack {
    Text("Team Meeting")
    Text("9:00 AM")
}
.padding(12)
.background(JohoColors.cyan)  // Event = Cyan
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(JohoColors.black, lineWidth: 1.5)
)
```

### Indicator Dots

Small colored dots indicate content type:

```swift
Circle()
    .fill(JohoColors.pink)  // Holiday indicator
    .frame(width: 8, height: 8)
    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
```

### Text on Colored Backgrounds

Text on semantic colors is always black:

```swift
Text("Holiday")
    .foregroundStyle(JohoColors.black)
```

---

## Color Accessibility

These colors were chosen for accessibility:

| Color | Contrast Ratio (on white) | WCAG Level |
|-------|---------------------------|------------|
| Black text on Yellow | 14.2:1 | AAA |
| Black text on Cyan | 12.8:1 | AAA |
| Black text on Pink | 11.4:1 | AAA |
| Black text on Orange | 11.9:1 | AAA |
| Black text on Green | 12.1:1 | AAA |
| Black text on Purple | 10.2:1 | AAA |
| White text on Red | 5.9:1 | AA |

All combinations meet WCAG AA requirements. Most meet AAA.

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│             情報デザイン COLOR REFERENCE                  │
│                                                         │
│   YELLOW  #FFE566  ████  Now / Present                 │
│   CYAN    #A5F3FC  ████  Scheduled Events              │
│   PINK    #FECDD3  ████  Special Days                  │
│   ORANGE  #FED7AA  ████  Movement / Travel             │
│   GREEN   #BBF7D0  ████  Money / Finance               │
│   PURPLE  #E9D5FF  ████  People / Contacts             │
│   RED     #E53935  ████  Alerts / Warnings             │
│   CREAM   #FEF3C7  ████  Personal Notes                │
│   BLACK   #000000  ████  Borders / Text                │
│   WHITE   #FFFFFF  ████  Backgrounds                   │
│                                                         │
│   Rule: Each color has ONE meaning. No exceptions.     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 5 — Border Language*


---


# Chapter 5: Border Language

> "A border is not decoration. A border is definition."

---

Borders are the most distinctive feature of 情報デザイン. Where other design systems treat borders as optional styling, 情報デザイン treats them as grammatical—as essential to meaning as words in a sentence.

---

## Why Every Element Needs a Border

Consider two UI elements. One has a border. One doesn't.

```
WITH BORDER:
┌─────────────────────────────────────────┐
│                                         │
│   This card has a defined boundary.     │
│   Your eye knows instantly where it     │
│   begins and ends.                      │
│                                         │
└─────────────────────────────────────────┘

WITHOUT BORDER:

   This card floats in space.
   Your eye must construct imaginary
   boundaries based on content edges.


```

The bordered element is a *thing*. It exists as a discrete unit. The borderless element is content that happens to be grouped—but grouping must be inferred.

This inference takes cognitive effort. Not much—milliseconds—but those milliseconds accumulate. In an interface with dozens of elements, borderless design creates a constant low-level processing burden.

Bordered design eliminates this burden. Every element announces itself: "I am a thing. Here are my edges. This is my territory."

---

## The Border Hierarchy

Not all borders are equal. 情報デザイン uses five specific border weights, each communicating something different:

| Weight | Use Case | Signal |
|--------|----------|--------|
| 1pt | Cells, small elements | "I am a unit within a larger structure" |
| 1.5pt | Rows, sections | "I am a grouping mechanism" |
| 2pt | Buttons, interactive elements | "I respond to touch" |
| 2.5pt | Selected, focused states | "I am currently active" |
| 3pt | Containers, cards | "I am a major content area" |

This hierarchy is absolute. A container never has a 1pt border. A cell never has a 3pt border. The weight tells the user what kind of element they're looking at before they read any content.

---

## 1pt Borders: The Atoms

1pt borders define the smallest meaningful units—the atoms of your interface.

**Calendar day cells:**
```
┌───┬───┬───┬───┬───┬───┬───┐
│ M │ T │ W │ T │ F │ S │ S │
├───┼───┼───┼───┼───┼───┼───┤
│ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │
├───┼───┼───┼───┼───┼───┼───┤
│ 8 │ 9 │10 │11 │12 │13 │14 │
└───┴───┴───┴───┴───┴───┴───┘
Each cell: 1pt border
```

**Type indicator dots:**
```
● ○ ◆ ◇
Each circle/shape: 1pt border (even on fills)
```

**Table cells:**
```
┌──────────┬──────────┬──────────┐
│  Cell A  │  Cell B  │  Cell C  │
└──────────┴──────────┴──────────┘
Internal cell dividers: 1pt
```

The 1pt border says: "I am one piece of a larger puzzle."

---

## 1.5pt Borders: The Molecules

1.5pt borders group atoms into meaningful collections—the molecules of your interface.

**List rows:**
```
┌───────────────────────────────────────────────────────┐
│  ☀ Morning workout                              9:00  │
├───────────────────────────────────────────────────────┤
│  📞 Call with Sarah                            10:30  │
├───────────────────────────────────────────────────────┤
│  ✏️ Review documents                            14:00  │
└───────────────────────────────────────────────────────┘
Row separators: 1.5pt
```

**Section dividers:**
```
┌───────────────────────────────────────────────────────┐
│  UPCOMING                                             │
│  ─────────────────────────────────────────────────── │
│  Item 1                                               │
│  Item 2                                               │
│  ─────────────────────────────────────────────────── │
│  COMPLETED                                            │
│  ─────────────────────────────────────────────────── │
│  Item 3                                               │
└───────────────────────────────────────────────────────┘
Section dividers: 1.5pt
```

**Bento compartment walls:**
```
┌─────┬──────────────────────────┬─────────────────────┐
│ ●   │  Event Title             │  [Badge]  [Icon]    │
│     │  Description             │                     │
└─────┴──────────────────────────┴─────────────────────┘
Internal vertical walls: 1.5pt
```

The 1.5pt border says: "I organize things into groups."

---

## 2pt Borders: Interactive Elements

2pt borders signal interactivity—elements that respond to touch.

**Buttons:**
```
┌─────────────────┐   ┌─────────────────┐
│     Cancel      │   │      Save       │
└─────────────────┘   └─────────────────┘
Button borders: 2pt
```

**Input fields:**
```
┌─────────────────────────────────────────┐
│  Enter your name...                     │
└─────────────────────────────────────────┘
Input border: 2pt
```

**Toggles:**
```
┌────────────────────────┐
│  ●○                    │  OFF
└────────────────────────┘
Toggle track border: 2pt
```

The 2pt border says: "Touch me. I do something."

Users learn this quickly. They scan for 2pt borders when looking for actions. The heavier weight catches the eye, inviting interaction.

---

## 2.5pt Borders: Active States

2.5pt borders indicate selection or focus—elements currently receiving attention.

**Selected calendar day:**
```
┌───┬───┬───┬───┬───────┬───┬───┐
│ M │ T │ W │ T │▐▐ F ▐▐│ S │ S │
├───┼───┼───┼───┼───────┼───┼───┤
Normal cells: 1pt
Selected cell: 2.5pt (bold)
```

**Focused input:**
```
Normal state (2pt):
┌─────────────────────────────────────────┐
│                                         │
└─────────────────────────────────────────┘

Focused state (2.5pt):
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
│                                         │
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

**Selected list item:**
```
┌───────────────────────────────────────────────────────┐
│  Item 1                                               │
┝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┥
│  Item 2  (SELECTED)                                   │
┝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┥
│  Item 3                                               │
└───────────────────────────────────────────────────────┘
Selected row: 2.5pt
```

The 2.5pt border says: "I am the active element. Your attention is here."

---

## 3pt Borders: Containers

3pt borders define major content areas—the containers that hold everything else.

**Main content card:**
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
│                                                       │
│   This is a major content container.                  │
│                                                       │
│   It holds rows (1.5pt), cells (1pt),                │
│   and buttons (2pt).                                  │
│                                                       │
│   The 3pt border establishes it as                    │
│   the top level of hierarchy.                         │
│                                                       │
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
Container border: 3pt
```

**Modal dialogs:**
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
│                                               │
│   Are you sure you want to delete?            │
│                                               │
│       ┌─────────┐   ┌─────────┐              │
│       │ Cancel  │   │ Delete  │              │
│       └─────────┘   └─────────┘              │
│                                               │
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
Dialog container: 3pt
Buttons inside: 2pt
```

The 3pt border says: "I am a major element. Everything inside me is subordinate."

---

## Nested Borders

When containers nest, border weights create visual hierarchy:

```
Outer container (3pt)
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
│                                                       │
│   Section (1.5pt)                                     │
│   ┌───────────────────────────────────────────────┐   │
│   │                                               │   │
│   │   Row (1.5pt)                                 │   │
│   │   ┌───────────────────────────────────────┐   │   │
│   │   │  Cell  │  Cell  │  Cell  │  Cell      │   │   │
│   │   └───────────────────────────────────────┘   │   │
│   │   1pt internal borders                        │   │
│   │                                               │   │
│   └───────────────────────────────────────────────┘   │
│                                                       │
│   Button area                                         │
│   ┌────────────┐   ┌────────────┐                    │
│   │   Cancel   │   │    Save    │                    │
│   └────────────┘   └────────────┘                    │
│   2pt button borders                                  │
│                                                       │
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

The rule: **outer containers have heavier borders than inner elements.**

This creates a clear hierarchy. Your eye follows the weight gradient: 3pt defines the overall container, 1.5pt organizes internal structure, 1pt delineates individual units.

---

## Border Color

In 情報デザイン, borders are black. Always.

```swift
// ✅ CORRECT
.stroke(JohoColors.black, lineWidth: 1.5)

// ❌ WRONG
.stroke(Color.gray, lineWidth: 1.5)
.stroke(JohoColors.cyan, lineWidth: 1.5)
.stroke(someColor.opacity(0.5), lineWidth: 1.5)
```

Exceptions are rare:
- White borders on dark backgrounds (inverted contexts)
- No other exceptions

Colored borders violate the semantic color principle. If a border is cyan, does that mean the element is event-related? Confusion results.

Gray borders reduce contrast. They become invisible at certain sizes or on certain backgrounds.

Transparent borders aren't borders at all.

Black borders work universally. They're visible on white backgrounds, on colored backgrounds, at any size. They create consistent visual rhythm.

---

## Implementing Borders

In SwiftUI, borders are applied via overlay:

```swift
// Container with 3pt border
VStack {
    // content
}
.padding(12)
.background(JohoColors.white)
.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(JohoColors.black, lineWidth: 3)
)

// Row with 1.5pt border
HStack {
    // content
}
.padding(8)
.background(JohoColors.white)
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(JohoColors.black, lineWidth: 1.5)
)

// Button with 2pt border
Button(action: {}) {
    Text("Action")
}
.padding(.horizontal, 16)
.padding(.vertical, 8)
.background(JohoColors.white)
.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(JohoColors.black, lineWidth: 2)
)
```

---

## Common Border Mistakes

**Missing borders entirely:**
```swift
// ❌ WRONG - no border
.background(JohoColors.cyan)

// ✅ CORRECT - with border
.background(JohoColors.cyan)
.clipShape(...)
.overlay(...stroke(JohoColors.black, lineWidth: 1.5))
```

**Wrong weight for element type:**
```swift
// ❌ WRONG - 3pt on a button
.stroke(JohoColors.black, lineWidth: 3)

// ✅ CORRECT - 2pt on a button
.stroke(JohoColors.black, lineWidth: 2)
```

**Colored borders:**
```swift
// ❌ WRONG - semantic color as border
.stroke(JohoColors.cyan, lineWidth: 1.5)

// ✅ CORRECT - black border, semantic background
.background(JohoColors.cyan)
.overlay(...stroke(JohoColors.black, lineWidth: 1.5))
```

**Disappearing borders:**
```swift
// ❌ WRONG - gray on white is barely visible
.stroke(Color.gray.opacity(0.3), lineWidth: 1)

// ✅ CORRECT - black is always visible
.stroke(JohoColors.black, lineWidth: 1)
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           情報デザイン BORDER REFERENCE                   │
│                                                         │
│   1pt    ─────  Cells, small elements, indicators      │
│   1.5pt  ━━━━━  Rows, sections, compartment walls      │
│   2pt    ▬▬▬▬▬  Buttons, inputs, interactive           │
│   2.5pt  ▰▰▰▰▰  Selected, focused states               │
│   3pt    █████  Containers, cards, dialogs             │
│                                                         │
│   COLOR: Always black (#000000)                        │
│   EXCEPTION: White on dark backgrounds                 │
│                                                         │
│   Rule: Every visible element has a border.            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 6 — Typography*


---


# Chapter 6: Typography

> "Rounded letters. Heavy weights. No whispers."

---

Typography in 情報デザイン serves one purpose: instant legibility. Every choice—font family, weight, size, spacing—optimizes for reading speed and clarity.

---

## The Rounded Font Mandate

情報デザイン uses rounded fonts exclusively. On Apple platforms, this means SF Pro Rounded.

Why rounded? Three reasons:

**1. Friendliness without weakness.**
Rounded letterforms feel approachable without sacrificing authority. Sharp corners can feel cold or aggressive. Rounded corners feel warm while maintaining professional clarity.

**2. Consistency with squircle geometry.**
The interface uses continuous corners everywhere. Rounded typography extends this visual language to text. Sharp-cornered letters in a squircle interface create subtle dissonance.

**3. Reduced visual noise.**
Sharp serifs and pointed terminals create complexity. Rounded terminals simplify letterforms, reducing the cognitive processing required to read.

```
SHARP TYPOGRAPHY:
The quick brown fox jumps over the lazy dog.
(Sharp terminals, angular joints)

ROUNDED TYPOGRAPHY:
The quick brown fox jumps over the lazy dog.
(Soft terminals, smooth joints)
```

In code:

```swift
// ✅ CORRECT - Rounded design
.font(.system(size: 16, weight: .medium, design: .rounded))

// ❌ WRONG - Default design (not rounded)
.font(.system(size: 16, weight: .medium))
.font(.body)
```

Every text element must include `.design(.rounded)`. No exceptions.

---

## The Type Scale

情報デザイン uses a fixed type scale with seven levels:

| Name | Size | Weight | Usage |
|------|------|--------|-------|
| displayLarge | 48pt | .heavy | Hero numbers, week displays |
| displayMedium | 32pt | .bold | Section titles, page headers |
| headline | 18pt | .bold | Card titles, row headers |
| body | 16pt | .medium | Primary content, descriptions |
| bodySmall | 14pt | .medium | Secondary content, metadata |
| label | 12pt | .bold | Pills, badges, tags |
| labelSmall | 10pt | .bold | Timestamps, fine print |

### displayLarge (48pt, Heavy)

The largest text in the system. Reserved for hero moments—the primary number or word that defines a screen.

```
┌─────────────────────────────────────────┐
│                                         │
│              ▄▄▄▄   ▄▄▄▄                │
│             █    █ █    █               │
│             █    █  ████                │
│             █    █ █    █               │
│              ████   ████                │
│                                         │
│              WEEK 42                    │
│                                         │
└─────────────────────────────────────────┘
Hero number: 48pt heavy
```

Use sparingly. One displayLarge per screen maximum.

### displayMedium (32pt, Bold)

Section titles and page headers. Establishes major divisions in content.

```
┌─────────────────────────────────────────┐
│                                         │
│   SPECIAL DAYS                          │  ← 32pt bold
│                                         │
│   ┌─────────────────────────────────┐   │
│   │  Christmas Day                  │   │
│   └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### headline (18pt, Bold)

Card titles and row headers. The primary text of individual content items.

```
┌─────────────────────────────────────────┐
│                                         │
│   Team Standup Meeting                  │  ← 18pt bold
│   9:00 AM - Conference Room A           │  ← 14pt medium
│                                         │
└─────────────────────────────────────────┘
```

### body (16pt, Medium)

Primary content text. The default for any paragraph or description.

```
This is body text at 16pt medium weight.
It's used for descriptions, explanations,
and any content that users need to read
in full. Comfortable for extended reading.
```

### bodySmall (14pt, Medium)

Secondary content. Metadata, supporting information, less critical details.

```
┌─────────────────────────────────────────┐
│   Meeting with Client                   │  ← headline
│   Tomorrow at 2:00 PM                   │  ← bodySmall
│   Added 3 days ago                      │  ← bodySmall
└─────────────────────────────────────────┘
```

### label (12pt, Bold, UPPERCASE)

Pills, badges, and categorical tags. Always uppercase.

```
┌─────────────────────────────────────────┐
│   ┌────────┐  ┌────────┐  ┌────────┐   │
│   │ WORK   │  │ URGENT │  │ 2024   │   │
│   └────────┘  └────────┘  └────────┘   │
│                                         │
│   Labels: 12pt bold UPPERCASE          │
└─────────────────────────────────────────┘
```

### labelSmall (10pt, Bold)

Timestamps and fine print. The smallest readable text.

```
┌─────────────────────────────────────────┐
│   Document Title                        │
│   Last modified: Jan 8, 2026 at 11:30   │  ← 10pt bold
└─────────────────────────────────────────┘
```

Never go smaller than 10pt. Anything smaller fails accessibility.

---

## Weight Rules

情報デザイン never uses light font weights.

| Weight | Allowed? | Usage |
|--------|----------|-------|
| .ultraLight | ❌ No | Never |
| .thin | ❌ No | Never |
| .light | ❌ No | Never |
| .regular | ⚠️ Rarely | Only if medium unavailable |
| .medium | ✅ Yes | Default for body text |
| .semibold | ✅ Yes | Emphasis within body |
| .bold | ✅ Yes | Headlines, labels |
| .heavy | ✅ Yes | Hero displays |
| .black | ✅ Yes | Maximum impact |

Light weights reduce contrast and legibility. They whisper when 情報デザイン should speak clearly.

```swift
// ✅ CORRECT
.font(.system(size: 16, weight: .medium, design: .rounded))
.font(.system(size: 18, weight: .bold, design: .rounded))

// ❌ WRONG
.font(.system(size: 16, weight: .light, design: .rounded))
.font(.system(size: 16, weight: .thin, design: .rounded))
```

---

## Labels Are Uppercase

All labels, badges, and pills use uppercase text. This is non-negotiable.

```
✅ CORRECT:
┌────────┐  ┌────────┐  ┌────────┐
│ EVENT  │  │ TODAY  │  │ 2026   │
└────────┘  └────────┘  └────────┘

❌ WRONG:
┌────────┐  ┌────────┐  ┌────────┐
│ Event  │  │ Today  │  │ 2026   │
└────────┘  └────────┘  └────────┘
```

Why uppercase?

1. **Increased legibility at small sizes.** Uppercase letters have more consistent height, making them easier to read at 12pt and below.

2. **Visual distinction.** Uppercase labels stand apart from body text, reinforcing their categorical nature.

3. **Symmetry.** Uppercase letters align more predictably in fixed-width containers.

In code:

```swift
Text("EVENT")
    .font(.system(size: 12, weight: .bold, design: .rounded))
    .textCase(.uppercase)  // Or just write "EVENT" directly
```

---

## Numeric Typography

Numbers require special attention in 情報デザイン.

### Monospaced Digits

When displaying numbers in columns or sequences, use monospaced digits:

```swift
Text("42")
    .font(.system(size: 48, weight: .heavy, design: .rounded))
    .monospacedDigit()
```

Monospaced digits ensure alignment:

```
WITH MONOSPACED DIGITS:
  Week 1
  Week 2
  Week 10
  Week 42
  (Numbers align perfectly)

WITHOUT MONOSPACED DIGITS:
  Week 1
  Week 2
  Week 10
  Week 42
  (Numbers shift based on character width)
```

### Year Formatting

Never use string interpolation with years:

```swift
// ❌ WRONG - May add locale formatting
Text("\(year)")

// ✅ CORRECT - Guaranteed clean output
Text(String(year))
```

String interpolation can add commas (2,026) or other locale-specific formatting. `String(year)` outputs exactly what you expect: 2026.

### Price Formatting

Format prices consistently:

```swift
// Currency with proper formatting
Text(price, format: .currency(code: "USD"))
    .font(.system(size: 16, weight: .medium, design: .rounded))
    .monospacedDigit()
```

---

## Text Color

Text color follows simple rules:

| Context | Color |
|---------|-------|
| On white/light backgrounds | Black (#000000) |
| On dark backgrounds | White (#FFFFFF) |
| On semantic color backgrounds | Black (usually) |
| Secondary/muted text | Black at 60% opacity |

```swift
// Primary text
.foregroundStyle(JohoColors.black)

// Secondary text
.foregroundStyle(JohoColors.black.opacity(0.6))

// Text on dark background
.foregroundStyle(JohoColors.white)
```

Never use gray as a text color. Use black with reduced opacity instead. This maintains color consistency while reducing visual weight.

---

## Line Height and Spacing

Default system line height works well with SF Pro Rounded. Avoid custom line spacing unless absolutely necessary.

For multi-line body text:

```swift
Text(longString)
    .font(.system(size: 16, weight: .medium, design: .rounded))
    .lineSpacing(4)  // Slight increase for readability
```

For labels and short text, use default spacing.

---

## Implementing the Type Scale

Define your type scale as reusable styles:

```swift
extension Font {
    static let johoDisplayLarge = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let johoDisplayMedium = Font.system(size: 32, weight: .bold, design: .rounded)
    static let johoHeadline = Font.system(size: 18, weight: .bold, design: .rounded)
    static let johoBody = Font.system(size: 16, weight: .medium, design: .rounded)
    static let johoBodySmall = Font.system(size: 14, weight: .medium, design: .rounded)
    static let johoLabel = Font.system(size: 12, weight: .bold, design: .rounded)
    static let johoLabelSmall = Font.system(size: 10, weight: .bold, design: .rounded)
}

// Usage
Text("Week 42")
    .font(.johoDisplayLarge)
    .monospacedDigit()

Text("HOLIDAY")
    .font(.johoLabel)
    .textCase(.uppercase)
```

---

## Common Typography Mistakes

**Missing .design(.rounded):**
```swift
// ❌ WRONG
.font(.system(size: 16, weight: .medium))

// ✅ CORRECT
.font(.system(size: 16, weight: .medium, design: .rounded))
```

**Using light weights:**
```swift
// ❌ WRONG
.font(.system(size: 16, weight: .light, design: .rounded))

// ✅ CORRECT
.font(.system(size: 16, weight: .medium, design: .rounded))
```

**Lowercase labels:**
```swift
// ❌ WRONG
Text("event")
    .font(.johoLabel)

// ✅ CORRECT
Text("EVENT")
    .font(.johoLabel)
```

**Gray text instead of opacity:**
```swift
// ❌ WRONG
.foregroundStyle(Color.gray)

// ✅ CORRECT
.foregroundStyle(JohoColors.black.opacity(0.6))
```

**Non-monospaced numbers in columns:**
```swift
// ❌ WRONG - Numbers misalign
Text("\(number)")

// ✅ CORRECT - Numbers align
Text(String(number))
    .monospacedDigit()
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           情報デザイン TYPOGRAPHY REFERENCE               │
│                                                         │
│   displayLarge   48pt  heavy   Hero numbers            │
│   displayMedium  32pt  bold    Section titles          │
│   headline       18pt  bold    Card titles             │
│   body           16pt  medium  Content                 │
│   bodySmall      14pt  medium  Secondary               │
│   label          12pt  bold    PILLS (UPPERCASE)       │
│   labelSmall     10pt  bold    Timestamps              │
│                                                         │
│   RULES:                                               │
│   • Always use .design(.rounded)                       │
│   • Never use weights below .medium                    │
│   • Labels are always UPPERCASE                        │
│   • Use .monospacedDigit() for numbers                 │
│   • Use String(year) not "\(year)"                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 7 — Spacing & Layout*


---


# Chapter 7: Spacing & Layout

> "Every gap has a purpose. No pixel is accidental."

---

Spacing in 情報デザイン follows a strict system. Every measurement derives from a 4pt base unit. Every gap communicates something about the relationship between elements.

---

## The 4pt Grid

All spacing in 情報デザイン is divisible by 4:

```
4pt   = xs (extra small)
8pt   = sm (small)
12pt  = md (medium)
16pt  = lg (large)
20pt  = xl (extra large)
24pt  = 2xl
32pt  = 3xl
```

Why 4pt? Because it scales cleanly across device resolutions and creates consistent rhythm. A 4pt base means your spacing is always 4, 8, 12, 16, 20, 24, 32... never 5, 7, 13, 19.

```swift
struct JohoSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}
```

---

## Spacing Tokens

情報デザイン uses four primary spacing tokens:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Cell gaps, tight grouping |
| sm | 8pt | Row gaps, element spacing |
| md | 12pt | Container padding, section gaps |
| lg | 16pt | Screen margins, major divisions |

### xs (4pt) — Tight Grouping

Use xs for elements that belong together as a single unit:

```
┌─────────────────────────────────────────┐
│   ●←4pt→Label                           │
│   ↑                                     │
│   Icon and label: 4pt gap               │
└─────────────────────────────────────────┘
```

```swift
HStack(spacing: JohoSpacing.xs) {
    Circle().frame(width: 8, height: 8)
    Text("Label")
}
```

### sm (8pt) — Element Spacing

Use sm for spacing between related elements:

```
┌─────────────────────────────────────────┐
│   Item 1                                │
│   ←──────── 8pt ────────→               │
│   Item 2                                │
│   ←──────── 8pt ────────→               │
│   Item 3                                │
└─────────────────────────────────────────┘
```

```swift
VStack(spacing: JohoSpacing.sm) {
    ItemRow()
    ItemRow()
    ItemRow()
}
```

### md (12pt) — Container Padding

Use md for internal padding of containers:

```
┌─────────────────────────────────────────┐
│ ↑                                       │
│ 12pt                                    │
│ ←12pt  Content goes here          12pt→ │
│                                         │
│ 12pt                                    │
│ ↓                                       │
└─────────────────────────────────────────┘
```

```swift
VStack {
    // content
}
.padding(JohoSpacing.md)
```

### lg (16pt) — Screen Margins

Use lg for screen-level margins:

```
┌─ Screen Edge ─────────────────────────────────────┐
│                                                   │
│  ←16pt→ ┌─────────────────────────────┐ ←16pt→   │
│         │                             │           │
│         │     Content Container       │           │
│         │                             │           │
│         └─────────────────────────────┘           │
│                                                   │
└───────────────────────────────────────────────────┘
```

```swift
ScrollView {
    VStack {
        // content
    }
    .padding(.horizontal, JohoSpacing.lg)
}
```

---

## The 8pt Maximum Top Padding Rule

This rule is critical and frequently violated: **No more than 8pt of padding at the top of a content area.**

```
❌ WRONG - 40pt top padding:
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                                         │
│   Content finally starts here           │
│                                         │
└─────────────────────────────────────────┘
Wasted space. User must scroll past nothing.

✅ CORRECT - 8pt top padding:
┌─────────────────────────────────────────┐
│   Content starts immediately            │
│                                         │
│   More content here                     │
│                                         │
└─────────────────────────────────────────┘
Efficient. User sees content immediately.
```

Top padding is the most expensive real estate in your interface. Users' eyes start at the top. Every pixel of empty space delays content.

```swift
// ❌ WRONG
.padding(.top, 40)
.padding(.top, 32)
.padding(.top, 20)

// ✅ CORRECT
.padding(.top, JohoSpacing.sm)  // 8pt
.padding(.top, 4)
.padding(.top, 0)
```

---

## Touch Target Minimums

Every interactive element must have a minimum touch target of 44×44pt.

```
┌─────────────────────────────────────────┐
│                                         │
│      ┌─────────────────┐                │
│      │                 │                │
│      │   Small Icon    │ ← Visual: 20pt │
│      │                 │                │
│      └─────────────────┘                │
│   ┌─────────────────────────┐           │
│   │                         │           │
│   │    Touch Target         │ ← Hit: 44pt│
│   │                         │           │
│   └─────────────────────────┘           │
│                                         │
└─────────────────────────────────────────┘
```

A small icon can be 20pt visually, but its tappable area must extend to at least 44pt:

```swift
Button(action: { }) {
    Image(systemName: "plus")
        .font(.system(size: 16))
}
.frame(minWidth: 44, minHeight: 44)  // Touch target
```

### Spacing Between Touch Targets

Maintain at least 12pt between adjacent touch targets to prevent accidental taps:

```
┌─────────────────────────────────────────┐
│                                         │
│   [Button A]  ←12pt→  [Button B]        │
│                                         │
└─────────────────────────────────────────┘
```

```swift
HStack(spacing: JohoSpacing.md) {  // 12pt
    Button("Cancel") { }
    Button("Save") { }
}
```

---

## Layout Patterns

### Full-Width Container

Content that spans the full width with standard margins:

```
┌─ Screen ─────────────────────────────────┐
│ ←16pt→ ┌────────────────────────┐ ←16pt→ │
│        │                        │        │
│        │   Full-width content   │        │
│        │                        │        │
│        └────────────────────────┘        │
└──────────────────────────────────────────┘
```

```swift
VStack {
    ContentContainer()
}
.padding(.horizontal, JohoSpacing.lg)
```

### Card Stack

Cards stacked vertically with consistent spacing:

```
┌─────────────────────────────────────────┐
│  ┌───────────────────────────────────┐  │
│  │  Card 1                           │  │
│  └───────────────────────────────────┘  │
│  ←────────────── 8pt ──────────────→    │
│  ┌───────────────────────────────────┐  │
│  │  Card 2                           │  │
│  └───────────────────────────────────┘  │
│  ←────────────── 8pt ──────────────→    │
│  ┌───────────────────────────────────┐  │
│  │  Card 3                           │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

```swift
VStack(spacing: JohoSpacing.sm) {
    Card1()
    Card2()
    Card3()
}
.padding(JohoSpacing.lg)
```

### Bento Layout

The signature 情報デザイン layout—compartmentalized content:

```
┌─────────────────────────────────────────────────────────┐
│ ┌─────────┬──────────────────────────┬────────────────┐ │
│ │         │                          │                │ │
│ │  Zone A │        Zone B            │    Zone C      │ │
│ │  (fixed)│       (flexible)         │    (fixed)     │ │
│ │         │                          │                │ │
│ └─────────┴──────────────────────────┴────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

```swift
HStack(spacing: 0) {
    // Zone A - Fixed width
    VStack { }
        .frame(width: 44)
        .border(JohoColors.black, width: 1.5)

    // Zone B - Flexible
    VStack { }
        .frame(maxWidth: .infinity)
        .border(JohoColors.black, width: 1.5)

    // Zone C - Fixed width
    VStack { }
        .frame(width: 80)
        .border(JohoColors.black, width: 1.5)
}
```

### Grid Layout

For calendar-style grids:

```
┌───┬───┬───┬───┬───┬───┬───┐
│ M │ T │ W │ T │ F │ S │ S │
├───┼───┼───┼───┼───┼───┼───┤
│ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │
├───┼───┼───┼───┼───┼───┼───┤
│ 8 │ 9 │10 │11 │12 │13 │14 │
└───┴───┴───┴───┴───┴───┴───┘
Cell gaps: 4pt (xs)
```

```swift
LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: JohoSpacing.xs), count: 7), spacing: JohoSpacing.xs) {
    ForEach(days) { day in
        DayCell(day: day)
    }
}
```

---

## Safe Area Handling

Respect safe areas but don't add excessive padding:

```swift
// ✅ CORRECT - Content respects safe area naturally
ScrollView {
    VStack {
        // content
    }
    .padding(.horizontal, JohoSpacing.lg)
}

// ❌ WRONG - Double safe area padding
ScrollView {
    VStack {
        // content
    }
    .padding()
    .padding(.top, 44)  // Redundant with safe area
}
```

For elements that should extend to edges (like a header background), ignore safe area selectively:

```swift
VStack {
    HeaderBackground()
        .ignoresSafeArea(edges: .top)

    Content()
}
```

---

## Responsive Spacing

On larger screens (iPad), spacing can increase proportionally:

```swift
struct AdaptiveSpacing {
    @Environment(\.horizontalSizeClass) var sizeClass

    var containerPadding: CGFloat {
        sizeClass == .regular ? JohoSpacing.xl : JohoSpacing.lg
    }

    var itemSpacing: CGFloat {
        sizeClass == .regular ? JohoSpacing.md : JohoSpacing.sm
    }
}
```

However, don't over-complicate. The base spacing tokens work well across most contexts.

---

## Common Spacing Mistakes

**Inconsistent gaps:**
```swift
// ❌ WRONG - Mixed arbitrary values
VStack(spacing: 10) { }
VStack(spacing: 15) { }
VStack(spacing: 7) { }

// ✅ CORRECT - Consistent token values
VStack(spacing: JohoSpacing.sm) { }  // 8pt
VStack(spacing: JohoSpacing.md) { }  // 12pt
```

**Excessive top padding:**
```swift
// ❌ WRONG
.padding(.top, 32)

// ✅ CORRECT
.padding(.top, JohoSpacing.sm)  // 8pt max
```

**Tiny touch targets:**
```swift
// ❌ WRONG - Too small to tap
Button { } label: {
    Image(systemName: "plus")
}
.frame(width: 24, height: 24)

// ✅ CORRECT - Proper touch target
Button { } label: {
    Image(systemName: "plus")
}
.frame(minWidth: 44, minHeight: 44)
```

**Buttons too close:**
```swift
// ❌ WRONG - Buttons touching
HStack(spacing: 4) {
    Button("A") { }
    Button("B") { }
}

// ✅ CORRECT - Adequate separation
HStack(spacing: JohoSpacing.md) {  // 12pt
    Button("A") { }
    Button("B") { }
}
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           情報デザイン SPACING REFERENCE                  │
│                                                         │
│   xs   4pt   Cell gaps, tight grouping                 │
│   sm   8pt   Row gaps, element spacing                 │
│   md  12pt   Container padding, sections               │
│   lg  16pt   Screen margins                            │
│                                                         │
│   RULES:                                               │
│   • All spacing divisible by 4                         │
│   • Maximum 8pt top padding                            │
│   • Minimum 44×44pt touch targets                      │
│   • Minimum 12pt between buttons                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 8 — Japanese Symbol Language*


---


# Chapter 8: Japanese Symbol Language

> "The shapes ARE the language."

---

Japan has developed the world's most sophisticated system of visual communication symbols. In 情報デザイン, we inherit this tradition—using shapes and symbols that communicate meaning independent of language.

---

## The Maru-Batsu System

At the foundation of Japanese visual language is Maru-Batsu (○×)—a system of shapes with universal meanings.

| Symbol | Name | Meaning |
|--------|------|---------|
| ◎ | Nijū-maru (double circle) | Excellent, best, highly recommended |
| ○ | Maru (circle) | Good, yes, correct, positive |
| △ | Sankaku (triangle) | Caution, partial, maybe |
| □ | Shikaku (square) | Note, reference, neutral information |
| × | Batsu (cross) | No, wrong, failed, negative |
| ー | Bō (bar) | Not applicable, none |

This system predates PlayStation—but PlayStation's controller buttons (○×△□) are directly derived from it. In Japan, ○ confirms and × cancels. (Western games inverted this, causing decades of confusion.)

### Why Maru-Batsu Works

On Japanese tests, correct answers are marked ○. Wrong answers are marked ×. Every Japanese person learns this in elementary school.

This creates a population-wide visual vocabulary. No explanation needed. ○ means yes. × means no. The shapes communicate across languages, ages, and contexts.

情報デザイン leverages this literacy. When you use ○ for positive states and × for negative states, you're speaking a language your users already know.

---

## Filled vs. Outlined Symbols

Filled and outlined versions communicate intensity:

| Filled | Outlined | Meaning Difference |
|--------|----------|-------------------|
| ● Kuro-maru | ○ Shiro-maru | Strong yes vs. Standard yes |
| ▲ Kuro-sankaku | △ Shiro-sankaku | Strong warning vs. Mild caution |
| ■ Kuro-shikaku | □ Shiro-shikaku | Active/Selected vs. Inactive |
| ◆ Kuro-hishi | ◇ Shiro-hishi | Important vs. Notable |

Use filled symbols for emphasis, outlined for standard states:

```
Content present:  ●  (filled = has content)
Content optional: ○  (outlined = available)
Selected item:    ■  (filled = active)
Available item:   □  (outlined = inactive)
```

---

## Reference Marks

Japanese documents use specific marks for notes and references:

| Symbol | Name | Usage |
|--------|------|-------|
| ※ | Kome-jirushi | Important note (THE most common reference mark) |
| ★ | Kuro-boshi | Important highlight |
| ☆ | Shiro-boshi | Standard highlight |
| † | Dagger | Footnote |
| ‡ | Double dagger | Secondary footnote |
| § | Section | Section reference |

The ※ symbol (kome-jirushi, "rice mark") is ubiquitous in Japanese text. It signals "pay attention to this note." If you see only one Japanese reference mark in your life, it will be ※.

---

## Calendar Symbols

Japanese calendars use specific markers for special days:

| Symbol | Meaning | Japanese |
|--------|---------|----------|
| 祝 | National holiday | Shukujitsu |
| 休 | Rest day, closed | Yasumi |
| 振 | Substitute holiday | Furikae kyūjitsu |
| ● | Day has content | - |
| ◎ | Important date | - |

### Day Color Conventions

In Japanese calendars, Sundays are red. This convention comes from the traditional association of Sunday (日曜日, nichiyōbi) with the sun, which is red in Japanese iconography.

| Day | Traditional Color |
|-----|------------------|
| Sunday (日) | Red |
| Saturday (土) | Blue (often) |
| Weekdays | Black |

情報デザイン follows this: Sundays use red text or red indicators.

---

## Why No Emoji

Emoji are forbidden in 情報デザイン. This seems restrictive—emoji are expressive and universal. But they violate core principles:

**1. Emoji are colorful.**
Emoji have fixed colors that can't be controlled. They break the semantic color system.

**2. Emoji render differently across platforms.**
The same emoji looks different on iOS, Android, Windows, and web. Inconsistent rendering breaks visual harmony.

**3. Emoji are decorative.**
Emoji express emotion. 情報デザイン communicates information. These are different goals.

**4. Emoji have variable sizing.**
Emoji don't align consistently with text. They create visual noise.

Instead of emoji, use SF Symbols (on Apple platforms) or equivalent monochrome icon systems:

| Concept | ❌ Emoji | ✅ SF Symbol |
|---------|----------|-------------|
| Warning | ⚠️ | `exclamationmark.triangle` |
| Star | ⭐ | `star.fill` |
| Heart | ❤️ | `heart.fill` |
| Location | 📍 | `mappin` |
| Fire | 🔥 | `flame` |
| Check | ✅ | `checkmark` |

SF Symbols are monochrome, scalable, and visually consistent. They communicate without decoration.

---

## SF Symbol Mapping

Here's how to map common concepts to SF Symbols:

### Maru-Batsu Equivalents

| Concept | SF Symbol | Unicode |
|---------|-----------|---------|
| Yes/Positive | `circle` / `circle.fill` | ○ ● |
| Excellent | `circle.circle` | ◎ |
| No/Cancel | `xmark` | × |
| Caution | `triangle` / `triangle.fill` | △ ▲ |
| Info/Neutral | `square` / `square.fill` | □ ■ |
| Special | `diamond` / `diamond.fill` | ◇ ◆ |

### Status Symbols

| Concept | SF Symbol |
|---------|-----------|
| Check/Complete | `checkmark` |
| Warning | `exclamationmark.triangle` |
| Error | `xmark.circle` |
| Info | `info.circle` |
| Prohibited | `nosign` |
| Important | `star.fill` |

### Navigation Symbols

| Concept | SF Symbol |
|---------|-----------|
| Forward | `chevron.right` |
| Back | `chevron.left` |
| Expand | `chevron.down` |
| Collapse | `chevron.up` |
| More | `ellipsis` |

### Content Type Symbols

| Type | SF Symbol |
|------|-----------|
| Calendar | `calendar` |
| Event | `clock` |
| Note | `doc.text` |
| Contact | `person` |
| Location | `mappin` |
| Money | `dollarsign.circle` |

---

## Icon Specifications

Icons in 情報デザイン follow specific size and weight rules:

| Context | Weight | Size |
|---------|--------|------|
| Navigation | .medium | 20pt |
| List icons | .medium | 16pt |
| Buttons | .semibold | 18pt |
| Badges | .bold | 12pt |
| Hero display | .bold | 32pt |

Never use thin or ultralight icon weights. Icons should be clearly visible and match the bold aesthetic of 情報デザイン.

```swift
// Navigation icon
Image(systemName: "chevron.right")
    .font(.system(size: 20, weight: .medium))

// List icon
Image(systemName: "calendar")
    .font(.system(size: 16, weight: .medium))

// Button icon
Image(systemName: "plus")
    .font(.system(size: 18, weight: .semibold))
```

---

## Type Indicator Circles

In 情報デザイン, small colored circles indicate content type. These are used in calendars and lists to show what kind of items exist:

| Type | Color | Code |
|------|-------|------|
| Holiday | Red #E53E3E | HOL |
| Observance | Orange #ED8936 | OBS |
| Event | Purple #805AD5 | EVT |
| Birthday | Pink #D53F8C | BDY |
| Note | Yellow #ECC94B | NTE |
| Trip | Blue #3182CE | TRP |
| Expense | Green #38A169 | EXP |

**Critical:** Indicator circles always have black borders.

```swift
Circle()
    .fill(typeColor)
    .frame(width: 10, height: 10)
    .overlay(
        Circle()
            .stroke(JohoColors.black, lineWidth: 1.5)
    )
```

Circle sizes vary by context:

| Context | Size | Border |
|---------|------|--------|
| Calendar grid | 7pt | 1pt |
| Collapsed row | 8pt | 1pt |
| Expanded items | 10pt | 1.5pt |
| Legend | 12pt | 1.5pt |

---

## Implementing Symbols

### Basic Symbol View

```swift
struct JohoSymbol: View {
    let symbol: String
    var size: CGFloat = 16
    var weight: Font.Weight = .medium

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(JohoColors.black)
    }
}

// Usage
JohoSymbol(symbol: "checkmark", size: 18, weight: .bold)
```

### Indicator Circle View

```swift
struct JohoIndicator: View {
    let color: Color
    var size: CGFloat = 10
    var borderWidth: CGFloat = 1.5

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(JohoColors.black, lineWidth: borderWidth)
            )
    }
}

// Usage
JohoIndicator(color: JohoColors.cyan, size: 10)  // Event indicator
JohoIndicator(color: JohoColors.pink, size: 10)  // Holiday indicator
```

---

## Symbol Combinations

Symbols can combine to create compound meanings:

```
Status + Type:
●✓  = Completed event (filled circle + check)
○⚠  = Available with warning
■★  = Selected and important

Hierarchy:
◎ → ○ → △ → ×
Best → Good → Caution → Bad
```

In implementation:

```swift
HStack(spacing: JohoSpacing.xs) {
    JohoIndicator(color: JohoColors.cyan)
    JohoSymbol(symbol: "checkmark", size: 12, weight: .bold)
}
// Shows: completed event
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           情報デザイン SYMBOL REFERENCE                   │
│                                                         │
│   MARU-BATSU:                                          │
│   ◎ Excellent  ○ Good  △ Caution  □ Info  × No        │
│                                                         │
│   FILLED VS OUTLINED:                                  │
│   ● Strong yes    ○ Standard yes                       │
│   ▲ Strong warn   △ Mild caution                       │
│   ■ Active        □ Inactive                           │
│                                                         │
│   REFERENCE:                                           │
│   ※ Note  ★ Important  ☆ Highlight                    │
│                                                         │
│   CALENDAR:                                            │
│   祝 Holiday  休 Rest  振 Substitute                   │
│   Sundays = Red text                                   │
│                                                         │
│   FORBIDDEN: All emoji                                 │
│   USE INSTEAD: SF Symbols (monochrome)                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 9 — Containers & Cards*


---


# Chapter 9: Containers & Cards

> "A container is not a box. A container is a statement: this content belongs together."

---

Part 3 introduces the component library—production-ready patterns you can implement immediately. We begin with containers, the fundamental building blocks of any 情報デザイン interface.

---

## The Base Container

Every 情報デザイン interface is built from containers. A container is a bordered rectangle with white background that holds content.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                                                         │
│           Content goes here                             │
│                                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

Properties of a container:
- White background (#FFFFFF)
- Black border (weight varies by hierarchy)
- Continuous corner radius (squircle)
- Internal padding (typically 12pt)

```swift
struct JohoContainer<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    var borderWidth: CGFloat = 3
    var padding: CGFloat = 12

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: borderWidth)
            )
    }
}
```

Usage:

```swift
JohoContainer {
    VStack(alignment: .leading, spacing: 8) {
        Text("Container Title")
            .font(.johoHeadline)
        Text("This is content inside a container.")
            .font(.johoBody)
    }
}
```

---

## Container Hierarchy

Containers nest inside each other. The border hierarchy communicates structure:

```
Outer container (3pt border)
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   Section (1.5pt border)                               │
│   ┌───────────────────────────────────────────────┐    │
│   │                                               │    │
│   │   Item (1pt border)                           │    │
│   │   ┌───────────────────────────────────────┐   │    │
│   │   │  Content                              │   │    │
│   │   └───────────────────────────────────────┘   │    │
│   │                                               │    │
│   │   Item (1pt border)                           │    │
│   │   ┌───────────────────────────────────────┐   │    │
│   │   │  Content                              │   │    │
│   │   └───────────────────────────────────────┘   │    │
│   │                                               │    │
│   └───────────────────────────────────────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## JohoCard

A card is a container for discrete content items—events, contacts, notes, etc.

```swift
struct JohoCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: 1.5)
            )
    }
}
```

Usage:

```swift
JohoCard {
    HStack {
        Circle()
            .fill(JohoColors.cyan)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))

        VStack(alignment: .leading) {
            Text("Team Meeting")
                .font(.johoHeadline)
            Text("9:00 AM - 10:00 AM")
                .font(.johoBodySmall)
        }

        Spacer()

        Image(systemName: "chevron.right")
            .foregroundStyle(JohoColors.black)
    }
}
```

---

## JohoSectionBox

A section box groups related items under a labeled header. The header uses a colored pill.

```
┌─────────────────────────────────────────────────────────┐
│  ┌──────────┐                                          │
│  │ SECTION  │                                          │
│  └──────────┘                                          │
│                                                         │
│   Item 1                                               │
│   Item 2                                               │
│   Item 3                                               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

```swift
struct JohoSectionBox<Content: View>: View {
    let title: String
    let accentColor: Color
    let content: Content

    init(title: String, accentColor: Color = JohoColors.black, @ViewBuilder content: () -> Content) {
        self.title = title
        self.accentColor = accentColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header pill
            Text(title.uppercased())
                .font(.johoLabel)
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            // Content
            content
        }
        .padding(12)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
        )
    }
}
```

Usage:

```swift
JohoSectionBox(title: "Upcoming Events", accentColor: JohoColors.cyan) {
    VStack(spacing: 8) {
        EventRow(event: event1)
        EventRow(event: event2)
        EventRow(event: event3)
    }
}
```

---

## JohoFormSection

Form sections have a black header bar with white text, followed by form content.

```
┌─────────────────────────────────────────────────────────┐
│ ██████████████████████████████████████████████████████ │
│ █                  FORM SECTION                      █ │
│ ██████████████████████████████████████████████████████ │
│                                                         │
│   Field 1: ___________________________                 │
│                                                         │
│   Field 2: ___________________________                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

```swift
struct JohoFormSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            Text(title.uppercased())
                .font(.johoLabel)
                .foregroundStyle(JohoColors.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(JohoColors.black)

            // Form content
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(16)
            .background(JohoColors.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 2)
        )
    }
}
```

---

## Semantic Containers

Containers can have semantic color backgrounds to indicate content type:

```swift
struct JohoSemanticContainer<Content: View>: View {
    let semanticColor: Color
    let content: Content

    init(semanticColor: Color, @ViewBuilder content: () -> Content) {
        self.semanticColor = semanticColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(semanticColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: 1.5)
            )
    }
}

// Usage - Event container (cyan)
JohoSemanticContainer(semanticColor: JohoColors.cyan) {
    Text("Team Meeting at 9:00 AM")
        .font(.johoBody)
        .foregroundStyle(JohoColors.black)
}

// Usage - Holiday container (pink)
JohoSemanticContainer(semanticColor: JohoColors.pink) {
    Text("Christmas Day")
        .font(.johoBody)
        .foregroundStyle(JohoColors.black)
}
```

---

## Empty State Container

When a container has no content, show a meaningful empty state:

```swift
struct JohoEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(JohoColors.black.opacity(0.3))

            VStack(spacing: 4) {
                Text(title)
                    .font(.johoHeadline)
                    .foregroundStyle(JohoColors.black)

                Text(message)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
        )
    }
}

// Usage
JohoEmptyState(
    icon: "calendar",
    title: "No Events",
    message: "Events you create will appear here"
)
```

---

## Container Best Practices

### Do:
- Always include borders
- Use consistent corner radii within hierarchy
- Maintain padding consistency
- Use semantic colors on backgrounds, not borders

### Don't:
- Nest more than 3 levels deep
- Use colored borders (except for state indication)
- Mix corner radius values at the same hierarchy level
- Skip borders on "clean" designs

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           情報デザイン CONTAINER REFERENCE                │
│                                                         │
│   JohoContainer     3pt border, 16pt radius            │
│                     Main content wrapper                │
│                                                         │
│   JohoCard          1.5pt border, 12pt radius          │
│                     Individual content items            │
│                                                         │
│   JohoSectionBox    3pt border, colored header pill    │
│                     Grouped related items               │
│                                                         │
│   JohoFormSection   2pt border, black header bar       │
│                     Form inputs                         │
│                                                         │
│   JohoEmptyState    For empty containers               │
│                                                         │
│   RULE: Every container has a border. No exceptions.   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 10 — Interactive Elements*


---


# Chapter 10: Interactive Elements

> "A 2pt border says: touch me."

---

Interactive elements—buttons, toggles, inputs—follow specific patterns in 情報デザイン. They're distinguished by 2pt borders and clear affordances.

---

## JohoButton

The standard button has a white background, black text, and 2pt border:

```
┌─────────────────────┐
│       Action        │
└─────────────────────┘
```

```swift
struct JohoButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .secondary

    enum ButtonStyle {
        case primary    // Black background, white text
        case secondary  // White background, black text
        case destructive // Red background, white text
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.johoBody)
                .fontWeight(.medium)
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(minWidth: 44, minHeight: 44)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(JohoColors.black, lineWidth: 2)
                )
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return JohoColors.black
        case .secondary: return JohoColors.white
        case .destructive: return JohoColors.red
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return JohoColors.white
        case .secondary: return JohoColors.black
        case .destructive: return JohoColors.white
        }
    }
}
```

Usage:

```swift
HStack(spacing: 12) {
    JohoButton(title: "Cancel", action: { dismiss() }, style: .secondary)
    JohoButton(title: "Save", action: { save() }, style: .primary)
}
```

---

## Button States

Buttons communicate state through visual changes:

### Normal State
```
┌─────────────────────┐
│       Action        │  White background, 2pt border
└─────────────────────┘
```

### Pressed State
```
┌─────────────────────┐
│       Action        │  Light gray background
└─────────────────────┘
```

### Disabled State
```
┌─────────────────────┐
│       Action        │  Gray text, reduced opacity
└─────────────────────┘
```

```swift
struct JohoButton: View {
    // ... previous code ...
    var isEnabled: Bool = true

    var body: some View {
        Button(action: action) {
            // ... content ...
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}
```

---

## Icon Buttons

Buttons with icons follow the same pattern:

```swift
struct JohoIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(JohoColors.black)
                .frame(width: size, height: size)
                .background(JohoColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(JohoColors.black, lineWidth: 2)
                )
        }
    }
}

// Usage
HStack(spacing: 12) {
    JohoIconButton(icon: "chevron.left", action: { goBack() })
    Spacer()
    JohoIconButton(icon: "plus", action: { addItem() })
}
```

---

## JohoToggle

The 情報デザイン toggle has a clear on/off visual state:

```
OFF: ┌────────────────────────┐
     │  ○                     │
     └────────────────────────┘

ON:  ┌────────────────────────┐
     │                    ●   │  (with semantic color fill)
     └────────────────────────┘
```

```swift
struct JohoToggle: View {
    @Binding var isOn: Bool
    var accentColor: Color = JohoColors.cyan

    var body: some View {
        Button(action: { isOn.toggle() }) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isOn ? accentColor : JohoColors.white)
                .frame(width: 52, height: 32)
                .overlay(
                    Circle()
                        .fill(JohoColors.white)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
                        .offset(x: isOn ? 10 : -10)
                    , alignment: isOn ? .trailing : .leading
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(JohoColors.black, lineWidth: 2)
                )
                .animation(.easeInOut(duration: 0.15), value: isOn)
        }
        .buttonStyle(.plain)
    }
}
```

---

## JohoToggleRow

A toggle with a label, commonly used in settings:

```
┌─────────────────────────────────────────────────────────┐
│   Enable notifications              ┌────────────────┐  │
│                                     │            ●   │  │
│                                     └────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

```swift
struct JohoToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var subtitle: String? = nil

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.johoBody)
                    .foregroundStyle(JohoColors.black)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.johoBodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }

            Spacer()

            JohoToggle(isOn: $isOn)
        }
        .padding(12)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }
}
```

---

## Text Input

Text inputs have 2pt borders and clear focus states:

```
Normal:
┌─────────────────────────────────────────┐
│  Placeholder text...                    │  2pt border
└─────────────────────────────────────────┘

Focused:
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
│  User input here                        │  2.5pt border
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

```swift
struct JohoTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.johoBody)
            .foregroundStyle(JohoColors.black)
            .padding(12)
            .background(JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: isFocused ? 2.5 : 2)
            )
            .focused($isFocused)
    }
}
```

---

## Swipe Actions

Swipe actions reveal edit and delete options:

```
Swipe right → Edit (Cyan)
┌─────────────────────────────────────────────────────────┐
│ ████████│                                               │
│ █ Edit █│  Item content                                 │
│ ████████│                                               │
└─────────────────────────────────────────────────────────┘

Swipe left → Delete (Red)
┌─────────────────────────────────────────────────────────┐
│                                               │████████│
│                              Item content     │█Delete█│
│                                               │████████│
└─────────────────────────────────────────────────────────┘
```

```swift
struct JohoSwipeRow<Content: View>: View {
    let content: Content
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    init(@ViewBuilder content: () -> Content, onEdit: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.content = content()
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                if let onEdit = onEdit {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(JohoColors.cyan)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if let onDelete = onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(JohoColors.red)
                }
            }
    }
}
```

**Important:** System items (indicated with a lock icon) have no swipe actions.

---

## Selection States

Selected items have 2.5pt borders and optional semantic color:

```swift
struct JohoSelectableRow<Content: View>: View {
    let isSelected: Bool
    let content: Content

    init(isSelected: Bool, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(isSelected ? JohoColors.yellow.opacity(0.3) : JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: isSelected ? 2.5 : 1.5)
            )
    }
}
```

---

## Stepper Controls

For numeric input:

```
┌─────┬───────────────┬─────┐
│  -  │      42       │  +  │
└─────┴───────────────┴─────┘
```

```swift
struct JohoStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...100

    var body: some View {
        HStack(spacing: 0) {
            // Minus button
            Button(action: { if value > range.lowerBound { value -= 1 } }) {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 44, height: 44)
            }
            .disabled(value <= range.lowerBound)

            // Value display
            Text(String(value))
                .font(.johoHeadline)
                .monospacedDigit()
                .frame(minWidth: 60)

            // Plus button
            Button(action: { if value < range.upperBound { value += 1 } }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .frame(width: 44, height: 44)
            }
            .disabled(value >= range.upperBound)
        }
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 2)
        )
    }
}
```

---

## Animation Guidelines

Interactive elements use quick, subtle animations:

| Animation | Duration | Curve |
|-----------|----------|-------|
| Button press | 0.1s | easeOut |
| Toggle switch | 0.15s | easeInOut |
| Selection change | 0.1s | easeOut |
| Swipe action | 0.2s | spring (light) |

```swift
// Quick and functional
.animation(.easeOut(duration: 0.1), value: isPressed)

// Toggle animation
.animation(.easeInOut(duration: 0.15), value: isOn)

// ❌ FORBIDDEN - Bouncy animations
.animation(.spring(response: 0.5, dampingFraction: 0.5), value: something)
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│           情報デザイン INTERACTIVE REFERENCE              │
│                                                         │
│   BUTTONS:                                             │
│   • 2pt border (all interactive elements)              │
│   • 44×44pt minimum touch target                       │
│   • 12pt minimum spacing between buttons               │
│                                                         │
│   STYLES:                                              │
│   • Primary: Black bg, white text                      │
│   • Secondary: White bg, black text                    │
│   • Destructive: Red bg, white text                    │
│                                                         │
│   STATES:                                              │
│   • Normal: 2pt border                                 │
│   • Focused/Selected: 2.5pt border                     │
│   • Disabled: 50% opacity                              │
│                                                         │
│   SWIPE:                                               │
│   • Right → Edit (Cyan)                                │
│   • Left → Delete (Red)                                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 11 — Navigation Patterns*


---


# Chapter 11: Navigation Patterns

> "Navigation is orientation. Users should always know where they are."

---

Every screen in a 情報デザイン interface needs clear navigation. Users must know where they are, where they can go, and how to get back. Navigation components follow the same visual language as content—bordered, high-contrast, functional.

---

## Page Headers

The page header establishes screen identity. It contains a title and optional controls.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ┌─────┐                                      ┌─────┐     │
│   │  ←  │    SCREEN TITLE              TODAY   │  +  │     │
│   └─────┘                                      └─────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Basic Header

```swift
struct JohoPageHeader: View {
    let title: String
    var showBackButton: Bool = false
    var onBack: (() -> Void)? = nil
    var trailingContent: AnyView? = nil

    var body: some View {
        HStack(spacing: JohoSpacing.md) {
            // Back button (optional)
            if showBackButton, let onBack = onBack {
                JohoIconButton(icon: "chevron.left", action: onBack)
            }

            // Title
            Text(title.uppercased())
                .font(.johoDisplayMedium)
                .foregroundStyle(JohoColors.black)

            Spacer()

            // Trailing content (optional)
            if let trailing = trailingContent {
                trailing
            }
        }
        .padding(.horizontal, JohoSpacing.lg)
        .padding(.vertical, JohoSpacing.sm)
    }
}
```

**Rules:**
- Title is uppercase
- Maximum 8pt top padding
- Back button only when there's somewhere to go back to
- Trailing controls are icon buttons with 2pt borders

---

## Bento Header

The signature 情報デザイン header—a compartmentalized control panel at the top of the screen.

```
┌─────────────────────────────────────────────────────────────┐
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ┌───────────┬───────────────────────────┬─────────────┐ │ │
│ │ │           │                           │             │ │ │
│ │ │  WEEK 42  │     October 2026          │  ┌───┬───┐  │ │ │
│ │ │           │                           │  │ < │ > │  │ │ │
│ │ │  (hero)   │     (context)             │  └───┴───┘  │ │ │
│ │ │           │                           │  (arrows)   │ │ │
│ │ └───────────┴───────────────────────────┴─────────────┘ │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct JohoBentoHeader: View {
    let weekNumber: Int
    let monthYear: String
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onToday: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Zone A: Hero number
            VStack {
                Text(String(weekNumber))
                    .font(.johoDisplayLarge)
                    .monospacedDigit()
                    .foregroundStyle(JohoColors.black)

                Text("WEEK")
                    .font(.johoLabel)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
            .frame(width: 100)
            .padding(.vertical, JohoSpacing.md)
            .background(JohoColors.white)
            .overlay(
                Rectangle()
                    .stroke(JohoColors.black, lineWidth: 1.5)
            )

            // Zone B: Context
            VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                Text(monthYear)
                    .font(.johoHeadline)
                    .foregroundStyle(JohoColors.black)

                Button(action: onToday) {
                    Text("TODAY")
                        .font(.johoLabel)
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(JohoColors.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(JohoColors.black, lineWidth: 1.5)
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(JohoSpacing.md)
            .background(JohoColors.white)
            .overlay(
                Rectangle()
                    .stroke(JohoColors.black, lineWidth: 1.5)
            )

            // Zone C: Navigation arrows
            VStack(spacing: 0) {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(JohoColors.black)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                }

                Divider()
                    .background(JohoColors.black)

                Button(action: onNext) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(JohoColors.black)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: 60)
            .background(JohoColors.white)
            .overlay(
                Rectangle()
                    .stroke(JohoColors.black, lineWidth: 1.5)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
        )
    }
}
```

**Bento Header Zones:**
- Zone A (fixed width): Hero display—the primary number or value
- Zone B (flexible): Context information and quick actions
- Zone C (fixed width): Navigation controls

---

## iPad Sidebar Navigation

On iPad, navigation uses a sidebar pattern with clear visual hierarchy.

```
┌───────────────────┬─────────────────────────────────────────┐
│                   │                                         │
│   ┌───────────┐   │                                         │
│   │ ★ HOME    │   │                                         │
│   └───────────┘   │                                         │
│                   │                                         │
│   ┌───────────┐   │          CONTENT AREA                  │
│   │   Week    │   │                                         │
│   └───────────┘   │                                         │
│                   │                                         │
│   ┌───────────┐   │                                         │
│   │   Year    │   │                                         │
│   └───────────┘   │                                         │
│                   │                                         │
│   ┌───────────┐   │                                         │
│   │  Settings │   │                                         │
│   └───────────┘   │                                         │
│                   │                                         │
└───────────────────┴─────────────────────────────────────────┘
```

### Implementation

```swift
struct JohoSidebar: View {
    @Binding var selection: NavigationItem
    let items: [NavigationItem]

    var body: some View {
        VStack(spacing: JohoSpacing.sm) {
            ForEach(items) { item in
                JohoSidebarItem(
                    item: item,
                    isSelected: selection == item,
                    action: { selection = item }
                )
            }
            Spacer()
        }
        .padding(JohoSpacing.md)
        .frame(width: 200)
        .background(JohoColors.white)
        .overlay(
            Rectangle()
                .frame(width: 3)
                .foregroundStyle(JohoColors.black),
            alignment: .trailing
        )
    }
}

struct JohoSidebarItem: View {
    let item: NavigationItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: JohoSpacing.sm) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(JohoColors.black)

                Text(item.title)
                    .font(.johoBody)
                    .foregroundStyle(JohoColors.black)

                Spacer()
            }
            .padding(JohoSpacing.md)
            .background(isSelected ? JohoColors.yellow : JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: isSelected ? 2.5 : 1.5)
            )
        }
    }
}
```

**Sidebar Rules:**
- Fixed width (200pt on iPad)
- 3pt border on trailing edge
- Selected item uses yellow background and 2.5pt border
- Items have 1.5pt borders

---

## iPhone Tab Bar

On iPhone, primary navigation uses a bottom tab bar.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                     CONTENT AREA                            │
│                                                             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│   │   📅    │  │   📆    │  │   ⭐    │  │   ⚙    │      │
│   │  Week   │  │  Year   │  │  Star   │  │Settings │      │
│   └─────────┘  └─────────┘  └─────────┘  └─────────┘      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct JohoTabBar: View {
    @Binding var selection: Tab
    let tabs: [Tab]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                JohoTabItem(
                    tab: tab,
                    isSelected: selection == tab,
                    action: { selection = tab }
                )
            }
        }
        .padding(.horizontal, JohoSpacing.sm)
        .padding(.vertical, JohoSpacing.sm)
        .background(JohoColors.white)
        .overlay(
            Rectangle()
                .frame(height: 3)
                .foregroundStyle(JohoColors.black),
            alignment: .top
        )
    }
}

struct JohoTabItem: View {
    let tab: Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: JohoSpacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(JohoColors.black)

                Text(tab.title)
                    .font(.johoLabelSmall)
                    .foregroundStyle(JohoColors.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoSpacing.sm)
            .background(isSelected ? JohoColors.yellow : JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: isSelected ? 2 : 0)
            )
        }
    }
}
```

**Tab Bar Rules:**
- 3pt border on top edge
- Selected tab uses yellow background
- Maximum 5 tabs
- Minimum 44pt touch targets

---

## Editor Sheet Headers

When presenting editor sheets (for creating or editing content), use a standardized header.

```
┌─────────────────────────────────────────────────────────────┐
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                                                         │ │
│ │   Cancel         EDIT EVENT             Save            │ │
│ │                                                         │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│                     FORM CONTENT                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct JohoSheetHeader: View {
    let title: String
    var onCancel: () -> Void
    var onSave: () -> Void
    var saveDisabled: Bool = false

    var body: some View {
        HStack {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.johoBody)
                    .foregroundStyle(JohoColors.black)
            }
            .frame(minWidth: 44, minHeight: 44)

            Spacer()

            Text(title.uppercased())
                .font(.johoHeadline)
                .foregroundStyle(JohoColors.black)

            Spacer()

            Button(action: onSave) {
                Text("Save")
                    .font(.johoBody)
                    .fontWeight(.bold)
                    .foregroundStyle(JohoColors.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(saveDisabled ? JohoColors.black.opacity(0.5) : JohoColors.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .disabled(saveDisabled)
        }
        .padding(.horizontal, JohoSpacing.lg)
        .padding(.vertical, JohoSpacing.md)
        .background(JohoColors.white)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundStyle(JohoColors.black),
            alignment: .bottom
        )
    }
}
```

**Sheet Header Rules:**
- Title is centered and uppercase
- Cancel button on left (text only)
- Save button on right (filled, primary style)
- 2pt border on bottom edge
- Save button disabled state at 50% opacity

---

## Breadcrumb Navigation

For deep navigation hierarchies, breadcrumbs show the path.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Home  ›  Settings  ›  Holidays  ›  Sweden                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct JohoBreadcrumb: View {
    let path: [String]
    var onTap: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: JohoSpacing.xs) {
            ForEach(Array(path.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Text("›")
                        .font(.johoBodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.4))
                }

                if index < path.count - 1 {
                    // Tappable ancestor
                    Button(action: { onTap?(index) }) {
                        Text(item)
                            .font(.johoBodySmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                            .underline()
                    }
                } else {
                    // Current (not tappable)
                    Text(item)
                        .font(.johoBodySmall)
                        .fontWeight(.bold)
                        .foregroundStyle(JohoColors.black)
                }
            }
        }
    }
}
```

---

## Segmented Control

For switching between views within a screen.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ ███████████│             │             │            │   │
│   │ █  DAY   ██│    WEEK     │    MONTH    │    YEAR    │   │
│   │ ███████████│             │             │            │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct JohoSegmentedControl<T: Hashable & CaseIterable & CustomStringConvertible>: View where T.AllCases: RandomAccessCollection {
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(T.allCases), id: \.self) { option in
                Button(action: { selection = option }) {
                    Text(option.description.uppercased())
                        .font(.johoLabel)
                        .foregroundStyle(selection == option ? JohoColors.white : JohoColors.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, JohoSpacing.md)
                        .background(selection == option ? JohoColors.black : JohoColors.white)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 2)
        )
    }
}
```

**Segmented Control Rules:**
- Selected segment has black background, white text
- Unselected segments have white background, black text
- All labels uppercase
- 2pt border around entire control

---

## Navigation State Indicators

Show current state clearly in navigation elements.

```
STATES:

Normal:     ┌─────────┐
            │  Item   │  1.5pt border, white background
            └─────────┘

Selected:   ┌─────────┐
            │  Item   │  2.5pt border, yellow background
            └─────────┘

Disabled:   ┌─────────┐
            │  Item   │  50% opacity
            └─────────┘
```

```swift
struct NavigationItemStyle {
    static func background(isSelected: Bool) -> Color {
        isSelected ? JohoColors.yellow : JohoColors.white
    }

    static func borderWidth(isSelected: Bool) -> CGFloat {
        isSelected ? 2.5 : 1.5
    }

    static func opacity(isEnabled: Bool) -> Double {
        isEnabled ? 1.0 : 0.5
    }
}
```

---

## Adaptive Navigation

Handle iPhone vs. iPad differences:

```swift
struct AdaptiveNavigation<Content: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Binding var selection: NavigationItem
    let items: [NavigationItem]
    let content: () -> Content

    var body: some View {
        if sizeClass == .regular {
            // iPad: Sidebar
            HStack(spacing: 0) {
                JohoSidebar(selection: $selection, items: items)
                content()
            }
        } else {
            // iPhone: Tab bar
            VStack(spacing: 0) {
                content()
                JohoTabBar(selection: $selection, tabs: items.map { $0.asTab })
            }
        }
    }
}
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│           情報デザイン NAVIGATION REFERENCE                  │
│                                                             │
│   HEADERS:                                                 │
│   • Title uppercase                                        │
│   • Max 8pt top padding                                    │
│   • Back button only when applicable                       │
│                                                             │
│   BENTO HEADER:                                            │
│   • Zone A: Hero (fixed width)                             │
│   • Zone B: Context (flexible)                             │
│   • Zone C: Controls (fixed width)                         │
│   • 3pt outer border                                       │
│                                                             │
│   SIDEBAR (iPad):                                          │
│   • 200pt width                                            │
│   • 3pt trailing border                                    │
│   • Selected: yellow + 2.5pt border                        │
│                                                             │
│   TAB BAR (iPhone):                                        │
│   • 3pt top border                                         │
│   • Selected: yellow background                            │
│   • Max 5 tabs                                             │
│                                                             │
│   SHEET HEADER:                                            │
│   • Cancel left, Save right                                │
│   • Title centered, uppercase                              │
│   • 2pt bottom border                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 12 — Data Display*



---


# Chapter 12: Data Display

> "Numbers are data. Tables are stories. Calendars are maps."

---

Data display is the heart of 情報デザイン. Information-dense interfaces require careful attention to how numbers, dates, lists, and tables present their content. Every display pattern follows consistent rules for clarity and quick comprehension.

---

## Calendar Grid

The calendar grid is a core 情報デザイン pattern—a dense, scannable display of temporal data.

```
┌─────────────────────────────────────────────────────────────┐
│  M   │  T   │  W   │  T   │  F   │  S   │  S   │           │
├──────┼──────┼──────┼──────┼──────┼──────┼──────┤           │
│  1   │  2   │  3   │  4   │  5   │  6   │  7   │  Week 1   │
│  ●   │      │  ●●  │      │      │      │  ●   │           │
├──────┼──────┼──────┼──────┼──────┼──────┼──────┤           │
│  8   │  9   │ 10   │ 11   │ 12   │ 13   │ 14   │  Week 2   │
│      │  ●   │      │      │  ●   │      │      │           │
└──────┴──────┴──────┴──────┴──────┴──────┴──────┘           │
```

### Day Cell Implementation

```swift
struct JohoDayCell: View {
    let day: Int
    let indicators: [Color]
    var isToday: Bool = false
    var isSunday: Bool = false
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: JohoSpacing.xs) {
            // Day number
            Text(String(day))
                .font(.johoBody)
                .monospacedDigit()
                .foregroundStyle(dayColor)

            // Indicator dots
            if !indicators.isEmpty {
                HStack(spacing: 2) {
                    ForEach(indicators.prefix(3), id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(JohoColors.black, lineWidth: 1))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, JohoSpacing.sm)
        .background(cellBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(JohoColors.black, lineWidth: isSelected ? 2.5 : 1)
        )
    }

    private var dayColor: Color {
        if isSunday { return JohoColors.red }
        return JohoColors.black
    }

    private var cellBackground: Color {
        if isToday { return JohoColors.yellow }
        if isSelected { return JohoColors.yellow.opacity(0.3) }
        return JohoColors.white
    }
}
```

### Calendar Grid Implementation

```swift
struct JohoCalendarGrid: View {
    let weeks: [[DayData]]
    @Binding var selectedDay: Int?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: JohoSpacing.xs), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            // Day headers
            HStack(spacing: JohoSpacing.xs) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.johoLabel)
                        .foregroundStyle(day == "S" ? JohoColors.red : JohoColors.black)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, JohoSpacing.sm)
            .background(JohoColors.black)
            .foregroundStyle(JohoColors.white)

            // Day grid
            LazyVGrid(columns: columns, spacing: JohoSpacing.xs) {
                ForEach(weeks.flatMap { $0 }) { day in
                    JohoDayCell(
                        day: day.number,
                        indicators: day.indicators,
                        isToday: day.isToday,
                        isSunday: day.isSunday,
                        isSelected: selectedDay == day.number
                    )
                    .onTapGesture { selectedDay = day.number }
                }
            }
            .padding(JohoSpacing.xs)
        }
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
        )
    }
}
```

**Calendar Grid Rules:**
- Day headers on black background
- Sunday column in red
- Today highlighted in yellow
- Indicator dots show content types
- 1pt cell borders, 3pt outer border

---

## Week Row

A compact horizontal representation of a week.

```
┌─────────────────────────────────────────────────────────────┐
│ WK 42 │ M │ T │ W │ T │ F │ S │ S │  Oct 14 - Oct 20       │
│       │ ● │   │●● │   │   │   │ ● │                         │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct JohoWeekRow: View {
    let weekNumber: Int
    let days: [DayData]
    let dateRange: String
    var isCurrentWeek: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Week number
            Text("WK \(weekNumber)")
                .font(.johoLabel)
                .monospacedDigit()
                .foregroundStyle(JohoColors.white)
                .frame(width: 56)
                .padding(.vertical, JohoSpacing.md)
                .background(isCurrentWeek ? JohoColors.yellow : JohoColors.black)
                .foregroundStyle(isCurrentWeek ? JohoColors.black : JohoColors.white)

            // Day cells
            ForEach(days) { day in
                VStack(spacing: 2) {
                    Text(day.initial)
                        .font(.johoLabelSmall)
                        .foregroundStyle(day.isSunday ? JohoColors.red : JohoColors.black.opacity(0.6))

                    HStack(spacing: 1) {
                        ForEach(day.indicators.prefix(2), id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 5, height: 5)
                                .overlay(Circle().stroke(JohoColors.black, lineWidth: 0.5))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, JohoSpacing.sm)
                .background(day.isToday ? JohoColors.yellow : JohoColors.white)
                .overlay(
                    Rectangle()
                        .stroke(JohoColors.black, lineWidth: 1)
                )
            }

            // Date range
            Text(dateRange)
                .font(.johoBodySmall)
                .foregroundStyle(JohoColors.black.opacity(0.6))
                .frame(width: 120)
                .padding(.horizontal, JohoSpacing.sm)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }
}
```

---

## Data Tables

Tables for structured data follow clear alignment rules.

```
┌─────────────────────────────────────────────────────────────┐
│  NAME               │  TYPE      │  DATE         │  AMOUNT │
├─────────────────────┼────────────┼───────────────┼─────────┤
│  Groceries          │  Expense   │  Oct 14       │  $45.00 │
├─────────────────────┼────────────┼───────────────┼─────────┤
│  Client Meeting     │  Event     │  Oct 15       │  -      │
├─────────────────────┼────────────┼───────────────┼─────────┤
│  Flight to NYC      │  Trip      │  Oct 20       │ $320.00 │
└─────────────────────┴────────────┴───────────────┴─────────┘
```

### Implementation

```swift
struct JohoDataTable<Item: Identifiable>: View {
    let columns: [TableColumn<Item>]
    let items: [Item]

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                ForEach(columns) { column in
                    Text(column.title.uppercased())
                        .font(.johoLabel)
                        .foregroundStyle(JohoColors.white)
                        .frame(width: column.width, alignment: column.alignment)
                        .padding(.vertical, JohoSpacing.md)
                        .padding(.horizontal, JohoSpacing.sm)
                }
            }
            .background(JohoColors.black)

            // Data rows
            ForEach(items) { item in
                HStack(spacing: 0) {
                    ForEach(columns) { column in
                        column.content(item)
                            .font(.johoBody)
                            .foregroundStyle(JohoColors.black)
                            .frame(width: column.width, alignment: column.alignment)
                            .padding(.vertical, JohoSpacing.md)
                            .padding(.horizontal, JohoSpacing.sm)
                    }
                }
                .background(JohoColors.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(JohoColors.black),
                    alignment: .bottom
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 2)
        )
    }
}

struct TableColumn<Item>: Identifiable {
    let id = UUID()
    let title: String
    let width: CGFloat?
    let alignment: Alignment
    let content: (Item) -> AnyView
}
```

**Table Rules:**
- Header row on black background
- Column headers uppercase
- Text columns left-aligned
- Number columns right-aligned
- Monospaced digits for all numbers
- 1pt row separators
- 2pt outer border

---

## Statistics Cards

Display key metrics prominently.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  │
│   │               │  │               │  │               │  │
│   │     127       │  │      8        │  │    $2,340     │  │
│   │               │  │               │  │               │  │
│   │   EVENTS      │  │   HOLIDAYS    │  │   EXPENSES    │  │
│   │               │  │               │  │               │  │
│   └───────────────┘  └───────────────┘  └───────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct JohoStatCard: View {
    let value: String
    let label: String
    var accentColor: Color = JohoColors.white

    var body: some View {
        VStack(spacing: JohoSpacing.sm) {
            Text(value)
                .font(.johoDisplayMedium)
                .monospacedDigit()
                .foregroundStyle(JohoColors.black)

            Text(label.uppercased())
                .font(.johoLabel)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, JohoSpacing.xl)
        .background(accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 2)
        )
    }
}

// Usage
HStack(spacing: JohoSpacing.sm) {
    JohoStatCard(value: "127", label: "Events", accentColor: JohoColors.cyan)
    JohoStatCard(value: "8", label: "Holidays", accentColor: JohoColors.pink)
    JohoStatCard(value: "$2,340", label: "Expenses", accentColor: JohoColors.green)
}
```

---

## List Rows

Standard rows for displaying items in a list.

```
┌─────────────────────────────────────────────────────────────┐
│  ●  Team Meeting                               9:00 AM  >  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  ●  Christmas Day                              Dec 25   🔒  │
│     National holiday                                       │
└─────────────────────────────────────────────────────────────┘
```

### Basic Row

```swift
struct JohoListRow: View {
    let title: String
    let subtitle: String?
    let indicatorColor: Color?
    let trailing: String?
    var showChevron: Bool = true
    var isLocked: Bool = false

    var body: some View {
        HStack(spacing: JohoSpacing.md) {
            // Indicator
            if let color = indicatorColor {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
            }

            // Content
            VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                Text(title)
                    .font(.johoHeadline)
                    .foregroundStyle(JohoColors.black)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.johoBodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }

            Spacer()

            // Trailing
            if let trailing = trailing {
                Text(trailing)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }

            // Lock or chevron
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            }
        }
        .padding(JohoSpacing.md)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }
}
```

---

## Progress Indicators

Show progress through a process or timeline.

### Linear Progress

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░  42%    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct JohoProgressBar: View {
    let progress: Double  // 0.0 to 1.0
    var accentColor: Color = JohoColors.cyan

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(JohoColors.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(JohoColors.black, lineWidth: 2)
                    )

                // Fill
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accentColor)
                    .frame(width: geometry.size.width * progress)
                    .padding(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(JohoColors.black, lineWidth: 1)
                            .padding(2)
                    )
            }
        }
        .frame(height: 24)
    }
}
```

### Step Progress

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│     ●────────●────────○────────○────────○                  │
│     1        2        3        4        5                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct JohoStepProgress: View {
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...totalSteps, id: \.self) { step in
                // Step circle
                Circle()
                    .fill(step <= currentStep ? JohoColors.black : JohoColors.white)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(JohoColors.black, lineWidth: 2)
                    )

                // Connector line (not after last step)
                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? JohoColors.black : JohoColors.black.opacity(0.3))
                        .frame(height: 2)
                }
            }
        }
    }
}
```

---

## Number Formatting

Numbers must be formatted consistently throughout.

### Currency

```swift
extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    static var joho: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: Locale.current.currency?.identifier ?? "USD")
    }
}

// Usage
Text(amount, format: .joho)
    .font(.johoBody)
    .monospacedDigit()
```

### Dates

```swift
struct JohoDateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// Usage
Text(JohoDateFormatter.shortDate.string(from: date))
```

### Week Numbers

```swift
// Always use String() for week numbers to avoid locale formatting
Text("Week \(String(weekNumber))")
    .font(.johoHeadline)
    .monospacedDigit()
```

---

## Empty States

When data is empty, show meaningful empty states.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                         📅                                  │
│                                                             │
│                   No Events Today                          │
│                                                             │
│           Tap + to add your first event                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct JohoEmptyDataState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: JohoSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(JohoColors.black.opacity(0.3))

            VStack(spacing: JohoSpacing.sm) {
                Text(title)
                    .font(.johoHeadline)
                    .foregroundStyle(JohoColors.black)

                Text(message)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                JohoButton(title: actionTitle, action: action, style: .primary)
            }
        }
        .padding(JohoSpacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
        )
    }
}
```

---

## Loading States

Show loading states with clear indicators.

```swift
struct JohoLoadingState: View {
    let message: String

    var body: some View {
        VStack(spacing: JohoSpacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: JohoColors.black))
                .scaleEffect(1.5)

            Text(message)
                .font(.johoBodySmall)
                .foregroundStyle(JohoColors.black.opacity(0.6))
        }
        .padding(JohoSpacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
        )
    }
}
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│           情報デザイン DATA DISPLAY REFERENCE                │
│                                                             │
│   CALENDARS:                                               │
│   • Sunday column red                                      │
│   • Today yellow background                                │
│   • Indicator dots show content types                      │
│   • 1pt cell borders, 3pt outer                           │
│                                                             │
│   TABLES:                                                  │
│   • Header on black background                             │
│   • Column headers uppercase                               │
│   • Text left-aligned, numbers right-aligned              │
│   • Monospaced digits always                              │
│                                                             │
│   FORMATTING:                                              │
│   • Use String(number) not "\(number)"                     │
│   • Currency: .currency(code:)                            │
│   • Always .monospacedDigit()                             │
│                                                             │
│   STATES:                                                  │
│   • Empty: icon + title + message                         │
│   • Loading: spinner + message                            │
│   • All states have 3pt borders                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

*Next: Part 4 — Case Study: Onsen Planner*



---


# Chapter 13: App Architecture

> "Design systems don't exist in theory. They exist in shipping products."

---

Part 4 demonstrates 情報デザイン through a real production app: Onsen Planner. This iOS calendar app displays ISO 8601 week numbers with semantic color coding. Every screen, every component, and every interaction follows the 情報デザイン principles we've covered.

---

## Onsen Planner Overview

**What it does:** Displays week numbers with visual indication of holidays, events, and special days.

**Core features:**
- ISO 8601 week number display
- Multi-region holiday support (Sweden, United States, Vietnam)
- Custom events and countdowns
- Daily notes
- Widgets (small, medium, large)
- Siri Shortcuts

**Technical stack:**
- SwiftUI
- SwiftData for persistence
- WidgetKit for home screen widgets
- App Intents for Siri integration

---

## Architecture Pattern

Onsen Planner uses a Manager + Model + View pattern:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   User Action                                               │
│       ↓                                                     │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                    View Layer                       │   │
│   │  (SwiftUI Views using 情報デザイン components)        │   │
│   └───────────────────────┬─────────────────────────────┘   │
│                           ↓                                 │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              Manager Layer (Singleton)              │   │
│   │        (Cache check → Query → Cache update)         │   │
│   └───────────────────────┬─────────────────────────────┘   │
│                           ↓                                 │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                   Model Layer                       │   │
│   │           (SwiftData + Pure Swift structs)          │   │
│   └───────────────────────┬─────────────────────────────┘   │
│                           ↓                                 │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                  Engine Layer                       │   │
│   │  (Calculations: Easter, Lunar, Week numbers)        │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

```
Vecka/
├── Core/                    # Week calculation logic
│   └── WeekCalculator.swift
│
├── Models/                  # Data models
│   ├── HolidayRule.swift    # SwiftData model
│   ├── CalendarRule.swift   # SwiftData model
│   ├── CountdownEvent.swift # SwiftData model
│   ├── DailyNote.swift      # SwiftData model
│   ├── Holiday.swift        # Pure Swift struct
│   └── HolidayEngine.swift  # Calculation engine
│
├── Views/                   # UI components
│   ├── ModernCalendarView.swift
│   ├── AppSidebar.swift
│   ├── PhoneLibraryView.swift
│   └── ... (all views)
│
├── Services/                # External integrations
│   ├── WeatherService.swift
│   ├── PDFExportService.swift
│   └── CurrencyService.swift
│
├── Intents/                 # Siri Shortcuts
│   └── CurrentWeekIntent.swift
│
├── JohoDesignSystem.swift   # Design system components
└── Localization.swift       # i18n strings
```

---

## The Core Engine

### Week Calculation

ISO 8601 week numbers are the foundation. The calculator uses a properly configured calendar:

```swift
struct WeekCalculator {
    static let shared = WeekCalculator()

    private let calendar: Calendar

    init() {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2              // Monday
        cal.minimumDaysInFirstWeek = 4    // ISO 8601
        cal.locale = Locale(identifier: "sv_SE")
        self.calendar = cal
    }

    func weekNumber(for date: Date) -> Int {
        calendar.component(.weekOfYear, from: date)
    }

    func year(for date: Date) -> Int {
        // ISO week year may differ from calendar year
        calendar.component(.yearForWeekOfYear, from: date)
    }
}
```

**Why `minimumDaysInFirstWeek = 4`?**

ISO 8601 defines that week 1 is the week containing January 4th (or equivalently, the week containing the first Thursday of the year). This means:
- Some years start with week 52 or 53 from the previous year
- Some years end with week 1 of the next year

This matches how most of Europe counts weeks.

### Holiday Engine

Holidays come in five types:

```swift
enum HolidayType: String, Codable {
    case fixed           // Dec 25 every year
    case easterRelative  // Good Friday = Easter - 2 days
    case floating        // Midsummer Eve (Friday between June 19-25)
    case nthWeekday      // Thanksgiving (4th Thursday of November)
    case lunar           // Tết (Lunar New Year)
}
```

Each type requires different calculation logic:

```swift
struct HolidayEngine {
    // Fixed: Simple month + day
    static func fixedDate(month: Int, day: Int, year: Int) -> Date? {
        DateComponents(calendar: .current, year: year, month: month, day: day).date
    }

    // Easter: Computus algorithm (complex astronomical calculation)
    static func easterDate(year: Int) -> Date {
        // Gregorian Computus implementation
        let a = year % 19
        let b = year / 100
        let c = year % 100
        // ... full algorithm
    }

    // Floating: Find specific weekday in date range
    static func floatingDate(weekday: Int, monthRange: Range<Int>, year: Int) -> Date? {
        // Find Friday between June 19-25, etc.
    }

    // Nth Weekday: Find nth occurrence of weekday in month
    static func nthWeekday(n: Int, weekday: Int, month: Int, year: Int) -> Date? {
        // 4th Thursday of November, etc.
    }

    // Lunar: Convert lunar calendar date to Gregorian
    static func lunarDate(lunarMonth: Int, lunarDay: Int, year: Int) -> Date? {
        // Chinese calendar conversion
    }
}
```

---

## SwiftData Models

### HolidayRule

```swift
@Model
final class HolidayRule {
    @Attribute(.unique) var id: String
    var name: String
    var localizedName: [String: String]  // ["en": "Christmas", "sv": "Jul"]
    var type: HolidayType
    var month: Int?
    var day: Int?
    var easterOffset: Int?
    var nthOccurrence: Int?
    var weekday: Int?
    var regionCode: String
    var isSystemProvided: Bool  // True = locked, no swipe actions
    var color: String  // Hex color code

    // Computed: Get the date for a specific year
    func date(for year: Int) -> Date? {
        switch type {
        case .fixed:
            return HolidayEngine.fixedDate(month: month!, day: day!, year: year)
        case .easterRelative:
            let easter = HolidayEngine.easterDate(year: year)
            return Calendar.current.date(byAdding: .day, value: easterOffset!, to: easter)
        // ... other types
        }
    }
}
```

### DailyNote

```swift
@Model
final class DailyNote {
    @Attribute(.unique) var dateKey: String  // "2026-01-08"
    var content: String
    var createdAt: Date
    var modifiedAt: Date

    var date: Date {
        // Parse dateKey to Date
    }
}
```

---

## Manager Layer

Managers handle business logic and caching:

```swift
@MainActor
class HolidayManager: ObservableObject {
    static let shared = HolidayManager()

    @Published var holidays: [Holiday] = []
    private var cache: [Int: [Holiday]] = [:]  // Year → Holidays

    func getHolidays(for year: Int, context: ModelContext) -> [Holiday] {
        // Check cache first
        if let cached = cache[year] {
            return cached
        }

        // Query SwiftData
        let rules = try? context.fetch(FetchDescriptor<HolidayRule>())

        // Calculate dates for year
        let holidays = rules?.compactMap { rule in
            guard let date = rule.date(for: year) else { return nil }
            return Holiday(
                id: rule.id,
                name: rule.localizedName(for: Locale.current),
                date: date,
                type: rule.isSystemProvided ? .system : .user,
                color: Color(hex: rule.color)
            )
        } ?? []

        // Update cache
        cache[year] = holidays
        self.holidays = holidays

        return holidays
    }
}
```

---

## View Layer

Views consume managers and display using 情報デザイン components.

### Basic View Structure

```swift
struct WeekDetailView: View {
    let weekNumber: Int
    let year: Int

    @EnvironmentObject var holidayManager: HolidayManager
    @Environment(\.modelContext) var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: JohoSpacing.sm) {
                // Bento header
                JohoBentoHeader(
                    weekNumber: weekNumber,
                    monthYear: monthYearString,
                    onPrevious: { /* navigate */ },
                    onNext: { /* navigate */ },
                    onToday: { /* jump to today */ }
                )

                // Day cards
                ForEach(days) { day in
                    JohoCard {
                        DayContent(day: day)
                    }
                }
            }
            .padding(.horizontal, JohoSpacing.lg)
            .padding(.top, JohoSpacing.sm)  // Max 8pt!
        }
        .background(JohoColors.white)
    }
}
```

---

## Multi-Target Support

Onsen Planner shares code between the main app and widget extension:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                    Shared Code                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  WeekCalculator    HolidayEngine    SwiftData Models │   │
│   │  JohoDesignSystem  JohoColors       Localization    │   │
│   └─────────────────────────────────────────────────────┘   │
│                           ↑                                 │
│             ┌─────────────┴─────────────┐                  │
│             │                           │                   │
│   ┌─────────┴───────┐       ┌───────────┴───────┐          │
│   │   Main App      │       │   Widget Extension │          │
│   │                 │       │                    │          │
│   │  Full UI        │       │  Timeline Provider │          │
│   │  Navigation     │       │  Compact Views     │          │
│   │  Services       │       │                    │          │
│   └─────────────────┘       └────────────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

Target membership in Xcode determines which files are compiled into which target.

---

## Navigation Architecture

### iPad: NavigationSplitView

```swift
struct ContentView: View {
    @State private var selectedTab: Tab = .week

    var body: some View {
        NavigationSplitView {
            AppSidebar(selection: $selectedTab)
        } detail: {
            switch selectedTab {
            case .week:
                WeekView()
            case .year:
                YearView()
            case .star:
                StarPage()
            case .settings:
                SettingsView()
            }
        }
    }
}
```

### iPhone: TabView

```swift
struct ContentView: View {
    @State private var selectedTab: Tab = .week

    var body: some View {
        TabView(selection: $selectedTab) {
            WeekView()
                .tabItem { Label("Week", systemImage: "calendar") }
                .tag(Tab.week)

            YearView()
                .tabItem { Label("Year", systemImage: "calendar.badge.plus") }
                .tag(Tab.year)

            StarPage()
                .tabItem { Label("Star", systemImage: "star") }
                .tag(Tab.star)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(Tab.settings)
        }
    }
}
```

---

## Deep Linking

The app supports URL-based navigation:

```swift
enum DeepLink {
    case today
    case week(number: Int, year: Int)
    case calendar

    init?(url: URL) {
        guard url.scheme == "vecka" else { return nil }

        switch url.host {
        case "today":
            self = .today
        case "week":
            // Parse /weekNumber/year from path
            let components = url.pathComponents.filter { $0 != "/" }
            guard components.count >= 2,
                  let week = Int(components[0]),
                  let year = Int(components[1]) else { return nil }
            self = .week(number: week, year: year)
        case "calendar":
            self = .calendar
        default:
            return nil
        }
    }
}
```

---

## Design System Integration

Every view imports and uses the design system:

```swift
// JohoDesignSystem.swift provides:

struct JohoColors {
    static let black = Color(hex: "000000")
    static let white = Color(hex: "FFFFFF")
    static let yellow = Color(hex: "FFE566")
    static let cyan = Color(hex: "A5F3FC")
    static let pink = Color(hex: "FECDD3")
    // ... all semantic colors
}

struct JohoSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    // ... all spacing tokens
}

extension Font {
    static let johoDisplayLarge = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let johoHeadline = Font.system(size: 18, weight: .bold, design: .rounded)
    // ... all typography styles
}
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│           WEEKGRID ARCHITECTURE REFERENCE                  │
│                                                             │
│   PATTERN: Manager + Model + View                          │
│                                                             │
│   LAYERS:                                                  │
│   • View: SwiftUI + 情報デザイン components                  │
│   • Manager: Business logic + caching (singleton)          │
│   • Model: SwiftData + pure Swift structs                  │
│   • Engine: Complex calculations                           │
│                                                             │
│   TARGETS:                                                 │
│   • Vecka (main app)                                       │
│   • VeckaWidgetExtension (widgets)                         │
│   • VeckaTests / VeckaUITests                              │
│                                                             │
│   SHARED CODE:                                             │
│   • WeekCalculator, HolidayEngine                          │
│   • SwiftData models                                       │
│   • JohoDesignSystem                                       │
│                                                             │
│   DEEP LINKS:                                              │
│   • vecka://today                                          │
│   • vecka://week/{number}/{year}                           │
│   • vecka://calendar                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 14 — Calendar Design*



---


# Chapter 14: Calendar Design

> "A calendar is a year made visible."

---

The calendar is Onsen Planner's primary interface. It demonstrates how 情報デザイン handles dense, scannable information displays. Every decision—from cell size to color coding—serves rapid comprehension.

---

## Week Row Design

The fundamental unit is the week row. A full year is 52 or 53 week rows stacked vertically.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌────────┬───┬───┬───┬───┬───┬───┬───┬──────────────────┐  │
│  │        │ M │ T │ W │ T │ F │ S │ S │                  │  │
│  │ WK 42  ├───┼───┼───┼───┼───┼───┼───┤  Oct 14 - 20     │  │
│  │        │   │ ● │   │●● │   │   │ ● │                  │  │
│  └────────┴───┴───┴───┴───┴───┴───┴───┴──────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Anatomy of a Week Row

```swift
struct WeekRowView: View {
    let week: WeekData
    var isCurrentWeek: Bool = false
    var isExpanded: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // 1. Week number zone (fixed width)
            WeekNumberCell(
                number: week.number,
                isCurrent: isCurrentWeek
            )

            // 2. Day cells zone (7 equal columns)
            ForEach(week.days) { day in
                DayCell(
                    day: day,
                    isToday: day.isToday,
                    isSunday: day.isSunday
                )
            }

            // 3. Date range zone (fixed width)
            DateRangeCell(
                startDate: week.startDate,
                endDate: week.endDate
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }
}
```

---

## Day Cell Design

Each day cell shows the day number and indicator dots for content.

### Cell States

```
┌───────────────────────────────────────────────────────────┐
│                                                           │
│   NORMAL          TODAY           SUNDAY        SELECTED  │
│                                                           │
│   ┌─────┐        ┌─────┐        ┌─────┐        ┌─────┐   │
│   │ 14  │        │ 15  │        │ 16  │        │ 17  │   │
│   │     │        │     │        │     │        │     │   │
│   │     │        │     │        │     │        │     │   │
│   └─────┘        └─────┘        └─────┘        └─────┘   │
│   White bg       Yellow bg      Red text       Yellow bg │
│   Black text     Black text     White bg       2.5pt     │
│   1pt border     1pt border     1pt border     border    │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct DayCell: View {
    let day: DayData
    var isToday: Bool = false
    var isSunday: Bool = false
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            // Day number
            Text(String(day.number))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(textColor)

            // Indicators (max 3)
            if !day.indicators.isEmpty {
                HStack(spacing: 1) {
                    ForEach(day.indicators.prefix(3), id: \.color) { indicator in
                        Circle()
                            .fill(indicator.color)
                            .frame(width: 5, height: 5)
                            .overlay(
                                Circle()
                                    .stroke(JohoColors.black, lineWidth: 0.5)
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, JohoSpacing.sm)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(JohoColors.black, lineWidth: borderWidth)
        )
    }

    private var textColor: Color {
        isSunday ? JohoColors.red : JohoColors.black
    }

    private var backgroundColor: Color {
        if isToday { return JohoColors.yellow }
        if isSelected { return JohoColors.yellow.opacity(0.3) }
        return JohoColors.white
    }

    private var borderWidth: CGFloat {
        isSelected ? 2.5 : 1
    }
}
```

---

## Indicator Dots

Indicator dots are the 情報デザイン solution for showing content types without overwhelming the interface.

### Color Meanings

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ● Cyan #A5F3FC     Events (meetings, appointments)       │
│   ● Pink #FECDD3     Holidays (bank holidays, observances) │
│   ● Orange #FED7AA   Trips (travel, vacation)              │
│   ● Green #BBF7D0    Expenses (financial entries)          │
│   ● Purple #E9D5FF   Contacts (birthdays, anniversaries)   │
│   ● Yellow #FFE566   Notes (daily notes, reminders)        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct IndicatorDot: View {
    let color: Color
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(JohoColors.black, lineWidth: size > 6 ? 1.5 : 1)
            )
    }
}

// Size variants
enum IndicatorSize {
    case calendar  // 5pt - in calendar grid
    case collapsed // 6pt - in collapsed rows
    case expanded  // 8pt - in expanded content
    case legend    // 10pt - in legend/settings

    var diameter: CGFloat {
        switch self {
        case .calendar: return 5
        case .collapsed: return 6
        case .expanded: return 8
        case .legend: return 10
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .calendar, .collapsed: return 0.5
        case .expanded, .legend: return 1.5
        }
    }
}
```

**Critical Rule:** Every indicator dot MUST have a black border. Colored circles without borders break visual hierarchy.

---

## Expanded Week View

When a user taps a week row, it expands to show full content.

```
┌─────────────────────────────────────────────────────────────┐
│  WEEK 42                                                    │
│  October 14 - October 20, 2026                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  MONDAY 14                                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ● Team Standup                           9:00 AM    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  TUESDAY 15                                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ● Client Meeting                         2:00 PM    │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ● Project deadline                       5:00 PM    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  WEDNESDAY 16                                               │
│  No events                                                  │
│                                                             │
│  ...                                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct ExpandedWeekView: View {
    let week: WeekData
    @Binding var selectedDay: Int?

    var body: some View {
        JohoContainer {
            VStack(alignment: .leading, spacing: JohoSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                    Text("WEEK \(String(week.number))")
                        .font(.johoDisplayMedium)
                        .foregroundStyle(JohoColors.black)

                    Text(week.dateRangeString)
                        .font(.johoBodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Divider()
                    .background(JohoColors.black)

                // Days
                ForEach(week.days) { day in
                    DaySection(
                        day: day,
                        isSelected: selectedDay == day.number,
                        onTap: { selectedDay = day.number }
                    )
                }
            }
        }
    }
}

struct DaySection: View {
    let day: DayData
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: JohoSpacing.sm) {
            // Day header
            Button(action: onTap) {
                HStack {
                    Text(day.weekdayName.uppercased())
                        .font(.johoLabel)
                        .foregroundStyle(day.isSunday ? JohoColors.red : JohoColors.black)

                    Text(String(day.number))
                        .font(.johoLabel)
                        .foregroundStyle(day.isSunday ? JohoColors.red : JohoColors.black)

                    Spacer()

                    if day.isToday {
                        Text("TODAY")
                            .font(.johoLabel)
                            .foregroundStyle(JohoColors.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(JohoColors.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(JohoColors.black, lineWidth: 1.5)
                            )
                    }
                }
            }

            // Events for day
            if day.events.isEmpty {
                Text("No events")
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            } else {
                ForEach(day.events) { event in
                    EventRow(event: event)
                }
            }
        }
        .padding(.vertical, JohoSpacing.sm)
        .background(isSelected ? JohoColors.yellow.opacity(0.1) : Color.clear)
    }
}
```

---

## Year Overview

The year view shows all 52/53 weeks at once.

```
┌─────────────────────────────────────────────────────────────┐
│                         2026                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Q1                                                        │
│   WK 1  │░░░░░░░│░░░░░░░│░░░░░░░│  Jan 1 - 7               │
│   WK 2  │░░░░░░░│░░░░░░░│░░░░░░░│  Jan 8 - 14              │
│   ...                                                       │
│                                                             │
│   Q2                                                        │
│   WK 14 │░░░░░░░│░░░░░░░│░░░░░░░│  Apr 1 - 7               │
│   ...                                                       │
│                                                             │
│   Q3                                                        │
│   WK 27 │░░░░░░░│░░░░░░░│░░░░░░░│  Jul 1 - 7               │
│   ...                                                       │
│                                                             │
│   Q4                                                        │
│   WK 40 │░░░░░░░│░░░░░░░│░░░░░░░│  Oct 1 - 7               │
│   WK 41 │░░░░░░░│░░░░░░░│░░░░░░░│  Oct 8 - 14              │
│   WK 42 │███████│███████│███████│  Oct 15 - 21  ← Current   │
│   ...                                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct YearOverviewView: View {
    let year: Int
    @StateObject var holidayManager = HolidayManager.shared

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: JohoSpacing.sm) {
                    ForEach(quarters, id: \.number) { quarter in
                        QuarterSection(
                            quarter: quarter,
                            year: year
                        )
                    }
                }
                .padding(.horizontal, JohoSpacing.lg)
                .padding(.top, JohoSpacing.sm)
            }
            .onAppear {
                // Auto-scroll to current week
                proxy.scrollTo(currentWeekNumber, anchor: .center)
            }
        }
        .background(JohoColors.white)
    }

    private var quarters: [Quarter] {
        [
            Quarter(number: 1, weeks: 1...13),
            Quarter(number: 2, weeks: 14...26),
            Quarter(number: 3, weeks: 27...39),
            Quarter(number: 4, weeks: 40...52)
        ]
    }
}

struct QuarterSection: View {
    let quarter: Quarter
    let year: Int

    var body: some View {
        VStack(alignment: .leading, spacing: JohoSpacing.sm) {
            // Quarter header
            Text("Q\(quarter.number)")
                .font(.johoLabel)
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(JohoColors.black)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            // Weeks in quarter
            ForEach(Array(quarter.weeks), id: \.self) { weekNumber in
                CompactWeekRow(weekNumber: weekNumber, year: year)
                    .id(weekNumber)
            }
        }
    }
}
```

---

## Month Header Design

When scrolling through the calendar, month headers appear.

```
┌─────────────────────────────────────────────────────────────┐
│ ██████████████████████████████████████████████████████████ │
│ █                     OCTOBER 2026                       █ │
│ ██████████████████████████████████████████████████████████ │
│                                                             │
│  WK 40 │ M │ T │ W │ T │ F │ S │ S │  Sep 28 - Oct 4       │
│  ...                                                        │
└─────────────────────────────────────────────────────────────┘
```

```swift
struct MonthHeader: View {
    let month: String
    let year: Int

    var body: some View {
        Text("\(month.uppercased()) \(String(year))")
            .font(.johoLabel)
            .foregroundStyle(JohoColors.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, JohoSpacing.md)
            .background(JohoColors.black)
    }
}
```

---

## Holiday Row Design

Holidays have special treatment to make them scannable.

```
┌─────────────────────────────────────────────────────────────┐
│  ●  Christmas Day                               Dec 25  🔒  │
│     National holiday - Sweden, United States               │
└─────────────────────────────────────────────────────────────┘
```

### System vs. User Holidays

```swift
struct HolidayRow: View {
    let holiday: Holiday

    var body: some View {
        HStack(spacing: JohoSpacing.md) {
            // Indicator
            IndicatorDot(color: JohoColors.pink, size: 10)

            // Content
            VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                Text(holiday.name)
                    .font(.johoHeadline)
                    .foregroundStyle(JohoColors.black)

                Text(holiday.subtitle)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }

            Spacer()

            // Date
            Text(holiday.formattedDate)
                .font(.johoBodySmall)
                .foregroundStyle(JohoColors.black.opacity(0.6))

            // Lock icon for system holidays
            if holiday.isSystem {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            }
        }
        .padding(JohoSpacing.md)
        .background(JohoColors.pink.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }
}
```

**Important:** System holidays (🔒) have no swipe actions. Users cannot edit or delete bank holidays.

---

## Calendar Accessibility

### VoiceOver

```swift
struct DayCell: View {
    // ...

    var body: some View {
        // ... visual content ...
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(day.events.isEmpty ? "No events" : "\(day.events.count) events")
    }

    private var accessibilityLabel: String {
        var label = "\(day.weekdayName) \(day.number)"
        if isToday { label += ", today" }
        if !day.indicators.isEmpty {
            label += ", has content"
        }
        return label
    }
}
```

### Dynamic Type

Calendar cells scale appropriately with Dynamic Type settings, though indicator dots maintain minimum sizes for visibility.

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│           情報デザイン CALENDAR REFERENCE                    │
│                                                             │
│   WEEK ROW ZONES:                                          │
│   1. Week number (fixed width)                             │
│   2. Day cells (7 equal columns)                           │
│   3. Date range (fixed width)                              │
│                                                             │
│   DAY CELL STATES:                                         │
│   • Normal: white bg, black text, 1pt border               │
│   • Today: yellow bg, black text, 1pt border               │
│   • Sunday: white bg, red text, 1pt border                 │
│   • Selected: yellow.opacity(0.3), 2.5pt border            │
│                                                             │
│   INDICATOR COLORS:                                        │
│   • Cyan: Events                                           │
│   • Pink: Holidays                                         │
│   • Orange: Trips                                          │
│   • Green: Expenses                                        │
│   • Purple: Contacts                                       │
│   • Yellow: Notes                                          │
│                                                             │
│   HOLIDAYS:                                                │
│   • System (🔒): No swipe actions                          │
│   • User: Swipe to edit/delete                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 15 — The "Star Page" Golden Standard*



---


# Chapter 15: The "Star Page" Golden Standard

> "One perfect page teaches more than a thousand guidelines."

---

Every design system needs a reference implementation—a single page that demonstrates every principle in harmony. In Onsen Planner, this is the "Star Page" (★). It's not just a feature screen; it's a teaching document rendered as UI.

---

## What is a Star Page?

A Star Page is a real, functional screen that serves dual purposes:

1. **For users:** A useful feature (in Onsen Planner, a quick-glance dashboard)
2. **For developers:** A canonical reference for implementing 情報デザイン

If your app has a Star Page, new team members can learn the design system by studying one file. Every component, every spacing decision, every color choice is visible in context.

---

## Onsen Planner's Star Page

The Star Page shows today's context at a glance:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                          ★                                  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ ┌─────────┬──────────────────────────┬─────────────┐  │  │
│  │ │         │                          │             │  │  │
│  │ │   42    │      October 2026        │   TODAY     │  │  │
│  │ │         │      Wednesday 15        │   button    │  │  │
│  │ │  WEEK   │                          │             │  │  │
│  │ └─────────┴──────────────────────────┴─────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  ┌──────────┐                                         │  │
│  │  │  TODAY   │                                         │  │
│  │  └──────────┘                                         │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │ ● Team Standup                        9:00 AM   │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │ ● Client Meeting                      2:00 PM   │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  ┌──────────┐                                         │  │
│  │  │ UPCOMING │                                         │  │
│  │  └──────────┘                                         │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │ ● Christmas Day                      Dec 25  🔒 │  │  │
│  │  │   in 71 days                                    │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │ ● New Year's Eve                     Dec 31     │  │  │
│  │  │   in 77 days                                    │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Anatomy of the Star Page

### 1. Page Title

The star icon (★) serves as the page title. No text needed—the symbol is universal.

```swift
Image(systemName: "star.fill")
    .font(.system(size: 24, weight: .bold))
    .foregroundStyle(JohoColors.black)
```

### 2. Bento Header

The classic 情報デザイン bento header with three zones:

```swift
struct StarPageHeader: View {
    let weekNumber: Int
    let monthYear: String
    let dayName: String
    let dayNumber: Int
    var onToday: () -> Void

    var body: some View {
        JohoContainer {
            HStack(spacing: 0) {
                // Zone A: Week number (hero)
                VStack(spacing: JohoSpacing.xs) {
                    Text(String(weekNumber))
                        .font(.johoDisplayLarge)
                        .monospacedDigit()
                        .foregroundStyle(JohoColors.black)

                    Text("WEEK")
                        .font(.johoLabel)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
                .frame(width: 100)
                .padding(.vertical, JohoSpacing.md)
                .overlay(
                    Rectangle()
                        .frame(width: 1.5)
                        .foregroundStyle(JohoColors.black),
                    alignment: .trailing
                )

                // Zone B: Date context
                VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                    Text(monthYear)
                        .font(.johoHeadline)
                        .foregroundStyle(JohoColors.black)

                    Text("\(dayName) \(dayNumber)")
                        .font(.johoBody)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(JohoSpacing.md)
                .overlay(
                    Rectangle()
                        .frame(width: 1.5)
                        .foregroundStyle(JohoColors.black),
                    alignment: .trailing
                )

                // Zone C: Today button
                Button(action: onToday) {
                    Text("TODAY")
                        .font(.johoLabel)
                        .foregroundStyle(JohoColors.black)
                        .padding(.horizontal, JohoSpacing.lg)
                        .padding(.vertical, JohoSpacing.md)
                }
                .background(JohoColors.yellow)
            }
        }
    }
}
```

### 3. Section Boxes

Each content section uses JohoSectionBox with semantic colors:

```swift
// Today's events (cyan)
JohoSectionBox(title: "Today", accentColor: JohoColors.cyan) {
    VStack(spacing: JohoSpacing.sm) {
        ForEach(todayEvents) { event in
            EventCard(event: event)
        }
    }
}

// Upcoming holidays/events (pink)
JohoSectionBox(title: "Upcoming", accentColor: JohoColors.pink) {
    VStack(spacing: JohoSpacing.sm) {
        ForEach(upcomingItems) { item in
            UpcomingCard(item: item)
        }
    }
}
```

### 4. Event Cards

Individual events follow the standard card pattern:

```swift
struct EventCard: View {
    let event: Event

    var body: some View {
        JohoCard {
            HStack(spacing: JohoSpacing.md) {
                // Type indicator
                IndicatorDot(color: event.typeColor, size: 10)

                // Content
                VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                    Text(event.title)
                        .font(.johoHeadline)
                        .foregroundStyle(JohoColors.black)

                    if let subtitle = event.subtitle {
                        Text(subtitle)
                            .font(.johoBodySmall)
                            .foregroundStyle(JohoColors.black.opacity(0.6))
                    }
                }

                Spacer()

                // Time or date
                Text(event.timeString)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }
        }
    }
}
```

### 5. Countdown Display

For upcoming items, show "in X days":

```swift
struct UpcomingCard: View {
    let item: UpcomingItem

    var body: some View {
        JohoCard {
            HStack(spacing: JohoSpacing.md) {
                IndicatorDot(color: item.typeColor, size: 10)

                VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                    Text(item.title)
                        .font(.johoHeadline)
                        .foregroundStyle(JohoColors.black)

                    Text("in \(item.daysUntil) days")
                        .font(.johoBodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }

                Spacer()

                // Date
                Text(item.dateString)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))

                // Lock for system items
                if item.isSystem {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(JohoColors.black.opacity(0.4))
                }
            }
        }
    }
}
```

---

## Complete Star Page Implementation

```swift
struct StarPage: View {
    @StateObject private var viewModel = StarPageViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: JohoSpacing.md) {
                // Page icon
                Image(systemName: "star.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(JohoColors.black)
                    .padding(.bottom, JohoSpacing.sm)

                // Bento header
                StarPageHeader(
                    weekNumber: viewModel.currentWeek,
                    monthYear: viewModel.monthYear,
                    dayName: viewModel.dayName,
                    dayNumber: viewModel.dayNumber,
                    onToday: { viewModel.jumpToToday() }
                )

                // Today section
                if !viewModel.todayEvents.isEmpty {
                    JohoSectionBox(title: "Today", accentColor: JohoColors.cyan) {
                        VStack(spacing: JohoSpacing.sm) {
                            ForEach(viewModel.todayEvents) { event in
                                EventCard(event: event)
                            }
                        }
                    }
                }

                // Empty state for today
                if viewModel.todayEvents.isEmpty {
                    JohoSectionBox(title: "Today", accentColor: JohoColors.cyan) {
                        HStack {
                            Spacer()
                            Text("No events today")
                                .font(.johoBodySmall)
                                .foregroundStyle(JohoColors.black.opacity(0.4))
                            Spacer()
                        }
                        .padding(.vertical, JohoSpacing.lg)
                    }
                }

                // Upcoming section
                JohoSectionBox(title: "Upcoming", accentColor: JohoColors.pink) {
                    VStack(spacing: JohoSpacing.sm) {
                        ForEach(viewModel.upcomingItems.prefix(5)) { item in
                            UpcomingCard(item: item)
                        }
                    }
                }

                // Notes section (if any)
                if let todayNote = viewModel.todayNote {
                    JohoSectionBox(title: "Note", accentColor: JohoColors.yellow) {
                        Text(todayNote.content)
                            .font(.johoBody)
                            .foregroundStyle(JohoColors.black)
                    }
                }
            }
            .padding(.horizontal, JohoSpacing.lg)
            .padding(.top, JohoSpacing.sm)  // Max 8pt!
            .padding(.bottom, JohoSpacing.xxxl)
        }
        .background(JohoColors.white)
        .onAppear {
            viewModel.load(context: modelContext)
        }
    }
}
```

---

## What Makes It a Golden Standard

### Every 情報デザイン Principle Visible

The Star Page demonstrates:

| Principle | Where It Appears |
|-----------|------------------|
| **Semantic colors** | Section header pills, indicator dots |
| **Border hierarchy** | 3pt containers, 1.5pt cards, 1pt separators |
| **Typography scale** | displayLarge (week), headline (events), body, label |
| **Spacing system** | Consistent 4/8/12/16pt gaps |
| **Squircle corners** | All containers |
| **Japanese symbols** | Star icon, indicator dots |
| **Maximum 8pt top padding** | Content starts immediately |

### No Exceptions

The Star Page doesn't bend any rules. Every other screen can point to it and say "do it like this."

### Living Documentation

When the design system evolves, the Star Page gets updated first. It's the truth source that auto-documents through example.

---

## How to Use a Star Page

### For Developers

1. **Study it first.** Before building any new screen, read the Star Page code.
2. **Copy patterns.** Don't reinvent—lift patterns directly.
3. **Compare your work.** Does your new screen have the same visual weight as the Star Page?

### For Designers

1. **Screenshot it.** Use it as reference when designing new features.
2. **Test against it.** Does your new design feel consistent with the Star Page?
3. **Propose changes carefully.** Changing the Star Page changes everything.

### For Code Review

1. **Ask: "Is this consistent with the Star Page?"**
2. **Check borders, colors, spacing against the reference.**
3. **Reject deviations without clear justification.**

---

## Creating Your Own Star Page

Every app implementing 情報デザイン should have a Star Page. Here's how to create one:

### Step 1: Choose the Right Screen

Pick a screen that:
- Users visit frequently
- Contains multiple component types
- Has both data display and interaction

### Step 2: Implement Every Pattern

Include at least:
- [ ] Bento header (or equivalent hero section)
- [ ] Section boxes with semantic colors
- [ ] Cards with indicator dots
- [ ] Interactive elements (buttons, toggles)
- [ ] Empty states
- [ ] Proper spacing throughout

### Step 3: Annotate the Code

Add comments explaining the "why":

```swift
// STAR PAGE: This spacing demonstrates the 8pt maximum top padding rule
.padding(.top, JohoSpacing.sm)

// STAR PAGE: Section boxes use semantic colors to indicate content type
JohoSectionBox(title: "Today", accentColor: JohoColors.cyan)

// STAR PAGE: Every card has exactly 12pt internal padding
.padding(JohoSpacing.md)
```

### Step 4: Keep It Updated

When you change the design system:
1. Update the Star Page first
2. Verify it still works
3. Use it as the template for updating other screens

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│           情報デザイン STAR PAGE REFERENCE                   │
│                                                             │
│   PURPOSE:                                                 │
│   • Reference implementation                               │
│   • Teaching document as UI                                │
│   • Living documentation                                   │
│                                                             │
│   REQUIRED ELEMENTS:                                       │
│   • Bento header                                           │
│   • Section boxes with semantic colors                     │
│   • Cards with indicator dots                              │
│   • Interactive elements                                   │
│   • Empty states                                           │
│   • Proper spacing (8pt max top padding)                   │
│                                                             │
│   USAGE:                                                   │
│   • Study before building                                  │
│   • Copy patterns directly                                 │
│   • Compare new work against it                            │
│   • Update first when system changes                       │
│                                                             │
│   MANTRA: "Do it like the Star Page"                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 16 — Before & After Transformations*



---


# Chapter 16: Before & After Transformations

> "Every interface can be clarified. Every element can be sharpened."

---

This chapter shows side-by-side transformations—common iOS patterns converted to 情報デザイン. Each example identifies what's wrong with the "before" and explains exactly how the "after" fixes it.

---

## Transformation 1: Settings Row

### Before (Standard iOS)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Notifications                              [Toggle ON]    │
│                                                             │
│   ─────────────────────────────────────────────────────── │
│                                                             │
│   Sound Effects                              [Toggle OFF]   │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Problems:
• No borders (violates 情報デザイン core principle)
• Gray separator instead of clear structure
• Toggle blends into background
• No container definition
```

### After (情報デザイン)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │   Notifications                ┌────────────────┐   │   │
│  │                                │            ●   │   │   │
│  │                                └────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │   Sound Effects                ┌────────────────┐   │   │
│  │                                │  ○             │   │   │
│  │                                └────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Fixes:
• 1.5pt border around each row
• Toggle has 2pt border with clear on/off visual
• ON state uses semantic cyan background
• Each row is a distinct container
```

### Code

```swift
// ❌ BEFORE
Toggle("Notifications", isOn: $notifications)

// ✅ AFTER
JohoToggleRow(title: "Notifications", isOn: $notifications)
```

---

## Transformation 2: List Card

### Before (Generic Card)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│    ╭──────────────────────────────────────────────────╮    │
│    │                                                  │    │
│    │   🗓️ Team Meeting                               │    │
│    │   9:00 AM - Conference Room A                   │    │
│    │                                                  │    │
│    │   ─────────────────────────────────             │    │
│    │   🗓️ Client Call                                │    │
│    │   2:00 PM - Virtual                             │    │
│    │                                                  │    │
│    ╰──────────────────────────────────────────────────╯    │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Problems:
• Rounded corners without continuous path (visual inconsistency)
• Emoji (forbidden—platform-dependent colors)
• Shadow/depth effect (violates flat aesthetic)
• Items share container (unclear boundaries)
• Gray separator
```

### After (情報デザイン)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ● Team Meeting                            9:00 AM > │   │
│  │   Conference Room A                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ● Client Call                             2:00 PM > │   │
│  │   Virtual                                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Fixes:
• Squircle corners (style: .continuous)
• Colored indicator dot instead of emoji
• Each item is own card with 1.5pt border
• No shadow—borders define depth
• Chevron indicates navigation
```

### Code

```swift
// ❌ BEFORE
ForEach(events) { event in
    HStack {
        Text("🗓️")
        VStack(alignment: .leading) {
            Text(event.title)
            Text(event.location)
                .foregroundColor(.gray)
        }
    }
}
.padding()
.background(.white)
.cornerRadius(12)
.shadow(radius: 4)

// ✅ AFTER
ForEach(events) { event in
    JohoCard {
        HStack(spacing: JohoSpacing.md) {
            IndicatorDot(color: JohoColors.cyan, size: 10)

            VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                Text(event.title)
                    .font(.johoHeadline)

                Text(event.location)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }

            Spacer()

            Text(event.timeString)
                .font(.johoBodySmall)
                .foregroundStyle(JohoColors.black.opacity(0.6))

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(JohoColors.black.opacity(0.4))
        }
    }
}
```

---

## Transformation 3: Button Group

### Before (iOS Standard)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│         ╭───────────╮       ╭───────────╮                  │
│         │  Cancel   │       │   Save    │                  │
│         ╰───────────╯       ╰───────────╯                  │
│                                                             │
│         Gray text           Blue fill                      │
│         No border           System blue                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Problems:
• System blue (not semantic)
• Cancel has no visual weight
• Different button styles create imbalance
• No borders
```

### After (情報デザイン)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│       ┌───────────────┐    ┌───────────────┐              │
│       │    Cancel     │    │     Save      │              │
│       └───────────────┘    └───────────────┘              │
│                                                             │
│       White bg             Black bg                        │
│       Black text           White text                      │
│       2pt border           2pt border                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Fixes:
• Both buttons have 2pt borders
• Cancel is secondary (white bg)
• Save is primary (black bg)
• Equal visual weight, clear hierarchy
• 12pt spacing between buttons
```

### Code

```swift
// ❌ BEFORE
HStack {
    Button("Cancel") { dismiss() }
        .foregroundColor(.gray)
    Button("Save") { save() }
        .buttonStyle(.borderedProminent)
}

// ✅ AFTER
HStack(spacing: JohoSpacing.md) {
    JohoButton(title: "Cancel", action: { dismiss() }, style: .secondary)
    JohoButton(title: "Save", action: { save() }, style: .primary)
}
```

---

## Transformation 4: Header

### Before (Typical App Header)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                                                             │
│                                                             │
│         Week 42                                             │
│         October 2026                                        │
│                                                             │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Problems:
• 40pt+ top padding (wasted space)
• No visual structure
• Week number isn't prominent
• Light font weight (whispers instead of speaks)
```

### After (情報デザイン Bento Header)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ ┌──────────┬────────────────────────────┬───────────┐ │  │
│  │ │          │                            │           │ │  │
│  │ │    42    │     October 2026           │   TODAY   │ │  │
│  │ │          │     Wednesday 15           │           │ │  │
│  │ │   WEEK   │                            │           │ │  │
│  │ └──────────┴────────────────────────────┴───────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Fixes:
• 8pt top padding (maximum allowed)
• 48pt heavy week number (hero display)
• Compartmentalized bento zones
• 3pt container border
• TODAY action button with 2pt border
```

---

## Transformation 5: Empty State

### Before (Minimal Empty State)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                    No events                                │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Problems:
• Just text—no visual design
• No container
• Light gray text (low contrast)
• No guidance for user
```

### After (情報デザイン Empty State)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                                                       │  │
│  │                        📅                             │  │
│  │                                                       │  │
│  │                   No Events                           │  │
│  │                                                       │  │
│  │         Events you create will appear here           │  │
│  │                                                       │  │
│  │               ┌─────────────────┐                    │  │
│  │               │   Add Event     │                    │  │
│  │               └─────────────────┘                    │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Fixes:
• 3pt container border
• SF Symbol icon (not emoji)
• Bold headline "No Events"
• Helpful subtitle explaining context
• Call-to-action button with 2pt border
```

---

## Transformation 6: Tab Bar

### Before (iOS Standard Tab Bar)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                     CONTENT                                 │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│     🏠        📅        ⚙️        👤                       │
│    Home     Calendar  Settings   Profile                   │
│                                                             │
│    Blue       Gray      Gray      Gray                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Problems:
• System blue for selection (not semantic)
• Gray for unselected (low contrast)
• No visual structure
• Items float without definition
```

### After (情報デザイン Tab Bar)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                     CONTENT                                 │
│                                                             │
├━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┤
│                                                             │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │
│  │  ★      │  │   📅    │  │   ⚙    │  │   👤    │       │
│  │  Home   │  │Calendar │  │Settings │  │Profile  │       │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘       │
│                                                             │
│  Yellow bg    White bg     White bg     White bg           │
│  2pt border   No border    No border    No border          │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Fixes:
• 3pt top border separating content from nav
• Selected tab has yellow background + 2pt border
• All tabs have black icons/text
• Clear visual indication of current location
```

---

## Transformation 7: Form Section

### Before (Standard Form)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Event Details                                             │
│                                                             │
│   Title  ___________________________________                │
│                                                             │
│   Date   ___________________________________                │
│                                                             │
│   Notes  ___________________________________                │
│          ___________________________________                │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Problems:
• Section header just text (no visual weight)
• Form fields have no defined boundaries
• No indication of required vs optional
• Light appearance throughout
```

### After (情報デザイン Form)

```
┌─────────────────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────────────────┐  │
│  │ █████████████████████████████████████████████████████ │  │
│  │ █               EVENT DETAILS                       █ │  │
│  │ █████████████████████████████████████████████████████ │  │
│  │                                                       │  │
│  │   Title                                               │  │
│  │   ┌─────────────────────────────────────────────┐    │  │
│  │   │  Event name...                              │    │  │
│  │   └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  │   Date                                                │  │
│  │   ┌─────────────────────────────────────────────┐    │  │
│  │   │  Select date...                             │    │  │
│  │   └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  │   Notes                                               │  │
│  │   ┌─────────────────────────────────────────────┐    │  │
│  │   │  Optional notes...                          │    │  │
│  │   │                                             │    │  │
│  │   └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

Fixes:
• Black header bar with white uppercase text
• 2pt border around entire section
• Each input field has 2pt border
• Label above each field
• Clear container boundary
```

---

## Transformation Summary

| Element | Before Problem | After Solution |
|---------|----------------|----------------|
| **Borders** | Missing or gray | Black, weight varies by hierarchy |
| **Colors** | System blue, emoji colors | Semantic palette only |
| **Corners** | .cornerRadius() | RoundedRectangle(.continuous) |
| **Spacing** | Arbitrary values | 4pt grid system |
| **Typography** | System defaults | .design(.rounded), medium+ weight |
| **Top padding** | 32-40pt | Maximum 8pt |
| **Depth** | Shadows, blur | Borders only |
| **Icons** | Emoji | SF Symbols |

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│           情報デザイン TRANSFORMATION CHECKLIST              │
│                                                             │
│   □ Does every container have a black border?              │
│   □ Are all corners continuous (.squircle)?                │
│   □ Are colors from the semantic palette only?             │
│   □ Is top padding ≤ 8pt?                                  │
│   □ Are all spacing values on the 4pt grid?                │
│   □ Is typography using .design(.rounded)?                 │
│   □ Are font weights ≥ .medium?                            │
│   □ Are labels uppercase?                                  │
│   □ Are icons SF Symbols (not emoji)?                      │
│   □ Are shadows and blur effects removed?                  │
│   □ Do buttons have 2pt borders?                           │
│   □ Do selected states have 2.5pt borders?                 │
│   □ Do touch targets meet 44×44pt minimum?                 │
│                                                             │
│   If any answer is NO, transform it.                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

*Next: Part 5 — Implementation*



---


# Chapter 17: SwiftUI Code Patterns

> "Good code is consistent code. Design systems enable both."

---

This chapter provides production-ready SwiftUI code for implementing 情報デザイン. Copy these patterns directly into your projects—they're tested, complete, and follow every principle.

---

## Foundation: JohoColors

Every color in the system:

```swift
import SwiftUI

struct JohoColors {
    // Core
    static let black = Color(hex: "000000")
    static let white = Color(hex: "FFFFFF")

    // Semantic - Time/State
    static let yellow = Color(hex: "FFE566")  // Today, Now, Current

    // Semantic - Content Types
    static let cyan = Color(hex: "A5F3FC")    // Events, Meetings
    static let pink = Color(hex: "FECDD3")    // Holidays, Special days
    static let orange = Color(hex: "FED7AA")  // Trips, Travel
    static let green = Color(hex: "BBF7D0")   // Expenses, Money
    static let purple = Color(hex: "E9D5FF")  // Contacts, People

    // Semantic - Status
    static let red = Color(hex: "E53935")     // Warning, Danger, Sunday
}

// Hex color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
```

---

## Foundation: JohoSpacing

The 4pt grid:

```swift
struct JohoSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}
```

---

## Foundation: Typography

Font extensions for the type scale:

```swift
extension Font {
    static let johoDisplayLarge = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let johoDisplayMedium = Font.system(size: 32, weight: .bold, design: .rounded)
    static let johoHeadline = Font.system(size: 18, weight: .bold, design: .rounded)
    static let johoBody = Font.system(size: 16, weight: .medium, design: .rounded)
    static let johoBodySmall = Font.system(size: 14, weight: .medium, design: .rounded)
    static let johoLabel = Font.system(size: 12, weight: .bold, design: .rounded)
    static let johoLabelSmall = Font.system(size: 10, weight: .bold, design: .rounded)
}
```

---

## Component: JohoContainer

The base container with 3pt border:

```swift
struct JohoContainer<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    var borderWidth: CGFloat = 3
    var padding: CGFloat = 12

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: borderWidth)
            )
    }
}
```

---

## Component: JohoCard

Content cards with 1.5pt border:

```swift
struct JohoCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(JohoSpacing.md)
            .background(JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: 1.5)
            )
    }
}
```

---

## Component: JohoButton

Buttons in three styles:

```swift
struct JohoButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .secondary
    var isEnabled: Bool = true

    enum ButtonStyle {
        case primary    // Black background, white text
        case secondary  // White background, black text
        case destructive // Red background, white text
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.johoBody)
                .fontWeight(.medium)
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(minWidth: 44, minHeight: 44)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(JohoColors.black, lineWidth: 2)
                )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return JohoColors.black
        case .secondary: return JohoColors.white
        case .destructive: return JohoColors.red
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return JohoColors.white
        case .secondary: return JohoColors.black
        case .destructive: return JohoColors.white
        }
    }
}
```

---

## Component: JohoIconButton

Icon-only buttons:

```swift
struct JohoIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(JohoColors.black)
                .frame(width: size, height: size)
                .background(JohoColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(JohoColors.black, lineWidth: 2)
                )
        }
    }
}
```

---

## Component: JohoToggle

Custom toggle control:

```swift
struct JohoToggle: View {
    @Binding var isOn: Bool
    var accentColor: Color = JohoColors.cyan

    var body: some View {
        Button(action: { isOn.toggle() }) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isOn ? accentColor : JohoColors.white)
                .frame(width: 52, height: 32)
                .overlay(
                    Circle()
                        .fill(JohoColors.white)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
                        .offset(x: isOn ? 10 : -10)
                    , alignment: isOn ? .trailing : .leading
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(JohoColors.black, lineWidth: 2)
                )
                .animation(.easeInOut(duration: 0.15), value: isOn)
        }
        .buttonStyle(.plain)
    }
}
```

---

## Component: JohoToggleRow

Toggle with label:

```swift
struct JohoToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var subtitle: String? = nil

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                Text(title)
                    .font(.johoBody)
                    .foregroundStyle(JohoColors.black)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.johoBodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }

            Spacer()

            JohoToggle(isOn: $isOn)
        }
        .padding(JohoSpacing.md)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }
}
```

---

## Component: JohoTextField

Text input field:

```swift
struct JohoTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.johoBody)
            .foregroundStyle(JohoColors.black)
            .padding(JohoSpacing.md)
            .background(JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: isFocused ? 2.5 : 2)
            )
            .focused($isFocused)
    }
}
```

---

## Component: JohoSectionBox

Section with colored header pill:

```swift
struct JohoSectionBox<Content: View>: View {
    let title: String
    let accentColor: Color
    let content: Content

    init(title: String, accentColor: Color = JohoColors.black, @ViewBuilder content: () -> Content) {
        self.title = title
        self.accentColor = accentColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: JohoSpacing.md) {
            // Header pill
            Text(title.uppercased())
                .font(.johoLabel)
                .foregroundStyle(JohoColors.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            // Content
            content
        }
        .padding(JohoSpacing.md)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
        )
    }
}
```

---

## Component: JohoIndicator

Colored indicator dot:

```swift
struct JohoIndicator: View {
    let color: Color
    var size: CGFloat = 10
    var borderWidth: CGFloat = 1.5

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(JohoColors.black, lineWidth: borderWidth)
            )
    }
}
```

---

## Component: JohoListRow

Standard list row:

```swift
struct JohoListRow: View {
    let title: String
    var subtitle: String? = nil
    var indicatorColor: Color? = nil
    var trailing: String? = nil
    var showChevron: Bool = true
    var isLocked: Bool = false

    var body: some View {
        HStack(spacing: JohoSpacing.md) {
            if let color = indicatorColor {
                JohoIndicator(color: color)
            }

            VStack(alignment: .leading, spacing: JohoSpacing.xs) {
                Text(title)
                    .font(.johoHeadline)
                    .foregroundStyle(JohoColors.black)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.johoBodySmall)
                        .foregroundStyle(JohoColors.black.opacity(0.6))
                }
            }

            Spacer()

            if let trailing = trailing {
                Text(trailing)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            } else if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(JohoColors.black.opacity(0.4))
            }
        }
        .padding(JohoSpacing.md)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 1.5)
        )
    }
}
```

---

## Component: JohoEmptyState

Empty state display:

```swift
struct JohoEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: JohoSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(JohoColors.black.opacity(0.3))

            VStack(spacing: JohoSpacing.sm) {
                Text(title)
                    .font(.johoHeadline)
                    .foregroundStyle(JohoColors.black)

                Text(message)
                    .font(.johoBodySmall)
                    .foregroundStyle(JohoColors.black.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                JohoButton(title: actionTitle, action: action, style: .primary)
            }
        }
        .padding(JohoSpacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JohoColors.black, lineWidth: 3)
        )
    }
}
```

---

## View Modifier: JohoCardStyle

Reusable card styling:

```swift
struct JohoCardModifier: ViewModifier {
    var borderWidth: CGFloat = 1.5
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(JohoSpacing.md)
            .background(JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: borderWidth)
            )
    }
}

extension View {
    func johoCard(borderWidth: CGFloat = 1.5, cornerRadius: CGFloat = 12) -> some View {
        modifier(JohoCardModifier(borderWidth: borderWidth, cornerRadius: cornerRadius))
    }
}

// Usage
Text("Content")
    .johoCard()
```

---

## View Modifier: JohoContainerStyle

Reusable container styling:

```swift
struct JohoContainerModifier: ViewModifier {
    var borderWidth: CGFloat = 3
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(JohoColors.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: borderWidth)
            )
    }
}

extension View {
    func johoContainer(borderWidth: CGFloat = 3, cornerRadius: CGFloat = 16, padding: CGFloat = 12) -> some View {
        modifier(JohoContainerModifier(borderWidth: borderWidth, cornerRadius: cornerRadius, padding: padding))
    }
}
```

---

## Complete Example: Settings Page

Combining all components:

```swift
struct SettingsPage: View {
    @State private var notifications = true
    @State private var soundEffects = false
    @State private var weekStartsMonday = true

    var body: some View {
        ScrollView {
            VStack(spacing: JohoSpacing.md) {
                // General section
                JohoSectionBox(title: "General", accentColor: JohoColors.black) {
                    VStack(spacing: JohoSpacing.sm) {
                        JohoToggleRow(
                            title: "Notifications",
                            isOn: $notifications,
                            subtitle: "Receive daily reminders"
                        )

                        JohoToggleRow(
                            title: "Sound Effects",
                            isOn: $soundEffects
                        )

                        JohoToggleRow(
                            title: "Week Starts Monday",
                            isOn: $weekStartsMonday,
                            subtitle: "ISO 8601 standard"
                        )
                    }
                }

                // About section
                JohoSectionBox(title: "About", accentColor: JohoColors.cyan) {
                    VStack(spacing: JohoSpacing.sm) {
                        JohoListRow(
                            title: "Version",
                            trailing: "2.0.0",
                            showChevron: false
                        )

                        JohoListRow(
                            title: "Privacy Policy",
                            trailing: nil
                        )

                        JohoListRow(
                            title: "Terms of Service",
                            trailing: nil
                        )
                    }
                }
            }
            .padding(.horizontal, JohoSpacing.lg)
            .padding(.top, JohoSpacing.sm)  // Max 8pt!
        }
        .background(JohoColors.white)
    }
}
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│           情報デザイン SWIFTUI COMPONENTS                    │
│                                                             │
│   FOUNDATION:                                              │
│   • JohoColors - Semantic color palette                    │
│   • JohoSpacing - 4pt grid tokens                          │
│   • Font extensions - Typography scale                     │
│                                                             │
│   CONTAINERS:                                              │
│   • JohoContainer - 3pt border, 16pt radius               │
│   • JohoCard - 1.5pt border, 12pt radius                  │
│   • JohoSectionBox - With colored header pill              │
│                                                             │
│   INTERACTIVE:                                             │
│   • JohoButton - Primary/Secondary/Destructive             │
│   • JohoIconButton - Icon-only buttons                     │
│   • JohoToggle - Custom toggle control                     │
│   • JohoTextField - Text input                             │
│                                                             │
│   DISPLAY:                                                 │
│   • JohoListRow - Standard list item                       │
│   • JohoIndicator - Colored dot                            │
│   • JohoEmptyState - Empty state display                   │
│                                                             │
│   MODIFIERS:                                               │
│   • .johoCard() - Apply card styling                       │
│   • .johoContainer() - Apply container styling             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

*Next: Chapter 18 — Design Audit Checklist*



---


# Chapter 18: Design Audit Checklist

> "Ship nothing that violates the system."

---

Every 情報デザイン interface should pass a comprehensive audit before release. This chapter provides the checklist, the tools to find violations, and the standards for compliance.

---

## The Complete Audit Checklist

### Borders

- [ ] **Every container has a border**
  - No borderless cards or sections
  - Containers: 3pt
  - Cards: 1.5pt
  - Buttons: 2pt
  - Selected states: 2.5pt
  - Grid cells: 1pt

- [ ] **All borders are black (#000000)**
  - No gray borders
  - No colored borders (except state indication)
  - No gradients on borders

### Colors

- [ ] **Only semantic palette colors used**
  - Yellow: Today/Now
  - Cyan: Events
  - Pink: Holidays
  - Orange: Trips
  - Green: Expenses
  - Purple: Contacts
  - Red: Warnings/Sunday
  - Black/White: Structure

- [ ] **No system colors**
  - No Color.blue
  - No Color.accentColor
  - No Color.primary
  - Use JohoColors exclusively

- [ ] **No emoji**
  - Replace all emoji with SF Symbols
  - Icons are monochrome

### Corners

- [ ] **All corners use .continuous style**
  - `.clipShape(RoundedRectangle(cornerRadius: X, style: .continuous))`
  - Never `.cornerRadius(X)`
  - Never `.clipShape(Circle())` for non-circular elements

- [ ] **Consistent radii within hierarchy**
  - Containers: 16pt
  - Cards: 12pt
  - Buttons: 8pt
  - Pills/badges: 6pt

### Typography

- [ ] **All fonts use .design(.rounded)**
  - `.font(.system(size: X, weight: Y, design: .rounded))`
  - Never plain `.font(.system(size: X))`
  - Never `.font(.body)` etc.

- [ ] **No light or thin weights**
  - Minimum weight: .medium
  - Headlines: .bold
  - Hero: .heavy

- [ ] **Labels are uppercase**
  - All pills, badges, section headers
  - `.textCase(.uppercase)` or direct "UPPERCASE"

- [ ] **Numbers use monospacedDigit()**
  - Week numbers
  - Dates
  - Prices
  - Any columnar data

### Spacing

- [ ] **All spacing on 4pt grid**
  - 4, 8, 12, 16, 20, 24, 32...
  - Never 5, 7, 10, 15...
  - Use JohoSpacing constants

- [ ] **Maximum 8pt top padding**
  - `.padding(.top, 8)` maximum
  - Never 16, 20, 32, 40...
  - Content starts immediately

- [ ] **Minimum 12pt between buttons**
  - Adjacent tap targets well-separated
  - Use JohoSpacing.md (12pt)

### Touch Targets

- [ ] **Minimum 44×44pt for all interactive elements**
  - `.frame(minWidth: 44, minHeight: 44)`
  - Small icons can be 16-20pt visually
  - Touch area must extend to 44pt

### Effects

- [ ] **No glass/blur effects**
  - No .ultraThinMaterial
  - No .blur()
  - No .opacity() for blur simulation

- [ ] **No shadows**
  - No .shadow()
  - Depth comes from borders only

- [ ] **No gradients**
  - No LinearGradient
  - No RadialGradient
  - Flat colors only

### Interaction

- [ ] **Swipe actions follow pattern**
  - Right swipe → Edit (Cyan)
  - Left swipe → Delete (Red)
  - System items (🔒) have no swipe

- [ ] **Selection uses 2.5pt border + yellow.opacity(0.3)**
  - Clear visual feedback
  - Consistent across all selectable items

---

## Audit Commands

Run these commands in your project directory to find violations:

### Find missing .rounded

```bash
grep -rn "\.font(\.system(" --include="*.swift" | \
  grep -v "design: .rounded"
```

### Find raw colors

```bash
grep -rn "Color\.blue\|Color\.red\|Color\.accentColor" --include="*.swift"
```

### Find non-continuous corners

```bash
grep -rn "\.cornerRadius(" --include="*.swift"
```

### Find glass effects

```bash
grep -rn "ultraThinMaterial\|\.blur(" --include="*.swift"
```

### Find shadows

```bash
grep -rn "\.shadow(" --include="*.swift"
```

### Find gradients

```bash
grep -rn "LinearGradient\|RadialGradient" --include="*.swift"
```

### Find excessive top padding

```bash
grep -rn "\.padding(\.top," --include="*.swift" | \
  grep -v "\.top, 4\|\.top, 8"
```

### Find emoji in code

```bash
grep -rP "[\x{1F300}-\x{1F9FF}]" --include="*.swift"
```

---

## Automated Audit Script

Save this as `audit-joho.sh`:

```bash
#!/bin/bash

echo "🔍 情報デザイン Design Audit"
echo "=========================="
echo ""

# Colors
echo "📌 Checking for raw colors..."
RAW_COLORS=$(grep -rn "Color\.blue\|Color\.red\|Color\.accentColor\|Color\.primary" --include="*.swift" 2>/dev/null | wc -l)
if [ "$RAW_COLORS" -gt 0 ]; then
    echo "❌ Found $RAW_COLORS raw color references"
    grep -rn "Color\.blue\|Color\.red\|Color\.accentColor\|Color\.primary" --include="*.swift"
else
    echo "✅ No raw colors found"
fi
echo ""

# Rounded fonts
echo "📌 Checking for non-rounded fonts..."
NON_ROUNDED=$(grep -rn "\.font(\.system(" --include="*.swift" 2>/dev/null | grep -v "design: .rounded" | wc -l)
if [ "$NON_ROUNDED" -gt 0 ]; then
    echo "❌ Found $NON_ROUNDED fonts without .rounded"
else
    echo "✅ All fonts use .rounded"
fi
echo ""

# Corners
echo "📌 Checking for non-continuous corners..."
BAD_CORNERS=$(grep -rn "\.cornerRadius(" --include="*.swift" 2>/dev/null | wc -l)
if [ "$BAD_CORNERS" -gt 0 ]; then
    echo "❌ Found $BAD_CORNERS uses of .cornerRadius()"
else
    echo "✅ All corners use .continuous style"
fi
echo ""

# Effects
echo "📌 Checking for forbidden effects..."
EFFECTS=$(grep -rn "ultraThinMaterial\|\.blur(\|\.shadow(\|LinearGradient\|RadialGradient" --include="*.swift" 2>/dev/null | wc -l)
if [ "$EFFECTS" -gt 0 ]; then
    echo "❌ Found $EFFECTS forbidden effects"
else
    echo "✅ No glass, blur, shadow, or gradient effects"
fi
echo ""

echo "Audit complete."
```

Run with:
```bash
chmod +x audit-joho.sh
./audit-joho.sh
```

---

## Pre-Commit Hook

Add this to `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# 情報デザイン pre-commit hook
VIOLATIONS=0

# Check for raw colors
if grep -rn "Color\.blue\|Color\.accentColor" --include="*.swift" > /dev/null 2>&1; then
    echo "❌ Commit blocked: Raw colors found (use JohoColors)"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Check for non-rounded fonts
if grep -rn "\.font(\.system(" --include="*.swift" 2>/dev/null | grep -v "design: .rounded" > /dev/null; then
    echo "❌ Commit blocked: Fonts without .rounded found"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Check for .cornerRadius
if grep -rn "\.cornerRadius(" --include="*.swift" > /dev/null 2>&1; then
    echo "❌ Commit blocked: Use RoundedRectangle(style: .continuous)"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Check for forbidden effects
if grep -rn "ultraThinMaterial\|\.shadow(" --include="*.swift" > /dev/null 2>&1; then
    echo "❌ Commit blocked: Forbidden effects found"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

if [ "$VIOLATIONS" -gt 0 ]; then
    echo ""
    echo "Run ./audit-joho.sh for details"
    exit 1
fi

echo "✅ 情報デザイン compliance check passed"
exit 0
```

---

## Code Review Standards

When reviewing 情報デザイン code, verify:

### Level 1: Structural (Must Pass)

1. Every container has a black border
2. All corners use `.continuous` style
3. No forbidden effects (blur, shadow, gradient)
4. No raw Color values

### Level 2: Typography (Must Pass)

1. All fonts use `.design(.rounded)`
2. No weights below `.medium`
3. Labels are uppercase
4. Numbers use `.monospacedDigit()`

### Level 3: Spacing (Must Pass)

1. All values on 4pt grid
2. Top padding ≤ 8pt
3. Touch targets ≥ 44pt
4. Button spacing ≥ 12pt

### Level 4: Semantics (Should Pass)

1. Colors match content meaning
2. Border weights match hierarchy
3. Swipe actions follow convention
4. Selection states consistent

---

## Common Violation Patterns

### "It looks fine without borders"

**No.** Borders are not optional. If you think something looks cleaner without a border, you're designing for a different system.

### "I used a slightly different blue"

**No.** Use the semantic color that matches the content type. If there's no matching color, the content type doesn't belong in this interface.

### "The top padding felt cramped"

**No.** Content starts at the top. Users expect information immediately. Every pixel of top padding delays content.

### "I made the font lighter for hierarchy"

**No.** Use size and position for hierarchy, not weight. The minimum weight is `.medium`.

### "I added a subtle shadow for depth"

**No.** Borders create depth. Shadows create visual noise. Remove all shadows.

---

## Appendix A: Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│              情報デザイン QUICK REFERENCE                    │
│                                                             │
│   BORDERS:                                                 │
│   Containers  3pt    Cards      1.5pt                      │
│   Buttons     2pt    Selected   2.5pt                      │
│   Cells       1pt                                          │
│                                                             │
│   COLORS:                                                  │
│   Yellow  #FFE566  Today     Cyan    #A5F3FC  Events       │
│   Pink    #FECDD3  Holidays  Orange  #FED7AA  Trips        │
│   Green   #BBF7D0  Money     Purple  #E9D5FF  People       │
│   Red     #E53935  Warning   Black/White: Structure        │
│                                                             │
│   TYPOGRAPHY:                                              │
│   displayLarge   48pt  heavy   displayMedium  32pt  bold   │
│   headline       18pt  bold    body           16pt  medium │
│   bodySmall      14pt  medium  label          12pt  bold   │
│   labelSmall     10pt  bold    ALL: .design(.rounded)      │
│                                                             │
│   SPACING:                                                 │
│   xs  4pt   sm  8pt   md  12pt  lg  16pt                  │
│   xl 20pt  xxl 24pt  xxxl 32pt                            │
│                                                             │
│   RULES:                                                   │
│   • Max 8pt top padding                                    │
│   • Min 44×44pt touch targets                              │
│   • Min 12pt between buttons                               │
│   • Always .continuous corners                             │
│   • Never shadow/blur/gradient                             │
│   • Never emoji                                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Appendix B: Border Width Decision Tree

```
Is it interactive (button, toggle, input)?
├── YES → 2pt border
│         Is it selected/focused?
│         └── YES → 2.5pt border
└── NO → Is it a major container (screen-level)?
         ├── YES → 3pt border
         └── NO → Is it a card or row?
                  ├── YES → 1.5pt border
                  └── NO → Is it a grid cell?
                           ├── YES → 1pt border
                           └── NO → 1.5pt border (default)
```

---

## Appendix C: Color Decision Tree

```
What type of content is this?

Time/State related (today, now, current)?
└── Yellow #FFE566

Events, meetings, appointments?
└── Cyan #A5F3FC

Holidays, special days, observances?
└── Pink #FECDD3

Travel, trips, vacation?
└── Orange #FED7AA

Money, expenses, financial?
└── Green #BBF7D0

People, contacts, birthdays?
└── Purple #E9D5FF

Warning, danger, error, Sunday?
└── Red #E53935

Structure, text, borders?
└── Black #000000 or White #FFFFFF

None of the above?
└── Don't add color. Use black/white.
```

---

## Conclusion

情報デザイン is not about aesthetics—it's about communication. Every border, every color, every pixel serves the goal of making information instantly comprehensible.

The rules are strict because consistency is clarity. When every interface follows the same patterns, users don't have to learn each screen. They recognize the language.

Ship nothing that violates the system. Run the audit. Fix the violations. Then ship with confidence.

Your interfaces will be clear, consistent, and instantly understandable—like the best Japanese train station signage, the clearest emergency instructions, the most functional everyday objects.

That's 情報デザイン.

---

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                         終                                  │
│                        (END)                                │
│                                                             │
│                    情報デザイン                              │
│              Information Design for iOS                     │
│                                                             │
│                                                             │
│        "Clear information serves all people."              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```



---


