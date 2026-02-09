# CLAUDE.md — 7day iOS App

## What This App Is

7day is a minimalist iOS bodyweight tracking app. The core philosophy is that **daily weigh-ins are noisy and unreliable — the weekly average is your "true" weight.** Users weigh themselves most mornings, and the app calculates weekly averages to show real trends. Users plan blocks of weeks (10-12 week cycles) where they're cutting, bulking, or maintaining weight, and can see at a glance whether their weekly average is on track vs their goal.

## Target

- iOS 17+ (use latest SwiftUI APIs freely)
- iPhone only (no iPad optimization needed)
- Swift 6 / SwiftUI
- Use Swift Charts for all graphs
- Use SwiftData for persistence
- No third-party dependencies

## Core User Flow

The user opens the app ~once per day, logs their weight in under 3 seconds, and closes it. That's 90% of usage. The weight input must be the very first thing they see — large, focused, and ready to type.

The remaining 10% is checking progress (weekly averages, charts, goal comparison) and occasionally planning a new block.

## Four Tabs

### 1. Log (Default Tab)
- **Weight input is the hero.** Large monospaced number input, auto-focused on app launch. Date picker defaults to today. Single "Log" button.
- Below input: **This Week summary card** showing current weekly average, number of weigh-ins this week, goal weight (if in an active block), and delta vs goal (color-coded).
- Below that: **vs last week** — simple comparison showing +/- lbs from last week's average.
- Below that: **Recent entries** — last 14 daily entries in reverse chronological order, each editable and deletable.

### 2. Progress
- **Weekly averages chart** using Swift Charts. Line chart with area fill. X-axis = weeks, Y-axis = weight. If blocks exist, show the goal line as a dashed overlay. Optionally shade the chart background by block type (red tint for cut, green for bulk, blue for maintain).
- Below chart: **Week by week list** — each row shows the week date range, average weight, entry count, min-max range, goal (if applicable), and color-coded delta vs goal.

