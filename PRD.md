# GoldMind — Product Requirements Document

**For:** Claude Code (iOS/SwiftUI Build)
**Version:** 1.0 Beta

---

## Overview

GoldMind is an awareness-based personal finance iOS app grounded in
behavioural economics. It does NOT sync to banks. Users manually log their
financial activity. The core philosophy is: **Stay aware. Adjust early. No
shame.**

The app addresses the "Ostrich Effect" — the tendency people have to avoid
looking at their finances when things feel overwhelming. Success is measured
by awareness streaks and alignment percentages, not perfect budget adherence.

---

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Backend/Database:** Supabase (PostgreSQL)
- **Auth:** Supabase Auth (email + password)
- **Notifications:** UserNotifications framework
- **Minimum iOS:** iOS 17+
- **Architecture:** MVVM

---

## Project Structure

```
GoldMind/
├── GoldMindApp.swift
├── ContentView.swift
├── Models/
│   ├── CheckIn.swift
│   ├── MoneyEvent.swift
│   ├── Question.swift
│   ├── BudgetMonth.swift
│   └── MonthlyDecision.swift
├── Views/
│   ├── HomeView.swift
│   ├── CheckInView.swift
│   ├── MoneyEventView.swift
│   ├── MonthView.swift
│   └── OnboardingView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── CheckInViewModel.swift
│   └── MoneyEventViewModel.swift
└── Services/
    ├── SupabaseService.swift
    └── NotificationService.swift
```

---

## Supabase Schema

See `supabase/schema.sql` for the canonical DDL. Tables: `budget_months`,
`daily_checkins`, `money_events`, `monthly_decisions`, `question_pool`. RLS
is enabled on every user-owned table with the policy
`auth.uid() = user_id`; `question_pool` is world-readable.

## Seed Data

See `supabase/seed.sql` for the 15 behavioural question rows.

---

## Screens & Features

### 1. Onboarding (first launch only)

- Tagline: "Stay aware. Adjust early. No shame."
- 3-step explanation
- Email + password sign-up (no sign-in in beta)
- On submit: create Supabase auth user, create first `budget_months` row
- Navigate to Home

### 2. Home Dashboard

- Title "GoldMind" + settings gear
- **Streak card**: flame, day count, motivational one-liner
  - 0 → "Start your streak today"
  - 1–6 → "Keep showing up"
  - 7–13 → "One week strong"
  - 14–29 → "You're building a habit"
  - 30+ → "Awareness mastery"
- **Alignment card**: percentage + "aligned this month", green ≥80%,
  amber 50–79%, red <50%
- Today's emotional tone (if checked in)
- Primary "Check in today" button (green checkmark if done)
- Secondary "Log money event" button
- Recent events (last 3)
- Link to `MonthView`

**Streak calculation:** if yesterday has a check-in, new streak =
yesterday.streak + 1; otherwise 1.

**Alignment calculation:** `max(0, (1 - unplanned_total / income_target) * 100)`
where `unplanned_total` = sum of `money_events.amount` with
`event_type = 'surprise'` for the current month.

### 3. Daily Check-In (under 90s target)

1. Load next question from `question_pool` where `last_shown IS NULL` or
   `last_shown < today - 14 days`. Prefer least recently shown. Update
   `last_shown` on select.
2. Display question text + small bias label.
3. Optional response text field.
4. "Why this matters" disclosure — **collapsed by default**.
5. Emotional tone: Calm / Neutral / Anxious.
6. On submit: compute streak + alignment, write row, show checkmark
   animation, navigate back.

### 4. Money Event (sheet)

- Amount (required, numeric keyboard)
- Type: Surprise / Win / Expected
- Category pill: Food, Transport, Shopping, Bills, Income, Health,
  Entertainment, Other
- Note (optional)
- Date (defaults to today)
- Save → write to `money_events`, dismiss, refresh Home.

### 5. Month View

- Month + year header
- Alignment % (colour coded)
- Editable income target
- Events grouped by type
- Totals by category
- Streak history dots (v1.1)

---

## Navigation

```
App launches
  ├── First launch → OnboardingView
  └── Returning   → HomeView
         ├── Check in → CheckInView (fullScreenCover)
         │       └── Log event → MoneyEventView (sheet)
         ├── Log money event → MoneyEventView (sheet)
         └── This month → MonthView (navigation push)
```

Root `NavigationStack`. `CheckInView` as `fullScreenCover`. `MoneyEventView`
as `sheet`. `MonthView` pushed.

---

## Supabase Integration

Singleton `SupabaseService.shared`, method surface:

```swift
// Auth
func signUp(email: String, password: String) async throws
func signIn(email: String, password: String) async throws
func signOut() async throws

// Check-ins
func saveCheckIn(_ checkIn: CheckIn) async throws
func fetchTodaysCheckIn() async throws -> CheckIn?
func fetchRecentCheckIns(limit: Int) async throws -> [CheckIn]

// Money events
func saveMoneyEvent(_ event: MoneyEvent) async throws
func fetchMoneyEvents(forMonth: Date) async throws -> [MoneyEvent]

// Questions
func fetchNextQuestion() async throws -> Question

// Budget months
func fetchOrCreateBudgetMonth(for: Date) async throws -> BudgetMonth
func updateIncomeTarget(_ amount: Double, for month: Date) async throws
```

Replace `YOUR_SUPABASE_URL` / `YOUR_SUPABASE_ANON_KEY` with values from
Supabase dashboard → Settings → API.

---

## Push Notifications

`UserNotifications` framework. Daily reminder at **8 PM**:
- Title: "GoldMind check-in"
- Body rotates: "60 seconds. That's all it takes." /
  "How's your awareness today?" / "Your streak is waiting."
- Request permission on first check-in completion, not on launch.
- Cancel scheduled reminder once today's check-in is logged.

---

## Design Guidelines

- **Colours:** system blue (primary), green (success), orange (warning),
  red (danger). `systemBackground` + `secondarySystemBackground`.
- **Typography:** SF Pro (system). Never hardcode font names.
- **Corner radius:** 16 (cards), 12 (buttons).
- **Spacing:** 16pt padding, 24pt between sections.
- **Streak flame:** SF Symbol `flame.fill` in orange.
- **No gradients, no shadows.** Flat clean design.
- **Dark mode** — semantic colours only.

---

## Key Behavioural UX Rules (non-negotiable)

1. **Never show red without context.** Low alignment always pairs with a
   reassurance line.
2. **Missed streak = no punishment.** Show "Start a new streak today" not
   "Streak broken".
3. **Check-in button always available**, even if done (green checkmark
   state).
4. **Why explanations are always opt-in.** Collapsed by default.
5. **Alignment clamped ≥ 0.** Never negative.

---

## Beta Scope

Ship for TestFlight:
- OnboardingView (sign up only)
- HomeView
- CheckInView
- MoneyEventView
- SupabaseService (auth + checkins + events + questions)
- NotificationService (daily reminder)

`MonthView` ships in v1.1 (scaffolded but not beta-gated).

---

## Environment Setup Notes

1. Xcode project already created: iOS App, SwiftUI, Swift, `GoldMind`.
2. Add Supabase Swift package via `File → Add Package Dependencies`.
3. Folder structure is already in place.
4. Build order: Models → Services → ViewModels → Views.
5. Test on iPhone 15 Pro simulator (iOS 17).
6. No `@AppStorage` for sensitive data — use Supabase auth session only.
7. async/await everywhere. No Combine.
8. All Supabase calls in `do/catch` with user-facing error messages.

---

*Core philosophy: Stay aware. Adjust early. No shame.*
