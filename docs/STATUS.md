# STATUS — AwareBudget

> Single source of truth for where the build currently stands.
> Update this file whenever you finish a unit of work.

**Last updated:** 2026-04-12
**Current phase:** PRD v1.1 — Money Green + Nugget Gold + NudgeEngine + category-free money events. 4-tab root, swipe cards, spending driver tags, Nudge mascot card, awareness-based MoneyEventView (planned/surprise/impulse + behaviour tags, no categories) all live. Supabase wiring blocked on Xcode package add.

---

## ✅ Done

### Project structure
- Xcode project (`AwareBudget.xcodeproj`) is wired to a
  `PBXFileSystemSynchronizedRootGroup` at `AwareBudget/`. Any file added to
  that folder is compiled automatically.
- Folder layout matches PRD: `Models/`, `Views/`, `ViewModels/`, `Services/`.
- `supabase/schema.sql` and `supabase/seed.sql` ready to run.

### Models (`AwareBudget/Models/`)
- `CheckIn.swift` — `EmotionalTone` enum with emoji updated to PRD v1.1
  set: calm=😌 · neutral=😐 · anxious=😟
- `MoneyEvent.swift` — **rebuilt**: `PlannedStatus` (planned/surprise/impulse),
  `behaviourTag` (SpendingDriver rawValue), `lifeEvent` (for large amounts),
  derived `sizeBucket`. No categories. `MoneyCategory` enum removed.
- `Question.swift` — PRD v1.1: now includes `biasCategory: String` and
  `difficulty: String` with snake_case `CodingKeys` (`bias_category`)
- `BiasLesson.swift` — **NEW** PRD v1.1 model: id, bias_name, category,
  short/full/real/howToCounter text, emoji, sort_order
