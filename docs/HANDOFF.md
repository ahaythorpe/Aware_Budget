# GoldMind — Session Handoff

> Read this at the START of every Claude Code session.
> Updated: 2026-05-13 (Build 32 staged — FINAL submission build)

---

## Current build state (2026-05-11)

**TestFlight: Builds 12–18 distributed.** Build 18 is the cumulative snapshot. Latest features in order:

| Build | What landed |
|---|---|
| 11 | Bias mind map v1 (Education tab → "Explore the bias map" card) |
| 12 | Nudge welcome popover · trimmed Backed-by-Research sheet · Top Biases ⓘ → algo · Settings + Insights InfoPopovers · industry top-5 restored · Pattern C copy tightened |
| 13 | Avatar photo upload (PHPicker + Supabase Storage `avatars` bucket) |
| 14 | Notification deep-link fix · mind map v2/v3/v3.1 (labels visible, tap-to-highlight, filter chips, heat tint, separated headers) · Nudge bottom-right · em-dash sweep 4 |
| 15 | Notification permission banner + iOS Settings deep-link (App-Store-readiness for denied state) |
| 16 | Gold-coin Nudge avatar · quieter mind map (no green halo, softer heat, no pulse) |
| 17 | Em-dash sweep round 5 (9 user-facing strings) |
| 18 | Muted/sophisticated colour theme — `accent #3F7A47`, `goldBase #A87E2A`, `goldText #D4A745`, supporting greens softened |
| 20 | UX cleanup: Nudge coin cut-out on Home · Insights empty-state no longer flashes blank charts · mind-map lane rectangles removed · node sheet redesigned (stat chip, bullet counters, real-example disclosure, related chips) · NudgeSays purpose card pinned on mind-map canvas · notification scheduling gated on permission grant · 11 verbose Insights blurbs compressed |
| 21 | Algorithm sheet plain English (no more "gold standard"/"weak signal") · bias-trend vs category-trend now visually distinct (warm gold vs cool green palettes + subtitles) · mind-map filter chips wired back into canvas · editorial pass on Awareness/Home/BiasReview/Settings/Patterns/Credibility · Onboarding/SignIn microcopy legibility bump · tree fully clean (AppConfig, .storekit, 7 migrations now tracked) |
| 22 | Multi-bias model end-to-end (data + algo + UI + aggregation + explainer) · Nudge cut-out as default profile avatar · future-you card on Home above calendar · Financial overview grouped INCOME/SPENDING/WEALTH · Spending-by-Bias + Research tab cards as collapsible BFAS categories · mind-map canvas clears pinned UI · false-claim fixes (Ostrich 12-days, Denomination 12-taps-$87) · Loss Aversion phrasing fix · 6 howToCounter run-on rewrites · algorithm doc consistency audit pass · v1.1 plan captured |
| 23 | Home future-you swapped to the interactive CompoundGrowthCard (range chips + drag-to-zoom + stat row) · Research tab text scales now consistent with rest of app · 4 nudgeSays accuracy fixes (Mental Accounting / Planning Fallacy / Status Quo / Moral Licensing) |
| 24 | Category-trend chart palette → gold family · notification routing fix (bias-hit → Log, weekly + monthly review → new Insights route) · Research dropdown polish (lighter stroke + matched label/chip styling + shadow) · Research card interactivity: "Seen N×" personal trigger chip, "THE FULL PICTURE" + "REAL EXAMPLE" collapsibles surfacing previously-unused BiasLesson fields |
| 25 | Notification routing reverted: weekly + monthly review pushes now also route to Log tab (per Bella's "all to Quick Log") · richer Nudge explainer on the Home compound-growth chart with method + citation · Research inner overcome cards now match outer card aesthetic (hairline stroke + shadow) · bias→personality attribution surfaced on Research labels + Awareness category headers ("The Drifter · AVOIDANCE", "YOU" pill on user's archetype) |
| 26 | "THE FOUR PAPERS" → "THE MAIN PAPERS" · Research paper / framework / ranking cards drop the heavy shimmering gold border for the same hairline + shadow as the rest of the app · DEV_HANDOVER.md doc added |
| 27 | Research-tab concept graph (#34): new ResearchMapView with 16 papers + 16 biases as tappable chips; tap a paper to highlight underpinning biases, tap a bias to find its source; embedded between THE FRAMEWORK and HOW THE RANKING WORKS; new ResearchGraph data lookups derived from existing BiasData.keyRef |
| 28 | 6 programmatic bias illustrations (Loss Aversion S-curve, Present Bias hyperbolic, Anchoring bars, Planning Fallacy overrun, Mental Accounting jars, Overconfidence calibration) · end-of-week bias review sheet on Insights tab · Scarcity Heuristic → Bandwagon Effect rename across 17 files + 6 Supabase tables · Cialdini 2001 → 1984 · MAIN PAPERS rename · Research personality cards thick gold border · mind-map related chips made static · Home Nudge speech bubble · concept graph on Education + Research tabs |
| 29 | Inline charts on Research overcome cards (was mind-map-only) · thick gold border restored on inner cards · personality icon disc on each Research category header · concept graph moved to top of Education tab · PLAN_BIAS_ANIMATIONS.md captured (v1.1 static illustrations + v2 Lottie animation path) |
| 30 | Sunday weekly push + monthly checkpoint push now tap-route to End-of-Week Review sheet on Insights · bias-paper map moved to Research-only (Education focuses on personal depth) · horizontal-shift bug fix on Education/Research tabs |
| 32 | **FINAL submission build.** Awareness Score gold progress bar at top of Education tab (X of 16 patterns identified) · DEBUG-only Screenshot Mode paywall bypass for App Store screenshot capture (-ScreenshotMode launch arg) · SCREENSHOTS_GUIDE.md captured |
| 33 | AboutScoreSheet ("How your score works") content sync — was showing stale Build-18-era scoring (+2/-1/+3), now matches live algorithm (+5/-2/0/+1/0-10) |

**App Store: NOT submitted.** Bella reaffirmed 2026-05-11 to stay in TestFlight-only iteration. No RevenueCat dashboard changes.

## Live follow-up tasks (audit 2026-05-12)

- **#26 Paywall pricing display** — parked. Needs RevenueCat dashboard or custom SwiftUI paywall; both off-limits.
- **#27 Organize biases in AwarenessView** — **done.** Already grouped by 6 BFAS categories. `Models/BiasData.swift:220` defines `biasCategories`; `Views/AwarenessView.swift:67` iterates them with per-category headers + mid-tab BFAS callouts after categories 2 and 4. If extending: sort modes / triggered-only filter / collapsible sections.
- **#28 Editorial pass + interactivity on dense screens** — open. No coach marks.
- **#29 Monthly checkpoint screen** — `NotificationService.scheduleMonthlyCheckpoint` already fires a 1st-of-month push but tap currently lands on Home with no dedicated recap UI. Needs an in-app monthly review screen (events / streaks / awareness moments delta from prior month).
- **#30 Mind map concept-graph interactivity** — beyond per-node sheet redesign (done in `ec90d5f`), explore concept-map layouts: zoom levels, multi-bias clusters, "show all relations" toggle, drag-to-rearrange. Concept maps as a richer interaction model than the current lane layout.
- **#31 Multi-bias question in check-ins** — Bella raised 2026-05-12: instead of one bias-tag question per spend (or bumping to two questions, which doubles tap cost), redesign the single question as a multi-select so one screen can capture 2+ co-driving biases. Faster, more accurate for stacked-driver events. No schema change (`behaviourTag` already nullable / could be array on a new field). Worth prototyping after #29.

## What this is

iOS behavioural finance app. Swift + SwiftUI + Supabase.
Philosophy: "Stay aware. Adjust early. No shame."
NOT a budgeting app. NO bank sync. NO categories.
Success = awareness streaks + behaviour trends improving.

Owner: Arabella (bundle id `goldmind.app`).
Solo dev with Claude Code. Xcode 26, iOS 26.2.

---

## Every Swift file and what it does (verified)

### Models/ (6 files)
- `CheckIn.swift` — EmotionalTone (calm/neutral/anxious), SpendingDriver (6 cases: present_bias, social, emotional, convenience, identity, friction_avoid), CodingKeys snake_case
- `MoneyEvent.swift` — PlannedStatus (planned/surprise/impulse), LifeEvent, SizeBucket (derived), behaviourTag, CodingKeys snake_case
- `Question.swift` — biasName, biasCategory, difficulty, whyExplanation, lastShown
- `BiasLesson.swift` — biasName, category, shortDescription, fullExplanation, realWorldExample, howToCounter, emoji, sortOrder
- `BudgetMonth.swift` — userId, month, incomeTarget
- `MonthlyDecision.swift` — userId, month, decision, insight

### Services/ (6 files)
- `SupabaseService.swift` — **LIVE** (supabase-swift 2.43.1). All methods real. Auth, check-ins, money events, questions, budget months, bias lessons, bias progress. BiasProgress model also defined here. ISO8601DateFormatter.dateOnly helper.
- `NudgeEngine.swift` — Pure Swift decision tree. 13 priority rules (added "no events in 2 days" nudge). `moneyEventResponse()` with instant bias feedback ("That's Anchoring. 3rd time."), `checkInResponse()`. NudgeContext gains `daysSinceLastEvent`, `eventLoggingStreak`.
- `NotificationService.swift` — **rebuilt** 4 notification types: (1) 8am morning "One question. 60 seconds. Nudge is waiting.", (2) 7pm evening if no check-in "Nudge noticed.", (3) 48h no events "Nudge has no data. That's also information.", (4) Bias hits 5x "[Bias] appeared 5 times. Nudge has something." All scheduled on app launch. Evening nudge cancelled on check-in. No-events timer reset on money event save. Bias alert fired when `countBehaviourTag == 5`.
- `QuestionPool.swift` — 15 hard-coded seed questions for offline use.
- `BiasLessonsMock.swift` — 16 seed BiasLesson objects for offline use. Grouped into 6 categories (Avoidance, Decision Making, Money Psychology, Time Perception, External Influence, Self Perception). `categoryOrder` array for display ordering.
- `BiasScoreService.swift` — **NEW** Bias scoring: MasteryStage (unseen/noticed/emerging/active/improving/aware), BiasTrend, scoring weights (+2 yes, -1 no, +3 tagged), computeScore().

### ViewModels/ (3 files)
- `HomeViewModel.swift` — @Observable. streak, alignmentPct, weekDots, nudgeMessage, greeting, todayLabel. buildNudge() from live data.
- `CheckInViewModel.swift` — @Observable. load question, submit with streak calc, alignment calc. Uses `await service.currentUserId`.
- `MoneyEventViewModel.swift` — @Observable. Amount validation, save, nudgeResponse. Uses `await service.currentUserId`.

### Views/ (14 files)
- `GoldMindApp.swift` — @main. Onboarding gate. RootTabView after onboarding.
- `RootTabView.swift` — 4 tabs: Home / Log / Insights / Library. Tint DS.primary. MoneyEventView is Log tab (direct). CheckInView opens as sheet from HomeView.
- `DesignSystem.swift` — DS enum with all colour tokens + Card, PrimaryButtonStyle, SecondaryButtonStyle, SectionHeader, NudgeAvatar, GoldButton, GoldRingModifier.
- `HomeView.swift` — Greeting header, NudgeCardView, **pattern alert cards** (biases 3+ times → emoji + count + trend, tappable → Insights), hero gradient check-in card (shows "Checked in · Day [streak]" with gold checkmark when done, opens CheckInView sheet), StreakRingView, **3 stat cards** (Alignment %, Biases Seen gold, This Week spend), **Daily Missions** (check-in/log event with completion state), alignment card, recent activity. Settings gear icon opens SettingsView sheet.
- `CheckInView.swift` — **Swipe YES/NO.** Green gradient #1B5E20-#2E7D32-#4CAF50. Right=YES green overlay, Left=NO coral overlay. +/-15 degree rotation. 2 back cards. Gold bias pill. No text input. White opacity tone picker. Progress dots. Driver pick phase. Completion with Nudge. **BFAS credibility line** below each question (caption2, italic, white 0.5 opacity). **Daily enforcement**: checks fetchTodaysCheckIn() on appear — shows "You checked in today" + streak + "Come back tomorrow" if done.
- `InsightFeedView.swift` — **Charts framework.** Hero gradient card with decorative circles. Bar chart: 6-week unplanned spend. Horizontal bar chart: bias frequency. Donut chart: planned vs unplanned %. Nudge card. Background #F5F7F5. Info button → "About your score" sheet (scoring weights, mastery stages, disclaimer).
- `LearnView.swift` — **Library tab.** Glossary card at top ("16 patterns. One line each." — grouped by category with section headers, all 16 biases with emoji + name + description, tappable → BiasDetailView). Categories: Avoidance, Decision Making, Money Psychology, Time Perception, External Influence, Self Perception. Swipe card deck below. 1 back card. 52pt emoji, 22pt bold bias name, 13pt description, IN REAL LIFE teal label. Two side-by-side buttons: "Learn more" + "How to counter it" → BiasDetailView. **Mastery stage badge** top-right (colour-coded). **Bias glossary** sheet via list button in toolbar. Filter pills. "X of 16" counter. Sources BiasLessonsMock.seed (16 biases).
- `BiasDetailView.swift` — Full bias lesson detail. 72pt emoji, name, category pill, fullExplanation, realWorldExample, howToCounter.
- `MoneyEventView.swift` — **Rebuilt as quick-log** (2026-04-13). 2-column grid with top 6 categories (bigger cards: Coffee, Lunch, Drinks, Shopping, Transport, Takeaway), "More categories ↓" expands remaining 10. ABS monthly average above range picker ("Avg: $180/mo · ABS 2022–23"). Tap range → planned/surprise/impulse. Auto-suggest bias tag (gold pill). **Driver insight card** slides in after tag: "WHAT THIS MEANS" / "HOW TO BREAK IT" + "See your [bias] pattern →" pill → Insights tab. BFAS credibility line below driver grid. Inline Nudge message. "Log it" gold button. No amount input, no note, no date picker. Stores: amount=midpoint, life_area=category, behaviour_tag=bias name.
- `NudgeCardView.swift` — Green accent bar, NudgeAvatar, message text, gold action button, dismiss X. NudgeDismissStore (24h), NudgeDedup.
- `StreakRingView.swift` — 140pt ring, DS.accent stroke, gold gradient number, M-S day dots.
- `SparklineView.swift` — 7-bar sparkline. Green improving, orange worsening.
- `OnboardingView.swift` — **rebuilt** 4-screen swipeable TabView onboarding: (1) Nudge 120pt welcome on heroGradient + gold "Get started →", (2) "The 7 patterns that cost people most" — 7 white cards on heroGradient (Loss Aversion, Present Bias, Overconfidence, Mental Accounting, Status Quo Bias, Anchoring, Ostrich Effect) + Pompian 2012 citation, (3) Budget Reality Check — sequential quiz (Q1 budget duration 4 options, Q2 why stopped 4 options), capsule pills, Nudge response card (heroGradient, "You're not broken. The method is.", 70% stat), (4) sign-up form + "Sign in" toggle.
- `SignInView.swift` — **NEW** email/password sign-in sheet with gold button. On success: hasCompletedOnboarding = true.
- `SettingsView.swift` — **NEW** gear icon sheet from HomeView. Sign out (Supabase + reset onboarding flag), reset demo data (clears user's checkins/events/progress), app version/build. **Debug**: "Reset onboarding (debug)" button (DEBUG only) — signs out + resets to onboarding.
- `MonthView.swift` — Legacy, NOT mounted in tab bar.

### Assets
- `Assets.xcassets/nudge.imageset/nudge.png` — Gold coin mascot. Source: images/Nudge_Asset.png. Wrapped in green Circle (NudgeAvatar) to hide black PNG background.
- `Assets.xcassets/AppIcon.appiconset/` — Nudge mascot at 1024px (Icon-1024.png), used for iOS light/dark/tinted variants
- `Assets.xcassets/AccentColor.colorset/` — default

---

## Exact colours (from DesignSystem.swift)

```
primary       = #2E7D32   // hero cards, nav, CTA buttons
accent        = #4CAF50   // section labels, ring, buttons
lightGreen    = #81C784   // card backs, tints
paleGreen     = #E8F5E9   // pills, tab active bg
bg            = #FAFAF8   // DesignSystem bg (views use #F5F7F5)
cardBg        = white

textPrimary   = #1A2E1A
textSecondary = #6B7A6B
textTertiary  = #A0B0A0

positive      = #4CAF50
warning       = #FF7043

goldBase      = #C59430
goldText      = #E8B84B

heroGradient  = #1B5E20 (0.0) -> #2E7D32 (0.35) -> #4CAF50 (0.65) -> #388E3C (1.0)
               topLeading -> bottomTrailing

nuggetGold    = #FFF0A0 -> #E8B84B -> #C59430 -> #8B6010 -> #D4A843

Card borders  = rgba(76,175,80,0.15)  (DS.accent.opacity(0.15) or paleGreen 0.5px)
App bg        = #F5F7F5 (used in CheckInView, InsightFeedView)
```

---

## Nudge mascot

- Name: Nudge. Gold metallic coin, thinking pose.
- Source: `/Users/bella/GoldMind/images/Nudge_Asset.png`
- Asset: `Assets.xcassets/nudge.imageset/nudge.png` (wired at 2x scale)
- Display: NudgeAvatar wraps in green Circle to mask black PNG bg
- Sizes: 44pt in NudgeCardView, 100pt onboarding, 72pt completion
- Appears in 5 places ONLY: HomeView NudgeCard, CheckInView completion, CheckInView follow-up, MoneyEventView post-save, OnboardingView welcome
- Personality: dry wit, max 2 sentences, no "great job", no exclamation marks, references real data, third person sometimes

---

## Supabase (LIVE)

- Project: `vdnnoezyogbgtiubamze`
- URL: `https://vdnnoezyogbgtiubamze.supabase.co`
- Anon key: `sb_publishable_lwuCqoY6jpKRwQRJoqZYFQ_CiavSWwH`
- Package: supabase-swift 2.43.1 (SPM, in xcodeproj)
- Tables: budget_months, daily_checkins, money_events, monthly_decisions, question_pool (30 rows), bias_lessons (16 rows), user_bias_progress
- RLS on all user tables, read-only on question_pool + bias_lessons
- 6 migrations applied (see STATUS.md for list)

---

## What still needs building (priority order)

1. Swap LearnView off BiasLessonsMock.seed -> service.fetchAllBiasLessons()
2. ~~Swap CheckInView off QuestionPool.seed -> service.fetchNextQuestion()~~ **DONE**
3. Backfill bias_category on original 15 question_pool rows
4. Verify sign-up -> first check-in -> streak = 1 flow on device
5. Verify notification permission fires after first check-in
6. HomeView: add three stat cards (not two), daily missions section
7. ~~OnboardingView with Nudge welcome screen~~ **DONE** (3-screen + sign in)
8. TestFlight build

---

## Design rules (non-negotiable)

- NO categories on money events. Planned/Surprise/Impulse only.
- NO purple or violet anywhere. Money green + nugget gold only.
- NO flat green on hero cards. Must be gradient.
- NO yellow squares for tone picker. White opacity buttons.
- NO rigid "budget vs actual" numbers. Show trends only.
- NO text input field on check-in cards.
- NO bank sync. All manual.
- NO "great job" from Nudge. Dry wit only.
- Background #F5F7F5, borders rgba(76,175,80,0.15)
- Section labels: 12pt 800 weight #4CAF50 uppercase tracking 1.5

---

*Last verified: 2026-04-13 — our source compiles clean on iPhone 17 Pro / iOS 26.2 (upstream swift-clocks SPM dep has Xcode 26 compat issue)*
