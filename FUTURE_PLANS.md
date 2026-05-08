# FUTURE_PLANS — GoldMind

> Deferred ideas, v1.1+ scope, and "nice to haves".
> Move items up to `STATUS.md` → "Next up" when they become active.

---

## v1.1 (post-beta)

- **Sign-in flow** for returning users. Currently onboarding is sign-up only.
- **Settings screen** (gear icon on Home) — sign out, income target,
  notification time, currency, delete account.
- **Streak history dots** on `MonthView` — row of day dots (green = checked
  in, grey = missed). PRD mentions this; skipped in scaffold.
- **Monthly decisions UI** — `monthly_decisions` table exists but there is
  no view for capturing end-of-month insight + next-month decision.
- **Biometric lock** (FaceID / TouchID) gate on the app.
- **Export to CSV** — user-initiated data export for their own records.

## v1.2+

- **Weekly digest notification** — Sunday summary of alignment + streak.
- **Partner view** — optional shared awareness with a trusted other.
- **Widget** — home-screen widget showing streak + today's question.
- **Watch companion** — check-in from the wrist in under 30 seconds.
- **Voice capture** for response field (Speech framework).
- **Custom question packs** — user can author their own behavioural
  prompts (still reviewed against the bias framework).

## Product-design bets to validate

- Does the "no shame" framing actually drive retention, or do users
  want explicit goals? (A/B with "target alignment" copy.)
- Do 15 questions rotating every 14 days feel fresh enough, or is
  variety a bigger driver than expected?
- Should check-in prompt vary by day-of-week or by recent emotional tone?

## Infra / tech debt

- Replace `SupabaseService` stub with real client (tracked in `STATUS.md`).
- Add a lightweight error banner component — right now errors surface as
  plain text in each view. Centralising would reduce duplication.
- Snapshot tests for the streak messaging + alignment colour logic.
- Decide on currency handling: device locale (current) vs. user preference
  saved in `budget_months`.

## Observations to keep in mind

- The question pool ships bundled locally in `QuestionPool.swift`. Once
  real Supabase is wired, decide whether to keep the local copy as an
  offline fallback or remove it to keep the source of truth in the DB.
