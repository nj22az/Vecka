# 日本の記号言語 - Japanese Symbol Language

## A Complete Visual Vocabulary for 情報デザイン

> "Japan has developed the world's most sophisticated system of visual communication symbols. Every symbol has meaning, history, and purpose."

---

## CRITICAL: Icon Style Rules

### 情報デザイン Icon Requirements

| Rule | Allowed | Forbidden |
|------|---------|-----------|
| **Style** | Flat, outlined, monochrome | 3D, gradients, shadows |
| **Type** | SF Symbols, Unicode symbols | Emoji, colored icons |
| **Weight** | Regular to Bold | Thin, ultralight |
| **Fill** | Outline OR solid fill | Partial fills, gradients |

### Why No Emoji?

Emoji are **NOT** 情報デザイン compliant:
- ❌ Colorful (violates monochrome principle)
- ❌ Platform-dependent rendering
- ❌ Decorative, not informational
- ❌ Variable sizing/alignment

**Use SF Symbols instead:**

| Concept | ❌ Emoji | ✅ SF Symbol |
|---------|----------|--------------|
| Egg | 🥚 | `oval` or custom |
| Fire | 🔥 | `flame` |
| Warning | ⚠️ | `exclamationmark.triangle` |
| Star | ⭐ | `star` / `star.fill` |
| Heart | ❤️ | `heart` / `heart.fill` |
| Location | 📍 | `mappin` |

### Acceptable Symbol Sources

1. **SF Symbols** (primary) - Apple's monochrome icon system
2. **Unicode geometric** - ○●◎△▲□■◇◆×
3. **Unicode arrows** - →←↑↓⇒⇐
4. **Unicode reference** - ※★☆†‡§¶
5. **Japanese text symbols** - 祝休振〒

### Forbidden

- ❌ Apple emoji
- ❌ Platform emoji (Google, Samsung, etc.)
- ❌ Colored Unicode (skin tone variants)
- ❌ Animated symbols
- ❌ 3D/skeuomorphic icons

---

## Quick Reference for Onsen Planner

### Implementation Priority

| Priority | Category | Symbols | Status |
|----------|----------|---------|--------|
| **P0** | Maru-Batsu Core | `○ ● ◎ × △ ▲ □ ■ ◇ ◆` | Foundation |
| **P0** | Status | `✓ ✔ ⚠ ！ ⊘` | Essential |
| **P1** | Numbers | `①②③④⑤⑥⑦⑧⑨⑩` | Lists |
| **P1** | Reference | `※ ★ ☆` | Notes |
| **P1** | Arrows | `→ ← ↑ ↓ ⇒ ⇐` | Navigation |
| **P2** | Calendar | `祝 休 振 ● ○ ◎` | Holidays |
| **P3** | Weather | `☀ ⛅ ☁ ☂ ❄` | Future |

---

## 1. MARU-BATSU EXTENDED (○×△□)

The foundation of Japanese visual communication. Sony's PlayStation borrowed this directly.

### Core Evaluation System

| Symbol | Name | Meaning | App Usage |
|--------|------|---------|-----------|
| ◎ | Nijū-maru | Excellent/Best | Top choice, primary |
| ○ | Maru | Good/Yes/Correct | Positive, available |
| △ | Sankaku | Caution/Partial/Maybe | Warning, partial |
| □ | Shikaku | Note/Reference/Neutral | Information |
| × | Batsu | No/Wrong/Failed | Negative, cancel |
| ー | Bō | Not applicable/None | N/A state |

### Filled vs Outlined (Critical Distinction)

| Filled | Outlined | Meaning |
|--------|----------|---------|
| ● Kuro-maru | ○ Shiro-maru | Strong yes vs Standard yes |
| ▲ Kuro-sankaku | △ Shiro-sankaku | Strong warning vs Mild caution |
| ■ Kuro-shikaku | □ Shiro-shikaku | Active/Selected vs Inactive |
| ◆ Kuro-hishi | ◇ Shiro-hishi | Important vs Notable |

### Special Variants

