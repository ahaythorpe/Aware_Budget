# CHANGELOG — GoldMind

> Append-only log of every agent/Claude Code session.
> Newest entries at the top. Each entry: date, agent, summary, links.

---

## 2026-05-13 — Build 26 — final-pass polish: rename + Research card borders (Claude Code, Opus 4.7 1M)

Final polish build ahead of App Store submission. Two visible UI changes plus a dev-handover doc.

- **"THE FOUR PAPERS" → "THE MAIN PAPERS"** on the Research tab. The four shown are foundational but the bias cards cite other authors across the app (Klontz, Cialdini, Samuelson & Zeckhauser, Baumeister) — "four" overclaimed the exhaustiveness. `f62b4b7`.
- **Research paper / framework / ranking cards** dropped `.shimmeringGoldBorder` (thick animated gold outline that read as visually heavier than every other card in the app). Same hairline 0.5pt @ 0.18 opacity stroke + `.premiumCardShadow()` as the rest of the Research surface. Three cards now consistent with the rest of the app. `618a45c`.
- **`docs/DEV_HANDOVER.md`** — paste-ready handover for the developer doing RevenueCat dashboard verification + Supabase backend audit + App Store Connect submission. Splits responsibilities so Bella focuses on TestFlight polish + marketing site updates. `f52676b`.

Deferred to v1.1 (per `docs/PLAN_V1_1.md`): #30 concept-graph mind map layouts, #34 papers↔biases concept graph on Research, #33 deeper Research interactivity (mini-quiz, filter bar, mark-as-understood), #32 interactive trend charts.

---

## 2026-05-13 — Build 25 — notification routing fix lands; bias → personality attribution; richer chart explainer (Claude Code, Opus 4.7 1M)

- **Notifications:** weekly review + monthly checkpoint pushes now route to Log tab (morning slot) per Bella's "all notifications land on Quick Log or log-numbers" principle. Removed the dead `openInsights` route case; RootTabView + HomeView consumePendingRoute simplified back to single-branch. Bias-hit push still routes to Log. `481436b`.
- **Home chart explainer:** Nudge note above the compound-growth chart rewritten in plain English explaining the method ("Nudge takes your last 30 days of logged spending and projects what it compounds to at 8% annual return..."). Added a citation line on the 8% assumption (long-run market average). `481436b`.
- **Research inner card polish:** the inner "overcome" cards inside each category dropdown still had the old heavy gold stroke. Brought into line with the outer card aesthetic — stroke 0.4 → 0.18 + hairline 0.5pt + `.premiumCardShadow()`. Inner + outer now read as one consistent card family. `481436b`.
- **Bias → personality attribution:** Research tab DisclosureGroup labels and Awareness tab category headers now show "The {Archetype}" as the primary heading with the BFAS category name underneath as a subtle attribution. Users see at a glance which spending personality owns which biases. YOU pill on the user's own archetype in Research.

---

## 2026-05-12 — Build 24 — Research interactivity, gold palette, notification routing fix (Claude Code, Opus 4.7 1M)

- **Category-trend chart palette** swapped from cool greens to a gold-family palette (goldBase, goldText, matteYellow, warning, goldForeground) so it sits naturally in the rest of the gold-themed Insights. Subtitle still differentiates WHY (bias trend) vs WHERE (category trend). `13eed6d`.
- **Notification routing fix:** bias-hit pushes had no slot/route — now route to Log tab (morning slot). Weekly + monthly review pushes had no destination — new `NotificationRoute.openInsights` case wired so they land on Insights, where the data lives. RootTabView pendingRoute handler switched from "always Home" to a switch over the route enum. `86a79d7`.
- **Research dropdown polish:** category card stroke 0.4→0.18 (hairline), label .headline→.subheadline matching Insights, count chip restyled with rounded-heavy font + 0.08 bg + 0.25 stroke, added `.premiumCardShadow()` so cards sit consistently with the rest of the app. `86a79d7`.
- **Research card interactivity:** per the v1.1 plan #33, surfaced two `BiasLesson` fields that had been sitting unused: `fullExplanation` (new "THE FULL PICTURE" disclosure) and `realWorldExample` (new "REAL EXAMPLE" disclosure, previously only on mind-map node sheet). Both collapsed by default so cards stay scannable. Added a personal "Seen N×" trigger chip in each card header (sourced from bias_progress + this-month eventTagCounts — matches mind-map node-sheet pattern). `c62a6bf`.

---

## 2026-05-12 — Build 23 — compound-growth chart on Home + Research text consistency (Claude Code, Opus 4.7 1M)

- **Home future-you replaced** with the actual CompoundGrowthCard (same interactive component used at the bottom of Insights — range chips 5/10/20/30yr, drag-to-zoom slider, bottom stat row). Build 22 shipped a text summary by mistake; this is what Bella originally asked for. `6592672`.
- **Future-you empty state:** Nudge cut-out card explaining the chart fills in once events log. `6592672`.
- **Future-you auto-populate note:** short Nudge card above the chart when populated, clarifying the projection is built from actual logged spending. `6592672`.
- **Research tab text consistency:** bias-card body text switched from fixed sizes (19 / 17) to semantic `.headline` / `.subheadline` matching Insights + AlgorithmExplainerSheet. Section labels brought into the size 11 / weight .heavy / tracking 1.2 convention. Added lineSpacing for multi-line breathing. `6592672`.
- **Bias nudgeSays accuracy sweep:** Mental Accounting (drop promotional line) · Planning Fallacy (Oxford comma) · Status Quo (soften "all chosen" claim) · Moral Licensing (research-accurate "another" instead of "several"). `c085330`.

---

## 2026-05-12 — Build 22 — Nudge avatar, multi-bias model, Home future-you (Claude Code, Opus 4.7 1M)

Biggest single-build batch this week. Lands the multi-bias model end-to-end, three new Home/Insights/Research UI restructures, copy fixes that close out false-claim risks for Apple review, and a docs audit alignment.

### Multi-bias model (max 2 biases per spend)
- **Data:** `MoneyEvent.secondaryBehaviourTag: String?` + migration `20260512200000_add_secondary_behaviour_tag.sql` (applied). `f13c2c0`.
- **Algorithm:** `BiasRotation.nextBiasPair(category:status:)` returns primary + optional secondary from a *different* BFAS category. Same-category secondaries filtered out as redundant. `f13c2c0`.
- **Save path:** MoneyEventViewModel now sets both tags optimistically and preserves the different-category invariant through the boost-rerank. `f13c2c0`.
- **Logging UI:** MoneyEventView now shows the primary bias chip plus a subtler "+ also <Secondary>" pill when two drivers apply. Framed in real-planner voice (Pompian 2012, Klontz 2011). `efb1fa2`.
- **Insights aggregation:** biasSpendingBreakdown counts both tags; each bias gets full credit for a co-driven spend. Total % can exceed 100 — accurate to the model. `efb1fa2`.
- **AlgorithmExplainerSheet:** rewritten step-by-step section explaining the two-bias model + new "each tag earns the +1 independently" note. Old Status Quo example replaced with the actual current Coffee+Impulse mapping. `d555cac`.
- **Consistency audit:** ALGORITHM.md step 1 + PRD.md scoring block updated to match shipped code. Deleted dead `suggestedBiasTag()` lookup table in MoneyEventViewModel (60 lines of stale Coffee+impulse → Status Quo Bias). `e13b84f`.

### Profile avatar + Home greeting
- **Default avatar:** Nudge cut-out replaces the gold initial-letter disc as the default profile picture. Uploaded photo still takes precedence. `3cad06f`.
- **Right-corner Nudge:** bumped 40 → 56pt (peer-sized to the left avatar). Offset moved to float past the bottom-right of the greeting card. `3cad06f`.
- **Future-you card:** new on Home, pinned above the calendar. Shows weekly planned-minus-impulse net + "N of 7 days you chose future you" pill. Empty state surfaces a Nudge note explaining the card fills in once spends log. `9eabc71`.

### Insights restructure
- **Financial overview** grouped INCOME / SPENDING / WEALTH with uppercase labels + hairline dividers between groups. WEALTH only renders when there's data to show. `945fe0f`.
- **Spending by Bias** rebuilt as DisclosureGroup-per-BFAS-category. The flat top-5 list is now collapsible rows showing category total + % of monthly spend; tap to expand to the biases inside. `945fe0f`.

### Research tab
- **Bias lessons grouped by BFAS category** with DisclosureGroups (the chunky flat 16-card scroll is now collapsible). Categories with no lessons skipped. `e74859d`.

### Mind map
- **Canvas clears the pinned UI** — bumped `canvasTopPadding` 180 → 240 so personality lane labels never sit under the filter chips. `dd0c8ce`.

### Copy / false-claim fixes (Apple review hygiene)
- BiasData Ostrich Effect: drop hardcoded "12 days straight" claim — user has 2 days of activity. `9eabc71`.
- BiasLessonsMock Denomination Effect: drop hardcoded "12 times this week / $87" personalised numbers. Reframed as illustrative. `9eabc71`.
- BiasData Loss Aversion: rewrote to make the loss-vs-gain asymmetry explicit ("Losing $50 feels twice as bad as gaining $50 feels good") rather than confusing arithmetic. `9eabc71`.
- BiasData Sunk Cost Fallacy: tighten run-on in the nudgeSays line. `dd0c8ce`.
- Six BiasLessonsMock howToCounter strings: punctuation + run-on sweep (Ostrich, Loss Aversion, Anchoring, Sunk Cost, Present Bias, Status Quo, Mental Accounting). `ef243b2`.
- ArchetypeRevealView: stop force-lowercasing archetype names + oneLiners in the why-explanation text (read like typos). `09caf61`.

### Plan docs (v1.1 captured, not built)
- `docs/PLAN_V1_1.md` covers #32 interactive charts (port CompoundGrowthCard pattern to bias / category / net-worth / financial trends) and #30 concept-graph layouts in Education tab. Both deferred to v1.1. `adc728c`.

### Known gap (v1.0 carry-over)
- `BiasReviewView` confirm flow still reviews the primary bias only. Secondary tag contributes to Insights aggregation but isn't presented for separate confirm/deny yet. Score updates via primary only. Recoverable post-launch without a migration.

---

## 2026-05-12 — Build 21 — chart differentiation + plain-English explainer + tree hygiene (Claude Code, Opus 4.7 1M)

---

## 2026-05-12 — Build 21 — chart differentiation + plain-English explainer + tree hygiene (Claude Code, Opus 4.7 1M)

Follow-up to Build 20 picking up the train-ride feedback (jargon on the algorithm sheet, the two graphs looking the same).

- **AlgorithmExplainerSheet:** score-delta rows now in plain English. Right column shows just the number (+5, −2, 0, +1, 0–10) and the left column names the actual user action ("'Yes, that's me' in a check-in", "A logged spend tagged with this bias", "Your sign-up BFAS answers"). No more "gold standard" / "weak signal" / "active denial" / "one-time seed". `72566a6`.
- **Insights charts:** bias-trend and category-trend were rendering with the same gold→yellow→green palette. Differentiated — bias = warm gold (goldBase, goldText, matteYellow, warning, deepGreen), category = cool green (accent, deepGreen, primary, lightGreen, goldBase). Each gained a subtitle line: bias = "WHY you spent...", category = "WHERE the money went...". `60aeb92`.
- **Mind map:** filter chips (All / My top 3 / Triggered / Untouched) were defined but never inserted into the canvas; wired back in below the purpose card. `62825ed`.
- **Editorial passes:** verbose blurbs compressed across AwarenessView, HomeView, BiasReviewView, SettingsView, PatternsDetailView, CredibilitySheet, AlgorithmExplainerSheet. Same meaning, fewer words. `782d87d`, `e0789d0`, `90a727e`, `81fb852`, `5759fb3`.
- **Onboarding + SignIn legibility:** caption-sized microcopy bumped to footnote/medium weight, SignIn privacy line opacity 70→80%. `c1cb3db`.
- **Tree hygiene:** AppConfig.swift, GoldMind.storekit, 7 supabase migrations (Apple-compliance batch from 2026-05-09) now in version control. `.agents/.claude/.kiro/` added to .gitignore. Working tree fully clean. `121beec`, `96a9105`, `edaece2`.

---

## 2026-05-12 — Build 20 — UX cleanup + notification gate (Claude Code, Opus 4.7 1M)

Nine commits sweeping the rough edges Bella surfaced during Build 18 TestFlight testing.

