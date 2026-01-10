# Chapter 17: SwiftUI Code Patterns

> "Good code is consistent code. Design systems enable both."

---

This chapter provides production-ready SwiftUI code for implementing Joho Dezain. Copy these patterns directly into your projects—they're tested, complete, and follow every principle.

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
│           Joho Dezain SWIFTUI COMPONENTS                    │
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