| Symbol | Name | Usage |
|--------|------|-------|
| ◉ | Janome ("Snake eye") | Target, bullseye, focus point |
| • | Small filled | Secondary, bullet point |
| · | Nakaguro (middle dot) | Separator, list item |

### Size Variants

```
●  Large filled   = Primary
•  Small filled   = Secondary, bullet
·  Tiny dot       = Separator (nakaguro)

◯  Large circle   = Main selection
○  Medium circle  = Standard
∘  Small circle   = Detail level
```

### Onsen Planner Application

```
ENTRY TYPE INDICATORS:
● Filled circle   = Has content (holiday, event, etc.)
○ Outlined circle = Available/Optional
◎ Double circle   = Primary/Important item
◆ Diamond         = Special/Featured

SELECTION STATES:
■ Selected/Active
□ Available/Inactive
```

---

## 2. JAPANESE CALENDAR SYMBOLS (暦記号)

### Rokuyo (六曜) - Six Day Cycle

Traditional calendar system still used for weddings, funerals, important decisions:

| Symbol | Reading | Meaning | Auspiciousness |
|--------|---------|---------|----------------|
| 大安 | Taian | Great Peace | ◎ Best - weddings, openings |
| 友引 | Tomobiki | Friend-pull | ○ Good (avoid funerals) |
| 先勝 | Senbu/Sakigachi | Early victory | △ Morning good only |
| 先負 | Senbu/Sakimake | Early loss | △ Afternoon good only |
| 赤口 | Shakku | Red mouth | × Only noon is safe |
| 仏滅 | Butsumetsu | Buddha's death | × Worst day |

### Day Color Associations

| Day | Kanji | Element | Traditional Color |
|-----|-------|---------|-------------------|
| Sunday | 日 | Sun | **RED** (休日 - holiday) |
| Monday | 月 | Moon | Silver/White |
| Tuesday | 火 | Fire/Mars | Red |
| Wednesday | 水 | Water | Blue/Cyan |
| Thursday | 木 | Wood | Green |
| Friday | 金 | Gold/Venus | Gold/Yellow |
| Saturday | 土 | Earth | Brown (often Blue in calendars) |

> **Note:** This is why Sunday is RED in Japanese calendars, and Saturday is often BLUE - opposite of Western conventions.

### Holiday Markers

| Symbol | Meaning | Japanese |
|--------|---------|----------|
| 祝 | National Holiday | 祝日 (shukujitsu) |
| 休 | Rest Day / Closed | 休み (yasumi) |
| 振 | Substitute Holiday | 振替休日 (furikae kyūjitsu) |
| ● | Special day marker | - |
| ◎ | Very important date | - |
| ★ | Featured/Highlighted | - |

---

## 3. DOCUMENT & REFERENCE SYMBOLS (文書記号)

### Proofreading Marks (校正記号)

| Symbol | Meaning | Action |
|--------|---------|--------|
| ∧ | Insert | Add text here |
| ∨ | Delete | Remove this |
| ⌒ | Transpose | Swap order |
| ○ | Circle/Emphasis | Highlight this |
| △ | Reduce | Make smaller |
| ▽ | Enlarge | Make bigger |
| ＝ | Keep as is | Ignore previous mark (stet) |
| ⎾ ⏌ | Move | Relocate text |
| ¶ | New paragraph | Break here |
| ～ | Wavy underline | Check this |

### Reference Marks (参照記号)

| Symbol | Name | Meaning | Usage |
|--------|------|---------|-------|
| ※ | Kome-jirushi | Note/Attention | THE most important reference mark |
| ☆ | Hoshi | Star reference | Highlight |
| ★ | Kuro-boshi | Important star | Strong highlight |
| † | Dagger | Footnote | Secondary reference |
| ‡ | Double dagger | Second footnote | Tertiary reference |
| § | Section | Section reference | Document structure |
| ¶ | Paragraph | Paragraph reference | Document structure |
| № | Number | Numero sign | Numbered items |
| 〆 | Shime | End/Total | Closing mark |
| ゝ | Repetition | Repeat previous kana | Text shorthand |
| 々 | Noma | Repeat previous kanji | Text shorthand |