### 3. Plan
- **New Block form:**
  - Block type selector: Cut / Bulk / Maintain (segmented control or toggle buttons)
  - Start date (date picker)
  - Number of weeks (stepper or text field, default 12)
  - Starting weight (text field, ideally pre-filled with current week's average)
  - Rate: % of bodyweight per week (e.g. 0.5%). Disabled for maintain blocks.
  - Preview line showing: "185.0 → 173.9 lbs (-11.1 over 12wk)"
  - "Create Block" button
- **Blocks list** — all planned/past blocks, with active block highlighted. Active block expands to show week-by-week goal vs actual breakdown.

### 4. Import (can be in Settings or its own tab)
- CSV import: accept pasted text or file picker. Two columns: date, weight. Support YYYY-MM-DD and MM/DD/YYYY formats.
- CSV export: generate and share a CSV of all entries.
- Danger zone: clear all entries, clear all blocks (with confirmation).

## Data Model (SwiftData)

```swift
@Model
class WeightEntry {
    var date: Date        // calendar date (strip time component)
    var weight: Double    // in lbs
    var createdAt: Date
    
    // Unique on date — one entry per day, newer overwrites
}

@Model
class Block {
    var type: BlockType   // .cut, .bulk, .maintain
    var startDate: Date   // always a Monday
    var weeks: Int
    var startWeight: Double
    var rate: Double      // percentage per week (e.g. 0.5)
    var createdAt: Date
    
    // Computed:
    // endDate = startDate + (weeks - 1) * 7 days
    // weeklyChange = startWeight * (rate / 100) * multiplier
    //   where multiplier = -1 for cut, +1 for bulk, 0 for maintain
    // goalForWeek(n) = startWeight + weeklyChange * n
}

enum BlockType: String, Codable {
    case cut, bulk, maintain
}
```

## Key Calculations

**Weekly average:** Group all entries by ISO week (Monday-Sunday). Average = sum of weights / count. Need at least 1 entry to show an average, but 4+ is ideal.

**Week key:** Given a date, find the Monday of that week. Use Calendar with `.firstWeekday = 2` (Monday).

**Goal for a given week within a block:**
```
weekIndex = number of weeks between block.startDate and the target Monday
goalWeight = block.startWeight + (block.startWeight * block.rate / 100 * multiplier * weekIndex)
```

**Delta coloring:**
- During a cut: over goal = red (bad), under goal = green (good)
- During a bulk: over goal = green (good), under goal = red (bad)  
- During maintain: use neutral color, flag if delta > 1.0 lbs

## Design System

### Colors
```swift
// Backgrounds
static let background = Color(hex: "#F5F5F3")     // warm light grey
static let surface = Color.white                    // cards
static let surfaceHover = Color(hex: "#F0F0ED")    // pressed/selected state

// Text
static let textPrimary = Color(hex: "#2D2D2D")     // dark charcoal
static let textSecondary = Color(hex: "#7A7A7A")   // secondary labels
static let textMuted = Color(hex: "#AAAAAA")        // hints, placeholders

// Accent
static let accent = Color(hex: "#34D399")           // mint green (primary)
static let accentLight = Color(hex: "#86EFAC")      // lighter mint
static let accentDim = Color(hex: "#34D399").opacity(0.10) // tinted backgrounds

// Semantic
static let cut = Color(hex: "#F87171")              // red for cutting
static let bulk = Color(hex: "#34D399")             // green for bulking (same as accent)
static let maintain = Color(hex: "#60A5FA")          // blue for maintaining
static let positive = Color(hex: "#22C55E")          // good delta
static let negative = Color(hex: "#EF4444")          // bad delta

// Borders
static let border = Color(hex: "#E4E4E0")
```

### Typography
- **Body / UI text:** System rounded (San Francisco Rounded) or Nunito if you want exact parity with the prototype. Prefer the system rounded font for native feel.
- **Numbers / Data:** Use a monospaced font. `Font.system(.body, design: .monospaced)` works, or IBM Plex Mono if imported.
- **Weight input:** Very large monospaced, light weight (~52pt)
- **Weekly average display:** Large monospaced (~32pt)
- **Section labels:** 11pt, uppercase, letter-spaced, semibold, muted color

### Card Style
```swift
// Standard card modifier
.padding(22)
.background(Color.white)
.clipShape(RoundedRectangle(cornerRadius: 18))
.shadow(color: .black.opacity(0.04), radius: 6, y: 2)
```

### Buttons
- Primary: mint green background, white text, bold, 10px corner radius, subtle mint shadow
- Outline: transparent background, border, dark text

## Architecture Notes

- Use `@Observable` view models (not ObservableObject)
- One `WeightViewModel` that owns the SwiftData queries and all computed properties
- Keep views thin — just layout and binding
- Use `@Query` in views where appropriate for SwiftData
- Tab bar should use SwiftUI `TabView` with custom styling if needed
- The weight input should use a focused `TextField` with `.keyboardType(.decimalPad)` and a large monospaced font
- For CSV import, support both paste (from clipboard) and file import (via `.fileImporter`)

## Future Enhancements (not for v1, but keep architecture open)
- HealthKit integration (read weight from Apple Health / smart scales)
- Home screen widget showing current week's average
- iCloud sync via SwiftData + CloudKit
- Dark mode (the app currently only has a light theme, but the color system should make it easy to add)
- Apple Watch quick-log complication

## File Structure Suggestion
```
7day/
├── 7day.swift          # App entry point, SwiftData container
├── Models/
│   ├── WeightEntry.swift         # SwiftData model
│   └── Block.swift               # SwiftData model + BlockType enum
├── ViewModels/
│   └── WeightViewModel.swift     # All business logic, computed props
├── Views/
│   ├── ContentView.swift         # TabView container
│   ├── LogTab/
│   │   ├── LogView.swift         # Weight input + this week + recent
│   │   └── WeekSummaryCard.swift
│   ├── ProgressTab/
│   │   ├── ProgressView.swift    # Chart + week list
│   │   └── WeightChart.swift     # Swift Charts wrapper
│   ├── PlanTab/
│   │   ├── PlanView.swift        # New block form + block list
│   │   └── BlockCard.swift
│   └── ImportTab/
│       └── ImportView.swift      # CSV import/export + data management
├── Utilities/
│   ├── DateHelpers.swift         # Week key calculation, formatting
│   └── CSVParser.swift           # CSV import logic
└── Theme/
    └── Theme.swift               # Colors, fonts, shared modifiers
```

## Important Behavioral Details
- One weight entry per day. If user logs twice on the same date, the newer entry replaces the older one.
- Weeks run Monday through Sunday.
- Blocks should not overlap (validate on creation, or at minimum, only one block can be "active" at a time).
- The "active block" is whichever block contains today's date.
- If no block is active, the Log tab just shows the weekly average without goal comparison.
- CSV import should merge with existing data (matching dates overwrite, new dates add).
- All weights are in lbs (no unit conversion needed for v1).
