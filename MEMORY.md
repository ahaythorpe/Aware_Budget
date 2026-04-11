# MEMORY — AwareBudget

> Durable facts about this project and the person building it.
> Distinct from `STATUS.md`: memory is *slow-changing*, status is *fast-changing*.
> Update when something new is learned that will matter next session.

---

## Product philosophy (non-negotiable)

- **"Stay aware. Adjust early. No shame."** — the tagline is a design brief.
- Counter the **Ostrich Effect**: make checking in low-friction (under 90s).
- Success = awareness streak + alignment %, **not** budget perfection.
- Never shame the user. No red without reassurance copy. No "streak broken".
- Behavioural education (`whyExplanation`) is always **opt-in** — the "Why?"
  disclosure must be collapsed by default.
- All financial data is logged **manually** — no bank sync, ever.

## Owner / intended audience

- The app is being built by **Arabella** (bundle id `Arabella.AwareBudget`).
- Target platforms (per project settings): iPhone, iPad, Mac Catalyst, visionOS.
- Beta distribution channel: TestFlight.

## Architecture decisions (stable)

- **MVVM** with `@Observable` (Swift 5.9 / iOS 17 macro), not `ObservableObject`.
- **async/await only**. No Combine anywhere.
- **Supabase** is the only backend. No Firebase, no CloudKit.
- **Stub-first**: `SupabaseService` ships with an in-memory stub so the app
  runs before the Supabase Swift package is added. Real wiring is a single
  file swap, not a refactor, because the method signatures already match.
- **Xcode synchronized groups** (`PBXFileSystemSynchronizedRootGroup`, Xcode 16+)
  are used for the source folder — do **not** add files via `project.pbxproj`
  edits. Drop Swift files into `AwareBudget/<subfolder>/` and they compile.

## Behavioural copy reference

Streak messages (by streak length):
- 0 → "Start your streak today"
- 1–6 → "Keep showing up"
- 7–13 → "One week strong"
- 14–29 → "You're building a habit"
- 30+ → "Awareness mastery"

Alignment colour bands:
- ≥80% green / 50–79% orange / <50% red — always paired with reassurance.

## Conventions

- Semantic colours only (`.primary`, `Color(.secondarySystemBackground)`, etc.)
  No hex literals, no gradients, no shadows. Flat design.
- Corner radius: 16 for cards, 12 for buttons.
- Spacing: 16pt inside cards, 24pt between sections.
- SF Symbols for all icons (`flame.fill`, `gearshape`, `checkmark.circle.fill`).
- Never `@AppStorage` for sensitive data — only for UI flags like
  `hasCompletedOnboarding`.

## External dependencies (intended, not yet added)

| Package                                     | Purpose          | Version     |
|---------------------------------------------|------------------|-------------|
| https://github.com/supabase/supabase-swift  | Auth + DB client | latest      |

## References

- Full PRD: `PRD.md`
- Supabase schema: `supabase/schema.sql`
- Question seed data: `supabase/seed.sql`
