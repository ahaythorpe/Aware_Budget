# CHANGELOG — AwareBudget

> Append-only log of every agent/Claude Code session.
> Newest entries at the top. Each entry: date, agent, summary, links.

---

## 2026-04-15 — PRD v1.2 check-in architecture + bias tracker spec (Claude Code)

- PRD.md bumped to v1.2. Added Check-in architecture section: time-of-day
  flow (first-open BFAS 16Q → throughout-day quick logs → evening 2Q →
  morning 2Q → Sunday 4Q), ranking formula (current_score +
  BFAS_initial_weight, hidden from user), question selection logic, motivation
  mechanisms (smart time nudges, loss aversion, pattern reveal), and
  explicit anti-patterns (no badges, XP, confetti).
- DESIGN_HANDBOOK §7.3: spec for "Top 4 biases" tracker card under
  Home monthly calendar. Emoji · name · trend · stage pill, tap -> BiasDetail.
  Reuses HomeViewModel.dailyPatterns (already populated).

---

## 2026-04-15 — Home monthly calendar + Nudge welcome message (Claude Code)

Reverts the misplaced Log empty-state feature and delivers two Home features in its place, per `DESIGN_HANDBOOK.md` §7.1 and §7.2.

**Home — monthly calendar card** (§7.1)
- New `Views/MonthCalendarView.swift` component. Inserted between check-in hero and Nudge card.
- Shows current month. Days with logged money events = filled `DS.accent` pill + bold white number. Today = gold outline ring. Empty days = disabled small grey number.
- Tap an event-day → popover: date header · event count · total $ · top 3 biases (tag × count). No-tag days fall back to "No bias tags that day".
- `HomeViewModel.monthEventsByDay: [String: [MoneyEvent]]` populated in `load()` from `SupabaseService.fetchMoneyEvents(forMonth:)`. No hardcoded fallback.

**Home — Nudge welcome message** (§7.2)
- `NudgeEngine.welcomeMessage(hour, isFirstOpen, streak, checkedInToday, loggedEventToday) -> String` added.
- Replaces the hardcoded `greeting` displayed at top-left of `HomeView` with a contextual Nudge line. First-open users see "Hi, I'm Nudge. Ready to understand your money mind?"; returning users see time-aware + streak/activity-aware copy.
- Voice rules preserved: dry wit, short, no shame language.

**Reverted (misplaced):**
- Removed `loadEmptyState`, `weekDots`, `topBiases`, `TopBias` from `MoneyEventViewModel` and the matching `logEmptyState` / `weekStrip` / `topBiasesPanel` / `trendArrow` from `MoneyEventView`.
- `HomeViewModel.computeWeekDots` kept non-private (harmless; may be reused).

Build verified on iPhone 17 Pro / iOS 26.2 — BUILD SUCCEEDED.

---

## 2026-04-15 — Design handbook + metallic palette lock (Claude Code)

- Added `docs/DESIGN_HANDBOOK.md` — master visual language doc. Locks `heroGradient` (7-stop metallic green), `nuggetGold` (6-stop foil), Apple-style polish (rim highlight + bottom rim shadow + dual drop shadow), element usage rules, tab-by-tab application spec.
- Restored 7-stop `heroGradient` in `DesignSystem.swift` to the Tue 04-14 peak (commit `344bb9b`) after brief drift.
- `HomeView.swift` + `WhyView.swift`: 4 hero call sites now use `DS.heroGradient` consistently (replaced inline 2–3 stop flat gradients).
- Added `preview_palette.html` at repo root — static browser preview kept in sync with `DesignSystem.swift` for palette review.

---

## 2026-04-14 — How it works 5th tab (Claude Code)

- Added `HowItWorksView` as 5th tab in `RootTabView.swift` (label "How it works", icon `info.circle`). Build green, 5 tabs verified via screenshot.

---

## 2026-04-13 — Real Supabase questions, Nudge app icon, notifications (Claude Code)

**Real Supabase questions:**
- CheckInView already wired to `service.fetchNextQuestion()` which queries
  `question_pool` ordered by `last_shown asc nulls first`, updates `last_shown`
  to today after fetch. 30 questions verified via REST API.
- Falls back to `QuestionPool.seed` only on network error.

**Nudge app icon:**
- Generated all icon sizes (20, 40, 60, 76, 120, 152, 180, 1024px) from
  `nudge.imageset/nudge.png` via `sips -z`. Contents.json already correct.

**4 notification types:**
- 8am morning: "One question. 60 seconds. Nudge is waiting."
- 7pm evening (no check-in): "Nudge noticed."
- 48h no events: "Nudge has no data. That's also information."
- Bias hits 5x: "[Bias] appeared 5 times. Nudge has something."
- All scheduled on app launch in AwareBudgetApp
- Evening nudge cancelled on check-in, no-events timer reset on money event
- Bias alert triggered in MoneyEventViewModel when tagCount == 5

---

## 2026-04-13 — Onboarding 4-screen swipeable TabView (Claude Code)

**Complete onboarding rewrite:**
- Screen 1: Nudge welcome — heroGradient background, NudgeAvatar 120pt,
  "Hi, I'm Nudge." white largeTitle, gold "Get started →" button
- Screen 2: The 7 Patterns — heroGradient background, 7 white rounded
  cards with emoji + bias name + one-liner (Loss Aversion, Present Bias,
  Overconfidence, Mental Accounting, Status Quo Bias, Anchoring, Ostrich
  Effect), Pompian 2012 citation, gold "I recognise these →" button
