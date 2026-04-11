# STATUS — AwareBudget

> Single source of truth for where the build currently stands.
> Update this file whenever you finish a unit of work.

**Last updated:** 2026-04-12
**Current phase:** Beta scaffolding complete — Supabase DB live, awaiting Swift package

---

## ✅ Done

### Project structure
- Xcode project (`AwareBudget.xcodeproj`) is wired to a
  `PBXFileSystemSynchronizedRootGroup` at `AwareBudget/`. Any file added to
  that folder is compiled automatically.
- Folder layout matches PRD: `Models/`, `Views/`, `ViewModels/`, `Services/`.
- `supabase/schema.sql` and `supabase/seed.sql` ready to run.

### Models (`AwareBudget/Models/`)
- `CheckIn.swift` — with `EmotionalTone` enum (calm/neutral/anxious + emoji)
- `MoneyEvent.swift` — with `EventType` (surprise/win/expected) and
  `MoneyCategory` enum
- `Question.swift`
- `BudgetMonth.swift`
- `MonthlyDecision.swift`

### Services (`AwareBudget/Services/`)
- `SupabaseService.swift` — **in-memory stub** (see "Blocked" below). Full
  method surface matches PRD: auth, check-ins, money events, questions,
  budget months.
- `QuestionPool.swift` — the 15 seed questions, used by the stub so the app
  works offline until Supabase is wired.
- `NotificationService.swift` — daily 8pm reminder scheduled via
  `UserNotifications`.

### ViewModels (`AwareBudget/ViewModels/`)
- `HomeViewModel.swift` — streak + alignment logic, colour + message
  computed properties, loads recent events.
- `CheckInViewModel.swift` — fetches next question, streak/alignment on
  submit, schedules the daily reminder on first completion.
- `MoneyEventViewModel.swift` — amount validation, save flow.

### Views (`AwareBudget/Views/`)
- `OnboardingView.swift` — 3-step explainer + sign-up form. First-launch
  only (flag in `@AppStorage("hasCompletedOnboarding")`).
- `HomeView.swift` — streak card, alignment card, tone row, primary
  buttons, recent events, navigation to `MonthView`.
- `CheckInView.swift` — question + "Why?" disclosure + tone picker +
  completion animation.
- `MoneyEventView.swift` — form sheet with amount / type / category /
  note / date.
- `MonthView.swift` — month totals, category breakdown, events by type,
  editable income target.

### App entry
- `AwareBudgetApp.swift` — root switches between `OnboardingView` and
  `HomeView` based on `@AppStorage("hasCompletedOnboarding")`.

---

## 🔐 Supabase project

- **Project ref:** `vdnnoezyogbgtiubamze`
- **URL:** `https://vdnnoezyogbgtiubamze.supabase.co`
- **Region:** Asia-Pacific
- **Public anon key:** wired into `Services/SupabaseService.swift` (safe to
  ship — `sb_publishable_...`)
- **Direct DB password + connection string:** stored in
  `.secrets/supabase.env` (gitignored, local only — never committed, never
  embedded in the iOS app)

## 🗄 Supabase CLI state

- `supabase init` → done (config.toml at `supabase/config.toml`)
- `supabase link --project-ref vdnnoezyogbgtiubamze` → done
- `supabase db push --include-seed` → done. Remote DB now has:
  - `budget_months`, `daily_checkins`, `money_events`,
    `monthly_decisions`, `question_pool`
  - RLS enabled on all user-owned tables
  - 15 rows in `question_pool` (verified via REST API)
- Migrations source of truth: `supabase/migrations/20260412000000_initial_schema.sql`
- Seed source of truth: `supabase/seed.sql`

## 🚧 Blocked / pending user action

1. **Add Supabase Swift package** (user must do this in Xcode UI):
   `File → Add Package Dependencies → https://github.com/supabase/supabase-swift`
2. **Swap the stub** — once the package is in place, replace the in-memory
   arrays in `SupabaseService` with real `client.from(...)` calls. All call
   sites already use the correct `async throws` signatures, so the view
   models and views do not need to change.
3. **(Optional) Add the Supabase MCP server** — run in a regular terminal:
   ```
   claude mcp add --scope project --transport http supabase \
     "https://mcp.supabase.com/mcp?project_ref=vdnnoezyogbgtiubamze"
   claude /mcp    # then pick "supabase" → Authenticate
   npx skills add supabase/agent-skills
   ```

## 🔜 Next up (in order)

1. Wire real Supabase calls in `SupabaseService.swift` (replace stub).
2. Verify sign-up → first check-in → streak = 1 flow on device/simulator.
3. Verify notification permission prompt fires after first check-in.
4. TestFlight build.

## 🧭 Beta scope reminder (from PRD)

Beta ships these screens only:
- OnboardingView (sign up only — no sign in yet)
- HomeView
- CheckInView
- MoneyEventView

`MonthView` is already built but is v1.1 scope. It works; it just isn't
gated as beta-required.

## ⚠️ Known gaps

- No sign-in flow yet (PRD says "no sign in for beta"). Returning users
  currently re-enter the stub path.
- No settings screen behind the gear icon on `HomeView`.
- No streak-history dots calendar on `MonthView` (PRD §MonthView mentions
  it — deferred to v1.1).
- Currency formatting uses the device locale; no user override.