### Form Symbols (帳票記号)

| Symbol | Meaning | Usage |
|--------|---------|-------|
| □ | Checkbox empty | Not selected |
| ☑ | Checkbox checked | Selected (checkmark style) |
| ☒ | Checkbox X | Selected (X style) or invalid |
| ○ | Radio empty | Option available |
| ◉ | Radio selected | Option chosen |
| ＿ | Blank field | Fill in here |
| （　） | Parentheses | Optional field |
| 【　】 | Black brackets | Required/Important field |
| 「　」 | Quotation brackets | Text entry |

### Japanese Brackets (Design Critical)

| Symbol | Name | Usage |
|--------|------|-------|
| 「　」 | Kagikakko | Standard quotes, titles |
| 『　』 | Nijū-kagikakko | Book titles, emphasis |
| 【　】 | Sumitsuki-kakko | Headlines, important items |
| 〔　〕 | Kikkō-kakko | Annotations, readings |
| 《　》 | Nijū-yamakakko | Book titles (formal) |
| 〈　〉 | Yamakakko | Single angle quotes |
| ［　］ | Kakukakko | Square brackets |
| （　） | Marukakko | Parentheses |
| ｛　｝ | Namikakko | Curly braces |

### Decorative Marks (装飾記号)

| Symbol | Usage |
|--------|-------|
| ◆◇◆ | Section divider |
| ───── | Horizontal rule |
| ═════ | Double horizontal rule |
| ♦♦♦ | Decorative separator |
| ✿✿✿ | Floral decoration |
| ★☆★ | Star pattern |
| ●○● | Dot pattern |
| 〜〜〜 | Wave separator |
| ∴ | Therefore (mathematical/decorative) |
| ∵ | Because |

---

## 4. NUMERIC & COUNTING SYMBOLS (数記号)

### Circled Numbers

```
Standard:     ①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳
Extended:     ㉑㉒㉓㉔㉕㉖㉗㉘㉙㉚㉛㉜㉝㉞㉟㊱㊲㊳㊴㊵
Negative:     ❶❷❸❹❺❻❼❽❾❿
Parenthesized: ⑴⑵⑶⑷⑸⑹⑺⑻⑼⑽⑾⑿
```

### Roman Numerals (Used in Japan)

```
Uppercase: ⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩⅪⅫ
Lowercase: ⅰⅱⅲⅳⅴⅵⅶⅷⅸⅹⅺⅻ
```

### Japanese Counting

| Symbol | Meaning | Reading |
|--------|---------|---------|
| 正 | Five (tally) | Sei - 5 strokes complete |
| 〇 | Zero/Circle | Rei/Zero |
| 一 | One | Ichi |
| 二 | Two | Ni |
| 三 | Three | San |
| 千 | Thousand | Sen |
| 万 | Ten thousand | Man |
| 億 | Hundred million | Oku |

---

## 5. ARROWS & DIRECTION (矢印記号)

### Standard Arrows

| Symbol | Meaning | Usage |
|--------|---------|-------|
| → | Right arrow | Next, forward, result |
| ← | Left arrow | Back, previous |
| ↑ | Up arrow | Increase, top |
| ↓ | Down arrow | Decrease, bottom |
| ↔ | Left-right | Bidirectional |
| ↕ | Up-down | Vertical range |

### Double Arrows (Emphasis)

| Symbol | Meaning | Usage |
|--------|---------|-------|
| ⇒ | Implies/Therefore | Strong result |
| ⇐ | Implied by | Strong cause |
| ⇔ | Equivalent | Bidirectional relation |

---

## 6. JAPANESE MAP SYMBOLS (地図記号)

Japan has **standardized map symbols** since 1886. Taught to all Japanese children.

> **Note:** Use SF Symbols in app implementation. Unicode/emoji shown for reference.

### Buildings & Landmarks

