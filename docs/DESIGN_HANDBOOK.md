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
- This spec applies on: Home, Why, Awareness, CheckIn, Log (Money Event save button), Onboarding, SignIn, InsightFeed, Nudge cards everywhere. Do NOT use for in-body content text elsewhere unless that text is itself a button, Nudge card, or greeting.

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

| Tab | Hero uses | Gold uses | Notes |
|---|---|---|---|
| Home | streak card, check-in card | Start check-in button | Awareness circle: `heroGradient` stroke |
| Insights (Learn) | bias detail header | "Mark as noticed" button | Stage pills stay semantic |
| Log (MoneyEvent) | confirmation hero | Save button | Category grid: white cards |
| Library | bias card active state | "Begin learning" CTA | |
| Why | top hero, bottom CTA panel | "That's why AwareBudget exists →" | Comparison table: white card |

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

**CredibilitySheet sections (top to bottom):**

1. **Hero** — Nudge 56pt coin · "Backed by research" `.title3` bold · subtitle "How AwareBudget ranks your patterns" `.subheadline` `DS.textSecondary`.
2. **Short Why** (3 lines reused from `WhyView`) — "Most budgets track the wrong thing. AwareBudget tracks how you decide, not what you bought."
3. **How the ranking works** — 3 plain-English bullets. Never show formula.
   - "Each check-in answer and tagged spend feeds your bias profile."
   - "The algorithm ranks biases by how often they show up in your decisions."
   - "As you notice them, they move from *Active* → *Aware*."
4. **Stage legend** — 5 rows (Unseen / Noticed / Emerging / Active / Aware) — each with its pill color from §3 + 1-line description.
5. **The research** — 4 citation cards (grid 2×2), each `#FFF8E1` bg + `book.closed.fill` icon + citation line:
   - Pompian, 2012 · BFAS
   - Kahneman & Tversky, 1979 · Prospect Theory
   - Thaler & Sunstein, 2008 · Nudge
   - Kahneman et al., 2004 · Day Reconstruction
6. **CTA** — `.goldButtonStyle()` "Read the full story →" — closes sheet + switches to `Why` tab.

### 8.2 Other sprinkle points (implemented later)

| Surface | Cue |
|---|---|
| Onboarding screen 1 | "Based on 40+ years of behavioural research" tag under hero |
| Check-in question screen | Footer "Q{n} of {total} · from BFAS assessment" (`.caption2` `.medium` `DS.textTertiary`) |
| After answer submitted | Citation pill flashes briefly (300ms fade) — `#FFF8E1` bg, `book.closed.fill` + citation text |
| BiasDetail | Full citation card (audit if present, add if not) |
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
