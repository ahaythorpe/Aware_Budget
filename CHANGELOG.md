# CHANGELOG — AwareBudget

> Append-only log of every agent/Claude Code session.
> Newest entries at the top. Each entry: date, agent, summary, links.

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