| Concept | Unicode | SF Symbol | Notes |
|---------|---------|-----------|-------|
| Shrine (Jinja) | ⛩ | custom | Torii gate shape |
| Temple (Tera) | 卍 | custom | Buddhist manji |
| Church | † | `cross` | Western cross |
| Post Office | 〒 | `envelope` | Postal mark |
| Hospital | ⚕ | `cross.case` | Medical |
| Gas Station | ⛽ | `fuelpump` | Fuel pump |
| Bank | - | `building.columns` | Financial |
| Port/Harbor | ⚓ | `anchor` | Maritime |
| Airport | ✈ | `airplane` | Aviation |
| Train Station | - | `tram` | Transit |

### Nature & Geography

| Concept | Unicode | SF Symbol | Notes |
|---------|---------|-----------|-------|
| Mountain | ⛰ | `mountain.2` | Peak shape |
| Hot Spring | ♨ | `drop.triangle` | Onsen - steam rising |
| River/Water | 〰 | `water.waves` | Wavy lines |
| Forest | - | `tree` | Conifer |
| Orchard | - | `leaf` | Deciduous |
| Rice Paddy | 田 | text/custom | Field pattern |
| Farm Field | 畑 | text/custom | Cultivated land |

### Boundaries & Areas

| Symbol | Meaning | Notes |
|--------|---------|-------|
| ─ ─ ─ | Prefecture Border | Dashed line |
| ─·─·─ | City Border | Dash-dot |
| ┅┅┅┅┅ | Town Border | Short dashes |
| ▒▒▒▒▒ | Built-up Area | Shaded region |

---

## 7. TRAIN & TRANSIT SYMBOLS (鉄道記号)

Japan's train system has perfected information design.

### Line Type Indicators

| Symbol | Meaning | Example |
|--------|---------|---------|
| ━━━━ | Regular line | Local trains |
| ════ | Express line | Limited express |
| ┅┅┅┅ | Planned/Future | Under construction |
| ─ ─ ─ | Alternate route | Bus substitution |
| ●━━━● | Stations on line | With stops marked |
| ●───● | Non-stop section | Express skip |
| ○ | Regular station | Standard stop |
| ◎ | Major station | Transfer point |
| ● | Terminal | End of line |
| ⊕ | Junction | Lines crossing |

### Service Type Colors

| Color | Service | Japanese | Meaning |
|-------|---------|----------|---------|
| BLACK | Local | 普通 | Stops at all stations |
| GREEN | Rapid | 快速 | Skips some stations |
| ORANGE | Express | 急行 | Skips many stations |
| RED | Ltd Express | 特急 | Major stations only |
| PURPLE | Shinkansen | 新幹線 | Bullet train |

---

## 8. WEATHER SYMBOLS (天気記号)

Japanese weather notation is distinct from Western systems.

> **Note:** Use SF Symbols in app. Unicode shown for reference.

| Concept | Unicode | SF Symbol | Japanese |
|---------|---------|-----------|----------|
| Clear/Sunny | ☀ | `sun.max` | 晴れ (hare) |
| Partly Cloudy | ⛅ | `cloud.sun` | 曇り時々晴れ |
| Cloudy | ☁ | `cloud` | 曇り (kumori) |
| Rain | ☂ | `cloud.rain` | 雨 (ame) |
| Thunderstorm | - | `cloud.bolt.rain` | 雷雨 (raiu) |
| Snow | ❄ | `snowflake` | 雪 (yuki) |
| Fog | - | `cloud.fog` | 霧 (kiri) |

### Formal Weather Notation (Maru-based)

| Symbol | Meaning | Japanese |
|--------|---------|----------|
| ○ | Clear | 快晴 (kaisei) |
| ◐ | Half cloudy | 半晴 (hanbare) |
| ● | Overcast | 曇天 (donten) |

---

## 9. SAFETY & WARNING SYMBOLS (安全記号)

> **Note:** Use SF Symbols in app. Emoji shown for reference only.

### JIS Safety Colors

| Color | Meaning | Unicode | SF Symbol |
|-------|---------|---------|-----------|
| **RED** | Prohibition/Fire/Danger | ⊘ | `nosign`, `flame` |
| **YELLOW** | Caution/Warning | ⚠ △ ！ | `exclamationmark.triangle` |
| **GREEN** | Safety/First Aid/Go | ✚ ✓ | `cross`, `checkmark` |
| **BLUE** | Mandatory/Information | ℹ ● | `info.circle`, `circle.fill` |

