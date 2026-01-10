# Chapter 9: Containers & Cards

> "A container is not a box. A container is a statement: this content belongs together."

---

Part 3 introduces the component library—production-ready patterns you can implement immediately. We begin with containers, the fundamental building blocks of any Joho Dezain interface.

---

## The Base Container

Every Joho Dezain interface is built from containers. A container is a bordered rectangle with white background that holds content.

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
│           Joho Dezain CONTAINER REFERENCE                │
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
