# Chapter 11: Navigation Patterns

> "Navigation is orientation. Users should always know where they are."

---

Every screen in a Joho Dezain interface needs clear navigation. Users must know where they are, where they can go, and how to get back. Navigation components follow the same visual language as content—bordered, high-contrast, functional.

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

The signature Joho Dezain header—a compartmentalized control panel at the top of the screen.

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
│           Joho Dezain NAVIGATION REFERENCE                  │
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