### Common Warning Marks

| Concept | Unicode | SF Symbol | Usage |
|---------|---------|-----------|-------|
| Warning | ⚠ | `exclamationmark.triangle` | General caution |
| Electricity | ⚡ | `bolt` | High voltage danger |
| Radiation | ☢ | `dot.radiowaves.right` | Nuclear/radioactive |
| Biohazard | ☣ | `allergens` | Biological danger |
| Fire | - | `flame` | Flammable/Fire danger |
| Poison | - | `cross.vial` | Toxic substance |
| Prohibited | ⊘ | `nosign` | Do not do this |
| Attention | ！ | `exclamationmark` | Important notice |

### Warning Hierarchy

| Symbol | Level | Japanese | Usage |
|--------|-------|----------|-------|
| ℹ | Info | 情報 | Helpful tips - Cyan border |
| ⚠ | Caution | 注意 | User should know - Yellow |
| ！ | Warning | 警告 | Action required - Red |
| ⊘ | Danger | 危険 | Critical/Destructive - Black+Red |

---

## 10. FOOD & DIETARY SYMBOLS (食品記号)

Japanese food labeling is extremely detailed.

> **Note:** Emoji shown below are for REFERENCE ONLY. Use SF Symbols in app.

### Allergen Symbols

| Concept | Reference | SF Symbol | Japanese |
|---------|-----------|-----------|----------|
| Egg | 🥚 | `oval` | 卵 |
| Milk | 🥛 | `drop` | 乳 |
| Wheat | 🌾 | `leaf` | 小麦 |
| Shrimp | 🦐 | custom | えび |
| Crab | 🦀 | custom | かに |
| Peanut | 🥜 | custom | 落花生 |
| Tree nuts | 🌰 | custom | ナッツ |

### Dietary Preference

| Concept | Reference | SF Symbol | Notes |
|---------|-----------|-----------|-------|
| Vegetarian | 🌱 | `leaf` | No meat |
| Vegan | 🍃 | `leaf.fill` | No animal products |
| Contains allergen | - | `exclamationmark.triangle` | Warning mark |
| Allergen-free | ✓ | `checkmark` | Safe |
| Halal | ハ | text | Islamic dietary law |
| Kosher | ユ | text | Jewish dietary law |

---

## 11. COMMERCE SYMBOLS (商業記号)

| Symbol | Meaning | Usage |
|--------|---------|-------|
| ¥ / ￥ | Yen | Japanese currency |
| 円 | En/Yen | Written form |
| 〒 | Postal code | Address prefix |
| ㊞ | Seal here | Place for hanko/stamp |
| 印 | Stamp/Seal | Personal seal mark |
| ㈱ | Kabushiki-gaisha | Corporation (Inc.) |
| ㈲ | Yūgen-gaisha | Limited company (Ltd.) |
| ㊤ | Top/Premium | Highest quality |
| ㊥ | Middle | Standard quality |
| ㊦ | Bottom | Basic quality |
| ㊧ | Left | Direction |
| ㊨ | Right | Direction |

---

## 12. ZODIAC SYMBOLS (十二支)

### Chinese Zodiac (Japanese Calendar)

| Kanji | Animal | Reading | Years |
|-------|--------|---------|-------|
| 子 | Rat | Ne | 2020, 2032 |
| 丑 | Ox | Ushi | 2021, 2033 |
| 寅 | Tiger | Tora | 2022, 2034 |
| 卯 | Rabbit | U | 2023, 2035 |
| 辰 | Dragon | Tatsu | 2024, 2036 |
| 巳 | Snake | Mi | 2025, 2037 |
| 午 | Horse | Uma | 2026, 2038 |
| 未 | Sheep | Hitsuji | 2027, 2039 |
| 申 | Monkey | Saru | 2028, 2040 |
| 酉 | Rooster | Tori | 2029, 2041 |
| 戌 | Dog | Inu | 2030, 2042 |
| 亥 | Boar | I | 2031, 2043 |

### Western Zodiac

