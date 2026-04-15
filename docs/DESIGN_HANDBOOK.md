# AwareBudget Design Handbook

> Master visual language. Applied consistently across every tab, screen, and component.

---

## 1. Brand palette — metallic gold + money green

### 1.1 Hero gradient (metallic green) — `DS.heroGradient`
7-stop diagonal shimmer, used on every hero card / CTA panel / dark green surface.

```
0%    #1B5E20   deep forest
15%   #2E7D32   primary
35%   #66BB6A   mid
50%   #4CAF50   accent
65%   #81C784   light
80%   #2E7D32
100%  #1B5E20
angle: 135° (topLeading → bottomTrailing)
```

### 1.2 Nugget gold gradient (metallic foil) — `DS.nuggetGold`
6-stop diagonal metallic gold, used on every primary action button + premium accent.

```
0%    #FFF8C0   highlight
20%   #F5C842   warm gold
40%   #D4A843
65%   #8B6010   deep bronze shadow
82%   #C59430
100%  #FFF0A0   highlight
angle: 135° (topLeading → bottomTrailing)
```

**Rule:** always use the gradient static, never a flat fill approximation.

### 1.3 Apple-style polish (depth layer)
Every hero card and gold button gets the same stacked shadow/stroke treatment so it feels minted, not painted:

```
border:      0.5px gradient stroke (rgba rim)
shadow: inset 0 1px 0 rgba(255,255,255,0.20)   — top rim highlight
shadow: inset 0 -1px 0 rgba(shadow,0.40)       — bottom rim shadow
shadow: 0 2px 4px rgba(shadow,0.25)            — close contact
shadow: 0 12px 28px rgba(shadow,0.30)          — ambient
```

For green hero: `shadow = #071F0C`, rim highlight = `rgba(165,232,172,0.35)`
For gold button: `shadow = #5C3A0A`, rim highlight = `rgba(255,251,232,0.50)`

---

## 2. Supporting tokens

```
primary       #2E7D32    accent        #4CAF50
lightGreen    #81C784    paleGreen     #E8F5E9
bg            #FAFAF8    cardBg        white
deepGreen     #1B5E20    darkGreen     #1A5C38
mintBg        #C8E6C9    mintLight     #A5D6A7

textPrimary   #1A2E1A    textSecondary #6B7A6B    textTertiary #A0B0A0
goldBase      #C59430    goldText      #E8B84B    goldForeground #1B3A00

positive      #4CAF50    warning       #FF7043    danger       #FF6B6B
```

All tokens live in `DesignSystem.swift`. **Never hardcode `Color(hex:)` in views.**

---

## 3. Element usage rules

| Element | Treatment |
|---|---|
| Hero cards (streak, check-in, CTA panels) | `DS.heroGradient` + Apple polish |
| Primary action button | `DS.nuggetGold` + Apple polish (minted coin) |
| Secondary button | `DS.paleGreen` fill, `DS.textPrimary` label |
| Tab bar background | `Color.white` + 0.5px top stroke `DS.accent.opacity(0.15)` |
| Tab bar active icon | `DS.deepGreen` |
| Tab bar inactive icon | `DS.textTertiary` |
| White cards | `DS.cardBg` + 0.5px stroke `DS.accent.opacity(0.15)` + soft drop shadow |
| App background | `DS.bg` |
| Section header | 11pt weight 800, `DS.accent`, uppercase, tracking 1.5 |
| Research citation pill | `#FFF8E1` bg, `#C59430` text, book.closed.fill icon |
| Nudge avatar | `NudgeAvatar(size:)` — never raw Image("nudge") |

---

## 3.5 Master typography

SF Pro only (Apple-approved). Serif reserved for numbers where editorial/luxury feel is wanted. All text uses semantic roles so Dynamic Type works automatically.

### Notification surfaces (Nudge card, Nudge-branded greeting)

| Element | Font |
|---|---|
| "NUDGE" label | `.system(size: 11, weight: .heavy, design: .rounded)` · tracking 1.5 · `DS.accent` · uppercase |
| Body message | `.system(.subheadline, weight: .semibold)` · `DS.textPrimary` · lineSpacing 3 |
| Citation (optional, biases only) | `.system(.caption2, weight: .semibold)` · `DS.textTertiary` |
| Coin avatar | 56pt (card) · 40pt (inline greeting) |

### Buttons

| Element | Font |
|---|---|
| Gold CTA (`.goldButtonStyle()`) | `.system(.headline, weight: .bold)` · `DS.goldForeground` |
| Secondary button label | `.system(.subheadline, weight: .semibold)` · `DS.textPrimary` |

### Headings / greeting

