# STATUS — GoldMind

> Single source of truth for where the build currently stands.
> Update this file whenever you finish a unit of work.

**Last updated:** 2026-04-17
**Current phase:** Algorithm rigour foundation, B + C decision-helper layers, and the financial-trend story v1 all shipped today. The "behaviour change → financial outcome" loop is now visible in-app: Settings → Net worth tracking lets the user enter monthly income + savings + investment manually (Privacy Act only, no bank API needed). Insights → Net worth trend plots the gold line over 6 months, overlaid with a faint dashed-green awareness curve (cumulative count of banked decision_lessons), with a Nudge insight card above ("Net worth up X% this month while you banked N awareness moments. The two move together"). Algorithm side: every (category × status) → bias mapping is citation-grounded in `BiasMappings.swift` with confidence flags; scoring is 5:1 active vs passive (cited from Stone 1991, Robinson & Clore 2002, Beck 1976); rotation cycles each Quick log through the shortlist; adaptive 14-day neglected-bias boost; per-mapping confirmation rate self-audit (UserDefaults + Supabase `bias_mapping_stats` + `bias_mapping_aggregate` view k-anonymity floor 50). Layers B (pre-spend hint banner per Gollwitzer 1999) and C (DecisionHelperSheet long-press for Gawande-style pre-decision checklist) both wired with outcome tracking. Critical fixes shipped: tolerant Date decoder (Home/Insights now actually populate — verified 0 EVENTS → 2 EVENTS), debug session no longer creates orphan users on every launch, MonthlyCheckpoint requires 30 days install. Insights chart palette swept (no orange), category trend chart replaced the unplanned bar chart (top 5 categories overlaid, tap legend to focus). Full methodology written up in `docs/ALGORITHM.md` with ~25 references. Build succeeds iPhone 17 Pro / iOS 26.2. AND morphs daily/weekly/monthly based on what's due — daily by default, weekly on Sundays not yet done, monthly checkpoint when this month's flag is empty. Quick log saves pop a small Nudge reward overlay at the top (~1.6s, bouncing coin, one-liner; every 5th save in a session gets a streak-flavoured line). New `Services/BiasRotation.swift` consolidates the (category × status) shortlist + per-pattern rotation index — single source of truth ready to be wired into the 3 call sites that currently each have their own copy. Earlier in the day: onboarding + BFAS gates now run in DEBUG too (release-mode auto-skip-onboarding bug also fixed). Duplicate Quick log sheet removed from Insights tab; CTA there now switches to Log tab so there is ONE entry point for the spend form. Home + Insights refetch on tab switch (fixes "logged event doesn't show on calendar / charts" — the `.task` modifier only fired on first appear). Skip-review popup replaced with single Apple-style white modal containing Nudge coin + NUDGE label + title + rotating chastise line + gold "Keep reviewing" pill + warning-red text-only "Skip anyway". BiasReview always shows the spend recap card above the question (was previously gated on `eventId != nil`); top-up questions recycle real session events with status-aware bias rotation. Calendar day popover now lists top-3 biases each with a one-line "how to counter" sentence. Onboarding bottom strip switched from solid `DS.deepGreen` to `DS.heroGradient` with shimmer overlay. Backlog: per-event bias rotation across 5–6 plausible biases for each category × status + 14-day neglected-bias boost (so all 16 get tested over time), 3-check-in daily cadence (meal-anchored notifications + end-of-day chunky-buys prompt), kill review pool padding entirely. Build succeeds iPhone 17 Pro / iOS 26.2.

---

## ✅ Done

### Project structure
- Xcode project (`GoldMind.xcodeproj`) is wired to a
  `PBXFileSystemSynchronizedRootGroup` at `GoldMind/`. Any file added to
  that folder is compiled automatically.
- Folder layout matches PRD: `Models/`, `Views/`, `ViewModels/`, `Services/`.
- `supabase/schema.sql` and `supabase/seed.sql` ready to run.

### Models (`GoldMind/Models/`)
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

### Services (`GoldMind/Services/`)
- `SupabaseService.swift` — **LIVE Supabase client** (supabase-swift 2.43.1).
  All methods now hit the real Supabase backend. Auth via `client.auth`,
  CRUD via `client.from(...)`. Methods: signUp/signIn/signOut, check-ins
  (save, fetchToday, fetchByDate, fetchRecent), money events (save, fetch
  by month, fetchRecent, fetchThisWeek, countBehaviourTag, fetchAll),
  questions (fetchNext with 14-day cooldown + last_shown update),
  budget months (fetchOrCreate, updateIncomeTarget), bias lessons
  (fetchAll, fetchByName), bias progress (fetch, update with
  upsert logic). `BiasProgress` model defined in same file.
  `ISO8601DateFormatter.dateOnly` helper for date-only queries.
