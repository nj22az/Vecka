# Building New Apps with 情報デザイン

> **Last Updated:** 2026-01-31
> **Template guide for creating new apps with this design foundation**

This guide explains how to build new iOS apps using the 情報デザイン (Jōhō Dezain) design system from Onsen Planner.

---

## Step 1: Copy Core Files

Copy these essential files to your new project:

### Required Files

| File | LOC | Purpose |
|------|-----|---------|
| `JohoDesignSystem.swift` | ~4000 | All design components |
| `JohoSymbols.swift` | - | Symbol definitions |
| `Haptics.swift` | - | Haptic feedback |

### Optional Files

| File | Purpose | When to Include |
|------|---------|-----------------|
| `Localization.swift` | i18n | Multi-language apps |
| `WeekCalculator.swift` | ISO 8601 weeks | Calendar apps |
| `HolidayEngine.swift` | Holiday calculation | Calendar apps |

---

## Step 2: Set Up Color Scheme

### Import the Semantic Palette

```swift
// Colors are already defined in JohoDesignSystem.swift
// Just use them throughout your app:

Text("Hello")
    .foregroundStyle(JohoColors.black)  // Always for text

VStack { }
    .background(JohoColors.white)  // Always for content areas
```

### Map Your Features to Semantic Colors

| If your feature is about... | Use this color |
|-----------------------------|----------------|
| Current state, "now", user notes | `JohoColors.yellow` |
| Scheduled items, events, calendar | `JohoColors.cyan` |
| Celebrations, holidays, birthdays | `JohoColors.pink` |
| Money, expenses, financial | `JohoColors.green` |
| People, contacts, relationships | `JohoColors.purple` |
| System warnings only | `JohoColors.red` |

---

## Step 3: Apply the Foundation

### App Background

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .johoBackground()  // Dark background
        }
    }
}
```

### Main Content Structure

```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Page header
                    pageHeader

                    // Content cards
                    contentCards
                }
                .padding(12)
            }
            .johoBackground()
        }
    }
}
```

---

## Step 4: Create Page Headers

### Simple Header

```swift
JohoPageHeader(
    title: "MY PAGE",
    icon: "star.fill",
    accentColor: JohoColors.yellow
)
```

### Bento Header (with controls)

```swift
private var headerWithControls: some View {
    VStack(spacing: 0) {
        HStack(spacing: 12) {
            // Icon zone
            Image(systemName: "star.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(JohoColors.black)
                .frame(width: 40, height: 40)
                .background(JohoColors.yellow.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(JohoColors.black, lineWidth: 1.5))

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text("PAGE TITLE")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("Subtitle here")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(JohoColors.black.opacity(0.6))
            }

            Spacer()

            // Controls (year picker, buttons, etc.)
            // ...
        }
        .padding(12)
        .background(JohoColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(JohoColors.black, lineWidth: 2))
    }
}
```

---

## Step 5: Create List Rows

### Standard List Row

```swift
JohoListRow(
    title: "Item Title",
    subtitle: "Optional subtitle",
    icon: "star.fill",
    accentColor: JohoColors.yellow
)
```

### Bento Row (compartmentalized)

```swift
HStack(spacing: 0) {
    // LEFT: Type indicator
    Circle()
        .fill(JohoColors.yellow)
        .frame(width: 10, height: 10)
        .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
        .frame(width: 28)

    Rectangle().fill(JohoColors.black).frame(width: 1.5)

    // CENTER: Content
    Text("Item Title")
        .font(.system(size: 16, weight: .medium, design: .rounded))
        .padding(.horizontal, 12)

    Spacer()

    Rectangle().fill(JohoColors.black).frame(width: 1.5)

    // RIGHT: Actions/badges
    Image(systemName: "chevron.right")
        .frame(width: 44)
}
.frame(height: 44)
.background(JohoColors.white)
.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
.overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
    .stroke(JohoColors.black, lineWidth: 1.5))