| Element | Font |
|---|---|
| Greeting welcome line | `.system(.headline, weight: .semibold)` · `DS.textPrimary` |
| Date caption | `.system(.caption2, weight: .medium)` · `DS.textTertiary` · format `"EEE · d MMMM"` |
| Calendar month header | `.system(.headline, weight: .semibold)` · `DS.textPrimary` |
| Section label (brand) | `.system(size: 11, weight: .heavy, design: .rounded)` · `DS.accent` · uppercase · tracking 1.5 |

### Numbers (kept serif for luxury/editorial feel)

| Element | Font |
|---|---|
| Streak count | `.system(size: 40, weight: .black, design: .serif)` · `DS.goldText` |
| Bias count (stats) | `.system(size: 22, weight: .black, design: .serif)` |

### Rules

- Never hardcode `.font(.system(size: N, ...))` for body/label/heading text. Use semantic roles.
- Inline sizes (size: N) only for numbers (luxury serif) or the NUDGE brand label.
- Never use `design: .serif` for body or labels. Serif is reserved for numeric emphasis.
- All Nudge card instances must use `NudgeSaysCard`. Never reimplement.
- All research citations must use `ResearchFootnote` (see §3.6). Never roll inline.
- This spec applies on: Home, Why (removed, now CredibilitySheet), Awareness, CheckIn, Log, Onboarding, SignIn, InsightFeed, Nudge cards everywhere.

### Canonical role → font table (locked)

| Role | Font | Colour |
|---|---|---|
| Tab screen title | `.largeTitle .bold` | `DS.textPrimary` |
| Tab screen subtitle | `.subheadline .medium` | `DS.textSecondary` |
| Section label (brand) | 11pt `.rounded .heavy` tracking 1.5 uppercase | `DS.accent` |
| Card title | `.headline .semibold` | `DS.textPrimary` |
| Card body | `.subheadline .regular` lineSpacing 3 | `DS.textPrimary` |
| Card subtitle / meta | `.footnote .medium` | `DS.textSecondary` |
| Research footnote | `.footnote .semibold` (was .caption2) | `DS.textSecondary` (was .textTertiary) |
| Empty state copy | `.subheadline .medium` | `DS.textSecondary` |
| Caption / hint | `.caption .medium` | `DS.textTertiary` |
| Streak / bias count numeric | `.system(size: 40, weight: .black, design: .serif)` | `DS.goldText` / `DS.deepGreen` |

---

## 3.6 Research footnote component

All research citations (BFAS, Pompian, Kahneman, Thaler, Sunstein, ABS data source, etc.) render through a single `ResearchFootnote` view. Never inline.

**API:**
```swift
ResearchFootnote(text: "Based on the BFAS framework · Pompian, 2012")
ResearchFootnote(text: "ABS Household Expenditure Survey 2022–23", icon: "chart.bar.doc.horizontal")
ResearchFootnote(text: "...", style: .pill)   // gold pill wrapper
ResearchFootnote(text: "...", style: .inline) // default: icon + text
```

**Inline style (default):**
- Icon: 10pt `book.closed.fill` (or passed), `DS.goldBase`
- Text: `.footnote .semibold`, `DS.textSecondary`
- HStack spacing 6pt, `.firstTextBaseline`

**Pill style:**
- Same icon + text
- Wrapped in `#FFF8E1` bg Capsule, 0.5px `DS.goldBase.opacity(0.3)` stroke
- Horizontal padding 12, vertical 7

**Where to use:**
- Under tab titles (Insights, Awareness, Log) — pill style
- At the bottom of category/bias sections — inline
- Inside `NudgeSaysCard` citation slot — inline (already implemented)
- On onboarding screens — pill (already implemented)

---

## 4. Radii + spacing

```
cardRadius    20pt
buttonRadius  14pt
capsule       999pt (pill buttons)
hPadding      16–18pt
sectionGap    20pt
```

---

## 5. Tab-by-tab application

4-tab app (v1.3). Why tab removed — all its content absorbed into the `CredibilitySheet` accessible from the Home Top Biases `ⓘ`.

| Tab | Hero uses | Gold uses | Notes |
|---|---|---|---|
| Home | streak card, check-in card | Start check-in button | Awareness circle: `heroGradient` stroke |
| Log (MoneyEvent) | confirmation hero | Save button | Category grid: white cards |
| Insights | bias detail header | "Mark as noticed" button | Stage pills stay semantic |
| Awareness | bias card active state | "Begin learning" CTA | |

### 5.1 Research footnote placement per tab (locked — text polish pass)