- Screen 3: Budget Reality Check — white background, lime caps label,
  NudgeAvatar 52pt, sequential quiz (Q1: budget duration, Q2: why stopped),
  capsule pills, Nudge response card (heroGradient, "You're not broken.
  The method is.", 70% stat), gold "That's why AwareBudget exists →"
- Screen 4: Sign up — NudgeAvatar 100pt, email/password fields, gold
  "Create account" button, "Already have an account? Sign in" toggle
- Removed old "How it works" 3-card explainer screen
- TabView paged with .ignoresSafeArea(), custom progress dots

---

## 2026-04-13 — All 16 biases grouped, debug onboarding reset (Claude Code)

**BiasLessonsMock expanded to 16:**
- Added 9 missing biases: Anchoring, Sunk Cost Fallacy, Ego Depletion,
  Availability Heuristic, Denomination Effect, Framing Effect, Planning
  Fallacy, Scarcity Heuristic, Moral Licensing
- Recategorized: Overconfidence Bias → Decision Making, Status Quo Bias
  → Self Perception. Removed "Inertia" category.
- Added `categoryOrder` array for display ordering

**Glossary card grouped by category:**
- 6 category section headers: Avoidance, Decision Making, Money Psychology,
  Time Perception, External Influence, Self Perception
- Headers: 11pt 800 weight #4CAF50 uppercase tracking 1.5
- All 16 biases visible and tappable → BiasDetailView

**Debug onboarding reset:**
- "Reset onboarding (debug)" button in SettingsView (#if DEBUG)
- Signs out + resets hasCompletedOnboarding → returns to onboarding
- Verified: onboarding screen 1 renders correctly

---

## 2026-04-13 — Quick log redesign, driver insights, BFAS, library glossary (Claude Code)

**Quick log redesign (MoneyEventView):**
- 2-column grid with top 6 categories (bigger cards), "More categories ↓" expander
- ABS monthly average shown above range picker ("Avg: $180/mo · ABS 2022–23")
- 14 categories have ABS Household Expenditure Survey 2022–23 averages
- Cancel/Done toolbar hidden when view is a tab (not sheet)
- Reset flow added for tab-based usage

**Driver insight card:**
- White card with 3pt green left border slides in with spring animation
- "WHAT THIS MEANS" (lime 10pt caps) + "HOW TO BREAK IT" (gold 10pt caps)
- "See your [bias] pattern →" pill navigates to Insights tab
- 16 drivers with custom means/fix copy
- BFAS credibility line below driver grid title

**BFAS credibility (CheckInView):**
- "Used in professional financial planning assessments · BFAS framework"
- caption2, italic, white 0.5 opacity, centred below each question card

**Library glossary card (LearnView):**
- "16 patterns. One line each." card at top of Library tab
- All 16 biases listed with emoji + name + one-line description
- Each row tappable → BiasDetailView

---

## 2026-04-13 — Tab restructure + HomeView patterns (Claude Code)

**Tab bar restructure:**
- Changed from Home/Check in/Learn/Insights → Home/Log/Insights/Library
- MoneyEventView is now the Log tab (direct navigation, not a sheet)
- LearnView is now the Library tab
- CheckInView removed from tab bar — opens as sheet from HomeView hero card
- Icons: house.fill / plus.circle.fill / chart.line.uptrend.xyaxis / books.vertical

**HomeView restructure:**
- Hero check-in card: shows "Checked in · Day [streak]" with gold checkmark when done
- Removed "Learn a bias" from daily missions (2 missions: check-in, log event)
- Added pattern alert cards: biases seen 3+ times shown with emoji, count, trend
- Pattern cards tappable → navigates to Insights tab
- Removed log event button (now a tab)

**Fix:** SettingsView moved Supabase calls to service layer (`resetUserData()`)
to fix PostgREST import errors.

---

## 2026-04-13 — Event motivation, glossary, softer questions (Claude Code)

**Event logging motivation:**
- NudgeContext gains `daysSinceLastEvent` + `eventLoggingStreak`.
- NudgeEngine rule: "Nudge has no data on your week. That's also data."
  fires when 2+ days since last event and user has checked in today.
- Post-log feedback improved: "That's Anchoring. 3rd time this week."
  with ordinal suffix and action button for 3+ counts.
- HomeViewModel computes event logging streak (consecutive days with events).

**Bias glossary:**
- List button in LearnView toolbar opens glossary sheet.
- "All 16 biases" list: emoji + name + one-line description + mastery
  stage badge + chevron. Each row navigates to BiasDetailView.

**Softer question framing:**
- Supabase migration updates 10 intermediate/advanced questions to add
  "even just a little?", "even slightly?", "even a small one?" suffixes.
- Lowers threshold for honest answers per behavioural UX rules.

**Nudge image verified:**
- Image("nudge") loads correctly in all 10 locations via NudgeAvatar.
- All wrapped in green circle (#2E7D32) which masks the black PNG bg.

---

## 2026-04-13 — Trust/transparency layer (Claude Code)

**Onboarding "How it works" screen:**
- Added 3-card swipeable explainer between quiz and sign-up (page 3 of 4).
- Card 1: "Built on real research" with Kahneman/Tversky/Cialdini citations.
- Card 2: "One question. One minute." with BFAS methodology reference.
- Card 3: "Your patterns. Not a grade." with revealed preference theory.
- Gold "I'm ready" button on last card.

**Research citations on questions:**
- Added `researchSource` to Question model.
- Supabase migration adds `research_source` column + populates all 16 biases.
- Displayed in CheckInView below "Why this matters" when expanded (italic, 11pt).

**Bias scoring system (BiasScoreService.swift):**
- MasteryStage: unseen → noticed → emerging → active → improving → aware.
- BiasTrend: worsening / stable / improving.
- Scoring weights: +2 yes, -1 no, +3 tagged spend.
- computeScore() builds full BiasScore from progress + events.

**"About your score" sheet:**
- Info button in InsightFeedView toolbar opens explanation sheet.
- Sections: The Science, The Scoring (+2/-1/+3), Your Stages (6 levels),
  Important (not clinical diagnosis disclaimer).
- Gold "Got it" dismiss button.

**Mastery stage badges on Learn cards:**
- Top-right corner badge on each LearnView card.
- Colour-coded: blue (noticed), amber (emerging), coral (active),
  green (improving), gold (aware). Hidden when unseen.
- Driven by BiasScoreService from user_bias_progress data.

---

## 2026-04-13 — Daily check-in enforcement, home stats, missions (Claude Code)

**CheckInView daily enforcement:**
- On appear, checks fetchTodaysCheckIn(). If already completed, shows
  NudgeAvatar 72pt + "You checked in today." + streak count + "Come
  back tomorrow" instead of questions.

**HomeView stat cards + daily missions:**
- 3 stat cards row: Alignment %, Biases Seen (gold), This Week spend.
- Daily Missions section: 3 rows with checkmark/circle state:
  - Daily check-in — "Keep the streak"
  - Log a money event — "Track what happened"
  - Learn a bias — "Swipe through Learn"
- Completion state driven by today's data from ViewModel.

**Real questions from Supabase (already wired):**
- fetchNextQuestion() was already hitting live Supabase with 14-day
  cooldown + last_shown update. Confirmed working.

---

## 2026-04-13 — Quick-log MoneyEventView with AUD ranges (Claude Code)

**MoneyEventView rebuilt as quick-log:**
- Replaced amount text input with 3-column category grid (16 categories).
- Each category has AUD range picker (3–4 buttons with midpoints).
- Planned/Surprise/Impulse selection after range.
- Auto-suggest bias tag based on category + status mapping.
- Inline Nudge message with bias one-liners or pattern alerts.
- "Log it" gold gradient button. No note/date fields.
- Added `lifeArea` field to MoneyEvent model + CodingKeys.
- Supabase migration: `life_area` column added to money_events.
- NudgeEngine.moneyEventResponse now accepts String bias tag.
- HomeViewModel topBiasLabel reads tag directly (not via SpendingDriver).

---

## 2026-04-13 — Learn buttons, settings screen (Claude Code)

**LearnView buttons:**
- Replaced single "See pattern" gold button with two side-by-side buttons.
- "Learn more": outline border, Color(hex: "1A5C38") text, clear bg.
- "How to counter it": filled Color(hex: "1A5C38") bg, white text.
- Both navigate to BiasDetailView via NavigationLink(value: lesson).

**SettingsView (NEW):**
- Gear icon in HomeView now opens SettingsView as a sheet.
- Sign out: calls SupabaseService.signOut(), resets hasCompletedOnboarding
  to false → user returns to OnboardingView.
- Reset demo data: deletes daily_checkins, money_events, user_bias_progress
  for current user. Confirmation dialog before executing.
- Shows app version + build number from Bundle.main.

---

## 2026-04-13 — App icon set to Nudge mascot (Claude Code)

**App icon:**
- Resized `nudge.png` to 1024x1024 via `sips`.
- Xcode 26 single-image format: `Icon-1024.png` assigned to iOS
  universal slot (light, dark, tinted variants all use same image).
- Removed legacy per-size/per-idiom entries (Xcode 26 auto-generates
  all sizes from the single 1024px source).

---

## 2026-04-13 — Onboarding, Budget Reality Check, sign up/in, real questions (Claude Code)

**Goal:** Rebuild onboarding as 3-screen paged flow with Budget Reality
Check quiz. Add sign-in screen. Verify real Supabase questions are wired.

**OnboardingView rebuilt (3 screens):**
- Screen 1: NudgeAvatar 120pt + "Hi, I'm Nudge." + value prop + gold
  "Get started" button. Progress dots at bottom.
- Screen 2: Budget Reality Check quiz. Q1: "How long did your last
  budget last?" (3 options). Q2: "Why did you stop?" (4 options,
  conditional on Q1). Nudge responds: "You're not broken. The method
  is." + 70% abandonment stat. Selected pills use heroGradient.
  Animated transitions with spring.
- Screen 3: Sign-up form. Email + password fields (paleGreen bg).
  Gold "Create account" button. "Already have an account? Sign in"
  link opens SignInView as sheet. On success: fetchOrCreateBudgetMonth,
  set hasCompletedOnboarding = true.

**SignInView (NEW):**
- Email + password + gold "Sign in" button.
- Presented as sheet from onboarding screen 3.
- NudgeAvatar 80pt + "Welcome back" header.
- On success: Supabase signIn(), hasCompletedOnboarding = true, dismiss.
- Cancel toolbar button to return to sign-up.

**Real Supabase questions (already wired):**
- `SupabaseService.fetchNextQuestion()` already queries `question_pool`
  ordered by `last_shown` ascending (nulls first), updates `last_shown`
  after fetch. 14-day cooldown filter. Falls back to least-recently-shown.
- `CheckInView.loadQuestions()` already calls `service.fetchNextQuestion()`
  in a loop (up to 5 questions), with `QuestionPool.seed` as fallback.
- No changes needed — TASK 2 was already complete.

**Build:** No errors in source files.

---

## 2026-04-13 — Gradients everywhere, typography scale, green consistency (Claude Code)

**Goal:** Enforce heroGradient on all selected cards/sheets, bump
typography scale for readability, enforce two-green colour system.

**GoldButtonStyle renamed + improved (DesignSystem.swift):**
- `GoldButton` → `GoldButtonStyle`: added `.fontWeight(.bold)`,
  `.frame(maxWidth: .infinity)`, padding 11→12. Extension updated.

**Hero gradient on all selected cards:**
- MoneyEventView: all 3 selection card types (planned status,
  behaviour tag, life event) now use `DS.heroGradient` when selected
  instead of flat `DS.primary`. Uses `AnyShapeStyle` for type erasure.
- Hero gradient location 0.7→0.75 for #2E7D32.

**Yes/No buttons restyled (CheckInView):**
- No button: coral `#FF6B6B` fill, white text, `Image(systemName: "xmark")`.
- Yes button: 3-stop gold gradient (#FFF0A0→#E8B84B→#C59430),
  dark green text, `Image(systemName: "checkmark")`.
- Both use `clipShape(RoundedRectangle(cornerRadius: 12))`.
- `.padding(.top, 16)` added.

**InsightFeedView "Log your first event" button:**
- Changed from `PrimaryButtonStyle()` to heroGradient fill + white bold text.

**Typography scale (all views):**
- SectionHeader: 11pt→12pt heavy.
- LearnView: header title3→largeTitle, description caption→subheadline,
  short description 13→15pt, "IN REAL LIFE" 10→12pt, example 11→13pt,
  category pill 10→11pt, "See pattern" 12→13pt.
- NudgeCardView: body 13→15pt, action label 12→13pt.
- InsightFeedView: "THIS WEEK" 10→12pt, hero pills 11→13pt.
- MoneyEventView: driver shortDescription 10→12pt.

**Green colour consistency (two greens only):**
- Heading green `#1A5C38`: bias names (LearnView), filter pills,
  dot indicators, completion checkmarks (CheckInView, MoneyEventView),
  default categoryColour.
- Lime green `#4CAF50`: "IN REAL LIFE" label, "Set target" text,
  demo data link, seen row icon, driver labels.
- Replaced all `DS.primary` text usage → `Color(hex: "1A5C38")`.
- Replaced all `DS.accent` label usage → `Color(hex: "4CAF50")`.

**Build:** No errors in source files. SPM dependency chain
(swift-clocks/ConcurrencyExtras) has Xcode 26 compatibility issue —
not our code, tracked upstream.

---

## 2026-04-13 — Core loop wired end-to-end (Claude Code)

**Goal:** Make check-in → money event → insights flow work with real
Supabase persistence.

**CheckInView saves to Supabase:**
- Added `saveCheckIn()` async method that computes streak (yesterday's
  streak + 1), alignment %, builds `CheckIn` record, and calls
  `service.saveCheckIn()`. Completion card now shows "Day N".
- Tone picker removed (swipe YES/NO is the only input).
- Rotation formula simplified to `dragOffset.width / 20`.

**DemoDataService + auto-seed:**
- `DemoDataService.swift` seeds 7 check-ins, 8 money events, 3 bias
  progress entries. `HomeViewModel.load()` auto-seeds on first open
  when streak=0 and no events (guarded by UserDefaults flag).
- "Load demo data" link visible below greeting header.

**Empty states redesigned:**
- HomeView: NudgeAvatar 120pt + "Hi, I'm Nudge" title bold + full-width
  gold CTA when no streak.
- InsightFeedView: NudgeAvatar 64pt + calm copy + green "Log your first
  event" button opening MoneyEventView sheet.

**LearnView emoji in circle:**
- Emoji now displayed inside 80pt circle filled with category bg colour.

**Design tweaks:**
- Hero gradient: 5-stop shimmer `#0A2E12→#1B5E20→#4CAF50→#2E7D32→#52B788`.
- Gold button text colour: `#1B3A00` (was `#3A2000`).
- Ostrich Effect emoji: `🫣` in local mock (Supabase RLS blocks anon PATCH).
- Text polish across all views: sentence case, no exclamation marks.

**Build:** `** BUILD SUCCEEDED **` (iPhone 17 Pro / iOS 26.2).

---

## 2026-04-12 — Rebuild CheckInView + InsightFeedView + docs audit (Claude Code)

**Goal:** Match UI mockup specs exactly. Rebuild CheckInView with swipe
YES/NO, rebuild InsightFeedView with native Charts, wire Nudge asset,
audit all files and create HANDOFF.md.

**Nudge asset wired:**
- `images/Nudge_Asset.png` copied to
  `Assets.xcassets/nudge.imageset/nudge.png` with Contents.json (2x scale).
- NudgeAvatar in DesignSystem.swift already references Image("nudge").

**CheckInView full rebuild:**
- Green gradient card `#1B5E20->#2E7D32->#4CAF50` (was DS.heroGradient).
- Swipe RIGHT > 80pt = YES (green `#4CAF50` overlay with "YES" text).
  Swipe LEFT > 80pt = NO (coral `DS.warning` overlay with "NO" text).
- Card rotates +/-15 degrees during drag (proportional to screen width).
- 2 back cards visible: middle `#81C784` scaled 0.96, back `#A5D6A7` 0.92.
- REMOVED text input field from card.
- Tone picker: white opacity buttons (0.08 bg, 0.20 selected), NOT yellow.
  Border: white opacity 0.5 when selected, not gold.
- Swipe hints: "← No" in coral (left), "Yes →" in green (right).
- Background `#F5F7F5`. Card borders `rgba(76,175,80,0.15)`.

**InsightFeedView rebuild with Charts:**
- `import Charts` (native SwiftUI iOS 16+).
- Weekly hero card with DS.heroGradient + decorative circles.
- Section 2: **Bar chart** (BarMark) — 6-week unplanned spend trend.
  Green bars improving, coral bars worsening. Y-axis with short amounts.
- Section 3: **Horizontal bar chart** (BarMark) — bias frequency from
  all money events + check-in drivers. Gradient green bars. Count
  annotations trailing.
- Section 4: **Donut chart** (SectorMark) — planned vs unplanned %.
  Green planned, coral unplanned. Legend with percentages.
- Section 5: NudgeCardView at bottom.
- Removed old SparklineView-based trend cards and horizontal scroll
  pattern cards. Background `#F5F7F5`. Borders `rgba(76,175,80,0.15)`.

**Documentation:**
- `docs/HANDOFF.md` — NEW. Complete file listing with descriptions,
  exact colours, Nudge rules, Supabase state, priority tasks, design
  rules. Read at start of every session.
- `MEMORY.md` — rewritten with all design decisions from today:
  Money Green + Nugget Gold colours, Nudge mascot rules, swipe YES/NO
  system, Charts framework choice, LearnView card layout.
- `docs/STATUS.md` — updated with rebuilt screen descriptions.

**Build:** `** BUILD SUCCEEDED **` (iPhone 17 Pro / iOS 26.2).

---

## 2026-04-12 — Wire Supabase Swift package + replace all stubs with live client (Claude Code)

**Goal:** Remove the in-memory stub in SupabaseService and connect to
the real Supabase backend.

**Package added:**
- supabase-swift 2.43.1 added to AwareBudget.xcodeproj via pbxproj edit
  (XCRemoteSwiftPackageReference + XCSwiftPackageProductDependency).
- Resolved via `xcodebuild -resolvePackageDependencies` (also pulled
  swift-crypto, swift-http-types, swift-concurrency-extras, etc.).

**SupabaseService.swift — full rewrite:**
- `import Supabase` uncommented, `SupabaseClient` initialised with real
  URL + anon key.
- All in-memory arrays removed. Every method now uses `client.from(...)`
  or `client.auth`.
- New methods: `fetchAllBiasLessons()`, `fetchBiasLesson(biasName:)`,
  `fetchBiasProgress()`, `updateBiasProgress(biasName:reflected:)`.
- `BiasProgress` model added (maps to `user_bias_progress` table).
- `ISO8601DateFormatter.dateOnly` helper for date-only PostgREST filters.
- `currentUserId` is now an `async` computed property (reads from
  `client.auth.session`).

**DB migration:**
- `20260412160000_rebuild_money_events_columns.sql` — aligns
  `money_events` table with PRD v1.1 Swift model: added
  `planned_status`, `behaviour_tag`, `life_event`; dropped old
  `category` + `event_type`. Existing rows migrated.
- Both `20260412150000` and `20260412160000` pushed and applied.

**ViewModel fixes:**
- `CheckInViewModel.submit()` — `await service.currentUserId`
- `MoneyEventViewModel.save()` — `await service.currentUserId`

**Build:** succeeds on iPhone 17 Pro simulator (Xcode 26, iOS 26.2).

---

## 2026-04-12 — Replace MonthView with InsightFeedView + SparklineView (Claude Code)

**Goal:** MonthView showed alignment % and income targets — legacy
budgeting concepts that don't belong. Replace with behaviour-based
awareness trends that show patterns, not budgets.

**Tab renamed:** "Month" → "Insights" (icon: chart.line.uptrend.xyaxis).
`RootTab.month` → `RootTab.insights`. All references updated (HomeView
nudge action handler).

**InsightFeedView (replaces MonthView):**
1. Weekly hero card: #1B5E20→#2E7D32→#4CAF50 gradient, gold "THIS
   WEEK" label, "This week: +/-£X from future you" (planned minus
   unplanned net), "N of 7 days you chose future you" sub, 3 trend
   pills (unplanned %, top bias, streak count)
2. Spending trends section: one SparklineView card per behaviour tag,
   showing 7 bars for last 7 weeks. Direction pill: "Improving" (green)
   or "Watch this" (orange). "Linked to [bias] bias" subtext.
3. Your patterns section: horizontal scroll of bias pattern cards.
   Each: emoji + name + count + strength pill (Emerging <3,
   Established 3-6, Strong 7+).
4. Weekly Nudge insight card at bottom with contextual message.

**SparklineView (new component):**
- 7-bar chart, configurable width/height.
- Green bars for improving trends, orange for worsening.
- Latest bar highlighted with full colour.

**SupabaseService:**
- Added `fetchAllMoneyEvents()` for insights calculations.

**Removed from tab bar:**
- MonthView still in codebase (not deleted) but no longer mounted.
- No income target, no alignment %, no categories anywhere in Insights.

**Build:** `** BUILD SUCCEEDED **` (iPhone 17 / iOS 26.2).

---

## 2026-04-12 — Wire NudgeEngine to live data + Nudge on all screens (Claude Code)

**Goal:** NudgeEngine should build its context from real data, not
placeholder values. Nudge should respond on every key screen.

**NudgeContext enriched (HomeViewModel.buildNudge):**
- `topBias` / `topBiasCount`: computed from money events behaviour
  tags this week (falls back to check-in SpendingDrivers)
- `unplannedSpendPct`: % of this week's money events that are
  surprise or impulse
- `weeklyNet`: planned total minus unplanned total this week
- `spendTrend`: derived from unplanned %  (>50% = "up", <20% = "down")
- `totalBiasesSeen`: union of distinct check-in drivers + event tags
- All other fields already computed from prior session

**NudgeEngine expanded:**
- New priority #4: high unplanned spend (>50%) + negative weekly net
  → "X% unplanned... pattern worth seeing" with openTrends action
- New priority #7: anxious tone + high unplanned (>40%)
- `moneyEventResponse()`: generates contextual Nudge message after
  saving a money event — pattern count ≥3 triggers "See your fix",
  life events get acknowledged, planned events get "That's the goal"
- `checkInResponse()`: generates completion message based on streak
  day, questions reflected, driver + tone combo

**MoneyEventView post-save confirmation:**
- After save, view transitions to a confirmation screen with green
  checkmark + "Logged" + NudgeCardView with contextual message.
  Replaces the old instant-dismiss flow.
- `MoneyEventViewModel.nudgeResponse` built from
  `NudgeEngine.moneyEventResponse()` with live `countBehaviourTag()`

**CheckInView completion card:**
- NudgeCardView now appears between driver chip and Done button
  on the completion screen, showing `NudgeEngine.checkInResponse()`

**SupabaseService:**
- Added `fetchMoneyEventsThisWeek()` (ISO week filter)
- Added `countBehaviourTag(_:)` (count all events with a given tag)

**Build:** `** BUILD SUCCEEDED **` (iPhone 17 / iOS 26.2).

---

## 2026-04-12 — Kill categories: awareness-based money events (Claude Code)

**Goal:** Categories are what made Mint fail. "Shopping: £220" tells you
nothing. Replace the entire category system with awareness-based tracking:
was this planned or a surprise? What behaviour drove it?

**Philosophy shift:** Trends now use planned/surprise ratio + behaviour
tags + amount size. Never categories. "Anchoring-driven spend" tells you
WHY money left your account. "Shopping" tells you nothing.

**MoneyEvent model rewrite:**
- Removed `EventType` (surprise/win/expected) and `MoneyCategory` enum
- Added `PlannedStatus` (planned/surprise/impulse) with `isUnplanned`
- Added `behaviourTag: String?` (reuses CheckIn.SpendingDriver rawValues)
- Added `LifeEvent` enum (job_change/unexpected_bill/medical/windfall/
  other_big) — shown only when amount > 200
- Added derived `SizeBucket` (small <50, medium 50-200, large 200+)
- Removed `category: String?` field entirely

**MoneyEventView rebuilt — 3 taps:**
1. Amount (numeric hero input)
2. Was this planned? — 3 full-width buttons with descriptions:
   [✓ Planned] [⚡ Surprise] [🎯 Impulse]
3. What drove it? — 2x3 behaviour tag grid (only for surprise/impulse)
4. Life event — 5 options (only if amount > 200)
Plus optional note + date. Sections animate in/out with spring.

**MonthView rebuilt:**
- Killed `categoryBreakdown` entirely
- New: unplanned spend ratio card (% of total + surprise/impulse counts)
- New: top behaviour card (most-tagged SpendingDriver this month)
- Events grouped by PlannedStatus, labelled with behaviour tag

**Alignment calc updated** in HomeViewModel, CheckInViewModel, MonthView:
uses `plannedStatus.isUnplanned` instead of `eventType == .surprise`.
HomeView event rows show PlannedStatus label/emoji.

**Build:** `** BUILD SUCCEEDED **` (iPhone 17 / iOS 26.2).

---

## 2026-04-12 — Money Green + Nugget Gold colour system (Claude Code)

**Goal:** Replace all purple/violet with bright money green + nugget
gold across every screen. Fresh, finance-forward visual identity.

**Colour system (DesignSystem.swift):**
- Primary `#2E7D32` (hero cards, nav, CTA buttons)
- Accent `#4CAF50` (section labels, ring stroke, filter pills)
- Light green `#81C784` (card backs, tints)
- Pale green `#E8F5E9` (pills, tab active bg, why section bg)
- Background `#FAFAF8`, cards white
- Text: `#1A2E1A` / `#6B7A6B` / `#A0B0A0`
- Gold: base `#C59430`, text `#E8B84B`, gradient 5-stop
- All purple/violet removed. No `deepPurple`, no `#2D1B69`,
  no `#7F77DD`.

**Screens updated:**
- HomeView: `#2E7D32` hero card, pale green card borders, green
  section labels, green accent throughout
- CheckInView: `#2E7D32` front card, `#81C784` / `#A5D6A7` backs,
  gold bias pill, `#E8F5E9` why section, green progress dots
- LearnView: green active filter pills, `#C8E6C9` / `#A5D6A7`
  card backs, `#2E7D32` CTA button, green dot indicator
- BiasDetailView: `#E8F5E9` tinted sections, green seen row,
  green section headers. Category colours preserved.
- StreakRingView: `#4CAF50` ring stroke, gold gradient number
- RootTabView: tint `#2E7D32`
- HomeViewModel: alignment colours use DS.positive / DS.warning
- PRD.md design section rewritten

**Build:** `** BUILD SUCCEEDED **` (clean, iPhone 17 / iOS 26.2).

---

## 2026-04-12 — Spending driver tags: post-check-in behaviour tagging (Claude Code)

**Goal:** Track *why* decisions happen, not just *what*. After each
check-in, ask "What drove this?" and let the user tag the behavioural
driver. This is the foundation for weekly pattern-awareness insights
("Most of your spending comes from convenience, not necessity").

**Added:**
- `CheckIn.SpendingDriver` enum (6 cases): Present Bias ("I want
  this now"), Social ("Others are doing it"), Reward ("I deserve
  this"), Convenience ("This is easier"), Identity ("This reflects
  who I am"), Friction Avoidance ("Too hard to change"). Each has
  rawValue, label, shortDescription, emoji.
- `spending_driver` optional field on `CheckIn` model with
  `CodingKey` mapping to `spending_driver`.
- Migration `20260412150000_add_spending_driver.sql`: nullable
  `spending_driver` text column with CHECK constraint on
  `daily_checkins`.

**CheckInView changes:**
- 3-phase flow: `questions` → `driverPick` → `done`.
- After all question cards are swiped, transitions to a "What drove
  this?" screen with 2x3 `LazyVGrid` of pill-style driver buttons.
  Each pill: emoji + label + one-line description. Single-select,
  optional skip. Tone: "No wrong answers. Just noticing."
- Continue/Skip button advances to completion. Completion view now
  shows selected driver chip if one was picked.
- `NotificationService.scheduleDailyReminder()` fires on Continue/
  Skip (moved from advance() to the driverPick → done transition).

**Build:** `** BUILD SUCCEEDED **` (clean build, iPhone 17 / iOS 26.2).

---

## 2026-04-12 — Beta shell: 4-tab root, StreakRing HomeView, CheckInView swipe (Claude Code)

**Goal:** Close out the beta shell so the app reads as a real product.
User list: (1) HomeView rebuild with streak ring + brand palette,
(2) CheckInView swipe stack, (3) Supabase live wiring, (4) daily 8pm
notifications, (5) 4-tab root.

**Added:**
- `Views/RootTabView.swift` — 4-tab root (Home · Check in · Learn ·
  Month). `@State selection: RootTab` passed down to HomeView +
  CheckInView so cards can switch tabs. Active tint `DS.accent`
  (`#7F77DD`). Wrapped in `AwareBudgetApp.swift` as the root scene,
  which also fires `NotificationService.requestPermission()` on
  launch.
- `Views/StreakRingView.swift` — coral 180pt circular ring with
  trimmed progress stroke (14pt, round cap), bold 56pt streak count
  in `DS.deepPurple`, and a labelled M–S dot row beneath. Animates
  `progress` and `streak` on change.
- `DS` brand palette: `DS.bg` `#F7F4EF`, `DS.deepPurple` `#2D1B69`,
  `DS.accent` `#7F77DD`, `DS.coral` `#FF7A6B`, `DS.teal` `#006064`.

**HomeView rebuild:**
- Background now `DS.bg`. Hero check-in card is a full-width
  `#2D1B69` rounded rectangle with white text and coral icon; tapping
  it switches the root tab to `.checkIn` via the new binding.
- Streak section now renders `StreakRingView` inside a white card
  with 0.5px `DS.accent`-tinted border. Streak message sits below.
- Alignment, log-event, and recent-activity rows all moved to the
  white-card-with-accent-border treatment (replaces the old
  `Card` container for these surfaces).
- `HomeViewModel` now tracks `weekDots: [Bool]` for Mon–Sun of the
  current ISO week, computed from `fetchRecentCheckIns(limit: 14)`.
- Removed the old `fullScreenCover` route into `CheckInView` —
  navigation to check-in is now the tab binding path.

**CheckInView:**
- Accepts optional `selectedTab: Binding<RootTab>?`. When embedded
  in the tab bar the xmark toolbar button is hidden and the "Done"
  button on the completion view switches back to `.home` instead of
  calling `dismiss()`. Standalone presentation still works via the
  `nil` branch.
- On completion (`currentIndex >= questions.count`) now calls
  `NotificationService.scheduleDailyReminder()` so the first
  successful check-in kicks off the 20:00 daily reminder cycle.

**Notifications:**
- `NotificationService.scheduleDailyReminder()` was already wired
  with a `UNCalendarNotificationTrigger` at `hour=20, minute=0,
  repeats: true` — verified, no change needed. Permission request
  now happens on app launch from `AwareBudgetApp.task`.

**Blocked / pending:**
- Supabase Swift package still needs to be added via Xcode UI
  (`File → Add Package Dependencies → supabase/supabase-swift`).
  Once present, `SupabaseService.swift` can be swapped from the
  in-memory stub to real `client.from(...)` calls. All view models
  already use the correct `async throws` surface.

**Build:**
- `** BUILD SUCCEEDED **` on iPhone 17 / iOS 26.2 after the full
  rebuild (single warning: AppIntents metadata skipped — unrelated).

---

## 2026-04-12 — UI/UX pass: design system + hero-first Home (Claude Code)

**Goal:** Turn Home from a generic vertical list of cards into a real
dashboard. Apply the same design language to Check-in and Money Event.
Remove the behavioural-UX foot-gun of showing a red 0% to a brand new
user who hasn't set an income target yet.

**Added:**
- `Views/DesignSystem.swift` — shared tokens (`DS.cardRadius`,
  `DS.hPadding`, `DS.sectionGap`), a reusable `Card` container,
  `PrimaryButtonStyle`, `SecondaryButtonStyle`, and `SectionHeader`
  with an optional trailing action. Every view now uses these so
  spacing + corners + button sizing are consistent.

**HomeView redesign:**
- Greeting header: "Good morning/afternoon/evening" + full date
  ("Sunday, 12 April"). Gear icon retained but greyed out (settings
  is out of beta scope).
- Hero check-in card — tappable full-width card that shows either
  the next question teaser ("Tap to check in") or, if already done,
  a "You showed up. See you tomorrow." + tone chip.
- Stats row — streak and alignment as side-by-side compact cards.
- **Alignment card is now context-aware**: if `incomeTarget == 0`
  it shows "Set target" as a call-to-action in blue (tap opens an
  income target editor alert) instead of a red 0%. This fixes the
  "no red without context" rule for brand-new users.
- `contentTransition(.numericText())` on streak + alignment so
  numbers animate when they change.
- "Log money event" is now a real full-width secondary button with
  a plus icon, not a text link.
- Recent activity section has a proper empty state card with a
  tray icon + nudge copy.
- "This month" → small inline chevron link at the bottom.
- `.sensoryFeedback(.success, trigger: isCheckedInToday)` for haptics
  on state change.

**CheckInView redesign:**
- Bigger typography on the question text, bias name in blue.
- "Why this matters" disclosure moved into the card, with a
  lightbulb icon. Still collapsed by default.
- Response field now has its own labelled sub-card.
- Tone picker: larger tap targets, spring animation on selection,
  selected state uses a blue border + tinted fill.
- Close affordance is a circular `xmark` button instead of a
  text "Close" toolbar item.
- Completion screen: big green circle + checkmark, "Nice work"
  headline, streak pill, `.sensoryFeedback(.success)`.

**MoneyEventView redesign:**
- Dropped `Form` for a scroll-view + custom cards layout.
- Amount hero card: huge rounded-display numeric input with a
  leading currency symbol.
- Type selector: 3 big cards with spring animation, same pattern as
  tone picker.
- Category pills: filled blue capsule for the selected state.
- Save button: full-width primary button with a checkmark icon.
- Haptic feedback on type + category selection.

**HomeViewModel:**
- Added `incomeTarget`, `isTargetSet`, `greeting`, `todayLabel`,
  `nextQuestionTeaser`, and a `saveTarget(_:)` async action for the
  alignment CTA.
- `alignmentColor` returns `.secondary` (not red) when no target
  is set.
- `alignmentReassurance` returns "Set a target to start tracking."
  when no target is set.

---

## 2026-04-12 — Fix blank white screen at launch (Claude Code)

**Problem:** App built and ran on iPhone 17 / iOS 26.2 simulator but
showed a fully white screen — no nav bar, no content.

**Likely cause:** iOS 26's `NavigationStack` at the root `WindowGroup`
was swallowing the `if/else` branch layout in `RootView`. Nothing was
rendering because the nav bar region + the scroll view's default
background were both white-on-white, with no visible bounds.

**Fix:**
- Removed the `RootView` wrapper struct. `AwareBudgetApp` now returns
  `OnboardingView` directly at first launch, or `NavigationStack {
  HomeView() }` once `hasCompletedOnboarding` is true. Onboarding
  doesn't need navigation so it has no `NavigationStack` at all.
- Wrapped `OnboardingView` body in a `ZStack` with an explicit
  `Color(.systemBackground).ignoresSafeArea()` base layer so the view
  bounds are always drawn.
- Replaced `.textFieldStyle(.roundedBorder)` with explicit padded
  `Color(.secondarySystemBackground)` capsules on the email + password
  fields. This also looks nicer than the default system rounded border.
- Added the same `ZStack` + `.systemBackground` base to `HomeView`.
- Added a `#Preview` for `OnboardingView` so future agents can see it
  in the Xcode canvas without building the whole app.

**If the screen is still blank after this build:** the simulator may
have `hasCompletedOnboarding = true` stored in UserDefaults from a
previous run. Delete the AwareBudget app from the simulator
(long-press → Remove App) and relaunch.

---

## 2026-04-12 — Fix iOS-only build errors (Claude Code)

**Problem:** Xcode showed 4 build errors in `OnboardingView.swift`:
`keyboardType`, `autocapitalization(.none)`, and a cascading
`.roundedBorder` "cannot infer base" error. Root cause: the target's
`SUPPORTED_PLATFORMS` was `"iphoneos iphonesimulator macosx xros xrsimulator"`
(Xcode 26 multi-platform default), so the compiler was also resolving
each TextField chain against macOS, where `keyboardType` and
`autocapitalization` don't exist.

**Fix:**
- Scoped the project to iOS only in `project.pbxproj`:
  `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"`,
  `SDKROOT = iphoneos`, `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad,
  dropped Mac Catalyst / visionOS). The PRD is iOS-only so nothing is
  lost.
- Defensive `#if !os(macOS)` guards around `.keyboardType` and
  `.textInputAutocapitalization` in `OnboardingView`, `MoneyEventView`,
  and `MonthView`. Replaced the deprecated `.autocapitalization(.none)`
  with `.textInputAutocapitalization(.never)` + `.autocorrectionDisabled(true)`.

---

## 2026-04-12 — Supabase project initialised and schema pushed (Claude Code)

**Ran:**
- `supabase init` → added `supabase/config.toml` and `supabase/.gitignore`.
  Our hand-authored `schema.sql` + `seed.sql` were preserved: `schema.sql`
  moved to `supabase/migrations/20260412000000_initial_schema.sql`,
  `seed.sql` kept at `supabase/seed.sql`.
- `supabase link --project-ref vdnnoezyogbgtiubamze` → linked.
- `supabase db push --include-seed` → migration applied, seed ran. Remote
  DB now has all five tables with RLS enabled. Verified via REST API:
  15 rows present in `question_pool`.

**Migrations are now the canonical source** — future schema changes
should go through `supabase migration new <name>` then
`supabase db push`, not by editing the pushed migration in place.

**Next agent should:** wait for the user to add the Supabase Swift
package in Xcode, then replace the in-memory stub in
`Services/SupabaseService.swift` with real `client.from(...)` calls.

---

## 2026-04-12 — Supabase credentials wired (Claude Code)

**Added:**
- `.gitignore` at repo root that excludes `.secrets/`, `*.env`, and
  common Xcode/SPM build artefacts.
- `.secrets/supabase.env` (local only, gitignored) containing the
  project URL, publishable anon key, DB password, and full Postgres
  connection string for the Supabase project `vdnnoezyogbgtiubamze`.
- Wired `supabaseURL` and `supabaseAnonKey` into
  `Services/SupabaseService.swift`. The anon key is the `sb_publishable_`
  form so it is safe to ship in the iOS client.
- `STATUS.md` → new "Supabase project" section, plus optional MCP server
  install steps.

**NOT done (by design — security):**
- The Postgres direct-connection password is **not** embedded in the
  iOS app and is **not** committed. It only lives in `.secrets/`.
- Did not run the `claude mcp add` / `claude /mcp` / `npx skills add`
  commands because they modify global Claude config and the user should
  run them from a regular terminal.

---

## 2026-04-12 — Initial scaffolding (Claude Code)

**Goal:** Bootstrap the project from the PRD the user wrote in Claude online.

**Added:**
- Full folder structure under `AwareBudget/` matching the PRD layout
  (`Models/`, `Views/`, `ViewModels/`, `Services/`).
- Xcode project wired via `PBXFileSystemSynchronizedRootGroup` so new Swift
  files compile without `.pbxproj` edits.
- Models: `CheckIn`, `MoneyEvent`, `Question`, `BudgetMonth`,
  `MonthlyDecision` — all `Codable` with snake_case `CodingKeys`.
- Services: `SupabaseService` (in-memory stub, method surface matches PRD
  spec), `QuestionPool` (15 seed questions bundled locally),
  `NotificationService` (daily 8pm reminder).
- ViewModels: `HomeViewModel`, `CheckInViewModel`, `MoneyEventViewModel`
  (all `@Observable`, async/await).
- Views: `OnboardingView`, `HomeView`, `CheckInView`, `MoneyEventView`,
  `MonthView` — semantic colours, 16pt card radius, dark-mode safe.
- Supabase SQL: `supabase/schema.sql` (DDL + RLS), `supabase/seed.sql`
  (question pool).
- Onboarding docs: `CLAUDE.md`, `STATUS.md`, `MEMORY.md`, `FUTURE_PLANS.md`,
  `README.md`, `PRD.md`.

**Deviations from PRD:** none — every struct/field/screen matches. Extra
`QuestionPool.swift` added so the stub has seed data without a network
round trip; it disappears once the real Supabase client is wired.

**Known limits:** Supabase Swift package not yet added (user action);
`SupabaseService` is a stub until then. No sign-in screen (beta scope
says sign-up only).

**Next agent should:** run `STATUS.md` → "Next up" list, starting with
wiring the real Supabase client once the package is added.
