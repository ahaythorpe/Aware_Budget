# Build 21 — TestFlight verification checklist

> Updated: 2026-05-12
> Open in GitHub mobile or any markdown viewer to tick boxes as you go.

Build 21 bundles all Build 20 changes plus the train-ride feedback (chart palettes, plain-English algorithm sheet) and a tree cleanup. Test in order below.

---

## 🏠 Home tab

### Greeting card
- [ ] Nudge avatar in the bottom-right is a floating cut-out coin
- [ ] No gold disc behind the avatar
- [ ] Tap the coin → welcome popover with rotating Nudge greeting

### Info popovers
- [ ] Tap streak ⓘ → popover reads "Days in a row you checked in."
- [ ] Tap patterns ⓘ → popover starts with "16 biases tracked..." (no "Patterns are the" preamble)

### Notifications banner
- [ ] If notifications denied: "Turn on notifications" banner appears
- [ ] If granted: no banner

### Microcopy
- [ ] Finance card "Track income and savings. Nudge connects them to your spending." (when empty)
- [ ] Stale-snapshot reminder "N days since your last update. A refresh keeps the picture honest." (when applicable)
- [ ] Privacy info card "100% voluntary. GoldMind never connects to your bank..." (short, no "Under Australian law, that means")
- [ ] Trend-graph empty state "The trend graph needs numbers to compare..." (no "It's been...")

---

## 📊 Insights tab — empty state (no events logged)

- [ ] Empty state appears **immediately on tab open**
- [ ] **No blank charts flash before the empty state**
- [ ] "Log your first event" gold button visible
- [ ] Nudge cut-out coin + "Your insights appear after you log an event"

---

## 📊 Insights tab — with events

### This week section
- [ ] Subtitle reads "Last 7 days of events and check-ins. Resets Monday."

### Bias spending trend chart
- [ ] Title "Bias spending trend"
- [ ] **New** subtitle line "WHY you spent. Driver-tagged dollars over the last six weeks."
- [ ] Chart uses **warm gold palette** — goldBase, goldText, matteYellow, warning-orange, deep green
- [ ] Reads visibly different from the Category chart below

### Category trend chart
- [ ] Title "Category trend"
- [ ] **New** subtitle line "WHERE the money went. Top five life areas, week by week."
- [ ] Chart uses **cool green palette** — accent, deep green, primary, light green, gold
- [ ] Reads visibly different from the Bias chart above

### Other Insights cards
- [ ] Compressed Nudge cards: "Each dollar tagged with its driver. Awareness precedes change."
- [ ] First-month empty: "First month logged. Bars appear side-by-side as months stack up."

---

## 🎓 Education tab → Explore the bias map

### Canvas pinned UI
- [ ] BIAS MAP title at top-left
- [ ] **Pinned NudgeSays card** under the header with Nudge coin: "Six money personalities, sixteen biases. Tap a node to unpack one..."
- [ ] **Filter chips below the NudgeSays card**: All / My top 3 / Triggered / Untouched
- [ ] Tapping a chip dims non-matching nodes

### Canvas itself
- [ ] **No peach/pink rounded rectangles** behind the personality columns
- [ ] Lanes show: dot grid + lane header icons + node circles + connecting lines only
- [ ] YOU chip on your primary personality (The Drifter)

### Node tap — the new sheet
- [ ] Compact hero row: icon + name + key cite on one line (not stacked)
- [ ] **Stat chip**: "Seen N× in your logs" (gradient) OR "Not seen in your logs yet" (light)
- [ ] Pattern one-liner under the chip
- [ ] **Gold Nudge speech card** with the cut-out coin inside it
- [ ] **HOW TO COUNTERACT** as a check-list with bullets (not a paragraph)
- [ ] **REAL EXAMPLE** disclosure — tap chevron to expand a real-world example
- [ ] **RELATED PATTERNS** chips at the bottom — tap any to re-target the sheet to that bias without closing

---

## 🧠 Awareness tab

- [ ] Hero NudgeSays: "Each pattern sharpens your BFAS profile. The framework planners use on clients."
- [ ] After the Social category: "These 16 patterns come from BFAS. The framework planners use on clients."

---

## ⚙️ Settings

### Profile section
- [ ] Footer below the toggles is short: "Display name shows in greetings. Use the toggles to override per field."
- [ ] Per-toggle ⓘ popovers still work (Hide name, Hide email)

### Algorithm explainer (ⓘ button → How the algorithm scores you)
- [ ] **HOW THE SCORE MOVES** section: right column is plain numbers only
  - +5 for "Yes, that's me" in a check-in
  - −2 for "No, different reason" in a check-in
  - 0 for "Not sure" in a check-in
  - +1 for a logged spend tagged with this bias
  - 0 to 10 (one-off) for your sign-up BFAS answers
- [ ] **No "gold standard", "weak signal", "active denial", "one-time seed" jargon anywhere**
- [ ] 5:1 paragraph reads "Active YES outweighs passive observation 5:1. When you identify a pattern in real time..." with citations in parens at the end

---

## 🔔 Notifications (best tested on a fresh install)

- [ ] **No system permission prompt fires on first launch** (only after onboarding completes)
- [ ] **No pushes fire at all until you grant**
- [ ] Tap Home "Turn on notifications" banner → system prompt
- [ ] Grant → daily reminders now scheduled **without needing an app relaunch**
- [ ] Deny → no requests sit in the OS pending list

---

## 🎨 Onboarding + Sign In legibility

- [ ] Intro slide subtitle text is readable size (not tiny caption)
- [ ] Sign In screen "Your Apple ID stays private..." line is readable (not too faded)

---

## ⚠️ Anything broken or feels off

Screenshot it and send. If everything looks right, that's the green light to keep iterating.