| Tab | Placement | Copy | Style |
|---|---|---|---|
| Home | Under Top Biases card | "BFAS · Behavioural Finance Assessment Score" | Inline |
| Log | Under tab title | "Powered by the BFAS framework · Pompian, 2012" | Pill |
| Log | Under category grid | "Ranges based on ABS Household Expenditure Survey 2022–23" | Inline, `chart.bar.doc.horizontal` icon |
| Insights | Under tab title | "Patterns assessed via BFAS · Pompian, 2012" | Pill |
| Awareness | Under awareness score bar | "Based on the BFAS framework — used in professional financial planning assessments" | Inline, readable weight |
| CheckIn | Under progress dots | "Q N of M · from BFAS assessment" — already implemented | Inline caption |
| Onboarding | Screen 1 under intro copy | "Based on 40+ years of behavioural research" — already implemented | Pill |

### 5.2 Text polish master plan (execution order)

1. **Build `ResearchFootnote` component** (new file).
2. **Fix Home truncation bug** — welcome message `lineLimit(3)`, drop `minimumScaleFactor`.
3. **Apply §3.5 role table** to tab titles, card titles, footnotes across Home, Log, Insights, Awareness.
4. **Swap every inline citation** to `ResearchFootnote` (pill or inline per §5.1).
5. **Handbook + STATUS + CHANGELOG** updated.

No content changes — only rendering consistency + visibility.

---

## 6. What NOT to do

- Never flat 2–3 stop green on hero cards. Always `DS.heroGradient`.
- Never raw `Color(hex: …)` in any View file. Use DS tokens.
- Never purple, violet, pink, blue accents. Green + gold only.
- Never yellow/gold squares on tone picker — use white opacity buttons.
- Never text input on check-in card front — swipe YES/NO only.
- Never inline `LinearGradient(colors: […])`. Always reference `DS.heroGradient` or `DS.nuggetGold`.

---

## 7. Empty-state patterns

### 7.1 Home — monthly calendar card

Inserted between the check-in hero and the Nudge card on `HomeView`. Shows the current month; days with logged money events are filled; tap any event-day → popover with top biases.

- Header: `MMMM yyyy` + total event count this month
- Week labels: M T W T F S S (ISO weekday, Monday-first)
- Day cells:
  - Empty day → small grey number, disabled
  - Day with events → filled `DS.accent` rounded pill, bold white number, tappable
  - Today → additional `DS.goldBase` 1.5px outline ring
- Popover: date header · event count · total $ · top 3 biases (tag × count) · empty-state "No bias tags that day"
- Source: `HomeViewModel.monthEventsByDay: [String: [MoneyEvent]]`, populated in `load()` from `SupabaseService.fetchMoneyEvents(forMonth:)`
- Component: `Views/MonthCalendarView.swift`
- No hardcoded events, no mock fallback — empty months render empty cells

### 7.3 Home — Top 4 biases tracker card (under calendar)

Backend-driven. Inserted directly beneath `MonthCalendarView` on Home. Shows the user's top-ranked biases from `BiasScoreService`. User never sees raw scores — only ranked name, trend, stage.

**Layout:**
```
┌──────────────────────────────────────┐
│ YOUR TOP BIASES              4/16    │
│                                      │
│ 🧠  Present Bias          ↗️  Active │
│ 🏷️  Anchoring             –   Noticed│
│ 👥  Social Proof          ↘️  Emerging│
│ ⚡  Scarcity Heuristic   ↗️  Active │
└──────────────────────────────────────┘
```

- Section label: `YOUR TOP BIASES` (11pt `.rounded` heavy, handbook §3.5)
- Counter right-aligned: `N/16` where N = biases with score > 0
- Row: emoji (18pt) · bias name (`.subheadline` semibold) · trend arrow · mastery stage pill
- Tap row → opens `BiasDetailView`
- Empty state: "Complete your first check-in to start tracking"
- Source: `HomeViewModel.dailyPatterns` (already populated in `load()`)
- Take top 4 by `score` DESC

**Stage pill colors** (from `DS.stage*`):
- `unseen` → grey outline
- `noticed` → `DS.stageNoticed` bg
- `emerging` → `DS.stageEmerging` bg
- `active` → `DS.stageActive` bg
- `aware` → `DS.positive` bg

**Never shown to user:** raw score number, BFAS weight, answer history.

---

### 7.2 Home — Nudge welcome message (top greeting)

The top-left greeting on `HomeView` is produced by `NudgeEngine.welcomeMessage(...)`. Never hardcode greeting copy in the view.

**Inputs (from `HomeViewModel`):**
- `hour` — `Calendar.current.component(.hour, from: Date())`
- `isFirstOpen` — `!UserDefaults.standard.bool(forKey: "hasSeenNudge")`
- `streak`, `checkedInToday` (`todaysCheckIn != nil`), `loggedEventToday` (`hasLoggedEventToday`)

**Copy matrix:**

