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

## 8. Reference preview

Static HTML palette preview at repo root: `preview_palette.html` — open in browser to see hero, gold button, swatches, A/B strips. Kept in sync with `DesignSystem.swift` whenever the palette changes.