- `QuestionPool.swift` — the 15 seed questions, used by the stub so the app
  works offline until Supabase is wired.
- `NotificationService.swift` — **rebuilt** with 4 notification types:
  (1) 8am morning: "One question. 60 seconds. Nudge is waiting."
  (2) 7pm evening if no check-in: "Nudge noticed."
  (3) 48h no events: "Nudge has no data. That's also information."
  (4) Bias hits 5x: "[Bias] appeared 5 times. Nudge has something."
  Legacy wrappers `scheduleDailyReminder()` / `cancelIfCheckedIn()` kept
  for existing callers. All scheduled on app launch via GoldMindApp.
- `BiasScoreService.swift` — **NEW** (2026-04-13). Bias scoring system with
  MasteryStage (unseen/noticed/emerging/active/improving/aware), BiasTrend,
  BiasScore struct, scoring weights (+2 yes, -1 no, +3 tagged spend),
  calculateStage(), calculateTrend(), weeklyNet(), computeScore().

### ViewModels (`GoldMind/ViewModels/`)
- `HomeViewModel.swift` — streak + alignment logic, colour + message
  computed properties, loads recent events. `buildNudge()` computes full
  `NudgeContext` from live data: behaviour tag patterns from money events,
  unplanned spend % this week, weekly net, spend trend, emotional tone,
  days since last check-in, total distinct biases seen.
- `CheckInViewModel.swift` — fetches next question, streak/alignment on
  submit, schedules the daily reminder on first completion.
- `MoneyEventViewModel.swift` — amount validation, save flow. Post-save:
  builds Nudge response via `NudgeEngine.moneyEventResponse()` based on
  behaviour tag count, life event, and planned status.

