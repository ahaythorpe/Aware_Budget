# STATUS — GoldMind

> Quick reference. Detailed state lives in `docs/HANDOFF.md`.

**Last updated:** 2026-05-12
**Current build:** 25 (staged 2026-05-13 — notification routing fix lands · bias → personality attribution on Research + Awareness · richer Home chart explainer · Research inner-card polish)
**App Store:** not submitted — Bella in TestFlight-only iteration mode

## Where to find things

- **Per-build feature breakdown:** `CHANGELOG.md`
- **Architecture, file map, design rules, what blocks App Store:** `docs/HANDOFF.md`
- **Algorithm + scoring methodology:** `docs/ALGORITHM.md`
- **Paywall + RevenueCat config:** `docs/PAYWALL.md`
- **Auditor findings + advisor warnings:** `docs/AUDIT.md`
- **Original PRD (mostly historical):** `docs/PRD.md`
- **Design tokens, components, patterns:** `docs/DESIGN_HANDBOOK.md`
- **Supabase migrations:** `supabase/migrations/`

## Live follow-up tasks (see HANDOFF for full text)

- **#26 Paywall discount display** — parked (off-limits RevenueCat work)
- **#28 Editorial pass on dense screens** — in progress (Insights + Home + AwarenessView done; CheckInView open)
- **#29 Monthly checkpoint screen** — open
- **#30 Mind-map concept-graph interactivity** — open
- **#31 Multi-bias question in check-ins** — discussed 2026-05-12, not yet built
- **App Store compliance prep** (privacy / terms / refund language) — pending

## What changed in this build (Build 20, 2026-05-12)

UX cleanup batch. See CHANGELOG entry for full list. Notable:
- Home Nudge avatar is now a floating cut-out (no gold disc).
- Insights empty state no longer flashes blank charts.
- Mind-map node sheet redesigned (stat chip, bullet counters, real-example disclosure, related-bias chips).
- Mind-map canvas gained a pinned NudgeSays purpose card + filter chips.
- Notifications scheduling gated on actual permission grant.
- Bias-trend and category-trend charts now use distinct palettes + subtitles.
- 16 verbose blurbs compressed across Insights, Home, AwarenessView.
- AlgorithmExplainerSheet score rows now in plain English (no more "gold standard" / "weak signal" jargon).
