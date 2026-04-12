# AwareBudget — Session Handoff

> Read this at the START of every Claude Code session.
> Updated: 2026-04-12

---

## What this is

iOS behavioural finance app. Swift + SwiftUI + Supabase.
Philosophy: "Stay aware. Adjust early. No shame."
NOT a budgeting app. NO bank sync. NO categories.
Success = awareness streaks + behaviour trends improving.

Owner: Arabella (bundle id `Arabella.AwareBudget`).
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

### Services/ (5 files)
- `SupabaseService.swift` — **LIVE** (supabase-swift 2.43.1). All methods real. Auth, check-ins, money events, questions, budget months, bias lessons, bias progress. BiasProgress model also defined here. ISO8601DateFormatter.dateOnly helper.
- `NudgeEngine.swift` — Pure Swift decision tree. 12 priority rules. `moneyEventResponse()`, `checkInResponse()`. NudgeContext, NudgeAction, NudgeMessage types.
- `NotificationService.swift` — UNCalendarNotificationTrigger at hour=20.
- `QuestionPool.swift` — 15 hard-coded seed questions for offline use.
- `BiasLessonsMock.swift` — 16 seed BiasLesson objects for offline use.

### ViewModels/ (3 files)
- `HomeViewModel.swift` — @Observable. streak, alignmentPct, weekDots, nudgeMessage, greeting, todayLabel. buildNudge() from live data.
- `CheckInViewModel.swift` — @Observable. load question, submit with streak calc, alignment calc. Uses `await service.currentUserId`.
- `MoneyEventViewModel.swift` — @Observable. Amount validation, save, nudgeResponse. Uses `await service.currentUserId`.

### Views/ (13 files)
- `AwareBudgetApp.swift` — @main. Onboarding gate. RootTabView after onboarding.
- `RootTabView.swift` — 4 tabs: Home / Check in / Learn / Insights. Tint DS.primary.
- `DesignSystem.swift` — DS enum with all colour tokens + Card, PrimaryButtonStyle, SecondaryButtonStyle, SectionHeader, NudgeAvatar, GoldButton, GoldRingModifier.
- `HomeView.swift` — Greeting header, NudgeCardView, hero gradient check-in card, StreakRingView, alignment card, log event button, recent activity.
- `CheckInView.swift` — **Swipe YES/NO.** Green gradient #1B5E20-#2E7D32-#4CAF50. Right=YES green overlay, Left=NO coral overlay. +/-15 degree rotation. 2 back cards. Gold bias pill. No text input. White opacity tone picker. Progress dots. Driver pick phase. Completion with Nudge.
- `InsightFeedView.swift` — **Charts framework.** Hero gradient card with decorative circles. Bar chart: 6-week unplanned spend. Horizontal bar chart: bias frequency. Donut chart: planned vs unplanned %. Nudge card. Background #F5F7F5.
- `LearnView.swift` — Swipe card deck. 1 back card. 52pt emoji, 22pt bold bias name, 13pt description, IN REAL LIFE teal label, gold "How to counter it" button. Filter pills. "X of 16" counter. Sources BiasLessonsMock.seed.
- `BiasDetailView.swift` — Full bias lesson detail. 72pt emoji, name, category pill, fullExplanation, realWorldExample, howToCounter.
- `MoneyEventView.swift` — Amount, planned/surprise/impulse, behaviour tag (2x3 grid, unplanned only), life event (>200 only), note, date, save. Post-save NudgeCard.
- `NudgeCardView.swift` — Green accent bar, NudgeAvatar, message text, gold action button, dismiss X. NudgeDismissStore (24h), NudgeDedup.
- `StreakRingView.swift` — 140pt ring, DS.accent stroke, gold gradient number, M-S day dots.
- `SparklineView.swift` — 7-bar sparkline. Green improving, orange worsening.
- `OnboardingView.swift` — 3-step explainer + sign-up form.
- `MonthView.swift` — Legacy, NOT mounted in tab bar.

### Assets
- `Assets.xcassets/nudge.imageset/nudge.png` — Gold coin mascot. Source: images/Nudge_Asset.png. Wrapped in green Circle (NudgeAvatar) to hide black PNG background.
- `Assets.xcassets/AppIcon.appiconset/` — empty (no icon yet)
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
- Source: `/Users/bella/Aware Budget/images/Nudge_Asset.png`
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
2. Swap CheckInView off QuestionPool.seed -> service.fetchNextQuestion()
3. Backfill bias_category on original 15 question_pool rows
4. Verify sign-up -> first check-in -> streak = 1 flow on device
5. Verify notification permission fires after first check-in
6. HomeView: add three stat cards (not two), daily missions section
7. OnboardingView with Nudge welcome screen
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
- Section labels: 11pt 800 weight #4CAF50 uppercase tracking 1.5

---

*Last verified: 2026-04-12 — build succeeds on iPhone 17 Pro / iOS 26.2*