```

---

## Step 6: Create Editor Sheets

```swift
.sheet(isPresented: $showEditor) {
    NavigationStack {
        VStack(spacing: 0) {
            // Header
            JohoEditorHeader(
                title: "EDIT ITEM",
                subtitle: "Description",
                icon: "pencil",
                accentColor: JohoColors.yellow,
                isValid: isFormValid,
                onBack: { showEditor = false },
                onSave: { saveItem() }
            )

            // Form content
            VStack(spacing: 12) {
                JohoFormField(label: "NAME") {
                    TextField("", text: $name)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }

                JohoFormField(label: "DESCRIPTION") {
                    TextField("", text: $description)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
            }
            .padding(12)

            Spacer()
        }
        .background(JohoColors.white)
    }
    .presentationBackground(JohoColors.black)
    .presentationDragIndicator(.hidden)
}
```

---

## Step 7: Add Interactivity

### Buttons

```swift
JohoActionButton(
    label: "ADD ITEM",
    icon: "plus",
    style: .primary
) {
    // Action
}
```

### Toggles

```swift
JohoToggleRow(
    title: "Enable Feature",
    isOn: $isEnabled
)
```

### Search

```swift
JohoSearchField(
    text: $searchText,
    placeholder: "Search items..."
)
```

---

## Design Checklist

Before shipping any view:

- [ ] **Black borders** on all containers (1-3pt based on hierarchy)
- [ ] **White backgrounds** for all content areas
- [ ] **Squircle corners** — `.clipShape(RoundedRectangle(cornerRadius: X, style: .continuous))`
- [ ] **Rounded typography** — `.font(.system(size: X, weight: .Y, design: .rounded))`
- [ ] **Semantic colors** — only use `JohoColors.*`
- [ ] **44pt touch targets** for all interactive elements
- [ ] **No vertical scroll** in forms/editors
- [ ] **No glass/blur** — `.background(.ultraThinMaterial)` is forbidden
- [ ] **No gradients** — `LinearGradient` is forbidden
- [ ] **No raw colors** — `Color.blue` is forbidden
- [ ] **JohoCalendarPicker** — never iOS DatePicker

---

## Common Patterns

### Container with Zone Color

```swift
VStack {
    content
}
.padding(12)
.background(JohoColors.white)
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
.overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
    .stroke(JohoColors.black, lineWidth: 2))
.background(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(JohoColors.yellow.opacity(0.1))
        .offset(x: 4, y: 4)
)
```

### Type Indicator Dot

```swift
Circle()
    .fill(accentColor)
    .frame(width: 10, height: 10)
    .overlay(Circle().stroke(JohoColors.black, lineWidth: 1.5))
```

### Section Header

```swift
Text("SECTION TITLE")
    .font(.system(size: 12, weight: .bold, design: .rounded))
    .foregroundStyle(JohoColors.black)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(JohoColors.black)
    .foregroundStyle(JohoColors.white)
    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
```

### Empty State

```swift
JohoEmptyState(
    icon: "tray",
    title: "No Items",
    message: "Add your first item to get started"
)
```

---

## Border Width Reference

| Element | Width |
|---------|-------|
| Day cells, indicators | 1pt |
| List rows, form fields | 1.5pt |
| Buttons, badges | 2pt |
| Selected/Today | 2.5pt |
| Cards, containers | 3pt |

---

## Typography Scale

| Scale | Size | Weight |
|-------|------|--------|
| Hero | 48pt | heavy |
| Title | 32pt | bold |
| Headline | 18pt | bold |
| Body | 16pt | medium |
| Caption | 14pt | medium |
| Label | 12pt | bold |
| Micro | 10pt | bold |

---

## See Also

- `.claude/GOLDEN_STANDARD.md` — Authoritative color/component reference
- `.claude/design-system.md` — Full visual specification
- `.claude/layout-rules.md` — Interaction patterns
- `Vecka/Views/SpecialDaysListView.swift` — Golden standard implementation
