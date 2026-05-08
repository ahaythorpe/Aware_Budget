# GoldMind

> Stay aware. Adjust early. No shame.

An awareness-based personal finance iOS app grounded in behavioural economics.
No bank sync — users manually log their financial activity. Success is
measured in awareness streaks and alignment percentages, not budget adherence.

## Quick start

```bash
open GoldMind.xcodeproj
```

1. In Xcode: **File → Add Package Dependencies** →
   `https://github.com/supabase/supabase-swift`
2. In the Supabase dashboard, run `supabase/schema.sql` then
   `supabase/seed.sql`.
3. Open `GoldMind/Services/SupabaseService.swift` and fill in
   `supabaseURL` / `supabaseAnonKey` from Settings → API.
4. Build & run on the iPhone 15 Pro simulator (iOS 17+).

Until step 1 is done the app runs against an in-memory stub — everything is
usable but nothing persists across launches.

## Project layout

```
GoldMind/                 ← Swift sources (auto-synced to Xcode)
├── GoldMindApp.swift
├── Models/                  ← Codable structs
├── Views/                   ← SwiftUI screens
├── ViewModels/              ← @Observable view models
└── Services/                ← Supabase + Notifications

supabase/                    ← schema + seed SQL
```

## Docs for agents

- [`CLAUDE.md`](CLAUDE.md) — onboarding for AI agents (read this first)
- [`STATUS.md`](STATUS.md) — current build state
- [`MEMORY.md`](MEMORY.md) — durable project facts
- [`CHANGELOG.md`](CHANGELOG.md) — session history
- [`FUTURE_PLANS.md`](FUTURE_PLANS.md) — v1.1+ roadmap
- [`PRD.md`](PRD.md) — full product requirements

## Stack

Swift 5 · SwiftUI · iOS 17+ · Supabase · `UserNotifications` · MVVM +
`@Observable` · async/await (no Combine)
