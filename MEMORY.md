# MEMORY — AwareBudget

> Durable facts about this project and the person building it.
> Distinct from `STATUS.md`: memory is *slow-changing*, status is *fast-changing*.
> Update when something new is learned that will matter next session.

---

## Product philosophy (non-negotiable)

- **"Stay aware. Adjust early. No shame."** — the tagline is a design brief.
- Counter the **Ostrich Effect**: make checking in low-friction (under 90s).
- Success = awareness streak + behaviour trends, **not** budget perfection.
- Never shame the user. No red without reassurance copy. No "streak broken".
- Behavioural education (`whyExplanation`) is always **opt-in** — the "Why?"
  disclosure must be collapsed by default.
- All financial data is logged **manually** — no bank sync, ever.
- **No categories on money events.** Planned/Surprise/Impulse only +
  behaviour tags (SpendingDriver). "Anchoring-driven spend" > "Shopping".

## Owner / intended audience

- The app is being built by **Arabella** (bundle id `Arabella.AwareBudget`).
- Sole dev, working with Claude Code. Jay (boyfriend) is busy with ScrollPaper.
- Target platforms: iPhone, iPad (iOS 26.2 / Xcode 26).
- Beta distribution channel: TestFlight.

## Architecture decisions (stable)

- **MVVM** with `@Observable` (Swift 5.9 / iOS 17 macro), not `ObservableObject`.
- **async/await only**. No Combine anywhere.
- **Supabase** is the only backend. supabase-swift 2.43.1 is live and wired.
- **Xcode synchronized groups** (`PBXFileSystemSynchronizedRootGroup`, Xcode 16+)
  are used for the source folder — do **not** add files via `project.pbxproj`
  edits. Drop Swift files into `AwareBudget/<subfolder>/` and they compile.

## Design system — Money Green + Nugget Gold (decided 2026-04-12)

All purple/violet removed. No `#2D1B69`, no `#7F77DD`.

### Colours (exact, from DesignSystem.swift)
- Primary: `#2E7D32` — hero cards, nav, CTA buttons
- Accent: `#4CAF50` — section labels, ring stroke, active filter pills
- Light green: `#81C784` — card backs, tints
- Pale green: `#E8F5E9` — pill backgrounds, tab active bg, why section bg
- Background: `#FAFAF8` (DS.bg) / `#F5F7F5` (view backgrounds)
- Cards: white
- Text: `#1A2E1A` / `#6B7A6B` / `#A0B0A0`
- Semantic: positive `#4CAF50`, warning `#FF7043`
- Gold: base `#C59430`, text `#E8B84B`
- Hero gradient: `#1B5E20→#2E7D32→#4CAF50→#388E3C` (topLeading→bottomTrailing)
- Nugget gold gradient: `#FFF0A0→#E8B84B→#C59430→#8B6010→#D4A843`
- Card borders: `rgba(76,175,80,0.15)` or `DS.paleGreen` at 0.5px
- Section labels: 11pt heavy `#4CAF50` uppercase tracking 1.5
- All hero cards MUST use gradient, never flat green

### Nudge mascot (decided 2026-04-12)
- Name: Nudge. Gold metallic coin, thinking pose, raised eyebrow.
- Source: `images/Nudge_Asset.png` → `Assets.xcassets/nudge.imageset/nudge.png`
- NudgeAvatar: green Circle + clipped Image("nudge") to mask black PNG bg
- Sizes: 44pt NudgeCard, 72pt completion, 100pt onboarding, 32pt inline
- Appears in exactly 5 places:
  1. NudgeCardView on HomeView
  2. CheckInView completion card
  3. CheckInView follow-up inline
  4. MoneyEventView after behaviour tag selected
  5. OnboardingView welcome screen
- Personality: dry wit, max 2 sentences, no "great job", no exclamation marks,
  references real data, third person sometimes, never financial advice

### CheckIn swipe system (decided 2026-04-12)
- Swipe RIGHT > 80pt = YES (green overlay). Swipe LEFT > 80pt = NO (coral overlay).
- Card rotates ±15 degrees during drag.
- NO text input field on check-in cards.
- Tone picker: white opacity buttons, NOT yellow squares.
- 2 back cards visible behind front card.
- Progress dots at top. "← No" coral left, "Yes →" green right hints.

### InsightFeedView — Charts framework (decided 2026-04-12)
- Uses `import Charts` (native SwiftUI, iOS 16+).
- Bar chart: unplanned spend 6 weeks, green improving, coral worsening.
- Horizontal bar chart: bias frequency from all events + check-ins.
- Donut chart (SectorMark): planned vs unplanned %.
- No SparklineView trend cards (replaced by native Charts).
- Bias emojis stay on learn cards (LearnView).

### LearnView card layout (decided 2026-04-12)
- Single back card only (not 2).
- 52pt emoji centred top, 22pt bold centred bias name, 13pt description max 2 lines.
- "IN REAL LIFE" teal label. Gold "How to counter it →" button bottom.
- "X of 16" counter below card.

## Conventions

- Background: `#F5F7F5` on all main views.
- Borders: `rgba(76,175,80,0.15)` on all cards.
- Corner radius: 20 for cards (`DS.cardRadius`), 14 for buttons (`DS.buttonRadius`).
- Spacing: 16pt (`DS.hPadding`) inside cards, 20pt (`DS.sectionGap`) between sections.
- SF Symbols for all icons.
- Never `@AppStorage` for sensitive data — only for UI flags like
  `hasCompletedOnboarding`.

## External dependencies

| Package                                     | Purpose          | Version |
|---------------------------------------------|------------------|---------|
| https://github.com/supabase/supabase-swift  | Auth + DB client | 2.43.1  |

## References

- Full PRD: `docs/PRD.md`
- Session handoff: `docs/HANDOFF.md`
- Supabase schema: `supabase/migrations/` (6 migration files)
- Question seed data: `supabase/seed.sql`
- Nudge image: `images/Nudge_Asset.png`
