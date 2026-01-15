# Chapter 15: The "Star Page" Golden Standard

> "One perfect page teaches more than a thousand guidelines."

---

Every design system needs a reference implementation—a single page that demonstrates every principle in harmony. In Onsen Planner, this is the "Star Page" (★). It's not just a feature screen; it's a teaching document rendered as UI.

---

## What is a Star Page?

A Star Page is a real, functional screen that serves dual purposes:

1. **For users:** A useful feature (in Onsen Planner, a quick-glance dashboard)
2. **For developers:** A canonical reference for implementing Joho Dezain

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

The classic Joho Dezain bento header with three zones:

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

### Every Joho Dezain Principle Visible

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

Every app implementing Joho Dezain should have a Star Page. Here's how to create one:

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
│           Joho Dezain STAR PAGE REFERENCE                   │
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