```
♈ ♉ ♊ ♋ ♌ ♍ ♎ ♏ ♐ ♑ ♒ ♓
```

---

## 13. BLOOD TYPE (血液型)

Important in Japanese culture for personality typing:

| Type | Symbol | Personality Stereotype |
|------|--------|------------------------|
| A | Ⓐ | Organized, anxious, detail-oriented |
| B | Ⓑ | Creative, selfish, unconventional |
| O | Ⓞ | Confident, insensitive, natural leader |
| AB | ⒜⒝ | Rational, indecisive, dual personality |

---

## 14. PLAYSTATION PHILOSOPHY

Understanding why these symbols work universally:

| Button | Symbol | Japanese Meaning | Function |
|--------|--------|------------------|----------|
| ○ | Circle | YES/CONFIRM | Positive, complete, whole |
| × | Cross | NO/CANCEL | Rejection, wrong, stop |
| △ | Triangle | VIEWPOINT | Perspective, map, menu |
| □ | Square | DOCUMENT | Information, inventory |

> In Japan, ○ marks correct answers on tests, × marks wrong answers. This is why Japanese games use ○ for confirm and × for cancel (opposite of Western games).

### Original PS1 Colors

| Symbol | Color | Meaning |
|--------|-------|---------|
| ○ | Pink | Soft, positive |
| × | Blue | Cool, stop |
| △ | Green | Go, view |
| □ | Red | Attention, important |

### Why This Matters

```
○ CIRCLE (Maru)
  └─ Japanese: YES/CONFIRM (positive, complete, whole)
  └─ In Japan, ○ means "correct answer" on every test
  └─ Western games swapped this to X (causing confusion!)

× CROSS (Batsu)
  └─ Japanese: NO/CANCEL (rejection, wrong, stop)
  └─ In Japan, × marks wrong answers on tests
  └─ NOT a Christian cross - it's a rejection mark

△ TRIANGLE (Sankaku)
  └─ Japanese: VIEWPOINT/PERSPECTIVE (head, point-of-view)
  └─ Represents looking at map/menu from above
  └─ Secondary action, alternative view

□ SQUARE (Shikaku)
  └─ Japanese: DOCUMENT/MENU (paper, information, list)
  └─ Represents a piece of paper or menu
  └─ Access to information, inventory, pause
```

---

## Universal Implementation Principle

**For non-CJK users, the SHAPE is the language:**

| Concept | Universal Symbol | Japanese | Meaning |
|---------|------------------|----------|---------|
| Excellent | ◎ | ◎ | Double circle = best |
| Good | ○ | ○ | Circle = positive |
| Caution | △ | △ | Triangle = warning |
| Reference | □ | □ | Square = info |
| Bad | × | × | Cross = negative |
| Important | ★ | 要 | Star = attention |
| Family | ♥ | 家 | Heart = love |
| Work | ⚙ | 仕 | Gear = job |

> **The shapes ARE the language. That's the beauty of 情報デザイン.**

---

## Onsen Planner Symbol Mapping

### Current Implementation

| App Element | Symbol | Meaning |
|-------------|--------|---------|
| Holiday (red) | ● | Filled = has content |
| Observance (orange) | ○ | Outlined = secondary |
| Event (purple) | ◆ | Diamond = special |
| Birthday (pink) | ● | Filled = celebration |
| Note (yellow) | □ | Square = information |
| Trip (blue) | ● | Filled = scheduled |
| Expense (green) | ● | Filled = transaction |

### Proposed Enhancements

| Feature | Current | Proposed | Reasoning |
|---------|---------|----------|-----------|
| Today | Yellow highlight | ◎ + Yellow | Double emphasis |
| Important | Star icon | ★ | Filled star |
| Optional | - | △ | Caution/partial |
| Cancelled | - | × | Cross/rejection |
| Complete | Checkmark | ○ or ✓ | Positive completion |

---

## Design System Integration

### SF Symbol Mapping