- **Home greeting:** Nudge avatar is now a cut-out coin (no gold disc behind it), matching popovers and bias cards. `e07effb`.
- **Insights empty state:** dropped the `!isLoading` clause from `hasNoData` so blank charts no longer flash before the "Log your first event" CTA. `fe59eb2`.
- **Mind map canvas:** removed the tinted personality-lane rectangles; grouping is now conveyed by node placement + lane header chip only. `c5eb1d7`.
- **Mind map node sheet:** full redesign — compact hero row, "Seen N× in your logs" stat chip, gold Nudge speech card, HOW TO COUNTERACT as a check-list bulleted from sentence splits, REAL EXAMPLE disclosure surfacing the previously-unused `BiasLesson.realWorldExample`, RELATED PATTERNS chips driven by `BiasRelationships` (tap re-targets the sheet to that bias). `ec90d5f`.
- **Mind map canvas:** pinned NudgeSays purpose card under the BIAS MAP header explaining what the map is. `3d6afa6`.
- **Notifications:** `requestPermission()` now returns Bool; all scheduling call sites (GoldMindApp launch, HomeView banner, CheckInViewModel) gate on the grant. New `scheduleAll()` / `cancelAll()` helpers. Banner tap now schedules immediately so reminders work without a relaunch. Closes the "ghost notification" App Store risk where pending requests would auto-fire if the user later flipped permission via Settings. `4f9a88e`.
- **Insights editorial pass:** 11 verbose Nudge cards / info popovers / empty states compressed. Same meaning, fewer words. `0aef7d1`.
- **Docs:** audited #27 (already done before Build 11 — `biasCategories` grouping was shipped). Added #29 monthly checkpoint screen + #30 concept-graph mind map to live follow-ups. `18f078d`, `6b9a3fb`.



### Build 11 — Bias Mind Map v1
- New `Views/MindMapView.swift` — full-screen visual canvas inside Education tab. Six horizontal lanes (Drifter / Reactor / Bookkeeper / Now / Bandwagon / Autopilot), each containing the personality's biases as 44pt SF Symbol discs.
- Curved bezier edges (via `Canvas`) connect biases listed in `BiasRelationships`.
- Tap a node → bottom-sheet detail with PATTERN + NUDGE SAYS + HOW TO COUNTERACT (latter from `BiasLessonsMock`).
- Subtle dot grid background. Launched from a prominent "Explore the bias map" card on Education.

### Build 12 — Polish batch
- **Nudge welcome popover** on Home greeting (38pt avatar between greeting text + gear, time-of-day + streak-aware hello).
- **Top Biases ⓘ rewired** — opens AlgorithmExplainerSheet instead of full Backed-by-Research.
- **CredibilitySheet trimmed** to 4 sections (hero + 96% fact + GoldMind-vs-Traditional table + CTA). Medium-detent default.
- **Education "How to spot & overcome" → "How to counteract your biases"** rename.
- **InfoPopovers** (Pattern B) extended to Settings → Hide name + Hide email toggles, plus Insights → THIS WEEK + SPENDING BY BIAS section titles.
- **Industry top-5 biases card** restored to Education's Your Progress section.
- **Pattern C copy tightened** — 7 of 13 "Why this fits" explanations rewritten to drop preachy lines.
- **BiasData em-dash sweep** — 13 strings cleaned.

### Build 13 — Photo upload
- Migration `20260511180000_add_avatar_url_to_profiles.sql` adds `profiles.avatar_url` + creates public `avatars` Storage bucket with RLS (public read, own-folder write).
- `Views/PhotoPicker.swift` — PHPickerViewController wrapper that downsizes to 512px JPEG @ 0.8 quality.
- `SupabaseService.uploadAvatar(jpegData:)` + `removeAvatar()`.
- AvatarDisc renders the uploaded photo via AsyncImage; falls back to initial-letter disc. Settings profile card gains a camera badge; tap to open picker.
- Home greeting picks up the same `avatar_url` so the photo appears in both spots.

### Build 14 — Notification fix + mind map iterations + Nudge corner
- **Notification deep-link fix:** RootTabView now switches to Home tab on `pendingRoute`, plus initial `.task` check covers the cold-launch case. HomeView's `consumePendingRoute` runs on both `.onChange` and `.task` so taps reliably open the finance editor sheet.
- **Mind map v2:** bias names always visible under each node. Wider lanes (184pt), tighter nodes (38pt), more spacing (92pt) for labels to fit. Edges dimmed (0.15 opacity / 1.0 lineWidth).
- **Mind map v3:** three Obsidian/Strava/Notion-inspired patterns — tap-to-highlight neighbours (dims non-related to 0.25, brightens connected edges), filter chips (All / My top 3 / Triggered / Untouched), lane heat tint based on user trigger count.
- **Mind map v3.1:** lane headers in their own 112pt band with thin gold divider, breathing room before first node, richer tap feedback (spring + accent border + 1.12× scale + green shadow).
- **Nudge moved to bottom-right** of the greeting card (overlay alignment .bottomTrailing, 36pt).
- **Em-dash sweep round 4:** NudgeEngine (5 strings), NudgeCardView preview, CheckIn "Most people abandon..." font bumped to .subheadline.

### Build 15 — Notification permission UX
- `NotificationService.requestPermission()` now gates on `.notDetermined` to avoid silent no-ops.
- New `authorizationStatus()` + `openSystemSettings()` helpers.
- **HomeView gets a "Turn on notifications" banner** when status is denied or not-determined. Tap → either requests permission (first time) or deep-links to iOS Settings (when previously denied). Banner clears once granted. Important for App Store review — denied state now has graceful recovery.

### Build 16 — Mind map cleanup + gold-coin Nudge
- **Mind map quieter:** primary cluster border subtler gold (0.55 opacity) instead of loud accent green. Heat tint capped at 0.08 opacity. Pulsing animation removed.
- **Nudge bottom-right is now a gold coin** — metallic `DS.nuggetGold` disc behind the Nudge face, gold-base hairline ring, bronze drop shadow. No more white background.

### Build 17 — Em-dash sweep round 5
- 9 user-facing em-dashes cleaned across BFASQuestion, AppConfig, BiasMappings, QuestionPool (×4), NotificationService, HomeView. Agent-driven exhaustive audit.

### Build 18 — Muted / sophisticated colour theme
- Single-file token swap in `DesignSystem.swift`. Easy to revert.
- Green palette: primary `2E7D32→295E2C`, accent `4CAF50→3F7A47`, lightGreen `81C784→6FA877`, paleGreen `E8F5E9→E4EFE5`.
- Gold palette: goldBase `C59430→A87E2A` (champagne brass), goldText `E8B84B→D4A745`.
- Net effect: shifts the app from "fresh & energetic" toward "considered & adult" — closer to Calm / Day One / Things 3 territory.

### Files added across this batch
- `Views/MindMapView.swift`
- `Views/PhotoPicker.swift`
- `Models/BiasRelationships.swift` (used by mind map edges + Education chip "RELATED")
- `Models/ArchetypeBiasExplanation.swift` (Pattern C content)
- `supabase/migrations/20260511180000_add_avatar_url_to_profiles.sql`

### Outstanding
- **#40** Start check-in disappearing bug — code investigation found no gating; needs fresh screenshot.
- **#26** Paywall discount badge — parked (RevenueCat dashboard work; Bella deferred).
- **Educational graph v2** — iterate after Bella tests Build 16's quieter version.
- **Photo upload edge cases** — initial ships; HEIC handling, deletion UI could come later.

---

## 2026-05-11 — Builds 8, 9, 10 + fold-up patterns (Claude Code, Opus 4.7 1M)