### Views (`GoldMind/Views/`)
- `OnboardingView.swift` — **rebuilt** 4-screen swipeable TabView onboarding:
  (1) Nudge 120pt welcome on heroGradient + gold "Get started →",
  (2) "The 7 patterns that cost people most" — 7 white cards on
  heroGradient with emoji + bias name + one-liner + Pompian 2012 citation,
  (3) Budget Reality Check — sequential quiz (Q1 budget duration, Q2 why
  stopped), capsule pills, Nudge response card (heroGradient, "You're not
  broken. The method is.", 70% stat),
  (4) Sign-up form with email/password + "Create account" gold button
  + "Already have an account? Sign in" toggle.
  Quiz answers stored in local state. Selected pills use heroGradient.
  TabView paged with .ignoresSafeArea(), custom progress dots (4 total).
- `SignInView.swift` — **NEW** sign-in screen. Email + password +
  gold "Sign in" button. Presented as sheet from onboarding.
  On success: sets hasCompletedOnboarding = true, navigates to HomeView.
- `HomeView.swift` — streak card, alignment card, tone row, primary
  buttons, recent events, navigation to `MonthView`.
- `CheckInView.swift` — **rebuilt with swipe YES/NO** (2026-04-12).
  Green gradient card `#1B5E20→#2E7D32→#4CAF50`. DragGesture:
  swipe-right > 80pt = YES (green overlay), swipe-left > 80pt = NO
  (coral overlay). Card rotates ±15 degrees during drag. 2 back cards
  visible (middle `#81C784` scaled 0.96, back `#A5D6A7` scaled 0.92).
  Front card content: gold bias pill on dark green, question text
  (.title3 bold white), "Why this matters" toggle collapsed by default,
  tone picker with **white opacity buttons** (NOT yellow squares).
  **NO text input field on card.** Progress dots at top (green, one per
  attempted question). Swipe hints: "\u{2190} No" coral left, "Yes \u{2192}"
  green right. After all cards: spending driver pick screen (2x3 grid
  with `rgba(76,175,80,0.15)` borders). Completion view: green circle +
  checkmark + "Nice work" + driver chip + NudgeCardView + Done.
  Background `#F5F7F5`. Real questions from Supabase (fallback to
  QuestionPool.seed). **Daily enforcement**: checks fetchTodaysCheckIn()
  on appear — if already completed, shows NudgeAvatar 72pt + "You
  checked in today." + streak count + "Come back tomorrow".
- `LearnView.swift` — **SIMPLIFIED** swipe card deck. Fixed 340pt card
  height, 1 back card (not 2). Front card: centred 52pt emoji, centred
  category pill (10pt), 22pt bold centred bias name with breathing room,
  13pt centred secondary description (max 2 lines), divider with 12pt
  padding, 10pt teal "IN REAL LIFE" caps, 11pt example in tinted card
  (max 3 lines, truncated), gold "How to counter it →" button pinned
  to bottom. Two side-by-side buttons: "Learn more" (outline, green text)
  and "How to counter it" (filled green bg, white text), both navigate to
  BiasDetailView. Seen count moved to subtle corner badge. Filter pills
  compact: 9pt text, less padding. Swipe counter "3 of 16" below card.
  `.navigationDestination(for: BiasLesson.self)` pushes
  `BiasDetailView(lesson:)`. Sources `BiasLessonsMock.seed`.
  **Glossary card** (2026-04-13): "16 patterns. One line each." at top
  of Library tab, grouped by category (Avoidance, Decision Making, Money
  Psychology, Time Perception, External Influence, Self Perception) with
  section headers (11pt 800 weight #4CAF50 uppercase tracking 1.5). All
  16 biases with emoji + name + one-line description, tappable →
  BiasDetailView.
- `BiasDetailView.swift` — **NEW** PRD v1.1. Receives `BiasLesson` +
  mock `timesSeen: Int = 0`. Layout: 72pt emoji, `.largeTitle` bold
  #2D1B69 name, category pill via `LearnView.categoryColour(for:)`,
  `.title3` short description, optional "Seen X times" row
  (conditional on `timesSeen > 0`), "What it is" section with
  fullExplanation, teal-tinted "IN REAL LIFE" card with
  realWorldExample, "How to counter it" section with howToCounter
  body.
- `HomeView.swift` — **rebuilt 2026-04-12, updated 2026-04-13** with brand palette.
  3 stat cards row (Alignment %, Biases Seen in gold, This Week spend).
  Daily Missions section with 2 rows (check-in, log event) showing
  completion state. **Pattern alert cards** (2026-04-13): biases seen 3+
  times shown as tappable cards with emoji, count, trend — tap navigates
  to Insights. Hero check-in card shows "Checked in · Day [streak]" with
  gold checkmark when done. Check-in opens as sheet (not tab switch).
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
- `RootTabView.swift` — **RESTRUCTURED** (2026-04-13). 4-tab root:
  Home (house.fill) / Log (plus.circle.fill) / Insights
  (chart.line.uptrend.xyaxis) / Library (books.vertical). MoneyEventView
  is now the Log tab (direct navigation, not a sheet). LearnView is
  now the Library tab. CheckInView removed from tab bar — opens as
  sheet from HomeView hero card.
- `DesignSystem.swift` — **Money Green + Nugget Gold** colour system.
  `DS.primary` `#2E7D32`, `DS.accent` `#4CAF50`, `DS.lightGreen`
  `#81C784`, `DS.paleGreen` `#E8F5E9`, `DS.bg` `#FAFAF8`,
  `DS.cardBg` white. Text: `DS.textPrimary` `#1A2E1A`,
  `DS.textSecondary` `#6B7A6B`, `DS.textTertiary` `#A0B0A0`.
  Semantic: `DS.positive` `#4CAF50`, `DS.warning` `#FF7043`.
  Gold: `DS.goldBase` `#C59430`, `DS.goldText` `#E8B84B`,
  `DS.nuggetGold` 5-stop gradient. `DS.heroGradient` 4-stop
  `#1B5E20→#2E7D32→#4CAF50→#388E3C` for hero cards. `NudgeAvatar`
  view: green circle + clipped Image("nudge"). `GoldButton` +
  `GoldRingModifier` ViewModifiers. `SectionHeader` 11pt heavy
  `#4CAF50` uppercase, tracking 1.5. `PrimaryButtonStyle` default
  tint `DS.primary`. `SecondaryButtonStyle` uses `DS.paleGreen` fill.
  `Card` uses `DS.cardBg`. All purple/violet hex values removed.
- `MoneyEventView.swift` — **rebuilt as quick-log** (2026-04-13, redesigned
  2026-04-13). 2-column grid showing top 6 categories (bigger cards) with
  "More categories" expander for remaining 10. ABS monthly average shown
  above range picker ("Avg: $180/mo · ABS 2022–23"). Driver insight card
  slides in after bias tag with "WHAT THIS MEANS" / "HOW TO BREAK IT"
  sections + "See your [bias] pattern →" pill to Insights. BFAS line
  below driver grid. No amount text input, no note, no date picker.
- `InsightFeedView.swift` — **rebuilt with Charts framework** (2026-04-12).
  `import Charts` (native SwiftUI). Tab 4 "Insights". Layout:
  (1) Weekly hero card with heroGradient, decorative circles, gold
  "THIS WEEK", "+/-X from future you", "N of 7 days", 3 trend pills.
  (2) **Bar chart** (BarMark): unplanned spend 6 weeks, green improving,
  coral worsening. (3) **Horizontal bar chart** (BarMark): bias frequency
  with gradient green bars + count annotations. (4) **Donut chart**
  (SectorMark): planned vs unplanned % with legend. (5) NudgeCardView.
  Borders `rgba(76,175,80,0.15)`. Background `#F5F7F5`.
- `SparklineView.swift` — **NEW** reusable 7-bar sparkline component.
  Green bars for improving, orange for worsening. Configurable width,
  height, colour direction.
- `SettingsView.swift` — **NEW** (2026-04-13). Opens from gear icon on
  HomeView as a sheet. Sign out (calls SupabaseService.signOut + resets
  hasCompletedOnboarding → returns to OnboardingView). Reset demo data
  (deletes daily_checkins, money_events, user_bias_progress for current
  user with confirmation dialog). App version + build number from Bundle.
  **Debug**: "Reset onboarding (debug)" button (DEBUG builds only) —
  signs out + resets hasCompletedOnboarding to test onboarding flow.
- `MonthView.swift` — kept in codebase but no longer mounted in tab bar.

### App entry
- `GoldMindApp.swift` — root switches between `OnboardingView` and
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
- `supabase db push` (2026-04-12, spending_driver + money_events rebuild) →
  applied `20260412150000_add_spending_driver.sql` and
  `20260412160000_rebuild_money_events_columns.sql`. `daily_checkins` now
  has `spending_driver` column. `money_events` now has `planned_status`,
  `behaviour_tag`, `life_event` columns (old `category` + `event_type`
  columns dropped). Existing rows migrated: event_type mapped to
  planned_status.
- Migrations source of truth:
  - `supabase/migrations/20260412000000_initial_schema.sql`
  - `supabase/migrations/20260412120000_add_bias_lessons_and_progress.sql`
  - `supabase/migrations/20260412130000_seed_15_new_questions.sql`
  - `supabase/migrations/20260412140000_seed_bias_lessons.sql`
  - `supabase/migrations/20260412150000_add_spending_driver.sql`
  - `supabase/migrations/20260412160000_rebuild_money_events_columns.sql`
  - `supabase/migrations/20260413120000_add_life_area_to_money_events.sql`
  - `supabase/migrations/20260413130000_add_research_source_to_questions.sql`
  - `supabase/migrations/20260413140000_soften_harder_questions.sql`
- Seed source of truth: `supabase/seed.sql` (15 original questions — kept
  for reference; 15 new PRD v1.1 questions + 16 bias_lessons are live via
  the migrations above)

## ✅ Supabase Swift package — DONE

- **supabase-swift 2.43.1** added to `GoldMind.xcodeproj` as SPM
  dependency via pbxproj edit + `xcodebuild -resolvePackageDependencies`.
- `import Supabase` active in `SupabaseService.swift`.
- `SupabaseClient` initialised with real URL + anon key.
- All in-memory stub arrays removed; all methods now use real
  `client.from(...)` / `client.auth` calls.
- Build succeeds on iPhone 17 Pro simulator (Xcode 26, iOS 26.2).

## 🚧 Remaining / pending

1. **(Optional) Add the Supabase MCP server** — run in a regular terminal:
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

1. ~~Add Supabase Swift package~~ — **DONE** (2026-04-12)
2. ~~Wire real Supabase calls in SupabaseService.swift~~ — **DONE** (2026-04-12)
3. Swap `LearnView` / `BiasDetailView` off `BiasLessonsMock.seed` →
   use `service.fetchAllBiasLessons()`. `CheckInView` off
   `QuestionPool.seed` → use `service.fetchNextQuestion()`.
4. Backfill `bias_category` on the original 15 `question_pool` rows.
5. Verify sign-up → first check-in → streak = 1 flow on device/simulator.
6. Verify notification permission prompt fires after first check-in
   (permission request already wired in `GoldMindApp.task`).
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

- ~~No sign-in flow~~ — **DONE** (2026-04-13). SignInView added.
- ~~No settings screen behind the gear icon on `HomeView`.~~ **DONE** (2026-04-13). SettingsView added.
- No streak-history dots calendar on `MonthView` (PRD §MonthView mentions
  it — deferred to v1.1).
- Currency formatting uses the device locale; no user override.