| Japanese | SF Symbol | Usage |
|----------|-----------|-------|
| ○ | `circle` | Positive |
| ● | `circle.fill` | Active/Selected |
| ◎ | `circle.circle` | Excellent |
| △ | `triangle` | Warning |
| ▲ | `triangle.fill` | Danger |
| □ | `square` | Info |
| ■ | `square.fill` | Selected |
| ◇ | `diamond` | Special |
| ◆ | `diamond.fill` | Featured |
| × | `xmark` | Cancel/No |
| ★ | `star.fill` | Important |
| ☆ | `star` | Reference |

### Color + Symbol Combinations

```swift
// Onsen Planner semantic indicators
enum IndicatorStyle {
    case positive   // ○ or ● with green
    case negative   // × with red
    case caution    // △ with yellow
    case info       // □ with blue
    case special    // ◆ with purple
    case excellent  // ◎ with gold
}
```

---

## Summary: Symbol Categories

### HIGH PRIORITY (Implement First)

```
MARU-BATSU:     ○ ● ◎ × △ ▲ □ ■ ◇ ◆
NUMBERS:        ①②③④⑤⑥⑦⑧⑨⑩
STATUS:         ✓ ✔ ⚠ ！ ⊘
REFERENCE:      ※ ★ ☆
ARROWS:         → ← ↑ ↓ ⇒ ⇐
```

### MEDIUM PRIORITY (Calendar-Specific)

```
DAY MARKERS:    ● ○ ◎ ★
ROKUYO:         大安 友引 先勝 先負 赤口 仏滅
HOLIDAY:        祝 休 振
```

### ENHANCEMENT (Future Features)

```
WEATHER:        ☀ ⛅ ☁ ☂ ❄  → SF: sun.max, cloud.sun, cloud, cloud.rain, snowflake
CATEGORIES:     ♥ ⚙ ✚ ◆ ✿   → SF: heart, gearshape, cross, diamond, leaf
TRANSIT:        ● ○ ◎ ⊕      → SF: circle.fill, circle, circle.circle, plus.circle
FOOD/DIETARY:   SF Symbols only → leaf, leaf.fill, exclamationmark.triangle
```

---

## References

- JIS Z 8210 (Safety Signs)
- JIS X 0208 (Character Set)
- Geospatial Information Authority of Japan (Map Symbols)
- Japanese Industrial Standards (JIS)

---

## Quick SF Symbol Reference (IMPLEMENTATION)

This is the ONLY section to use when implementing. All symbols above are for understanding context.

### Core Maru-Batsu
| Concept | SF Symbol | Unicode (reference) |
|---------|-----------|---------------------|
| Yes/Positive | `circle` / `circle.fill` | ○ ● |
| Excellent | `circle.circle` | ◎ |
| No/Cancel | `xmark` | × |
| Caution | `triangle` / `triangle.fill` | △ ▲ |
| Info/Neutral | `square` / `square.fill` | □ ■ |
| Special | `diamond` / `diamond.fill` | ◇ ◆ |

### Status & Actions
| Concept | SF Symbol |
|---------|-----------|
| Check/Complete | `checkmark` |
| Warning | `exclamationmark.triangle` |
| Prohibited | `nosign` |
| Info | `info.circle` |
| Important | `star.fill` |
| Reference | `star` |

### Weather
| Concept | SF Symbol |
|---------|-----------|
| Clear | `sun.max` |
| Partly cloudy | `cloud.sun` |
| Cloudy | `cloud` |
| Rain | `cloud.rain` |
| Storm | `cloud.bolt.rain` |
| Snow | `snowflake` |
| Fog | `cloud.fog` |

### Safety
| Concept | SF Symbol |
|---------|-----------|
| Fire/Flame | `flame` |
| Electric | `bolt` |
| Poison | `cross.vial` |
| Biohazard | `allergens` |
| Medical | `cross.case` |

### Navigation
| Concept | SF Symbol |
|---------|-----------|
| Forward | `chevron.right` |
| Back | `chevron.left` |
| Up | `chevron.up` |
| Down | `chevron.down` |
| Expand | `chevron.down` |
| Collapse | `chevron.up` |

---

*Document created for Onsen Planner 情報デザイン standardization*
*Last updated: 2026-01-03*
