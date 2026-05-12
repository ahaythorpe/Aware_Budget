# Build 22 — TestFlight verification checklist

> Updated: 2026-05-12
> Open in GitHub mobile or any markdown viewer to tick boxes as you test.

Build 22 is the biggest single-build batch this week. Multi-bias model end-to-end, Nudge as default avatar, future-you Home card, Insights restructure, Research tab collapsibles, false-claim fixes, doc consistency audit. Test in tab order below.

---

## 🏠 Home tab

### Greeting card
- [ ] Left avatar (where the "B" used to be) is now the **Nudge cut-out coin**. If you've uploaded a photo, the photo is still there.
- [ ] Right side of the card still has the floating Nudge coin, now bigger (~56pt) and slightly below the card edge.
- [ ] Tap the right-corner Nudge → welcome popover with greeting line.

### Future-you card (new)
- [ ] Appears **above the May calendar**.
- [ ] If you have events logged this week: shows `+$X from future you` (or `-$X` if more impulse than planned) + `N of 7 days you chose future you`.
- [ ] If you have no events this week: empty state with a Nudge cut-out + a note: *"Log a spend or two and this fills in..."*

### Microcopy regressions (carried from Build 21, re-check)
- [ ] Streak ⓘ popover: "Days in a row you checked in."
- [ ] Patterns ⓘ: "16 biases tracked from your tagged spending..."
- [ ] Finance empty: "Track income and savings. Nudge connects them to your spending."
- [ ] Privacy info: "100% voluntary. GoldMind never connects to your bank..."

---

## ➕ Log tab — single spend flow

### Bias suggestion chip after picking planned-status
- [ ] After you pick a category + amount + Planned/Surprise/Impulse, the **WHAT'S DRIVING THIS?** section shows your primary bias chip (gold pill).
- [ ] When the algorithm finds a second plausible bias from a **different** BFAS category, a smaller `+ also <Bias>` pill appears next to it.
- [ ] If only one bias applies, only the primary chip shows (no empty `+ also` pill).
- [ ] Spend saves with both tags. (You won't see the secondary surface elsewhere until Insights re-loads.)

### Specific combos to test (these are the fixed mappings)
- [ ] **Coffee + Impulse** → should be Ego Depletion OR Present Bias (NOT Status Quo Bias — that was removed). Possibly with the other as secondary.
- [ ] **Lunch + Impulse** → Ego Depletion / Social Proof / Mental Accounting (rotation cycles).
- [ ] **Subscriptions + Planned** → Status Quo Bias (still correct, this is the actual habit pattern).

---

## 📊 Insights tab

### Financial overview card (new grouping)
- [ ] Card has three labelled groups with hairline dividers between them:
  - **INCOME** — single row (Income).
  - **SPENDING** — three rows (Spent this month, Impulse spending, Planned spending).
  - **WEALTH** — Estimated savings / Savings balance / Invested (only renders if you have income or a snapshot).
- [ ] Old flat list is gone.

### Spending by Bias (new collapsibles)
- [ ] Below the financial overview, **SPENDING BY BIAS** is now a list of **BFAS categories** (Avoidance / Decision Making / Money Psychology / Time Perception / Social / Defaults & Habits).
- [ ] Each category row shows the category name, dollar total, % of monthly spend pill.
- [ ] **Tap a category row** to expand — individual biases inside (e.g. Decision Making expands to Loss Aversion, Anchoring, etc.) with each bias's emoji + dollar amount.
- [ ] Total of all category %'s **can exceed 100%** — that's intentional. A co-driven spend credits both biases.
- [ ] Categories with no spend this month are skipped (not just empty).

### Bias spending trend vs Category trend
- [ ] Already in Build 21 but re-verify visual difference: bias chart = warm gold, category chart = cool green, distinct subtitles.

### Empty state
- [ ] If you have zero events: no blank chart flash, just the Nudge cut-out empty state + "Log your first event" button.

---

## 🎓 Education tab

### Research tab (the bias lessons)
- [ ] **HOW TO COUNTERACT YOUR TOP BIASES** section is now organised by BFAS category, each one a **collapsible card** (DisclosureGroup).
- [ ] Each category row shows category name + a count badge ("3 biases", etc.).
- [ ] Tap a category to expand — individual bias cards (Ostrich Effect, Loss Aversion etc.) appear inside.
- [ ] The 16-card flat scroll is gone.

### Mind map (Education → Explore the bias map)
- [ ] Lane labels ("The Drifter", "The Reactor") are now **fully below** the filter chips — no overlap with the pinned NudgeSays card or the chip row.
- [ ] NudgeSays purpose card under BIAS MAP header is visible.
- [ ] Filter chips (All / My top 3 / Triggered / Untouched) are visible and tappable.

### Mind map — node tap sheet
- [ ] Open any node sheet. Hero row, stat chip, gold Nudge speech card, HOW TO COUNTERACT bullets, REAL EXAMPLE disclosure, RELATED PATTERNS chips — all present (carried from Build 20).

---

## 🧠 Awareness tab

### Hero NudgeSays
- [ ] Reads: *"Each pattern sharpens your BFAS profile. The framework planners use on clients."*

### Bias cards — false-claim fixes
- [ ] Open Ostrich Effect detail. Nudge copy should be: *"Just opening GoldMind beats the avoidance pattern. Most people look away. You're looking."* (No more "12 days straight" — that was fiction.)
- [ ] Open Loss Aversion. Should read: *"Losing $50 feels twice as bad as gaining $50 feels good. Same dollar amount, double the sting..."* (The old "registers like $100" framing is gone.)
- [ ] Open Sunk Cost Fallacy. Should read: *"Money already spent is gone. Spending more won't bring it back. The only question now: what's the best move from here?"*

---

## ⚙️ Settings

### Algorithm explainer (ⓘ → How Nudge decides)
- [ ] STEP BY STEP section now has **five steps** (was four).
- [ ] Step 2 says: *"Nudge suggests up to two biases for that combination. Example: Coffee + Impulse → Ego Depletion ... and Present Bias..."*
- [ ] Step 3 is the new one explaining *why* two biases (Pompian / Klontz citation).
- [ ] HOW THE SCORE MOVES rows still in plain English (no jargon): +5 / −2 / 0 / +1 / 0 to 10.
- [ ] New line under the divider: *"When a spend has two bias tags, each tag earns the +1 independently. Two real drivers means two signals."*

---

## 🔔 Cross-cutting

### Notifications (fresh install)
- [ ] No pushes fire before you grant permission.
- [ ] Tap Home "Turn on notifications" banner → grant → daily reminders schedule without relaunch.

### Onboarding + Sign In legibility
- [ ] Microcopy on the intro slides + Apple ID privacy line on Sign In are readable size (carried from Build 21).

---

## ⚠️ Known gaps in Build 22 (deliberate v1.0 carry-overs)

These are NOT bugs — they're flagged for v1.1:
- **BiasReviewView confirm flow** only reviews the primary bias. The secondary tag contributes to Insights aggregation but doesn't get a separate confirm/deny pass yet.
- **Bias trend, Category trend, Net worth, Financial trend charts** are not yet interactive in the CompoundGrowthCard sense (range chips + drag-to-zoom). Plan captured in `docs/PLAN_V1_1.md`.
- **Concept-graph layouts** in Education tab are also v1.1 (`docs/PLAN_V1_1.md` Path A recommended).

---

## Anything broken or feels off

Screenshot it. Otherwise this is Apple-submission ready (pending privacy/terms wording updates on the marketing site and the App Store Connect questionnaire).
