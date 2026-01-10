# Chapter 10: Interactive Elements

> "A 2pt border says: touch me."

---

Interactive elements—buttons, toggles, inputs—follow specific patterns in Joho Dezain. They're distinguished by 2pt borders and clear affordances.

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

The Joho Dezain toggle has a clear on/off visual state:

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
│           Joho Dezain INTERACTIVE REFERENCE              │
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