### Build 8 (uploaded 2026-05-11)
- **NamePromptSheet** (`Views/NamePromptSheet.swift`) — auto-prompts for display name on first Home load when `profile.display_name` is empty and `hasPromptedForName` AppStorage flag is false. Save → patches profile; Skip → flag set.
- **Notification deep-link unification** (#39):
  - `NotificationRoute` enum + `NotificationRouter.pendingRoute` channel (additive to slot-based routing).
  - `NotificationService.scheduleAddNumbersReminder()` — fires 48h after first launch with `userInfo["route"] = "finance_editor"`.
  - `cancelAddNumbersReminder()` auto-called when finance numbers are saved.
- **Em-dash sweep round 2** — Insights, Awareness, AlgorithmExplainerSheet, ResearchView papers/ranking. ~20 more user-facing em-dashes removed.

### Build 9 (uploaded 2026-05-11)
- **Audit-driven legibility pass** across 6 files. Bumped `.caption` / `.caption2` / `.footnote` on user-facing copy to `.subheadline` / `.body` / 14pt minimums. Worst offenders: MoneyEventView (8 hits), InsightFeedView (6), HomeView (4), CredibilitySheet (4), AwarenessView (2), AlgorithmExplainerSheet (1).
- **Education biasMiniRow redesign** (Bella's main complaint): name 16pt, body 14pt with extra lineSpacing, citation de-emphasized to 11pt semibold gold-opacity, row padding 10→12, VStack spacing 4→6. Hierarchy fixed.
- **Tab restructure (5 tabs preserved):**
  - `RootTab.awareness` removed as top-level. `.education` repurposed as Learn slot (position 3). `.research` is Reference slot (position 4).
  - `ResearchView` extended with `Mode` enum (`.learn` / `.reference`). Body conditionally renders sections; navigation title swaps.
  - **Education tab** = hero + quiz CTA + 6 spending personalities (with tap-to-flip bias chips) + **Your Progress section** (patterns-identified ring + top 5 triggered biases, folded in from old AwarenessView).
  - **Research tab** = 4 papers + BFAS framework + ranking explainer + all 16 biases + counteract guide.
  - SF Symbols: Education = `graduationcap.fill`; Research = `book.closed.fill`.
- **Profile surfaces (`Views/AvatarDisc.swift`):**
  - Reusable gold-gradient initial-letter disc.
  - Home greeting: avatar on left (tap → Settings); personality chip + day shows under name if archetype set.
  - Settings: full profile card at top with 76pt avatar + serif name + personality chip + streak/biases-seen stat card.
- **Consolidation pass** — "spending personality" everywhere in user copy. "Archetype" retained in code/enum/citations only. BFAS auto-prompt removed from launch gate; Money Mind Quiz is now primary entry-level assessment.
- **Quiz + reveal redesign:**
  - `MoneyMindQuizView` — soft hero halo, per-question Nudge framer card, single gold-bordered question card with paleGreen-on-accent radio rows, full-width gold `Next` with chevron + sparkles icon, BFAS citation pill footer.
  - `ArchetypeRevealView` — numbered top 3 biases (gold #1 medallion, gold-outline #2/#3), full comparison table of all 6 archetype scores with mini bars + "YOU" chip on primary, plain-English "Why X and not Y" explainer.
- **Education tab — spending personalities + interactive bias chips:**
  - "The 6 families" → "The 6 spending personalities".
  - NudgeSaysCard explainer above the list.
  - Personality cards use gold-circled SF Symbols (eye-slash for Drifter, bolt for Reactor, tray for Bookkeeper, hourglass for Now, person-wave for Bandwagon, repeat for Autopilot) tinted with category accent.
  - Bias chips tap-to-flip between one-liner and Nudge's contextual note with chevron + paleGreen highlight.
- **Home counteract-your-top-biases card** — collapsible card pairing the user's top 3 ranked biases with the matching `BiasLessonsMock.seed` `howToCounter` strategy. Each row tap-to-expand with chevron + paleGreen highlight. Hides when no signal yet.
- **Gear icon fix** — Home gear was wired to Dev menu, blocking access to Settings (Profile, Delete account, etc.). Re-wired: tap → Settings in all builds; DEBUG-only long-press still exposes Dev menu.
- **Empty-state CTA clarity** — "Add your numbers" → "Add income, savings & investments" + "Takes 30 seconds · manual entry only" subtitle.
- **Gold button polish:**
  - `nuggetGold` specular peak `#FFFDF0 → #EFD080` (warm champagne, no near-white).
  - GoldButtonStyle adds subtle dark text shadow (#3A2400 @ 0.55).
  - Slow 4.5s shimmer band capped at `#F5DC9C` opacity 0.28 with `.plusLighter` blend; respects Reduce Motion.
- **'How to Spot & Overcome' → 'How to counteract your biases'** rename.
- **BiasData em-dash cleanup** (oneLiners + 5 nudgeSays strings).
- **DEBUG trigger** — Dev menu → Notifications section → "Fire 'Add numbers' in 10s" button. Lets us verify the deep-link route without waiting 48h.

### Build 10 (uploaded 2026-05-11) — Fold-up patterns
- **Pattern A: "See related" chips** — `Models/BiasRelationships.swift` defines research-grounded co-occurrence pairs (16 entries). When a bias is expanded inside a personality card, a horizontally-scrolling row of 1-3 sibling biases appears with chevrons. Tapping a chip adds that bias to `revealedBiases` so it expands inline below the current row. Builds the mental web in place.
- **Pattern B: InfoPopover** (`Views/InfoPopover.swift`) — reusable gold "?" disc that opens a popover with title + short explanation. Wired onto Home's `Patterns identified` and `Day streak` labels. Closes the "what does this mean?" gap without sending users away.
- **Pattern C: "Why this fits [archetype]"** — `Models/ArchetypeBiasExplanation.swift` holds 13 unique rationales keyed by archetype × bias. When a bias chip is expanded inside its parent personality card, the rationale appears under the Nudge note in a paleGreen panel with accent border.

### Supabase / backend
- **No DB changes in this batch.** All work is client-side; reads from existing `profiles.archetype`, `bias_progress`, `money_events`, `money_mind_quiz_responses` tables. RLS policies untouched.

### Files added
- `Models/BiasRelationships.swift`
- `Models/ArchetypeBiasExplanation.swift`
- `Views/AvatarDisc.swift`
- `Views/InfoPopover.swift`
- `Views/NamePromptSheet.swift`

### Memory updates
- `feedback_em_dash_overuse.md` — em-dashes as AI-tell noise; grep before shipping copy.
- `feedback_gold_button_legibility.md` — saturated gold pills too heavy.
- `project_goldmind_archetypes.md` — 6-archetype canonical framework.
- `project_goldmind.md` updated — no App Store / RevenueCat changes until Bella explicitly says.

### Outstanding
- **#40** Start check-in disappearing — code investigation found no gating logic; needs fresh screenshot for repro.
- **#26** Paywall discount badge — parked (RevenueCat dashboard work; Bella deferred).
- **Mind map** — designed, deferred to dedicated session.
- **Photo upload on avatar** — initial-letter ships first; PHPickerViewController + `profiles.avatar_url` column later.

---

## 2026-05-11 — Build 7 + post-7 polish (Claude Code, Opus 4.7 1M)

**Shipped in Build 7** (uploaded 2026-05-11, state VALID, Internal Test group):

- **Money Mind Quiz (Build 7 hero feature):**
  - New Supabase table `money_mind_quiz_responses` + `profiles.archetype` and `profiles.top_biases` columns (migration `20260511120000_add_money_mind_quiz.sql`).
  - `Models/Archetype.swift` defines 6 archetypes (Drifter / Reactor / Bookkeeper / Now / Bandwagon / Autopilot) mapped 1:1 to BiasCategory + scoring logic with stable tie-break.
  - `Views/MoneyMindQuizView.swift` — 6 multi-choice questions with progress bar, weighted per option, ~2 min.
  - `Views/ArchetypeRevealView.swift` — animated reveal with top biases from the matching category + BFAS citation footer.
  - Home tile + Education tab CTA, hidden once an archetype is saved.
  - "← You" tag + accent border on the user's matching category card in Education.
- **Gear icon now opens Settings** (was Dev menu). Dev menu surfaced via DEBUG-only long-press.
- **Gold buttons muted:** nuggetGold specular peak `#FFFDF0 → #EFD080`, inner highlight 0.25→0.18, ring colour shifted to goldBase. Applied to all 11 `goldButtonStyle()` call sites.
- **Empty-state labels** clearer: "Add your numbers" → "Add income, savings & investments" + "Takes 30 seconds · manual entry only" subtitle.
- **Em-dash sweep (round 1):** 10 files. MoneyEventView Planned/Surprise/Impulse status detail, DecisionHelperSheet buttons, CredibilitySheet, SettingsView, SignInView, OnboardingView, BiasReviewView (16 bias hints + related-bias prompt), ResearchView, HomeView, NudgeVoice.

**Done post-Build-7 (next build):**

- **NamePromptSheet** (`Views/NamePromptSheet.swift`) — prompts for display name on first Home load if profiles.display_name is empty and `hasPromptedForName` is false. Save → patches profile; Skip → flag set so we don't ask again.
- **Notification deep-link unification (#39):**
  - New `NotificationRoute` enum + `NotificationRouter.pendingRoute` channel (additive, slot-based routing unchanged).
  - `NotificationService.scheduleAddNumbersReminder()` — fires 48h after app launch, deep-links to the Home finance editor.
  - `cancelAddNumbersReminder()` auto-called when the user actually saves finance numbers.
- **Em-dash sweep (round 2):** Insights, Awareness, AlgorithmExplainerSheet, ResearchView papers/ranking. ~20 more user-facing em-dashes removed.

**Memory updates:**
- `feedback_em_dash_overuse.md` — Bella reads em-dashes as AI-tell noise. Grep ` — ` before shipping user copy.
- `feedback_gold_button_legibility.md` — Saturated gold pills too heavy. Mute saturation, audit all `goldButtonStyle()` callers.
- `project_goldmind_archetypes.md` — Canonical 6-archetype framework (Klontz × Pompian × BFAS).
- `project_goldmind.md` — Reaffirmed: no App Store / RevenueCat changes until Bella explicitly says.

**Outstanding:**
- #40 — "Start check-in disappears after adding numbers" — code investigation found no gating logic; need a fresh screenshot to repro.
- #26 — Paywall discount badge (parked: RevenueCat dashboard work).
- #28 — Editorial pass on dense screens (partial; em-dash sweep covered most popups).

---

## 2026-05-11 — Build 6 Education tab restructure (Claude Code, Opus 4.7 1M)

Additive only — existing screens untouched. New entry point for the bias
catalog using the 6-archetype framework approved earlier today.

**Tab rename:**
- `RootTabView.swift` — "Research" → "Education" (label only; struct stays
  `ResearchView` per micro-fix policy to avoid rename churn across imports
  and previews).

**Hero copy:**
- `ResearchView.swift` — title "The science behind it" → "Your money mind";
  tagline replaced to lead with the 6-families framing.
- `navigationTitle("Research")` → `navigationTitle("Education")`.

**New section — categoriesSection (clickable bias families):**
- Added between hero and papersSection. Renders the 6 BiasCategory rows
  (already defined in `BiasData.swift`) as expandable cards.
- Each card header: category emoji + archetype name (Drifter/Reactor/
  Bookkeeper/Now/Bandwagon/Autopilot) + category subtitle + tagline +
  pattern count + chevron.
- Tap toggles inline expansion via `expandedCategories: Set<String>`.
  Multiple cards can be open simultaneously for comparison.
- Expanded body lists each `BiasPattern` in the family with SF Symbol +
  `displayName` + `oneLiner` + `keyRef` citation. No navigation away —
  self-contained map.
- New private `archetype(for:)` helper maps category name → (archetype,
  tagline). Source of truth: `project_goldmind_archetypes.md` in memory.

**Preserved:**
- All 5 existing sections (papersSection, frameworkSection, howRankingWorks,
  allBiasesSection, spotAndOvercomeSection) untouched. The new categories
  section is purely additive at the top.

Reversible: delete the `categoriesSection` var + helpers + the call site
in body VStack; revert tab label string in RootTabView.

---

## 2026-05-11 — Build 5 micro-edits (Claude Code, Opus 4.7 1M)

Scope intentionally tight per Bella's "micro fixes, no rewrites" rule.

**Notification cold-launch safety:**
- `GoldMindApp.swift` — moved `NotificationRouter.install()` from the
  WindowGroup `.task` block to `init()` so the delegate is set
  synchronously at launch, before any async work. Prevents a DEBUG-only
  race where the OS could deliver `didReceive(:)` before the delegate
  was installed (after `ensureDebugSession()`). Reversible: move the
  call back into `.task`.

**Type scale (extends 2026-05-10 #22):**
- `InsightFeedView.swift:313` — "SPENDING BY BIAS" header bumped from
  10pt to 12pt; tracking 1.5 → 1.6.
- `InsightFeedView.swift:1299` — inline "NUDGE" label bumped from 10pt
  to 12pt; tracking 1.4 → 1.6.

**Verified (no code change needed):**
- Notification deep-link to Log tab: full wiring trace confirmed correct.
- InsightFeedView empty state already complete (Nudge image + card +
  tagline + Log CTA at line 87-onwards).
- AwarenessView shows all 16 patterns always (greyed when not
  triggered) — design intent; no empty-state Nudge needed.
- ResearchView has no sub-11pt labels — nothing to bump.

Build 5 = build 4 contents + above. No DB changes this session.

---

## 2026-05-09 — TestFlight bug audit (Claude Code, Opus 4.7 1M)

**Context:** Bella vs friend's TestFlight builds showed two visible bugs
(ghost "18% patterns identified" with 0 events; friend's name greeting
showing "Xfbsmt9rs4" — raw email local-part). Plus 1 CRITICAL + 11 WARN
flagged by Supabase Advisor. Fix queue tracked in TaskList #1–12.

**Step 1 — Kill demo seed in production builds:**
- `HomeViewModel.swift:294` — wrapped `DemoDataService.seed()` block in
  `#if DEBUG`. Production builds (TestFlight + App Store) now show a
  truly empty state for new users.
- Root cause of "ghost 18%": `DemoDataService` writes `user_bias_progress`
  rows that survive forever; events age out of "this month" but the
  bias_progress rows still inflate `biasesSeenCount`.
- Reversible: remove the `#if DEBUG` / `#endif` lines to restore.

**Steps 3-5 + advisor cleanup — Database migrations:**
- `20260509120000_add_profiles_table.sql` — new `public.profiles` table
  with `id` PK referencing `auth.users` ON DELETE CASCADE. Auto-create
  trigger on auth.users INSERT. Backfilled 13 existing users.
- `20260509121000_add_cascade_to_user_fks.sql` — added ON DELETE CASCADE
  to budget_months, daily_checkins, money_events, monthly_decisions,
  user_bias_progress (Apple 5.1.1(v) prerequisite).
- `20260509122000_replace_delete_account_rpc.sql` — fixed bogus
  `DELETE FROM public.question_pool` (no user_id column) and tracked
  the function as a proper migration (was dashboard-drift before).
- `20260509123000_rls_perf_select_auth_uid.sql` — converted 15 RLS
  policies across 9 tables to `(select auth.uid())` form.
- `20260509124000_fix_security_definer_view.sql` — set
  `bias_mapping_aggregate` view to `security_invoker = true`. Closes
  CRITICAL Supabase Advisor warning.
- `20260509125000_advisor_followup_cleanup.sql` — fixed 4 INSERT
  policies that were missed (use `with_check`, not `qual`) and the
  search_path on `set_profiles_updated_at`. Revoked anon EXECUTE on
  `handle_new_user`.

**Steps 6-8 — Name capture + Profile editor:**
- `Models/Profile.swift` — new `Profile` and `ProfileUpdate` types
  matching the new public.profiles schema.
- `Services/SupabaseService.swift` — added `fetchProfile()`,
  `updateProfile()`, `captureAppleDisplayName()`. Rewrote
  `fetchFirstName()` to read `profiles.display_name` first, drop the
  email-prefix fallback that printed "Xfbsmt9rs4" for Apple Hide-My-
  Email users. Returns "there" if `hide_name = true` or no name set.
- `Views/SignInView.swift` — captures `credential.fullName` from Apple
  on first sign-in (only available once) and immediately persists to
  profiles.display_name.
- `Views/SettingsView.swift` — new Profile section with display name
  TextField + "Hide my name" + "Hide my email" toggles + Save button.
  Email row now respects `hideEmail` for masked display.

Builds clean (verified `xcodebuild ... build` after each Swift change).

**Step 11 — Test data wipe (Bella + 12 other testers):**
- Bulk transactional wipe of all user-scoped tables for all 13 users.
- Cleared `raw_user_meta_data.full_name` from auth.users so cached names
  don't leak through `fetchFirstName()` fallback chain.
- Re-inserted empty profile rows for every auth user (1:1 with auth.users).
- All 13 testers now in identical fully-fresh state. The single
  `budget_months` row remaining is Bella's auto-created on app reload
  (expected — `fetchOrCreateBudgetMonth(now)` runs on home load).

**Step 12 — Final advisor cleanup migration:**
- `20260509130000_db_cleanup_indexes_and_legacy_funcs.sql`
- Set search_path on legacy `bias_mapping_stats_touch_updated()`.
- Revoked anon + authenticated EXECUTE on `rls_auto_enable()`.
- Added 4 missing FK indexes (budget_months.user_id,
  daily_checkins.question_id, money_events.user_id,
  monthly_decisions.user_id).

**Final advisor state (was 1 CRITICAL + 11 WARN at session start):**
- 0 CRITICAL.
- 2 WARN remaining: (a) `delete_account` callable by authenticated —
  by design, Apple 5.1.1(v); (b) leaked-password-protection disabled —
  dashboard toggle, deferred to Bella.
- 5 INFO "unused index" — expected, DB is post-wipe empty; resolve
  themselves on first user activity.

---

## 2026-04-17 (session 2) — Streak fix, date bug, Insights expansion, UI polish (Claude Code)

**Critical fixes:**
- UTC date encoding bug: events saved as wrong day in AEST (ISO8601 UTC
  truncation). Now encodes local date string for DATE columns.
- Streak counted only check-ins, not event logging. Now uses max of both.
- Date comparisons across app switched to local timezone formatter.
- Onboarding quiz had transparent background (Home bled through). Fixed
  with opaque DS.bg / heroGradient.

**New Insights sections:**
- Income vs Spending: auto-calculates expenses from logged events, derives
  savings = income − expenses. NudgeSaysCard with O'Donoghue & Rabin 1999
  citation. Info popup explains methodology.
- Bias Impact Analysis: before/after spending comparison per identified bias.
  Literature popup with Kahneman 2011, Fischhoff 1982 citations.

**UI/UX design system updates:**
- Button rules locked: Yes = matteYellow (left), No = red/danger (right).
  NuggetGold gradient reserved for primary CTAs only.
- All full-screen flows (onboarding, BFAS) get heroGradient metallic green
  background with shimmer overlay.
- BFAS: thick goldBase 2.5pt card border, goldBase Yes button, white
  heroTextLegibility header, frosted gold citation footer.
- Onboarding quiz: hero gradient + compact white-on-dark pills with checkmark.
- CheckIn "Why this matters" → canonical NudgeSaysCard(surface: .dark).
- Calendar popup: compact Apple-style (no counter sentences, dot indicators).
- NudgeSaysCard: new .dark surface variant for dark green backgrounds.

---

## 2026-04-17 — Big day: rigour foundation + B/C layers + finance trend (Claude Code)

Long session that landed the algorithm-rigour foundation, the
B + C decision-helper layers, the financial-trend story v1, plus
several blocker fixes. Twenty-plus commits — chronological summary
below.

**Critical fixes:**
- `4e5eb7c` — global JSON decoder handles Postgres DATE columns.
  Root cause of "events save but Home/Insights show 0." VERIFIED:
  calendar went 0 EVENTS → 2 EVENTS, patterns 0/16 → 2/16.
- `3aee96b` — debug session no longer creates a fresh user every
  launch. Save creds before signUp; sign-in fallback inside catch;
  clear bad creds if both fail. (4 orphan users in the table from
  the bug.)
- `e1cb137` — MonthlyReviewTracker now requires 30 days since first
  install before "Monthly checkpoint" appears. Stops day-1 install
  showing it as the prompt.

**Algorithm rigour foundation (Waves 1–4 + 5 follow-ons):**
- `860b9e8` — citation-grounded BiasMappings.swift (40+ rows tying
  category × status × bias → published reference + confidence flag).
- `a30c90a` — re-weighted scoring 5:1 active vs passive (was backwards
  in PRD); NudgeVoice.researchCueFor() one-liner per bias paired with
  foundational paper; AlgoExplainerSheet citation footer expanded
  (Tversky & Kahneman, Thaler, Cialdini, Samuelson & Zeckhauser,
  Baumeister, Stone, Robinson & Clore, Beck, Pompian).
- `2046c9b` — adaptive neglected-bias threshold (clamp 14–60 days,
  scales with median log gap × 5).
- `0ab5a84` — per-mapping confirmation rate stats (UserDefaults v1).
- `fa24b88` — post-save Nudge cites the research per bias.
- `e91561e` — algorithm self-audit panel in AlgoExplainerSheet
  surfaces low-confirmation mappings (rate < 30% after 20+ samples).
- `551a57f` — Supabase aggregate VIEW (k-anonymity floor 50) +
  Supabase-backed self-audit read path.
- `913cb69` — research cues in WeeklyReview top-biases + CheckIn
  'why this matters'.
- `7441db1` — sibling-bias hint when same bias hits 3+ in a session
  (addresses "feels broken when same heuristic keeps showing").

**B + C decision-helper layers:**
- `928c5d3` — decision_lessons table (live Supabase) + Layer B
  pre-spend hint banner (Gollwitzer 1999 implementation intentions).
- `b091b48` — Layer C DecisionHelperSheet (Gawande 2009 checklists)
  via long-press on category tile.

**Financial-trend story v1 (manual entry, Privacy Act only):**
- `6822948` — user_monthly_income + user_balance_snapshots tables;
  Settings entry flow; net worth gold line on Insights.
- `47cb9c8` — bias-awareness overlay on the chart (decision_lessons
  cumulative count, faint dashed green) + trend insight Nudge above
  the chart with three states (gold-up + awareness-up / gold-up /
  awareness-up).
- `346b6aa` — expandable category trend chart replaces the unplanned
  bar chart (top 5 categories overlaid, tap legend to focus).

**Notifications + UX:**
- `b32f8e7` — meal-anchored notification copy + 9pm chunky-buys
  reminder.
- `f7ff0f6` — deep-link notifications → Log tab with pre-highlighted
  tiles (NotificationRouter @Observable singleton).

**Auth:**
- `08d12e6` — signup gracefully recovers from missing-SMTP
  confirmation error (auto-sign-in fallback).

**Visual sweep + spec consistency:**
- `73862eb`, `e91561e`, `e51f782` — card audit Waves 1, 2a, 2b
  (Home/Log/Insights/Awareness/Research/CheckIn/BiasReview/
  CredibilitySheet/WeeklyReview all use DS.cardRadius).
- `66f4ff1`, `795f71a`, `fe7c75b` — onboarding follows in-app spec
  (metallic shimmer hero + goldButtonStyle Next + spec card radius).
- `7536844`, `3018488` — BFAS question copy refined (19 questions
  rewritten plain-English, theory-grounded).
- `c1bfae4` — "40+ years" → "50+ years" of behavioural research
  (Tversky & Kahneman 1973 → 2026 = 53 years).
- `2740344` — clarified Mental Accounting whyExplanations
  (overspending mechanism made explicit) + readable check-in
  citation footer.
- `7ce10f8` — 4 abstract emojis swapped (😨→📉, 🕳️→🧾, 🎯→📈,
  🔋→🌙) + CheckIn skip-chastise overlay matching MoneyEvent's.
- `ff964b6` — Insights chart palette: gold + green, no orange.

**Documentation:**
- `5d118f5` — `docs/ALGORITHM.md` full methodology + ~25 references
  + known issues (Availability over-assignment, demo-data flag,
  hand-curated shortlist plan, lesson decay backlog,
  income/savings roadmap).

**Roadmap items still pending:**
- Visual nits 5/8/11/12/13/14/15 (need pointer screenshots from user).
- Basiq aggregator integration (v2 of finance side).
- CDR accreditation (v3, partner-or-build decision).
- Per-bias trend overlay (currently aggregate awareness count).
- Tests on BiasRotation + BiasScoreService maths.

Build verified iPhone 17 Pro / iOS 26.2.

Supabase migrations applied directly via MCP:
- 20260416180000_add_bias_mapping_stats.sql
- 20260416190000_add_bias_mapping_aggregate_view.sql
- (in-MCP) decision_lessons
- (in-MCP) user_monthly_income + user_balance_snapshots

---

## 2026-04-16 (PM) — Neglected-bias boost + review = events-only (Claude Code)

Two backlog items closed:

1. **Review pool padding killed.** Review now asks one question per
   real session event — no fillers, no padding to 10. If user logs 3
   events, review is 3 questions. Was previously hard-capped at 10 and
   recycled session entries with rotated biases to fill the gap; the
   recycling logic was a workaround for a problem the rotation system
   now solves at save time. ~70 lines deleted from MoneyEventView.

2. **14-day neglected-bias boost.** New `BiasRotation.boostedPick`:
   given the user's `bias_progress` rows, prefers any bias in the
   current shortlist whose `last_seen` is older than 14 days (or
   never recorded). Most-neglected wins. Wired into
   `MoneyEventViewModel.onPlannedStatusSet` as an async upgrade —
   optimistic sync rotation pick first (so picker shows a tag
   immediately), then async fetch progress + upgrade if a stale bias
   qualifies. Net effect: rare biases like Denomination Effect and
   Endowment Effect get force-promoted into the next compatible
   event after 2 weeks of neglect, guaranteeing all 16 stay touched
   over time.

Build verified iPhone 17 Pro / iOS 26.2.

Backlog: 3-check-in daily cadence (meal-anchored notifications +
end-of-day chunky-buys prompt), card audit Wave 1 (Home/Log/Insights
spec sweep).

---

## 2026-04-16 — Home check-in works + morphs daily/weekly/monthly + Quick log reward + BiasRotation service (Claude Code)

Two reframes shipped together:

1. Home check-in card was a dead button (`action: {}`). Wired it to
   present `CheckInView` and made the card morph based on what's due:
   - Default → "Today's check-in · 5 quick swipes · 30 sec"
   - Sunday + weekly not done → "Sunday review · Last week's patterns
     — let's revisit"
   - Monthly checkpoint due → "Monthly checkpoint · Re-checking the
     biases you flagged"
   Priority: monthly > weekly > daily. CheckInView already routes to
   the right internal flow based on the trackers, so this is just the
   surface layer that surfaces the right CTA copy + presents the sheet.

2. Quick log saves now pop a small **Nudge reward overlay** at the top
   of the screen for ~1.6s — bouncing Nudge coin + one-line reward
   copy. Builds the "every log gets noticed" loop the user wants for
   motivation. Every 5th log in a session gets a streak-flavoured line
   ("🔥 N logs this session — outpacing 70% of users"); other saves
   rotate through `NudgeVoice.postSave`.

3. New `Services/BiasRotation.swift`. Single source of truth for the
   (category × status) → bias shortlist that previously lived inside
   BiasReviewView (private) AND was duplicated inside MoneyEventView.
   Exposes `nextBias(category:status:)` (advances rotation index in
   UserDefaults so the same purchase pattern probes a different bias
   each time) and `peekNextBias(...)` for previews. **Not yet wired
   in** — added so the next commit can drop in rotation at all 3 call
   sites. Backlog: 14-day neglected-bias boost (needs async
   bias_progress fetch).

Build verified iPhone 17 Pro / iOS 26.2.

---

## 2026-04-16 — Onboarding gates + tab refresh + unified review/popup styling (Claude Code)

Session focused on UX consistency, removing the duplicate Quick log entry
point, and making logs actually flow through to Home + Insights.

- `GoldMindApp.swift`: removed the DEBUG bypass that mounted RootTabView
  directly. Onboarding + BFAS gates now run in DEBUG too — `Reset onboarding
  + BFAS` in the dev menu now actually shows the flow on next launch. Buggy
  release-mode `if currentUserId != nil { hasCompletedOnboarding = true }`
  removed (was auto-skipping onboarding for any signed-in user).
- `OnboardingView.swift`: bottom safe-area strip changed from solid
  `DS.deepGreen` to `DS.heroGradient` with shimmer overlay so the green
  reads as one continuous shimmery hero instead of a dark stripe.
- `BiasReviewView.swift`: event recap card now ALWAYS renders above the
  bias question (was gated on `eventId != nil`).
- `MoneyEventView.swift`:
  - `reviewEntriesToppedUp` rewritten — top-up questions recycle real
    session events (so the spending recap is always shown above the
    question) and rotate the bias via a status-aware shortlist.
  - `.alert("Skipping already?", ...)` replaced with a custom
    Apple-style modal: ONE white rounded card containing Nudge coin,
    NUDGE label, title, rotating chastise line, gold "Keep reviewing"
    pill, and warning-red text-only "Skip anyway" — all inside a single
    container with soft shadow + tap-outside-to-dismiss.
- `InsightFeedView.swift`: killed the duplicate Quick log sheet — the
  "Log your first event" CTA now switches `selectedTab` to `.log`
  instead of opening a second copy of MoneyEventView. Single source of
  truth for the Quick log form. Added `.onChange(of: selectedTab)` to
  refetch when user returns to the Insights tab.
- `HomeView.swift`: same `.onChange(of: selectedTab)` refetch pattern
  added so calendar + cards reload when user returns to Home (fixes
  "logged event doesn't show on calendar" — the `.task` modifier only
  fired on first appear and never again). Pull-to-refresh added.
- `MonthCalendarView.swift`: day popover now shows a one-line "how to
  counter" sentence under each top-3 bias (first sentence of
  `BiasLesson.howToCounter`).
- `RootTabView.swift`: `selectedTab` binding wired through to HomeView
  + InsightFeedView for the new tab-switch refresh logic.

Build: clean. Verified iPhone 17 Pro / iOS 26.2 simulator launch.

Backlog: bias rotation per-event (cycle through 5–6 plausible biases for
each category × status so all 16 get covered over time + neglected-bias
boost after 14 days), 3-check-in cadence (morning/midday/evening +
end-of-day chunky purchases prompt), kill review pool padding entirely.

---

## 2026-04-15 — Backlog: multi-log session + Research tab + status sync (Claude Code)

Documentation-only commit while user reviews the rebuilt UI.

- Backlog L1 expanded: "Multi-category logging session + summary" —
  MyFitnessPal-style. User logs back-to-back without leaving Log tab,
  banner shows "N logged · $X", end-of-session SUMMARY screen lists
  all events + top biases triggered + Nudge commentary + back to Home
  CTA. Each event saves to Supabase as added (not batched).
- Backlog T1 added: "5th tab — Research / Library". iOS allows 5 tabs
  before "More" collapse. Tab order proposal: Home · Log · Insights ·
  Awareness · Research. Promotes credibility content currently behind
  CredibilitySheet ⓘ into a permanent surface for users who want the
  deep-dive (4 papers, BFAS framework, 16 biases with citations,
  plain-English algorithm transparency). CredibilitySheet stays as
  the contextual popup.
- STATUS updated to reflect current state (white-gallery rolled out
  across every visible screen, shimmer dialled, white-text-on-green
  legibility fixed).

---

## 2026-04-15 — White-gallery pivot + ShimmeringGoldBorder (Claude Code)

Direction change after seeing green-flood theme in context. Pivot to
App Store convention: white base, green reserved for moments, gold as
signature accent. Matches Apple Wallet / Apple Fitness+ / Monarch /
Copilot Money / Stripe pattern.

Safe revert: tag `before-white-pivot` (commit 0e7148d).

All 4 tabs + CredibilitySheet: heroGradient background -> DS.bg white.

Green kept for moments (unchanged):
- HomeView streak card + check-in hero.
- CredibilitySheet internal hero panel at top.
- CredibilitySheet "You're not broken" dark panel.
- Awareness hero still just text/hero area on white.

Text tokens reverted to black/grey for white bg:
- DS.onDarkPrimary/Secondary -> DS.textPrimary/Secondary/Tertiary
  across HomeView, AwarenessView, InsightFeedView, MoneyEventView,
  CredibilitySheet, MonthCalendarView, TopBiasesCard (cards also
  reverted from frostedCardBg -> cardBg in earlier commit).

Gold: the signature accent.
- All .goldButtonStyle() buttons unchanged (already shimmer).
- ResearchFootnote pills unchanged.
- NEW ShimmeringGoldBorder.swift: animated AngularGradient stroke
  that rotates a bright highlight around a rounded rectangle.
  Apply via `.shimmeringGoldBorder(cornerRadius:)`.
- Applied to: Home greeting card, Top Biases card, NudgeSaysCard
  (.whiteShimmer variant), CredibilitySheet "THE DIFFERENCE" table.
- NudgeSaysCard gained .whiteShimmer surface variant = white bg +
  animated gold border. Handbook §1.3 update pending.

Log sheet drag indicator removed (user ask).

Build verified iPhone 17 Pro iOS 26.2.

Revert: `git reset --hard before-white-pivot` (or `git revert <hash>`).

---

## 2026-04-15 — Autonomous Phase B rollout + S1 Credibility rebuild (Claude Code)

Executed while user was at lunch/interview prep. Full autonomy granted
for the post-screenshot design plan. Safe revert point: tag
`phase-b1-stable` (commit d5d4b61). Each phase = one atomic commit.

B2-home (e9da626):
- Bg off-white -> heroGradient. Greeting card gold. Awareness circle
  frosted dark with gold progress ring. BFAS footnote .inline -> .pill.
  Nudge Says .paleGreen -> .gold. MonthCalendar + TopBiasesCard
  repainted internally for dark bg.

B3-log (56c5ad7):
- Removed dropdown + "More categories" entirely. 16 square gold tiles
  in LazyVGrid. Tap tile -> bottom sheet (.height 340) with gold
  range pill buttons + ABS avg footnote. Custom header "Quick log"
  .largeTitle + motivation copy "Log at your own pace — patterns
  show up over time." planned/surprise/impulse pills gold-surface
  (was white).

B4-insights (3f68f68):
- Bg -> heroGradient. Empty state: 64pt -> 96pt Nudge, plain text
  -> NudgeSaysCard .gold, grammar fix "an event" + "Start logging
  now.", "Nudge tracks patterns, not perfection" -> gold statement
  block (italic .headline, non-button shape), CTA swapped to
  .goldButtonStyle().

S1-credibility (this commit):
- Full rebuild per §8.4. Sticky green hero with 72pt Nudge + bold
  white .largeTitle. Body on green. Each section now a layered
  card (not floating text). THE IDEA/HOW THE RANKING WORKS/FRAMEWORK
  -> gold surface cards. THE DIFFERENCE table + WHAT THE STAGES
  MEAN -> frosted dark cards. Bullets replaced with numbered
  circles ①②③. YOU'RE NOT BROKEN stays deep-green panel with gold
  border. Citations stay gold 2×2. Nudge Says variant = .gold.
  Section labels recolored to DS.goldText (visible on green).

Build verified iPhone 17 Pro iOS 26.2 after each commit.

Revert options:
- Undo S1 only: `git revert <S1-hash>`
- Undo B4 only: `git revert <B4-hash>`
- Undo B3 only: `git revert <B3-hash>`
- Undo B2 only: `git revert <B2-hash>`
- Undo everything back to B1: `git reset --hard phase-b1-stable`
  (then `git push --force origin main` — destructive, use carefully)

---

## 2026-04-15 — Phase A tokens + Phase B1 Awareness repaint (Claude Code)

Phase A (already committed 7b9b044): added DS.onDarkPrimary/Secondary/
Tertiary, DS.frostedCardBg/Stroke, DS.goldSurfaceBg/Stroke tokens;
locked handbook §1.3 metallic-green-first visual language spec.

Phase B1 — Awareness tab full repaint:
- Background: DS.heroGradient.ignoresSafeArea (was #FAFAF8).
- Hero redesign: "Your money mind" .largeTitle white + subtitle
  white-0.75 on green + gold score pill top-right showing N/16 in
  serif with OF N subcaption.
- Awareness score card: frosted-dark surface (white 8% bg, white 15%
  stroke). Gold nuggetGold progress fill (was 2-tone green). BFAS
  ResearchFootnote .pill shown clearly inside.
- Nudge Says: gold surface variant (new). Uses the .gold case added
  to NudgeSaysCard.Surface.
- Category section headers: gold pill capsule with per-category
  emoji (🙈 Avoidance / 🔀 Decision Making / 💚 Emotion / 🧠 Memory /
  ⚡ Heuristic / 👥 Social). Dark-gold text #8B6010.
- Bias rows: gold-surface bg (was white). Bigger bias name .headline
  semibold DS.textPrimary. Description .subheadline regular
  DS.textSecondary lineSpacing 3 (was 9.5pt grey). Triggered count
  pill now deep-green bg + white text. Chevron gold.
- Expanded row: Nudge section uses ResearchFootnote for the key ref.

NudgeSaysCard component: added Surface enum (.paleGreen / .gold).
Existing call sites unchanged (default .paleGreen). Awareness passes
.gold.

Build verified iPhone 17 Pro iOS 26.2.

Remaining Phase B: Home (B2), Log (B3), Insights (B4). Sheets (S1+S2),
Formatting rhythm sweep (F1–F9), Smart notifications (N1+N2).

---

## 2026-04-15 — PLAN: master text polish pass (Claude Code)

Audit after simulator screenshots (Home, Log, Insights, Awareness)
found truncation, inconsistent sizes, invisible footnotes, and missing
BFAS attribution on most tabs. Planning-only commit — no behaviour
change yet.

DESIGN_HANDBOOK updates:
- §3.5 extended with a canonical role → font table (tab title, tab
  subtitle, section label, card title, card body, card meta, research
  footnote, empty state, caption, streak numeric). Each role locked to
  a single semantic font.
- §3.6 added: ResearchFootnote component spec. One canonical way to
  render any citation anywhere — inline (icon + text) or pill
  (#FFF8E1 bg + 0.5px gold stroke). Bumped to .footnote .semibold
  DS.textSecondary (was .caption2 .medium DS.textTertiary).
- §5.1 added: research footnote placement per tab. Home, Log x2,
  Insights, Awareness, CheckIn, Onboarding.
- §5.2 added: 5-step execution order.

Next commit: execute the plan — build ResearchFootnote, fix Home
welcome truncation, apply role table, swap citations on all 4 tabs.

---

## 2026-04-15 — Close out §8.2: BiasDetail citation + answer-flash (Claude Code)

- BiasDetailView: new "The research" section appended after "How to
  counter it". Looks up bias name in allBiasPatterns and renders the
  full citation in a gold pill (#FFF8E1 bg, book.closed.fill, .footnote
  medium). Graceful fallback text when no match.
- CheckInView: citation flash pill. On advance(), the just-answered
  bias's keyRef is written to @State flashedCitation; the progress
  footer cross-fades to show it for 1.6s, then reverts to the
  "Q{n} of {total} · from BFAS assessment" subtitle. Uses the same
  gold-tone pill style (#FFF8E1 bg, book.closed.fill DS.goldBase,
  .caption2 semibold #8B6010).
- DESIGN_HANDBOOK §8.2 — BiasDetail row and answer-flash row marked
  ✅ Implemented with concrete specs.

Closes out all of §8.2 credibility sprinkle points. Only smart
time-of-day notifications remain from the original backlog.

Build verified iPhone 17 Pro iOS 26.2.

---

## 2026-04-15 — Check-in plan complete: tailored Qs + weekly review + sprinkle cues (Claude Code)

Wraps the PRD v1.2 daily check-in architecture (steps 4 + 5) plus
first pass of §8.2 credibility sprinkle points.

Step 4 — tailored daily questions:
- New SupabaseService.fetchTailoredQuestions(count:). Ranks biases
  by BiasScoreService.computeScore (BFAS weight + activity), then
  for each top bias pulls the least-recently-shown question. Falls
  back to fetchNextQuestion for unfilled slots. Updates last_shown
  as it picks.
- CheckInView.loadQuestions switched to fetchTailoredQuestions(4).
  Offline fallback kept (QuestionPool.seed.shuffled().prefix(4)).

Step 5 — Sunday weekly review:
- New WeeklyReviewTracker (Services): isDueNow() true iff Sunday AND
  current ISO week not marked done; markDone() stores "YYYY-WW" in
  UserDefaults.
- New WeeklyReviewSummary view: hero ("Your week in patterns" + ISO
  week range) / 3-stat grid ($ spent / events / streak) / top 3 biases
  with stage pills / NudgeSaysCard commentary / gold "Begin 4
  questions →" CTA.
- CheckInView wires the tracker: on load, if due, fetches week events,
  today's check-in, bias progress → shows the summary first.

Sprinkle cues (handbook §8.2):
- Check-in progress dots now show "Q{n} of {total} · from BFAS
  assessment" subtitle — surfaces the research pedigree on every
  question.
- Onboarding screen 1 gets a research credibility pill directly under
  the intro copy: "Based on 40+ years of behavioural research" with
  book.closed.fill icon. White-opacity capsule against the dark green
  hero.

Build verified iPhone 17 Pro iOS 26.2 — BUILD SUCCEEDED.

---

## 2026-04-15 — Why tab absorbed into CredibilitySheet; 4-tab app (Claude Code)

PRD v1.3. All Why tab content merged into the expandable CredibilitySheet
reached from Home Top Biases ⓘ. Why tab removed entirely. Tab bar now has
4 tabs: Home · Log · Insights · Awareness.

CredibilitySheet rewritten with 10 sections:
1. Hero — Nudge 64pt + "Backed by research" .largeTitle
2. THE IDEA
3. THE DIFFERENCE — 5-row comparison table (Traditional × vs GoldMind ✓)
4. HOW THE RANKING WORKS — 3 plain-English bullets
5. WHAT THE STAGES MEAN — 5-row legend
6. THE FRAMEWORK — "Built on BFAS" card (absorbed from Why)
7. THE RESEARCH — 4 citation cards
8. YOU'RE NOT BROKEN — dark green hero panel (absorbed from Why)
9. NUDGE SAYS — in-context NudgeSaysCard about the assessment
10. CTA — "Got it" (closes sheet)

Typography polish: all SF Pro semantic roles (.largeTitle, .body,
.subheadline, .footnote, .caption2). Section labels keep master §3.5 spec
(11pt .rounded heavy DS.accent tracking 1.5). Comparison table header uses
DS.paleGreen zebra. No hardcoded hex in views (only #FFF8E1 citation bg
which is a handbook-designated value).

File changes:
- GoldMind/Views/WhyView.swift DELETED
- GoldMind/Views/CredibilitySheet.swift rewritten
- GoldMind/Views/RootTabView.swift — Why tab removed, RootTab enum
  reindexed (home=0, log=1, insights=2, awareness=3)
- GoldMind/Views/HomeView.swift — selectedTab param dropped (no longer
  needed to route to Why); sheet presents CredibilitySheet with no args
- docs/PRD.md bumped to v1.3
- docs/DESIGN_HANDBOOK.md §5 updated (4 tabs); §8.1 rewritten for new
  10-section sheet structure

Build verified iPhone 17 Pro iOS 26.2 — BUILD SUCCEEDED.

---

## 2026-04-15 — Top 4 biases card + credibility cues strategy (Claude Code)

- New `Views/TopBiasesCard.swift`. Implements DESIGN_HANDBOOK §7.3. Shows
  up to 4 top-ranked biases under Home calendar (emoji · name · trend ·
  stage pill). User sees zero raw scores. onTap scaffolded.
- PRD v1.2 extended: Credibility cues strategy. Verified 4 canonical papers
  (Pompian 2012, Kahneman & Tversky 1979, Thaler & Sunstein 2008,
  Kahneman et al. 2004). 6 sprinkle points documented. Reference apps
  (Noom, Headspace, Fitness+, Waking Up, Duolingo).
- DESIGN_HANDBOOK §8 added: CredibilitySheet spec for Home Top Biases
  ⓘ tap — hero / short Why / ranking explanation (plain English, no
  formula) / stage legend / 4 citation cards / gold CTA to Why tab.

---

## 2026-04-15 — PRD v1.2 check-in architecture + bias tracker spec (Claude Code)

- PRD.md bumped to v1.2. Added Check-in architecture section: time-of-day
  flow (first-open BFAS 16Q → throughout-day quick logs → evening 2Q →
  morning 2Q → Sunday 4Q), ranking formula (current_score +
  BFAS_initial_weight, hidden from user), question selection logic, motivation
  mechanisms (smart time nudges, loss aversion, pattern reveal), and
  explicit anti-patterns (no badges, XP, confetti).
- DESIGN_HANDBOOK §7.3: spec for "Top 4 biases" tracker card under
  Home monthly calendar. Emoji · name · trend · stage pill, tap -> BiasDetail.
  Reuses HomeViewModel.dailyPatterns (already populated).

---

## 2026-04-15 — Home monthly calendar + Nudge welcome message (Claude Code)

Reverts the misplaced Log empty-state feature and delivers two Home features in its place, per `DESIGN_HANDBOOK.md` §7.1 and §7.2.

**Home — monthly calendar card** (§7.1)
- New `Views/MonthCalendarView.swift` component. Inserted between check-in hero and Nudge card.
- Shows current month. Days with logged money events = filled `DS.accent` pill + bold white number. Today = gold outline ring. Empty days = disabled small grey number.
- Tap an event-day → popover: date header · event count · total $ · top 3 biases (tag × count). No-tag days fall back to "No bias tags that day".
- `HomeViewModel.monthEventsByDay: [String: [MoneyEvent]]` populated in `load()` from `SupabaseService.fetchMoneyEvents(forMonth:)`. No hardcoded fallback.

**Home — Nudge welcome message** (§7.2)
- `NudgeEngine.welcomeMessage(hour, isFirstOpen, streak, checkedInToday, loggedEventToday) -> String` added.
- Replaces the hardcoded `greeting` displayed at top-left of `HomeView` with a contextual Nudge line. First-open users see "Hi, I'm Nudge. Ready to understand your money mind?"; returning users see time-aware + streak/activity-aware copy.
- Voice rules preserved: dry wit, short, no shame language.

**Reverted (misplaced):**
- Removed `loadEmptyState`, `weekDots`, `topBiases`, `TopBias` from `MoneyEventViewModel` and the matching `logEmptyState` / `weekStrip` / `topBiasesPanel` / `trendArrow` from `MoneyEventView`.
- `HomeViewModel.computeWeekDots` kept non-private (harmless; may be reused).

Build verified on iPhone 17 Pro / iOS 26.2 — BUILD SUCCEEDED.

---

## 2026-04-15 — Design handbook + metallic palette lock (Claude Code)

- Added `docs/DESIGN_HANDBOOK.md` — master visual language doc. Locks `heroGradient` (7-stop metallic green), `nuggetGold` (6-stop foil), Apple-style polish (rim highlight + bottom rim shadow + dual drop shadow), element usage rules, tab-by-tab application spec.
- Restored 7-stop `heroGradient` in `DesignSystem.swift` to the Tue 04-14 peak (commit `344bb9b`) after brief drift.
- `HomeView.swift` + `WhyView.swift`: 4 hero call sites now use `DS.heroGradient` consistently (replaced inline 2–3 stop flat gradients).
- Added `preview_palette.html` at repo root — static browser preview kept in sync with `DesignSystem.swift` for palette review.

---

## 2026-04-14 — How it works 5th tab (Claude Code)

- Added `HowItWorksView` as 5th tab in `RootTabView.swift` (label "How it works", icon `info.circle`). Build green, 5 tabs verified via screenshot.

---

## 2026-04-13 — Real Supabase questions, Nudge app icon, notifications (Claude Code)

**Real Supabase questions:**
- CheckInView already wired to `service.fetchNextQuestion()` which queries
  `question_pool` ordered by `last_shown asc nulls first`, updates `last_shown`
  to today after fetch. 30 questions verified via REST API.
- Falls back to `QuestionPool.seed` only on network error.

**Nudge app icon:**
- Generated all icon sizes (20, 40, 60, 76, 120, 152, 180, 1024px) from
  `nudge.imageset/nudge.png` via `sips -z`. Contents.json already correct.

**4 notification types:**
- 8am morning: "One question. 60 seconds. Nudge is waiting."
- 7pm evening (no check-in): "Nudge noticed."
- 48h no events: "Nudge has no data. That's also information."
- Bias hits 5x: "[Bias] appeared 5 times. Nudge has something."
- All scheduled on app launch in GoldMindApp
- Evening nudge cancelled on check-in, no-events timer reset on money event
- Bias alert triggered in MoneyEventViewModel when tagCount == 5

---

## 2026-04-13 — Onboarding 4-screen swipeable TabView (Claude Code)

**Complete onboarding rewrite:**
- Screen 1: Nudge welcome — heroGradient background, NudgeAvatar 120pt,
  "Hi, I'm Nudge." white largeTitle, gold "Get started →" button
- Screen 2: The 7 Patterns — heroGradient background, 7 white rounded
  cards with emoji + bias name + one-liner (Loss Aversion, Present Bias,
  Overconfidence, Mental Accounting, Status Quo Bias, Anchoring, Ostrich
  Effect), Pompian 2012 citation, gold "I recognise these →" button
- Screen 3: Budget Reality Check — white background, lime caps label,
  NudgeAvatar 52pt, sequential quiz (Q1: budget duration, Q2: why stopped),
  capsule pills, Nudge response card (heroGradient, "You're not broken.
  The method is.", 70% stat), gold "That's why GoldMind exists →"
- Screen 4: Sign up — NudgeAvatar 100pt, email/password fields, gold
  "Create account" button, "Already have an account? Sign in" toggle
- Removed old "How it works" 3-card explainer screen
- TabView paged with .ignoresSafeArea(), custom progress dots

---

## 2026-04-13 — All 16 biases grouped, debug onboarding reset (Claude Code)

**BiasLessonsMock expanded to 16:**
- Added 9 missing biases: Anchoring, Sunk Cost Fallacy, Ego Depletion,
  Availability Heuristic, Denomination Effect, Framing Effect, Planning
  Fallacy, Scarcity Heuristic, Moral Licensing
- Recategorized: Overconfidence Bias → Decision Making, Status Quo Bias
  → Self Perception. Removed "Inertia" category.
- Added `categoryOrder` array for display ordering

**Glossary card grouped by category:**
- 6 category section headers: Avoidance, Decision Making, Money Psychology,
  Time Perception, External Influence, Self Perception
- Headers: 11pt 800 weight #4CAF50 uppercase tracking 1.5
- All 16 biases visible and tappable → BiasDetailView

**Debug onboarding reset:**
- "Reset onboarding (debug)" button in SettingsView (#if DEBUG)
- Signs out + resets hasCompletedOnboarding → returns to onboarding
- Verified: onboarding screen 1 renders correctly

---

## 2026-04-13 — Quick log redesign, driver insights, BFAS, library glossary (Claude Code)

**Quick log redesign (MoneyEventView):**
- 2-column grid with top 6 categories (bigger cards), "More categories ↓" expander
- ABS monthly average shown above range picker ("Avg: $180/mo · ABS 2022–23")
- 14 categories have ABS Household Expenditure Survey 2022–23 averages
- Cancel/Done toolbar hidden when view is a tab (not sheet)
- Reset flow added for tab-based usage

**Driver insight card:**
- White card with 3pt green left border slides in with spring animation
- "WHAT THIS MEANS" (lime 10pt caps) + "HOW TO BREAK IT" (gold 10pt caps)
- "See your [bias] pattern →" pill navigates to Insights tab
- 16 drivers with custom means/fix copy
- BFAS credibility line below driver grid title

**BFAS credibility (CheckInView):**
- "Used in professional financial planning assessments · BFAS framework"
- caption2, italic, white 0.5 opacity, centred below each question card

**Library glossary card (LearnView):**
- "16 patterns. One line each." card at top of Library tab
- All 16 biases listed with emoji + name + one-line description
- Each row tappable → BiasDetailView

---

## 2026-04-13 — Tab restructure + HomeView patterns (Claude Code)

**Tab bar restructure:**
- Changed from Home/Check in/Learn/Insights → Home/Log/Insights/Library
- MoneyEventView is now the Log tab (direct navigation, not a sheet)
- LearnView is now the Library tab
- CheckInView removed from tab bar — opens as sheet from HomeView hero card
- Icons: house.fill / plus.circle.fill / chart.line.uptrend.xyaxis / books.vertical

**HomeView restructure:**
- Hero check-in card: shows "Checked in · Day [streak]" with gold checkmark when done
- Removed "Learn a bias" from daily missions (2 missions: check-in, log event)
- Added pattern alert cards: biases seen 3+ times shown with emoji, count, trend
- Pattern cards tappable → navigates to Insights tab
- Removed log event button (now a tab)

**Fix:** SettingsView moved Supabase calls to service layer (`resetUserData()`)
to fix PostgREST import errors.

---

## 2026-04-13 — Event motivation, glossary, softer questions (Claude Code)

**Event logging motivation:**
- NudgeContext gains `daysSinceLastEvent` + `eventLoggingStreak`.
- NudgeEngine rule: "Nudge has no data on your week. That's also data."
  fires when 2+ days since last event and user has checked in today.
- Post-log feedback improved: "That's Anchoring. 3rd time this week."
  with ordinal suffix and action button for 3+ counts.
- HomeViewModel computes event logging streak (consecutive days with events).

**Bias glossary:**
- List button in LearnView toolbar opens glossary sheet.
- "All 16 biases" list: emoji + name + one-line description + mastery
  stage badge + chevron. Each row navigates to BiasDetailView.

**Softer question framing:**
- Supabase migration updates 10 intermediate/advanced questions to add
  "even just a little?", "even slightly?", "even a small one?" suffixes.
- Lowers threshold for honest answers per behavioural UX rules.

**Nudge image verified:**
- Image("nudge") loads correctly in all 10 locations via NudgeAvatar.
- All wrapped in green circle (#2E7D32) which masks the black PNG bg.

---

## 2026-04-13 — Trust/transparency layer (Claude Code)

**Onboarding "How it works" screen:**
- Added 3-card swipeable explainer between quiz and sign-up (page 3 of 4).
- Card 1: "Built on real research" with Kahneman/Tversky/Cialdini citations.
- Card 2: "One question. One minute." with BFAS methodology reference.
- Card 3: "Your patterns. Not a grade." with revealed preference theory.
- Gold "I'm ready" button on last card.

**Research citations on questions:**
- Added `researchSource` to Question model.
- Supabase migration adds `research_source` column + populates all 16 biases.
- Displayed in CheckInView below "Why this matters" when expanded (italic, 11pt).

**Bias scoring system (BiasScoreService.swift):**
- MasteryStage: unseen → noticed → emerging → active → improving → aware.
- BiasTrend: worsening / stable / improving.
- Scoring weights: +2 yes, -1 no, +3 tagged spend.
- computeScore() builds full BiasScore from progress + events.

**"About your score" sheet:**
- Info button in InsightFeedView toolbar opens explanation sheet.
- Sections: The Science, The Scoring (+2/-1/+3), Your Stages (6 levels),
  Important (not clinical diagnosis disclaimer).
- Gold "Got it" dismiss button.

**Mastery stage badges on Learn cards:**
- Top-right corner badge on each LearnView card.
- Colour-coded: blue (noticed), amber (emerging), coral (active),
  green (improving), gold (aware). Hidden when unseen.
- Driven by BiasScoreService from user_bias_progress data.

---

## 2026-04-13 — Daily check-in enforcement, home stats, missions (Claude Code)

**CheckInView daily enforcement:**
- On appear, checks fetchTodaysCheckIn(). If already completed, shows
  NudgeAvatar 72pt + "You checked in today." + streak count + "Come
  back tomorrow" instead of questions.

**HomeView stat cards + daily missions:**
- 3 stat cards row: Alignment %, Biases Seen (gold), This Week spend.
- Daily Missions section: 3 rows with checkmark/circle state:
  - Daily check-in — "Keep the streak"
  - Log a money event — "Track what happened"
  - Learn a bias — "Swipe through Learn"
- Completion state driven by today's data from ViewModel.

**Real questions from Supabase (already wired):**
- fetchNextQuestion() was already hitting live Supabase with 14-day
  cooldown + last_shown update. Confirmed working.

---

## 2026-04-13 — Quick-log MoneyEventView with AUD ranges (Claude Code)

**MoneyEventView rebuilt as quick-log:**
- Replaced amount text input with 3-column category grid (16 categories).
- Each category has AUD range picker (3–4 buttons with midpoints).
- Planned/Surprise/Impulse selection after range.
- Auto-suggest bias tag based on category + status mapping.
- Inline Nudge message with bias one-liners or pattern alerts.
- "Log it" gold gradient button. No note/date fields.
- Added `lifeArea` field to MoneyEvent model + CodingKeys.
- Supabase migration: `life_area` column added to money_events.
- NudgeEngine.moneyEventResponse now accepts String bias tag.
- HomeViewModel topBiasLabel reads tag directly (not via SpendingDriver).

---

## 2026-04-13 — Learn buttons, settings screen (Claude Code)

**LearnView buttons:**
- Replaced single "See pattern" gold button with two side-by-side buttons.
- "Learn more": outline border, Color(hex: "1A5C38") text, clear bg.
- "How to counter it": filled Color(hex: "1A5C38") bg, white text.
- Both navigate to BiasDetailView via NavigationLink(value: lesson).

**SettingsView (NEW):**
- Gear icon in HomeView now opens SettingsView as a sheet.
- Sign out: calls SupabaseService.signOut(), resets hasCompletedOnboarding
  to false → user returns to OnboardingView.
- Reset demo data: deletes daily_checkins, money_events, user_bias_progress
  for current user. Confirmation dialog before executing.
- Shows app version + build number from Bundle.main.

---

## 2026-04-13 — App icon set to Nudge mascot (Claude Code)

**App icon:**
- Resized `nudge.png` to 1024x1024 via `sips`.
- Xcode 26 single-image format: `Icon-1024.png` assigned to iOS
  universal slot (light, dark, tinted variants all use same image).
- Removed legacy per-size/per-idiom entries (Xcode 26 auto-generates
  all sizes from the single 1024px source).

---

## 2026-04-13 — Onboarding, Budget Reality Check, sign up/in, real questions (Claude Code)

**Goal:** Rebuild onboarding as 3-screen paged flow with Budget Reality
Check quiz. Add sign-in screen. Verify real Supabase questions are wired.

**OnboardingView rebuilt (3 screens):**
- Screen 1: NudgeAvatar 120pt + "Hi, I'm Nudge." + value prop + gold
  "Get started" button. Progress dots at bottom.
- Screen 2: Budget Reality Check quiz. Q1: "How long did your last
  budget last?" (3 options). Q2: "Why did you stop?" (4 options,
  conditional on Q1). Nudge responds: "You're not broken. The method
  is." + 70% abandonment stat. Selected pills use heroGradient.
  Animated transitions with spring.
- Screen 3: Sign-up form. Email + password fields (paleGreen bg).
  Gold "Create account" button. "Already have an account? Sign in"
  link opens SignInView as sheet. On success: fetchOrCreateBudgetMonth,
  set hasCompletedOnboarding = true.

**SignInView (NEW):**
- Email + password + gold "Sign in" button.
- Presented as sheet from onboarding screen 3.
- NudgeAvatar 80pt + "Welcome back" header.
- On success: Supabase signIn(), hasCompletedOnboarding = true, dismiss.
- Cancel toolbar button to return to sign-up.

**Real Supabase questions (already wired):**
- `SupabaseService.fetchNextQuestion()` already queries `question_pool`
  ordered by `last_shown` ascending (nulls first), updates `last_shown`
  after fetch. 14-day cooldown filter. Falls back to least-recently-shown.
- `CheckInView.loadQuestions()` already calls `service.fetchNextQuestion()`
  in a loop (up to 5 questions), with `QuestionPool.seed` as fallback.
- No changes needed — TASK 2 was already complete.

**Build:** No errors in source files.

---

## 2026-04-13 — Gradients everywhere, typography scale, green consistency (Claude Code)

**Goal:** Enforce heroGradient on all selected cards/sheets, bump
typography scale for readability, enforce two-green colour system.

**GoldButtonStyle renamed + improved (DesignSystem.swift):**
- `GoldButton` → `GoldButtonStyle`: added `.fontWeight(.bold)`,
  `.frame(maxWidth: .infinity)`, padding 11→12. Extension updated.

**Hero gradient on all selected cards:**
- MoneyEventView: all 3 selection card types (planned status,
  behaviour tag, life event) now use `DS.heroGradient` when selected
  instead of flat `DS.primary`. Uses `AnyShapeStyle` for type erasure.
- Hero gradient location 0.7→0.75 for #2E7D32.

**Yes/No buttons restyled (CheckInView):**
- No button: coral `#FF6B6B` fill, white text, `Image(systemName: "xmark")`.
- Yes button: 3-stop gold gradient (#FFF0A0→#E8B84B→#C59430),
  dark green text, `Image(systemName: "checkmark")`.
- Both use `clipShape(RoundedRectangle(cornerRadius: 12))`.
- `.padding(.top, 16)` added.

**InsightFeedView "Log your first event" button:**
- Changed from `PrimaryButtonStyle()` to heroGradient fill + white bold text.

**Typography scale (all views):**
- SectionHeader: 11pt→12pt heavy.
- LearnView: header title3→largeTitle, description caption→subheadline,
  short description 13→15pt, "IN REAL LIFE" 10→12pt, example 11→13pt,
  category pill 10→11pt, "See pattern" 12→13pt.
- NudgeCardView: body 13→15pt, action label 12→13pt.
- InsightFeedView: "THIS WEEK" 10→12pt, hero pills 11→13pt.
- MoneyEventView: driver shortDescription 10→12pt.

**Green colour consistency (two greens only):**
- Heading green `#1A5C38`: bias names (LearnView), filter pills,
  dot indicators, completion checkmarks (CheckInView, MoneyEventView),
  default categoryColour.
- Lime green `#4CAF50`: "IN REAL LIFE" label, "Set target" text,
  demo data link, seen row icon, driver labels.
- Replaced all `DS.primary` text usage → `Color(hex: "1A5C38")`.
- Replaced all `DS.accent` label usage → `Color(hex: "4CAF50")`.

**Build:** No errors in source files. SPM dependency chain
(swift-clocks/ConcurrencyExtras) has Xcode 26 compatibility issue —
not our code, tracked upstream.

---

## 2026-04-13 — Core loop wired end-to-end (Claude Code)

**Goal:** Make check-in → money event → insights flow work with real
Supabase persistence.

**CheckInView saves to Supabase:**
- Added `saveCheckIn()` async method that computes streak (yesterday's
  streak + 1), alignment %, builds `CheckIn` record, and calls
  `service.saveCheckIn()`. Completion card now shows "Day N".
- Tone picker removed (swipe YES/NO is the only input).
- Rotation formula simplified to `dragOffset.width / 20`.

**DemoDataService + auto-seed:**
- `DemoDataService.swift` seeds 7 check-ins, 8 money events, 3 bias
  progress entries. `HomeViewModel.load()` auto-seeds on first open
  when streak=0 and no events (guarded by UserDefaults flag).
- "Load demo data" link visible below greeting header.

**Empty states redesigned:**
- HomeView: NudgeAvatar 120pt + "Hi, I'm Nudge" title bold + full-width
  gold CTA when no streak.
- InsightFeedView: NudgeAvatar 64pt + calm copy + green "Log your first
  event" button opening MoneyEventView sheet.

**LearnView emoji in circle:**
- Emoji now displayed inside 80pt circle filled with category bg colour.

**Design tweaks:**
- Hero gradient: 5-stop shimmer `#0A2E12→#1B5E20→#4CAF50→#2E7D32→#52B788`.
- Gold button text colour: `#1B3A00` (was `#3A2000`).
- Ostrich Effect emoji: `🫣` in local mock (Supabase RLS blocks anon PATCH).
- Text polish across all views: sentence case, no exclamation marks.

**Build:** `** BUILD SUCCEEDED **` (iPhone 17 Pro / iOS 26.2).

---

## 2026-04-12 — Rebuild CheckInView + InsightFeedView + docs audit (Claude Code)

**Goal:** Match UI mockup specs exactly. Rebuild CheckInView with swipe
YES/NO, rebuild InsightFeedView with native Charts, wire Nudge asset,
audit all files and create HANDOFF.md.

**Nudge asset wired:**
- `images/Nudge_Asset.png` copied to
  `Assets.xcassets/nudge.imageset/nudge.png` with Contents.json (2x scale).
- NudgeAvatar in DesignSystem.swift already references Image("nudge").

**CheckInView full rebuild:**
- Green gradient card `#1B5E20->#2E7D32->#4CAF50` (was DS.heroGradient).
- Swipe RIGHT > 80pt = YES (green `#4CAF50` overlay with "YES" text).
  Swipe LEFT > 80pt = NO (coral `DS.warning` overlay with "NO" text).
- Card rotates +/-15 degrees during drag (proportional to screen width).
- 2 back cards visible: middle `#81C784` scaled 0.96, back `#A5D6A7` 0.92.
- REMOVED text input field from card.
- Tone picker: white opacity buttons (0.08 bg, 0.20 selected), NOT yellow.
  Border: white opacity 0.5 when selected, not gold.
- Swipe hints: "← No" in coral (left), "Yes →" in green (right).
- Background `#F5F7F5`. Card borders `rgba(76,175,80,0.15)`.

**InsightFeedView rebuild with Charts:**
- `import Charts` (native SwiftUI iOS 16+).
- Weekly hero card with DS.heroGradient + decorative circles.
- Section 2: **Bar chart** (BarMark) — 6-week unplanned spend trend.
  Green bars improving, coral bars worsening. Y-axis with short amounts.
- Section 3: **Horizontal bar chart** (BarMark) — bias frequency from
  all money events + check-in drivers. Gradient green bars. Count
  annotations trailing.
- Section 4: **Donut chart** (SectorMark) — planned vs unplanned %.
  Green planned, coral unplanned. Legend with percentages.
- Section 5: NudgeCardView at bottom.
- Removed old SparklineView-based trend cards and horizontal scroll
  pattern cards. Background `#F5F7F5`. Borders `rgba(76,175,80,0.15)`.

**Documentation:**
- `docs/HANDOFF.md` — NEW. Complete file listing with descriptions,
  exact colours, Nudge rules, Supabase state, priority tasks, design
  rules. Read at start of every session.
- `MEMORY.md` — rewritten with all design decisions from today:
  Money Green + Nugget Gold colours, Nudge mascot rules, swipe YES/NO
  system, Charts framework choice, LearnView card layout.
- `docs/STATUS.md` — updated with rebuilt screen descriptions.

**Build:** `** BUILD SUCCEEDED **` (iPhone 17 Pro / iOS 26.2).

---

## 2026-04-12 — Wire Supabase Swift package + replace all stubs with live client (Claude Code)

**Goal:** Remove the in-memory stub in SupabaseService and connect to
the real Supabase backend.

**Package added:**
- supabase-swift 2.43.1 added to GoldMind.xcodeproj via pbxproj edit
  (XCRemoteSwiftPackageReference + XCSwiftPackageProductDependency).
- Resolved via `xcodebuild -resolvePackageDependencies` (also pulled
  swift-crypto, swift-http-types, swift-concurrency-extras, etc.).

**SupabaseService.swift — full rewrite:**
- `import Supabase` uncommented, `SupabaseClient` initialised with real
  URL + anon key.
- All in-memory arrays removed. Every method now uses `client.from(...)`
  or `client.auth`.
- New methods: `fetchAllBiasLessons()`, `fetchBiasLesson(biasName:)`,
  `fetchBiasProgress()`, `updateBiasProgress(biasName:reflected:)`.
- `BiasProgress` model added (maps to `user_bias_progress` table).
- `ISO8601DateFormatter.dateOnly` helper for date-only PostgREST filters.
- `currentUserId` is now an `async` computed property (reads from
  `client.auth.session`).

**DB migration:**
- `20260412160000_rebuild_money_events_columns.sql` — aligns
  `money_events` table with PRD v1.1 Swift model: added
  `planned_status`, `behaviour_tag`, `life_event`; dropped old
  `category` + `event_type`. Existing rows migrated.
- Both `20260412150000` and `20260412160000` pushed and applied.

**ViewModel fixes:**
- `CheckInViewModel.submit()` — `await service.currentUserId`
- `MoneyEventViewModel.save()` — `await service.currentUserId`

**Build:** succeeds on iPhone 17 Pro simulator (Xcode 26, iOS 26.2).

---

## 2026-04-12 — Replace MonthView with InsightFeedView + SparklineView (Claude Code)

**Goal:** MonthView showed alignment % and income targets — legacy
budgeting concepts that don't belong. Replace with behaviour-based
awareness trends that show patterns, not budgets.

**Tab renamed:** "Month" → "Insights" (icon: chart.line.uptrend.xyaxis).
`RootTab.month` → `RootTab.insights`. All references updated (HomeView
nudge action handler).

**InsightFeedView (replaces MonthView):**
1. Weekly hero card: #1B5E20→#2E7D32→#4CAF50 gradient, gold "THIS
   WEEK" label, "This week: +/-£X from future you" (planned minus
   unplanned net), "N of 7 days you chose future you" sub, 3 trend
   pills (unplanned %, top bias, streak count)
2. Spending trends section: one SparklineView card per behaviour tag,
   showing 7 bars for last 7 weeks. Direction pill: "Improving" (green)
   or "Watch this" (orange). "Linked to [bias] bias" subtext.
3. Your patterns section: horizontal scroll of bias pattern cards.
   Each: emoji + name + count + strength pill (Emerging <3,
   Established 3-6, Strong 7+).
4. Weekly Nudge insight card at bottom with contextual message.

**SparklineView (new component):**
- 7-bar chart, configurable width/height.
- Green bars for improving trends, orange for worsening.
- Latest bar highlighted with full colour.

**SupabaseService:**
- Added `fetchAllMoneyEvents()` for insights calculations.

**Removed from tab bar:**
- MonthView still in codebase (not deleted) but no longer mounted.
- No income target, no alignment %, no categories anywhere in Insights.

**Build:** `** BUILD SUCCEEDED **` (iPhone 17 / iOS 26.2).

---

## 2026-04-12 — Wire NudgeEngine to live data + Nudge on all screens (Claude Code)

**Goal:** NudgeEngine should build its context from real data, not
placeholder values. Nudge should respond on every key screen.

**NudgeContext enriched (HomeViewModel.buildNudge):**
- `topBias` / `topBiasCount`: computed from money events behaviour
  tags this week (falls back to check-in SpendingDrivers)
- `unplannedSpendPct`: % of this week's money events that are
  surprise or impulse
- `weeklyNet`: planned total minus unplanned total this week
- `spendTrend`: derived from unplanned %  (>50% = "up", <20% = "down")
- `totalBiasesSeen`: union of distinct check-in drivers + event tags
- All other fields already computed from prior session

**NudgeEngine expanded:**
- New priority #4: high unplanned spend (>50%) + negative weekly net
  → "X% unplanned... pattern worth seeing" with openTrends action
- New priority #7: anxious tone + high unplanned (>40%)
- `moneyEventResponse()`: generates contextual Nudge message after
  saving a money event — pattern count ≥3 triggers "See your fix",
  life events get acknowledged, planned events get "That's the goal"
- `checkInResponse()`: generates completion message based on streak
  day, questions reflected, driver + tone combo

**MoneyEventView post-save confirmation:**
- After save, view transitions to a confirmation screen with green
  checkmark + "Logged" + NudgeCardView with contextual message.
  Replaces the old instant-dismiss flow.
- `MoneyEventViewModel.nudgeResponse` built from
  `NudgeEngine.moneyEventResponse()` with live `countBehaviourTag()`

**CheckInView completion card:**
- NudgeCardView now appears between driver chip and Done button
  on the completion screen, showing `NudgeEngine.checkInResponse()`

**SupabaseService:**
- Added `fetchMoneyEventsThisWeek()` (ISO week filter)
- Added `countBehaviourTag(_:)` (count all events with a given tag)

**Build:** `** BUILD SUCCEEDED **` (iPhone 17 / iOS 26.2).

---

## 2026-04-12 — Kill categories: awareness-based money events (Claude Code)

**Goal:** Categories are what made Mint fail. "Shopping: £220" tells you
nothing. Replace the entire category system with awareness-based tracking:
was this planned or a surprise? What behaviour drove it?

**Philosophy shift:** Trends now use planned/surprise ratio + behaviour
tags + amount size. Never categories. "Anchoring-driven spend" tells you
WHY money left your account. "Shopping" tells you nothing.

**MoneyEvent model rewrite:**
- Removed `EventType` (surprise/win/expected) and `MoneyCategory` enum
- Added `PlannedStatus` (planned/surprise/impulse) with `isUnplanned`
- Added `behaviourTag: String?` (reuses CheckIn.SpendingDriver rawValues)
- Added `LifeEvent` enum (job_change/unexpected_bill/medical/windfall/
  other_big) — shown only when amount > 200
- Added derived `SizeBucket` (small <50, medium 50-200, large 200+)
- Removed `category: String?` field entirely

**MoneyEventView rebuilt — 3 taps:**
1. Amount (numeric hero input)
2. Was this planned? — 3 full-width buttons with descriptions:
   [✓ Planned] [⚡ Surprise] [🎯 Impulse]
3. What drove it? — 2x3 behaviour tag grid (only for surprise/impulse)
4. Life event — 5 options (only if amount > 200)
Plus optional note + date. Sections animate in/out with spring.

**MonthView rebuilt:**
- Killed `categoryBreakdown` entirely
- New: unplanned spend ratio card (% of total + surprise/impulse counts)
- New: top behaviour card (most-tagged SpendingDriver this month)
- Events grouped by PlannedStatus, labelled with behaviour tag

**Alignment calc updated** in HomeViewModel, CheckInViewModel, MonthView:
uses `plannedStatus.isUnplanned` instead of `eventType == .surprise`.
HomeView event rows show PlannedStatus label/emoji.

**Build:** `** BUILD SUCCEEDED **` (iPhone 17 / iOS 26.2).

---

## 2026-04-12 — Money Green + Nugget Gold colour system (Claude Code)

**Goal:** Replace all purple/violet with bright money green + nugget
gold across every screen. Fresh, finance-forward visual identity.

**Colour system (DesignSystem.swift):**
- Primary `#2E7D32` (hero cards, nav, CTA buttons)
- Accent `#4CAF50` (section labels, ring stroke, filter pills)
- Light green `#81C784` (card backs, tints)
- Pale green `#E8F5E9` (pills, tab active bg, why section bg)
- Background `#FAFAF8`, cards white
- Text: `#1A2E1A` / `#6B7A6B` / `#A0B0A0`
- Gold: base `#C59430`, text `#E8B84B`, gradient 5-stop
- All purple/violet removed. No `deepPurple`, no `#2D1B69`,
  no `#7F77DD`.

**Screens updated:**
- HomeView: `#2E7D32` hero card, pale green card borders, green
  section labels, green accent throughout
- CheckInView: `#2E7D32` front card, `#81C784` / `#A5D6A7` backs,
  gold bias pill, `#E8F5E9` why section, green progress dots
- LearnView: green active filter pills, `#C8E6C9` / `#A5D6A7`
  card backs, `#2E7D32` CTA button, green dot indicator
- BiasDetailView: `#E8F5E9` tinted sections, green seen row,
  green section headers. Category colours preserved.
- StreakRingView: `#4CAF50` ring stroke, gold gradient number
- RootTabView: tint `#2E7D32`
- HomeViewModel: alignment colours use DS.positive / DS.warning
- PRD.md design section rewritten

**Build:** `** BUILD SUCCEEDED **` (clean, iPhone 17 / iOS 26.2).

---

## 2026-04-12 — Spending driver tags: post-check-in behaviour tagging (Claude Code)

**Goal:** Track *why* decisions happen, not just *what*. After each
check-in, ask "What drove this?" and let the user tag the behavioural
driver. This is the foundation for weekly pattern-awareness insights
("Most of your spending comes from convenience, not necessity").

**Added:**
- `CheckIn.SpendingDriver` enum (6 cases): Present Bias ("I want
  this now"), Social ("Others are doing it"), Reward ("I deserve
  this"), Convenience ("This is easier"), Identity ("This reflects
  who I am"), Friction Avoidance ("Too hard to change"). Each has
  rawValue, label, shortDescription, emoji.
- `spending_driver` optional field on `CheckIn` model with
  `CodingKey` mapping to `spending_driver`.
- Migration `20260412150000_add_spending_driver.sql`: nullable
  `spending_driver` text column with CHECK constraint on
  `daily_checkins`.

**CheckInView changes:**
- 3-phase flow: `questions` → `driverPick` → `done`.
- After all question cards are swiped, transitions to a "What drove
  this?" screen with 2x3 `LazyVGrid` of pill-style driver buttons.
  Each pill: emoji + label + one-line description. Single-select,
  optional skip. Tone: "No wrong answers. Just noticing."
- Continue/Skip button advances to completion. Completion view now
  shows selected driver chip if one was picked.
- `NotificationService.scheduleDailyReminder()` fires on Continue/
  Skip (moved from advance() to the driverPick → done transition).

**Build:** `** BUILD SUCCEEDED **` (clean build, iPhone 17 / iOS 26.2).

---

## 2026-04-12 — Beta shell: 4-tab root, StreakRing HomeView, CheckInView swipe (Claude Code)

**Goal:** Close out the beta shell so the app reads as a real product.
User list: (1) HomeView rebuild with streak ring + brand palette,
(2) CheckInView swipe stack, (3) Supabase live wiring, (4) daily 8pm
notifications, (5) 4-tab root.

**Added:**
- `Views/RootTabView.swift` — 4-tab root (Home · Check in · Learn ·
  Month). `@State selection: RootTab` passed down to HomeView +
  CheckInView so cards can switch tabs. Active tint `DS.accent`
  (`#7F77DD`). Wrapped in `GoldMindApp.swift` as the root scene,
  which also fires `NotificationService.requestPermission()` on
  launch.
- `Views/StreakRingView.swift` — coral 180pt circular ring with
  trimmed progress stroke (14pt, round cap), bold 56pt streak count
  in `DS.deepPurple`, and a labelled M–S dot row beneath. Animates
  `progress` and `streak` on change.
- `DS` brand palette: `DS.bg` `#F7F4EF`, `DS.deepPurple` `#2D1B69`,
  `DS.accent` `#7F77DD`, `DS.coral` `#FF7A6B`, `DS.teal` `#006064`.

**HomeView rebuild:**
- Background now `DS.bg`. Hero check-in card is a full-width
  `#2D1B69` rounded rectangle with white text and coral icon; tapping
  it switches the root tab to `.checkIn` via the new binding.
- Streak section now renders `StreakRingView` inside a white card
  with 0.5px `DS.accent`-tinted border. Streak message sits below.
- Alignment, log-event, and recent-activity rows all moved to the
  white-card-with-accent-border treatment (replaces the old
  `Card` container for these surfaces).
- `HomeViewModel` now tracks `weekDots: [Bool]` for Mon–Sun of the
  current ISO week, computed from `fetchRecentCheckIns(limit: 14)`.
- Removed the old `fullScreenCover` route into `CheckInView` —
  navigation to check-in is now the tab binding path.

**CheckInView:**
- Accepts optional `selectedTab: Binding<RootTab>?`. When embedded
  in the tab bar the xmark toolbar button is hidden and the "Done"
  button on the completion view switches back to `.home` instead of
  calling `dismiss()`. Standalone presentation still works via the
  `nil` branch.
- On completion (`currentIndex >= questions.count`) now calls
  `NotificationService.scheduleDailyReminder()` so the first
  successful check-in kicks off the 20:00 daily reminder cycle.

**Notifications:**
- `NotificationService.scheduleDailyReminder()` was already wired
  with a `UNCalendarNotificationTrigger` at `hour=20, minute=0,
  repeats: true` — verified, no change needed. Permission request
  now happens on app launch from `GoldMindApp.task`.

**Blocked / pending:**
- Supabase Swift package still needs to be added via Xcode UI
  (`File → Add Package Dependencies → supabase/supabase-swift`).
  Once present, `SupabaseService.swift` can be swapped from the
  in-memory stub to real `client.from(...)` calls. All view models
  already use the correct `async throws` surface.

**Build:**
- `** BUILD SUCCEEDED **` on iPhone 17 / iOS 26.2 after the full
  rebuild (single warning: AppIntents metadata skipped — unrelated).

---

## 2026-04-12 — UI/UX pass: design system + hero-first Home (Claude Code)

**Goal:** Turn Home from a generic vertical list of cards into a real
dashboard. Apply the same design language to Check-in and Money Event.
Remove the behavioural-UX foot-gun of showing a red 0% to a brand new
user who hasn't set an income target yet.

**Added:**
- `Views/DesignSystem.swift` — shared tokens (`DS.cardRadius`,
  `DS.hPadding`, `DS.sectionGap`), a reusable `Card` container,
  `PrimaryButtonStyle`, `SecondaryButtonStyle`, and `SectionHeader`
  with an optional trailing action. Every view now uses these so
  spacing + corners + button sizing are consistent.

**HomeView redesign:**
- Greeting header: "Good morning/afternoon/evening" + full date
  ("Sunday, 12 April"). Gear icon retained but greyed out (settings
  is out of beta scope).
- Hero check-in card — tappable full-width card that shows either
  the next question teaser ("Tap to check in") or, if already done,
  a "You showed up. See you tomorrow." + tone chip.
- Stats row — streak and alignment as side-by-side compact cards.
- **Alignment card is now context-aware**: if `incomeTarget == 0`
  it shows "Set target" as a call-to-action in blue (tap opens an
  income target editor alert) instead of a red 0%. This fixes the
  "no red without context" rule for brand-new users.
- `contentTransition(.numericText())` on streak + alignment so
  numbers animate when they change.
- "Log money event" is now a real full-width secondary button with
  a plus icon, not a text link.
- Recent activity section has a proper empty state card with a
  tray icon + nudge copy.
- "This month" → small inline chevron link at the bottom.
- `.sensoryFeedback(.success, trigger: isCheckedInToday)` for haptics
  on state change.

**CheckInView redesign:**
- Bigger typography on the question text, bias name in blue.
- "Why this matters" disclosure moved into the card, with a
  lightbulb icon. Still collapsed by default.
- Response field now has its own labelled sub-card.
- Tone picker: larger tap targets, spring animation on selection,
  selected state uses a blue border + tinted fill.
- Close affordance is a circular `xmark` button instead of a
  text "Close" toolbar item.
- Completion screen: big green circle + checkmark, "Nice work"
  headline, streak pill, `.sensoryFeedback(.success)`.

**MoneyEventView redesign:**
- Dropped `Form` for a scroll-view + custom cards layout.
- Amount hero card: huge rounded-display numeric input with a
  leading currency symbol.
- Type selector: 3 big cards with spring animation, same pattern as
  tone picker.
- Category pills: filled blue capsule for the selected state.
- Save button: full-width primary button with a checkmark icon.
- Haptic feedback on type + category selection.

**HomeViewModel:**
- Added `incomeTarget`, `isTargetSet`, `greeting`, `todayLabel`,
  `nextQuestionTeaser`, and a `saveTarget(_:)` async action for the
  alignment CTA.
- `alignmentColor` returns `.secondary` (not red) when no target
  is set.
- `alignmentReassurance` returns "Set a target to start tracking."
  when no target is set.

---

## 2026-04-12 — Fix blank white screen at launch (Claude Code)

**Problem:** App built and ran on iPhone 17 / iOS 26.2 simulator but
showed a fully white screen — no nav bar, no content.

**Likely cause:** iOS 26's `NavigationStack` at the root `WindowGroup`
was swallowing the `if/else` branch layout in `RootView`. Nothing was
rendering because the nav bar region + the scroll view's default
background were both white-on-white, with no visible bounds.

**Fix:**
- Removed the `RootView` wrapper struct. `GoldMindApp` now returns
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
previous run. Delete the GoldMind app from the simulator
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
- Full folder structure under `GoldMind/` matching the PRD layout
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
