# CLAUDE.md — GoldMind Agent Rules

> Read this file first on every session.

---

## ABSOLUTE RULES — NEVER SKIP

### 1. SCREENSHOT AFTER EVERY VISUAL CHANGE
After every visual change, run the simulator, take a screenshot, and paste
it into the response. If the screenshot does not show the expected result,
the task is NOT done. Do not mark any task complete without a screenshot
proving it works.
```
xcrun simctl io booted screenshot /tmp/verify.png
```
Then Read the screenshot file to display it. No screenshot = task not complete.

### 2. NEVER SAY DONE WITHOUT PROOF
If claiming something exists run grep first.
Show the grep output.
Show the actual lines changed.

### 3. SHOW BEFORE AND AFTER
Before any edit show current code.
After edit show new code.
Then screenshot.

### 4. ONE TASK AT A TIME
Verify each task before starting next.
Never batch without verification.

### 5. BUILD AFTER EVERY FILE CHANGE
Not at the end — after each file.
If build fails stop and fix immediately.

### 6. VERIFY SUPABASE DATA WITH CURL
Never claim data exists without:
```
curl "[url]/rest/v1/[table]?limit=1" \
  -H "apikey: [key]"
```
Show the response.

---

## PROJECT CONTEXT

| Key             | Value                                                    |
|-----------------|----------------------------------------------------------|
| Path            | `/Users/bella/GoldMind/GoldMind`                  |
| Supabase URL    | `https://vdnnoezyogbgtiubamze.supabase.co`               |
| Anon key        | `sb_publishable_lwuCqoY6jpKRwQRJoqZYFQ_CiavSWwH`        |
| Nudge image     | `Assets.xcassets/nudge.imageset/nudge.png`                |
| Currency        | AUD                                                      |
| Bundle ID       | `goldmind.app`                                   |
| Stack           | Swift + SwiftUI + Supabase (supabase-swift 2.43.1)       |
| Architecture    | MVVM with `@Observable` view models, async/await          |
| Target          | iOS 17+, Xcode 26, iPhone 17 Pro simulator (iOS 26.2)   |

Xcode uses `PBXFileSystemSynchronizedRootGroup` — files auto-compile when
added to folders. **Do not manually edit `project.pbxproj`.**

---

## WHAT NOT TO DO

- Never use categories for money events — Planned/Surprise/Impulse only
- Never flat green on hero cards — always gradient
- Never purple or violet anywhere — money green + nugget gold only
- Never add text input on check-in cards — swipe YES/NO only
- Never yellow/gold squares for tone picker — white opacity buttons
- Never "great job" from Nudge — dry wit only
- Never rigid "budget vs actual" numbers — show trends only
- Never bank sync — all manual
- Never claim built without screenshot proof
- Never commit `.secrets/`, `.DS_Store`, `xcuserdata/`
- Never `git add -A` or `git add .` — stage files by name
- Never amend a pushed commit — create a new one
- Never skip hooks (`--no-verify`)
- Never `git push --force` on main

---

## GIT RULES

Arabella is sole dev on `main`. Agents commit + push directly to `main`.

- Commit after each self-contained unit of work that builds clean
- Push to `origin main` immediately after every commit
- Imperative mood, short subject (<72 chars), scope prefix (`feat:`, `fix:`, `ui:`, `docs:`, `chore:`, `supabase:`)
- Co-author: `Co-Authored-By: Claude <noreply@anthropic.com>`
- Update `STATUS.md` + `CHANGELOG.md` after every task

---

## SESSION START/END

**Start:** Read `CLAUDE.md` → `docs/HANDOFF.md` → `docs/STATUS.md`
**End:** Update `docs/STATUS.md`, `CHANGELOG.md`, `docs/HANDOFF.md` if structure changed

### How to start every session

To update files use terminal `cp` command:
```
cp ~/Downloads/[filename] "/Users/bella/GoldMind/GoldMind/GoldMind/Views/[filename]"
```
Never use Finder drag to replace Swift files.
Always use `cp` from terminal after downloading from Claude.

---

## IMPLEMENTATION GUIDE WORKFLOW

When implementing from an implementation guide (e.g. `Implementation_Guide/goldmind_implementation.md`):

```
# Start session
cd "/Users/bella/GoldMind/GoldMind"
claude

# Agent auto-reads CLAUDE.md, then you say:
"Read goldmind_implementation.md and implement File 3"

# After Xcode build passes:
"build passed"

# Agent re-reads the guide and does File 4
# Never from memory — always from the file
```

**Rules for guide-driven sessions:**
1. One file at a time only
2. Do not refactor anything not mentioned
3. Do not rename existing variables or functions
4. After each file, say only "Done ↵" and immediately continue to the next file unless user types "stop"
5. If build fails, fix only the error, nothing else
6. Always re-read the guide file for each new File N — never implement from memory

**Response protocol (guide-driven sessions only):**

After completing a file say only:
```
Done ↵
```

Immediately continue to the next file unless user types "stop". Do not wait for any input.

No other commentary. No suggestions. No explanations.

---

## DESIGN TOKENS (from DesignSystem.swift)

```
primary       = #2E7D32    accent        = #4CAF50
lightGreen    = #81C784    paleGreen     = #E8F5E9
bg            = #FAFAF8    cardBg        = white
textPrimary   = #1A2E1A    textSecondary = #6B7A6B
textTertiary  = #A0B0A0    goldBase      = #C59430
goldText      = #E8B84B    warning       = #FF7043
heroGradient  = #1B5E20 → #2E7D32 → #4CAF50 → #388E3C
Background    = #F5F7F5    Borders = rgba(76,175,80,0.15)
Section labels: 12pt 800 weight #4CAF50 uppercase tracking 1.5
```
