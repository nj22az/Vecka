# JDS-REF-SFW-001 — Japanese Packaging Information Design

**Doc No:** JDS-REF-SFW-001
**Rev:** B
**Status:** CURRENT
**Date:** 2026-05-30
**Author:** Nils Johansson
**Type:** Reference (design source material, not normative engineering spec)

---

This reference document captures the Japanese consumer-packaging information-design tradition that informs Onsen Planner's shareable cards, fact boxes, day-summary exports and detail sheets. It is the authoritative source for **why** those components look the way they do.

For the normative engineering spec (which Swift components implement which template, where they live), see [`JDS-MAN-SFW-001 §12`](JDS-MAN-SFW-001_joho-design-system.md).

The full source material follows.

---

## Japanese Information Design Logic Guide
### Bento-Box Structure + Color Meaning + Color Combinations

**Purpose**: This is the complete system for structuring and coloring information the way Japanese designers actually do it. Use this to create authentic, professional English labels and text boxes.

---

### 1. The Fundamental Principle

Japanese information design is built on two layers:

**Layer 1 – Structure (The Bento Box)**
Every piece of information lives in its own clear, bordered compartment. The order is almost always the same (7 compartments). This creates calm, high-density, scannable information.

**Layer 2 – Color Meaning**
Color is never decorative. Every color (and every color combination) carries a specific, culturally understood meaning. Color tells the reader instantly what *kind* of information they are looking at.

Master both layers and your designs will feel genuinely Japanese.

---

### 2. The 7-Compartment Bento Structure (Fixed Order)

Japanese product labels almost always follow this exact sequence:

| # | Compartment                  | Purpose                              | Typical Color Treatment                     |
|---|------------------------------|--------------------------------------|---------------------------------------------|
| 1 | Catchy Hook / Slogan         | Grab attention                       | Blue header bar + white bold text           |
| 2 | Feature / Technology         | Highlight special method or benefit  | Teal, Green, or light Blue box              |
| 3 | Ingredients + Allergens      | Full list + clear allergen callout   | White background + Blue text + Red sub-box  |
| 4 | Nutrition Facts              | Easy-to-scan table                   | Clean table with Blue headers               |
| 5 | Manufacturer & Dates         | Trust + legal information            | White box + Blue text + Yellow highlight    |
| 6 | Warning Box                  | Safety / legal requirements          | **Sharp Red background + Red text**         |
| 7 | Footer                       | Barcodes, QR, origin, copyright      | Small, clean, minimal color                 |

This structure is **non-negotiable** in Japanese design. Change the colors, but keep the order and compartment logic.

---

### 3. Single Color Meanings (The Base Logic)

| Color     | Core Meaning                              | When to use it                                      | Emotional effect          |
|-----------|-------------------------------------------|-----------------------------------------------------|---------------------------|
| **Blue**  | Trust, cleanliness, neutrality, calm      | Standard information, ingredients, nutrition, manufacturer | Professional & readable   |
| **Red**   | Urgency, danger, importance, "pay attention" | Safety warnings, choking hazards, allergens         | High alert                |
| **Yellow**| Attention, energy, positivity, "notice this" | Best Before dates, special claims, highlights       | Friendly attention        |
| **Orange**| Warmth, appetite, fruit energy            | Citrus, tropical, "juicy" or "sweet" products       | Appetizing                |
| **Green** | Nature, health, freshness, real ingredients | "Made with real fruit", healthy claims, eco         | Fresh & trustworthy       |
| **Teal / Cyan** | Refreshing, modern, juicy texture     | Chewy gummies, "mouthfeel" focused products         | Modern & juicy            |
| **Purple**| Berry, grape, premium, cute               | Grape/berry flavors, premium cute positioning       | Luxurious or adorable     |
| **Pink**  | Sweetness, fluffiness, cuteness           | Strawberry, "fluffy" texture, kawaii products       | Sweet & cute              |

---

### 4. Color Combination Logic (This is where it gets powerful)

Japanese designers frequently **combine colors** to create layered meanings. Here are the most common and effective combinations:

| Combination       | New Meaning Created                          | Best Used For                                      | Example |
|-------------------|----------------------------------------------|----------------------------------------------------|---------|
| **Blue + Red**    | Trusted information + Safety warning         | Ingredients section with allergen callout          | Blue ingredients box + small red "GELATIN" box inside |
| **Blue + Yellow** | Important trusted info that must be noticed  | Manufacturer section with "Best Before" highlight  | Blue manufacturer box + yellow "2026.12" date |
| **Teal + Pink**   | Refreshing + Cute / Adorable                 | Modern juicy gummies with cute positioning         | Teal main box + pink accents on "Juicy!" text |
| **Green + Blue**  | Healthy + Reliable                           | Functional foods, supplements, "real ingredients"  | Green header + blue body text |
| **Red + Yellow**  | Strong attention + Positive energy           | Limited edition + safety note                      | Red warning box with yellow "New!" badge |
| **Orange + Green**| Real fruit + Fresh & Natural                 | Fruit juice powder or natural candy                | Orange flavor claim + green "real fruit" badge |
| **Purple + Pink** | Berry flavor + Premium Cute                  | Grape or blueberry premium products                | Purple main color + pink highlights |
| **Teal + White**  | Clean + Modern + Juicy                       | Minimalist modern packaging                        | Teal header on white background |

**Key Rule**: The first color usually sets the main compartment feeling. The second color adds a specific layer of meaning or creates contrast for hierarchy.

---

### 5. Color Decision Framework (How to Choose Logically)

When designing any label, ask these questions in order:

1. **What is the main emotional feeling of this product?**
   → Juicy/chewy → Teal
   → Healthy/natural → Green
   → Cute/sweet → Pink or Purple
   → Bold/energetic → Orange or Red

2. **What type of information is in this compartment?**
   → Standard info → Blue
   → Safety/warning → Red
   → Date or highlight → Yellow

3. **Do I need to layer meanings?**
   → Yes → Use a combination (see table above)

4. **What creates the best visual hierarchy?**
   → Use contrast: Blue compartment + Red warning box inside it is extremely common and effective.

---

### 6. Ready-to-Use Templates with Correct Color Logic

#### Template 1: Standard Gummy Candy (Teal + Red combination)

```
┌──────────────────────────────────────────────────────────────┐
│  CHEWY, JUICY, IRRESISTIBLE! (Blue header, white text)       │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  AROMA FOUNDATION METHOD (Teal box)                          │
│  Fluffy thin-layer coating delivers juicy flavor deep inside │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  Ingredients (Blue text on white)                            │
│  • Sugar, water candy, gelatin, acidulant...                 │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  ALLERGENS: GELATIN (Red box, red text)                  │ │
│  └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘

Nutrition Facts (Blue table headers)

Best Before: 2026.12 (Yellow highlight)

┌──────────────────────────────────────────────────────────────┐
│  WARNING – CHOKING HAZARD (Sharp Red box + Red text)         │
│  • Be careful not to get stuck in throat                     │
│  • Manufactured in facility that processes milk              │
└──────────────────────────────────────────────────────────────┘
```

#### Template 2: Healthy / Natural Product (Green + Blue)

```
┌──────────────────────────────────────────────────────────────┐
│  MADE WITH REAL FRUIT (Green header, white text)             │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  100% Real Fruit Juice Powder (Green box)                    │
│  No artificial colors or flavors                             │
└──────────────────────────────────────────────────────────────┘

Ingredients + Nutrition (Blue text on white)

┌──────────────────────────────────────────────────────────────┐
│  WARNING (Red box)                                           │
│  Contains natural fruit sugars                               │
└──────────────────────────────────────────────────────────────┘
```

---

### 7. Best LLM Instruction Prompt (Copy & Paste)

```
You are an expert in Japanese product information design.

Follow this exact system:

STRUCTURE (always use this order):
1. Catchy Hook (Blue header + white bold text)
2. Feature / Technology
3. Ingredients + Allergens (White background + Blue text + Red allergen sub-box)
4. Nutrition Facts (clean table with Blue headers)
5. Manufacturer & Dates (White box + Blue text + Yellow date highlight)
6. Warning Box (Sharp Red background + Red text)
7. Footer

COLOR LOGIC:
- Use single colors for clear meaning (see color table)
- Use combinations when you want to layer meaning (Blue + Red = trusted info with safety note)
- Always match color to product personality and information type

Now structure and color the following product information using authentic Japanese logic:

[PASTE RAW PRODUCT INFORMATION HERE]
```

---

### Summary: The Complete Japanese Logic

- **Structure** = Bento compartments in fixed 7-step order
- **Color** = Semantic meaning (not decoration)
- **Combinations** = Layered meaning + visual hierarchy
- **Decision process** = Product feeling → Information type → Single color or combination

This is how real Japanese designers think.
