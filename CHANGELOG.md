# CHANGELOG — AwareBudget

> Append-only log of every agent/Claude Code session.
> Newest entries at the top. Each entry: date, agent, summary, links.

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