| State | Copy |
|---|---|
| First open | "Hi, I'm Nudge. Ready to understand your money mind?" |
| Morning + streak 0 | "Good morning. Let's start seeing your patterns." |
| Morning + streak 1–6 | "Good morning. Day {N} of noticing." |
| Morning + streak 7+ | "Good morning. Habit is forming." |
| Afternoon + no check-in | "Good afternoon. Quick check-in?" |
| Afternoon + checked in | "Good afternoon. Nice momentum." |
| Evening + no events today | "Good evening. Any money moments today?" |
| Evening + events today | "Good evening. Patterns noticed today." |

**Voice rules:** dry wit, short lines, never "great job", no shame language. New states added to this spec must follow the same tone.

---

## 8. Credibility cues

Evidence-based consumer design (NNg Group pattern). Hide the ranking math, surface research authority at key moments. Applied sparingly, never shouty.

### 8.1 Home — Top Biases `ⓘ` + CredibilitySheet

On the `TopBiasesCard` header, insert a small `info.circle.fill` icon (14pt, `DS.deepGreen`) right after the "YOUR TOP BIASES" label. Tap → presents `CredibilitySheet` as a `.sheet(isPresented:)`.

**CredibilitySheet sections (top to bottom) — absorbs all content from the deprecated Why tab:**

1. **Hero** — Nudge 56pt coin · "Backed by research" `.largeTitle` bold · subtitle "How AwareBudget ranks your patterns" `.subheadline` `DS.textSecondary`.
2. **THE IDEA** — 3 lines: "Most budgets track the wrong thing. AwareBudget tracks how you decide, not what you bought."
3. **THE DIFFERENCE** — comparison table (2 columns, Traditional × vs AwareBudget ✓), 5 rows (Focuses on / Feels like / Based on / When wrong / Result). Absorbed from Why.
4. **HOW THE RANKING WORKS** — 3 plain-English bullets. Never show formula.
5. **WHAT THE STAGES MEAN** — 5-row stage legend with pill colors + descriptions.
6. **THE FRAMEWORK** — "Built on the BFAS framework" expanded card. Absorbed from Why's BFAS panel.
7. **THE RESEARCH** — 4 citation cards in 2×2 grid (Pompian 2012, Kahneman & Tversky 1979, Thaler & Sunstein 2008, Kahneman et al 2004).
8. **YOU'RE NOT BROKEN** — closing hero panel (dark `heroGradient`, Nudge coin 36pt, "You're not broken. The method is.", supporting copy). Absorbed from Why.
9. **NUDGE SAYS** — one `NudgeSaysCard` about the assessment (NOT redundant — this is the in-context Nudge voice talking *about* the research sheet itself).
10. **CTA** — `.goldButtonStyle()` "Got it" — closes sheet.

### 8.2 Other sprinkle points (implemented later)

| Surface | Cue |
|---|---|
| Onboarding screen 1 | ✅ Implemented. Pill capsule under intro copy on the dark hero: white-opacity 0.12 bg, 0.5px white-opacity 0.2 stroke, `book.closed.fill` 10pt `DS.goldText` + `.caption2 .semibold` text "Based on 40+ years of behavioural research". |
| Check-in question screen | ✅ Implemented. Footer under progress dots: "Q{n} of {total} · from BFAS assessment" (`.caption2 .semibold` `DS.textTertiary`). Updates as user advances. |
| After answer submitted | ✅ Implemented. On advance, `flashedCitation` state flips to the just-answered bias's `keyRef`. Replaces the "Q{n} of {total}" footer for 1.6s with a gold pill (`#FFF8E1` bg, `book.closed.fill` 9pt `DS.goldBase`, `.caption2 .semibold` text in `#8B6010`). Cross-fade back to footer. |
| BiasDetail | ✅ Implemented. New "The research" section after "How to counter it" — full BibTeX-style citation (from `allBiasPatterns[biasName].citation`) in a `#FFF8E1` card with `book.closed.fill` 12pt `DS.goldBase` + `.footnote .medium` body. Falls back to "Citation coming soon." if no match. |
| Weekly review | "Reviewed by the BFAS framework" badge on summary header |
| BFAS completion | "Your baseline is set. Based on Pompian, 2012." caption |

### 8.3 Rules

- Never expose raw score, BFAS weight, or formula text in the UI.
- Citations must be real — the 4 above are the canonical set. Never fabricate.
- Don't shout — each cue is a single line, small size. No full-page "how it works" walls except in `Why` tab.
- Don't duplicate — if `WhyView` already says it, link to it, don't re-render.

---

## 9. Reference preview

Static HTML palette preview at repo root: `preview_palette.html` — open in browser to see hero, gold button, swatches, A/B strips. Kept in sync with `DesignSystem.swift` whenever the palette changes.
