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

### 7.1 Log tab — pre-selection empty state

Before the user picks a category on `MoneyEventView`, fill the space with two backend-driven blocks. No hardcoded content, no mock fallback — if backend is empty, show an empty-state line.

**Block 1 — Check-in calendar strip**
- 7-day dot row, Monday→Sunday of current ISO week
- Source: `SupabaseService.fetchRecentCheckIns(limit: 14)` + `HomeViewModel.computeWeekDots()` logic (reuse, do not duplicate)
- Today = larger dot, gold outline ring
- Sunday badge when weekly review due
- Tap → opens `CheckInView`
- Empty state copy: *"No check-ins yet this week"*

**Block 2 — Top biases panel (ranked)**
- Top 3 biases from `bias_progress` table, ranked by `BiasScoreService.computeScore().score` — same logic as `HomeViewModel.dailyPatterns`
- Row: `emoji` · bias name · `timesEncountered` count · trend arrow (`↑` worsening / `↓` improving / `–` stable)
- Section heading: *"Your patterns to watch"*
- Empty state copy: *"Log 3 events to see your top patterns"*
- Gets richer as backend ranking matures (trend, mastery stage, score)

**Data dependencies (all already wired):**
- `SupabaseService.fetchRecentCheckIns`
- `SupabaseService.fetchBiasProgress`
- `BiasScoreService.computeScore`
- `BiasLessonsMock.seed` (emoji + name lookup only)

**Do NOT:**
- Hardcode bias names, counts, or check-in dates
- Fall back to mock data when backend returns empty — show the empty-state copy
- Duplicate `computeWeekDots` logic — reuse from `HomeViewModel`

---

## 8. Reference preview

Static HTML palette preview at repo root: `preview_palette.html` — open in browser to see hero, gold button, swatches, A/B strips. Kept in sync with `DesignSystem.swift` whenever the palette changes.
