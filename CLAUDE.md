# CLAUDE.md — AwareBudget

> Instructions for any AI agent (Claude Code or other) working in this repo.
> **Read this file first on every session.** When you finish a task, update
> `STATUS.md` and `CHANGELOG.md` so the next agent can resume cleanly.

---

## What this project is

AwareBudget is an **awareness-based** personal finance iOS app (SwiftUI) built
on the philosophy **"Stay aware. Adjust early. No shame."** It does NOT sync to
banks — all logging is manual. The full product spec lives in `PRD.md`.

Success metrics are behavioural (streaks, alignment %) not budget adherence.

## Tech stack

| Layer         | Choice                                        |
|---------------|-----------------------------------------------|
| Language      | Swift 5 (Swift 6 concurrency mode)            |
| UI            | SwiftUI, iOS 17+                              |
| Architecture  | MVVM with `@Observable` view models           |
| Backend       | Supabase (PostgreSQL + Auth)                  |
| Notifications | `UserNotifications` framework                 |
| Concurrency   | async / await only (no Combine)               |

## Repository layout

```
AwareBudget/                    ← repo root (this folder)
├── CLAUDE.md                   ← THIS FILE — read first
├── STATUS.md                   ← current state of the build
├── MEMORY.md                   ← durable facts about project/user
├── CHANGELOG.md                ← append-only log of every agent session
├── FUTURE_PLANS.md             ← roadmap / deferred ideas
├── PRD.md                      ← full product requirements
├── README.md                   ← human-facing quick start
├── supabase/
│   ├── schema.sql              ← run this in Supabase first
│   └── seed.sql                ← then run this for the question pool
├── AwareBudget.xcodeproj/      ← Xcode project (synced folder group)
└── AwareBudget/                ← Swift sources (auto-included via synced group)
    ├── AwareBudgetApp.swift
    ├── Models/
    ├── Views/
    ├── ViewModels/
    └── Services/
```

**Important:** The Xcode project uses a `PBXFileSystemSynchronizedRootGroup`
pointing at `AwareBudget/`. Any file dropped into that folder (or its
subfolders) is compiled automatically. **Do not manually edit `project.pbxproj`
to add files** — just create them in the right subfolder.

## Ground rules for agents

1. **Start every session by reading**: `CLAUDE.md` → `STATUS.md` → `MEMORY.md`.
2. **End every session by updating**: `STATUS.md` (current state),
   `CHANGELOG.md` (what you did), and `FUTURE_PLANS.md` if you deferred work.
3. **Follow the PRD** (`PRD.md`). If you want to deviate, flag it in
   `CHANGELOG.md` with a `DEVIATION:` line.
4. **Behavioural UX rules are non-negotiable** (see PRD §"Key Behavioural UX
   Rules"). No red without reassurance. No streak shaming. "Why?" is opt-in.
5. **Never hardcode secrets in committed files.** The Supabase **public**
   URL and `sb_publishable_` anon key are safe in `SupabaseService.swift`.
   The Postgres password and direct connection string live in
   `.secrets/supabase.env` which is gitignored. Never stage that folder.
6. **MVVM discipline.** Views are dumb. ViewModels own state & business logic.
   Services wrap Supabase.
7. **Concurrency**: all Supabase calls `async throws`, wrapped in `do/catch`
   with a user-facing error message.
8. **No Combine.**
9. **Dark mode**: use semantic colours (`Color(.secondarySystemBackground)`,
   `.primary`, etc.) only. No hex literals.

## Git commit + push rules

Arabella is the sole developer on `main` and has explicitly authorised
agents to commit + push directly to `main`. Follow these rules every
session:

### When to commit
- **After any self-contained unit of work** that leaves the repo in a
  buildable state (new screen done, bug fixed, schema migration added,
  docs refresh, etc.). Don't batch unrelated changes into one commit.
- **Always** after updating `STATUS.md` / `CHANGELOG.md` at the end of
  a task — those living docs must be kept in sync with the code on `main`.
- **Never** commit when something is half-built or the app won't compile.

### What to stage
- Stage files by name — never `git add -A` or `git add .` (risk of
  accidentally committing `.secrets/`, `.DS_Store`, IDE state files).
- Double-check `git status` before committing: if `.secrets/`,
  `supabase.env`, `xcuserdata/`, or `.DS_Store` show up, **stop** and
  fix `.gitignore` first.

### Commit message style
- Imperative mood, short subject line (<72 chars), blank line, optional
  body. Match the existing repo voice — concise, no fluff.
- Prefix with a scope tag when helpful: `feat:`, `fix:`, `docs:`,
  `chore:`, `supabase:`, `ui:`.
- Co-author trailer for Claude-authored commits:
  `Co-Authored-By: Claude <noreply@anthropic.com>`
- Use a heredoc for multi-line messages so formatting is preserved.

### When to push
- Push to `origin main` **immediately after every commit**, unless the
  commit is experimental or the user has asked you to hold.
- If no `origin` remote is configured, skip push and tell the user in
  the end-of-turn summary so they can add one.
- Never use `git push --force` on `main` — there is no need for it and
  it destroys history.

### What NOT to do
- Never amend a pushed commit. Create a new commit instead.
- Never skip hooks (`--no-verify`).
- Never commit the PRD password, Postgres URL, or anything from
  `.secrets/`.

## How to run the app

1. Open `AwareBudget.xcodeproj` in Xcode 16+.
2. Add the Supabase Swift package: *File → Add Package Dependencies →*
   `https://github.com/supabase/supabase-swift` (latest stable).
3. Open `Services/SupabaseService.swift` and:
   - Uncomment `import Supabase`
   - Uncomment the `client` property and its initialiser
   - Replace placeholder URL/key with values from Supabase dashboard
   - Replace the stub store methods with real Supabase queries
4. In Supabase, run `supabase/schema.sql` then `supabase/seed.sql`.
5. Build & run on the iPhone 15 Pro simulator (iOS 17+).

**Until the package is added, the app builds and runs against an in-memory
stub.** The stub is clearly marked in `SupabaseService.swift`.

## Current state at a glance

See `STATUS.md` for the authoritative state. High level: beta scaffolding is
in place (all screens, models, VMs, stub service). Real Supabase wiring is
pending.

## When the user asks for a new feature

1. Check if it's already in `FUTURE_PLANS.md`.
2. Check the PRD — is this in beta scope or v1.1+?
3. If beta scope: implement it, update `STATUS.md` + `CHANGELOG.md`.
4. If out of scope: add it to `FUTURE_PLANS.md` and surface the tradeoff to
   the user before writing code.