- `BudgetMonth.swift`
- `MonthlyDecision.swift`
- `QuestionPool.swift` stub seed updated so all 15 hard-coded rows pass
  the new required `biasCategory` + `difficulty` initialiser args

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
- `CheckInView.swift` — **rebuilt again as swipe card stack** (2026-04-12).
  Three stacked cards (front #2D1B69, middle #3D2B85 scaled 0.96,
  back #EEEDFE scaled 0.92). DragGesture: swipe-up > 80pt = complete,
  swipe-right > 80pt = skip, release < threshold = spring back. Front
  card content: gold `#F5C742` bias pill showing `BiasName · Category`,
  `.title3.weight(.bold)` white question text, optional response
  TextField, "Why this matters" toggle with rotating chevron collapsed
  by default, tone picker 😌/😐/😟 (all optional). Progress dots at
  top (gold, one per attempted question). Swipe hints at edges.
  After all cards: transitions to **spending driver pick** screen —
  "What drove this?" with 2x3 grid of pill-style `SpendingDriver`
  tags (Present Bias / Social / Reward / Convenience / Identity /
  Friction). Single-select, optional skip. Tone: "curious, not
  corrective". Continue/Skip button advances to completion view.
  Completion view: green circle + checkmark + "Nice work" + selected
  driver chip (if any) + Done button.
  Mock data from `QuestionPool.seed.shuffled().prefix(5)` —
  no Supabase yet. Accepts optional `selectedTab: Binding<RootTab>?`
  to integrate with root tab bar (hides xmark when embedded). On
  completion, schedules `NotificationService.scheduleDailyReminder()`.
  `CheckIn.SpendingDriver` enum added to `CheckIn.swift`: 6 cases
  with rawValue matching the `spending_driver` DB column
  (`present_bias`, `social`, `emotional`, `convenience`, `identity`,
  `friction_avoid`). Each case has label, shortDescription, emoji.
  Migration `20260412150000_add_spending_driver.sql` adds nullable
  `spending_driver` text column with CHECK constraint to
  `daily_checkins`.
- `LearnView.swift` — **NEW** PRD v1.1 swipe card deck. Header
  "Understanding your money mind", horizontal-scroll filter pill row
  (All + 7 categories with static `categoryColour(for:)` returning
  the 7 hex pairs from PRD), card stack of 3 (front white with 0.5px
  purple border, middle #F0EEF8 0.96, back #E8E5F5 0.92). Front
  card: 48pt emoji, category pill + mock "Seen 0 times" badge,
  `.title2` bold #2D1B69 bias name, secondary short description,
  divider, teal "IN REAL LIFE" label, teal-tinted example card, and
  deep-purple "How to counter it →" NavigationLink button. Horizontal
  DragGesture cycles cards. Dot indicator at bottom is tappable.
  `.navigationDestination(for: BiasLesson.self)` pushes
  `BiasDetailView(lesson:)`. Sources `BiasLessonsMock.seed`.
- `BiasDetailView.swift` — **NEW** PRD v1.1. Receives `BiasLesson` +
  mock `timesSeen: Int = 0`. Layout: 72pt emoji, `.largeTitle` bold
  #2D1B69 name, category pill via `LearnView.categoryColour(for:)`,
  `.title3` short description, optional "Seen X times" row
  (conditional on `timesSeen > 0`), "What it is" section with
  fullExplanation, teal-tinted "IN REAL LIFE" card with
  realWorldExample, "How to counter it" section with howToCounter
  body.
- `HomeView.swift` — **rebuilt 2026-04-12** with brand palette.
  Background `#F7F4EF` (`DS.bg`). Hero check-in card is a full-width
  `#2D1B69` (`DS.deepPurple`) rounded rectangle with white text,
  coral accent icon, and teaser question. Tapping it switches the
  root tab to `.checkIn` via optional `selectedTab` binding. The
  streak section now renders `StreakRingView` (coral circular ring
  with progress fill out of 7-day goal, streak count in bold rounded
  font, M-S day dots row below) inside a white rounded card with
  0.5px `#7F77DD` border. Alignment card, log-event button, and
  recent activity rows all use the white-card-with-accent-border
  treatment. `HomeViewModel` now computes `weekDots: [Bool]`
  (Mon-Sun of current ISO week) from
  `fetchRecentCheckIns(limit: 14)`. Old ❌ full-screen-cover for
  `CheckInView` removed — root tab navigation replaces it.
- `StreakRingView.swift` — **NEW** reusable component. 180pt coral
  circular ring with 14pt line width, `#FF7A6B` stroke, progress
  trimmed to `min(streak / goalDays, 1.0)`, large 56pt rounded
  streak count inside, "DAY STREAK" caption. Below the ring: a row
  of 7 labelled dots (M T W T F S S) filled coral when that day has
  a check-in, otherwise grey.
- `RootTabView.swift` — **NEW** 4-tab root. Tabs: Home / Check in /
  Learn / Month. `@State selection: RootTab` binding passed down to
  `HomeView` and `CheckInView` so they can switch tabs. Uses
  `.tint(DS.accent)` for active tab color. `AwareBudgetApp.swift`
  now mounts `RootTabView()` (with a `.task { await
  NotificationService.requestPermission() }` on launch) in place of
  the old `NavigationStack { HomeView() }`.
- `DesignSystem.swift` — **Money Green + Nugget Gold** colour system.
  `DS.primary` `#2E7D32`, `DS.accent` `#4CAF50`, `DS.lightGreen`
  `#81C784`, `DS.paleGreen` `#E8F5E9`, `DS.bg` `#FAFAF8`,
  `DS.cardBg` white. Text: `DS.textPrimary` `#1A2E1A`,
  `DS.textSecondary` `#6B7A6B`, `DS.textTertiary` `#A0B0A0`.
  Semantic: `DS.positive` `#4CAF50`, `DS.warning` `#FF7043`.
  Gold: `DS.goldBase` `#C59430`, `DS.goldText` `#E8B84B`,
  `DS.nuggetGold` 5-stop gradient. `GoldButton` + `GoldRingModifier`
  ViewModifiers. `SectionHeader` updated to 10pt bold `DS.accent`
  uppercase. `PrimaryButtonStyle` default tint `DS.primary`.
  `SecondaryButtonStyle` uses `DS.paleGreen` fill. `Card` uses
  `DS.cardBg`. All purple/violet hex values removed.
- `MoneyEventView.swift` — **rebuilt**: no categories. Flow: amount →
  planned/surprise/impulse (3 full-width buttons) → conditional behaviour
  tag picker (2x3 grid, only for surprise/impulse) → conditional life
  event picker (only if amount > 200) → note → date → save. All sections
  animate in/out with spring. Uses DS green palette throughout.
- `MonthView.swift` — **rebuilt**: alignment %, income target, unplanned
  spend ratio card (% + surprise/impulse pill counts), top behaviour card
  (most-tagged SpendingDriver), events grouped by PlannedStatus with
  behaviour tag labels. No categories. Uses DS green palette.

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
- `supabase db push` (2026-04-12, PRD v1.1 migration) → applied
  `20260412120000_add_bias_lessons_and_progress.sql`. Remote DB now also has:
  - `bias_lessons` table (empty — seed pending)
  - `user_bias_progress` table (empty)
  - `question_pool.bias_category` (nullable) + `question_pool.difficulty`
    (default `'beginner'`) columns added
  - RLS + `"read lessons"` SELECT policy on `bias_lessons`
  - RLS + `"own data only"` policy on `user_bias_progress`
  - Verified via REST: `bias_lessons` returns `[]`, `question_pool`
    row confirms new columns exist.
- `supabase db push` (2026-04-12, PRD v1.1 question seed) → applied
  `20260412130000_seed_15_new_questions.sql`. Inserted 15 new rows into
  `question_pool` (covering one new intermediate/advanced question per
  existing bias where PRD v1.1 has a second, plus both Availability
  Heuristic questions and the single Framing Effect question). Verified
  via REST: `question_pool` now returns `content-range: 0-29/30` — 30
  rows total. Existing 15 rows untouched and still have
  `bias_category = NULL` pending backfill.
- `supabase db push` (2026-04-12, PRD v1.1 bias lessons seed) → applied
  `20260412140000_seed_bias_lessons.sql`. Inserted all 16 bias_lessons
  rows verbatim from `docs/PRD.md` § "Seed Data — 16 Bias Lessons"
  (Ostrich Effect → Framing Effect, sort_order 1–16). Verified via REST:
  `bias_lessons?order=sort_order.asc` returned all 16 with correct
  emoji + sort_order.
- Migrations source of truth:
  - `supabase/migrations/20260412000000_initial_schema.sql`
  - `supabase/migrations/20260412120000_add_bias_lessons_and_progress.sql`
  - `supabase/migrations/20260412130000_seed_15_new_questions.sql`
  - `supabase/migrations/20260412140000_seed_bias_lessons.sql`
- Seed source of truth: `supabase/seed.sql` (15 original questions — kept
  for reference; 15 new PRD v1.1 questions + 16 bias_lessons are live via
  the migrations above)

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

## 📐 Swipe card architecture (appended to PRD 2026-04-12)

`docs/PRD.md` → new § "Swipe Card Architecture" between "Screens &
Features" and "Navigation". Specifies:
- **CheckInView**: card stack of 3 (front `#2D1B69`, middle `#3D2B85`
  scaled 0.96, back `#EEEDFE` scaled 0.92). DragGesture thresholds
  swipe-up > 80pt = complete, swipe-right > 80pt = skip (no streak
  impact), release < threshold = spring back. Front card content
  order: bias pill (gold), question (.title3 bold white), optional
  response field, collapsed "Why" toggle with rotating chevron, tone
  picker 3 buttons, all optional except the swipe gesture. Progress
  dots at top (one per attempted question), swipe hints at edges.
- **LearnView**: card stack of 3 visible (front white with 0.5px purple
  border, middle `#F0EEF8` 0.96, back `#E8E5F5` 0.92). Front card:
  48pt emoji, category pill, seen-count badge, `.title2` bold
  `#2D1B69` bias name, `.body` secondary short description, divider,
  teal "In real life" label, tinted example card, primary
  "How to counter it →" button `#2D1B69`. Swipe left/right OR tap
  dot indicator (5 dots showing filtered-set position). Category
  filter pills with 7 hardcoded hex colour pairs per bias category.

## 🔜 Next up (in order)

1. **[BLOCKED on Xcode UI]** Add Supabase Swift package:
   `File → Add Package Dependencies → https://github.com/supabase/supabase-swift`
2. Wire real Supabase calls in `SupabaseService.swift` (replace stub)
   once package is in place. Extend with `fetchAllBiasLessons`,
   `fetchBiasLesson(biasName:)`,
   `updateBiasProgress(biasName:reflected:)`, `fetchBiasProgress`.
3. Swap `LearnView` / `BiasDetailView` / `HomeView` / `CheckInView`
   off mock data once the service is live.
4. Backfill `bias_category` on the original 15 `question_pool` rows.
5. Verify sign-up → first check-in → streak = 1 flow on device/simulator.
6. Verify notification permission prompt fires after first check-in
   (permission request already wired in `AwareBudgetApp.task`).
7. TestFlight build.

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
