# v1.1 plan — interactive charts + concept graphs

> Captured 2026-05-12 ahead of v1.0 submission. These are post-launch features Bella explicitly scoped tonight but agreed are NOT blockers for tomorrow's Apple submission.

---

## #32 — Interactive charts (port CompoundGrowthCard pattern)

**Reference implementation:** `Views/Insights/CompoundGrowthCard.swift` (304 lines).

What makes it good (the pattern to lift):
- **Range chips** at the top (5yr / 10yr / 20yr / 30yr) — instant horizon switch.
- **Two-thumb drag-to-zoom slider** beneath the chart — narrow the window without leaving the card.
- **Visible-points filter** computed from slider state — the chart re-renders to the zoomed window.
- **Bottom stat row** that updates as the zoom changes — In yr 10 / You put in / Growth.
- **Reset button** when zoomed.

### Target charts to upgrade

In priority order (each gains the same interaction surface):

1. **`biasTrendChart`** (InsightFeedView ~line 681) — bias spending over weeks. Most useful trend; user should be able to scrub.
2. **`categoryTrendSection`** (InsightFeedView ~line 1346) — category spending over weeks.
3. **`netWorthTrendSection`** — net worth + awareness overlay. Already partially interactive.
4. **`financialTrendChart`** — monthly bars; range chips would be 3mo/6mo/1yr.

### Extraction strategy

Rather than porting per-chart, extract a reusable view:

```swift
struct InteractiveTrendCard<Point: TimeSeriesPoint, Content: View>: View {
    let title: String
    let subtitle: String
    let points: [Point]
    let rangeOptions: [Int]
    let unit: String          // "yr" / "wk" / "mo"
    let bottomStats: ([Point]) -> AnyView
    let chartContent: ([Point]) -> Content
    // ...range chip + zoom slider state owned here
}

protocol TimeSeriesPoint {
    associatedtype XValue: Comparable
    var x: XValue { get }
}
```

Each call site provides its own Chart content + bottomStats. Range/zoom/reset are reused.

### Scope estimate

- Extract `InteractiveTrendCard`: ~3 hours (state machine + slider math).
- Migrate biasTrendChart + categoryTrendSection: ~1 hour each.
- Polish + test: ~1 hour.
- **Total: 6-8 hours.** Not a tomorrow-night task.

### Open design Qs (Bella to decide)

- Range chips per chart — what's the right horizon for bias trend (4wk / 12wk / 26wk)?
- Should the bottom stat row show the same three columns everywhere, or per-chart relevant stats?
- Reset behaviour — does each chart remember its zoom across tab switches?

---

## #30 — Concept graphs in Education tab

Bella's note (2026-05-12): the Research tab bias cards are "chunky and not as well designed as the rest of the app". Concept graphs are the v1.1 evolution.

### What "concept graph" probably means here

Three flavours, ranked by ambition:

**A. Zoomable cluster view (low effort).** Take the existing 6-lane mind map and add concept-clustering. Lanes group not by personality archetype but by behavioural-finance concept (decision-making / loss-avoidance / time-perception / social-proof). Same nodes, different lanes. Probably 1 day's work.

**B. Force-directed network (medium effort).** Replace the lane-grid layout with a SwiftUI Canvas-driven force-directed graph. Biases pull together along the BiasRelationships edges, repel based on category distance. Tap a node → it becomes the centre, others orbit. Probably 2-3 days.

**C. Concept layers / drill-down (high effort).** Surface → Concept → Bias → Detail. User starts at "Why we spend the way we do" (4-6 high-level concepts). Tap a concept → see the biases inside it. Tap a bias → current sheet. New navigation paradigm. Probably 4-5 days.

### My recommendation

**Path A.** Reuses the existing mind map. Adds a "Layout: personality / concept" toggle in the canvas header. Minimal architectural risk, clear v1.1 win, doesn't compete with the more thoughtful path C if Bella later wants it.

### Open design Qs (Bella to decide)

- Personality view stays the default, or concept view does?
- Are the 6 concept clusters defined yet? (If not, I'd suggest: Avoidance / Decision Friction / Time Trade-offs / Social Pull / Defaults & Inertia / Mental Accounting — broadly aligned with the existing BFAS categories.)
- Should clusters be tappable to drill in, or static-context-only?

### Today-now: Research tab bias cards redesign

Separate from the concept-graphs work, the immediate fix Bella saw on Build 21 is the chunky bias-card list on Research. Same DisclosureGroup-by-category pattern that landed on Insights spending-by-bias (`945fe0f`) applied here:

- One card per BFAS category.
- Tap a category to expand the biases inside.
- HOW TO SPOT IT + HOW TO OVERCOME IT collapsed to a single "Why it fits / What to do" subhead per bias (currently doubles vertical space).

This **is** a tonight job — straightforward port of the Insights pattern. Logged as #33 if it doesn't make tonight's cut.

---

## #33 — Research tab: more text + more interactivity

Bella's note (2026-05-12 evening): the category-grouped Research tab (`e74859d`) is a good start, but the bias cards inside need richer content + interactive elements. Currently each card shows `shortDescription` + `howToCounter` only.

### Unused content already in `BiasLessonsMock`

The `BiasLesson` model carries four text fields. The Research tab only uses two:

| Field | Used? | Length |
|---|---|---|
| `shortDescription` | ✓ HOW TO SPOT IT | one sentence |
| `fullExplanation` | ✗ unused on Research | two to three sentences |
| `realWorldExample` | ✗ unused on Research (used in Mind-Map node sheet) | scenario, two to three sentences |
| `howToCounter` | ✓ HOW TO OVERCOME IT | two to four sentences |

**Low-effort v1.1 win:** surface `fullExplanation` + `realWorldExample` on the Research card. Either expanded by default (more text on first read) or as a "Read more" disclosure.

### Interactivity ideas (ranked low → high effort)

1. **Personal trigger count chip** per bias card. Reuses `viewModel.biasProgress` from the existing data path. One line: "Seen N× in your logs." Same chip pattern already used on the mind-map node sheet.
2. **Mastery stage badge** (Unseen / Noticed / Emerging / Active / Aware) drawn from `bias_progress.stage`. Compact pill in the card header.
3. **"Mark as understood" toggle** writes to `bias_progress` as a passive awareness signal. Adds +1 to that bias (same weight as a logged spend).
4. **Tap-to-open detail sheet** that reuses the Mind-Map node sheet (already has stat chip, Nudge quote, counter bullets, real-example disclosure, related-pattern chips). Avoids building a second detail UI.
5. **Mini-quiz card** per bias — one multiple-choice question (e.g. "Which of these is anchoring?"). Confirms understanding without requiring a check-in.
6. **Filter bar** at top of Research: All / My top 3 / Triggered / Untouched — same chip pattern as the mind-map filter.
7. **Search bar** for finding a specific bias by name.

### My recommendation

Tonight = nothing. Submit v1.0 with the category grouping that's already in.

Post-launch v1.1 sequence (1-2 days total):
- Day 1: Surface `fullExplanation` + `realWorldExample` (idea 0). Add trigger-count chip + mastery badge (ideas 1+2). Wire the existing Mind-Map node sheet as the tap-to-open detail (idea 4) — no new view to build.
- Day 2: Filter bar (idea 6) + search (idea 7) if usage data shows the list-scrolling problem hasn't fixed itself.

Skip mini-quiz + mark-as-understood until there's signal that users want them. Those add complexity (state, write paths, scoring decisions) that don't pay back until v2.

---

## #34 — Research-tab concept graph (papers ↔ biases)

Bella's note (2026-05-13 morning): apply the concept-graph idea from #30 to the Research tab itself, not just the Mind Map. Make the research → bias relationship visual + interactive so the tab teaches the framework rather than just listing it.

### What it is

A node-edge graph showing how the **foundational papers** connect to the **16 biases** they underpin. Three layers:

1. **Paper nodes** at the top (Pompian 2012, Kahneman & Tversky 1979, Thaler & Sunstein 2008, Kahneman et al. 2004, plus Klontz / Cialdini / Samuelson & Zeckhauser / Baumeister where they're load-bearing).
2. **Framework node** in the middle (BFAS · 16 patterns · 6 spending personalities).
3. **Bias nodes** at the bottom (the 16 we already render), already coloured by their BFAS category.

Edges connect:
- Paper → bias (each paper introduces or formalises specific biases — Kahneman & Tversky 1979 → Loss Aversion, Anchoring; Samuelson & Zeckhauser 1988 → Status Quo Bias; etc.).
- Framework → all 6 categories.

### Interactivity

- **Tap a paper:** all biases it underpins glow gold; unrelated biases dim to 0.18 (same dim treatment as the existing Mind Map).
- **Tap a bias:** the paper(s) it traces to glow; the bias's BFAS category lights up on the framework node.
- **Tap an edge:** short Nudge card pops with the citation context — "Loss aversion: Kahneman & Tversky (1979) showed losses feel ~2× worse than equivalent gains. Established Prospect Theory."
- **Zoom / scroll:** the graph is wider than the screen at default zoom — drag-to-zoom and pinch-to-explore similar to the Mind Map.

### Data layer

No new schema. The mapping data lives in two new static dictionaries:

```swift
enum ResearchGraph {
    /// Bias name → primary source citation key. Used by the Research
    /// graph to light up the founding paper when a bias is tapped.
    static let primaryPaper: [String: String] = [
        "Loss Aversion":          "kahneman_tversky_1979",
        "Anchoring":              "kahneman_tversky_1974",
        "Status Quo Bias":        "samuelson_zeckhauser_1988",
        "Mental Accounting":      "thaler_1985",
        "Present Bias":           "laibson_1997",
        // ... 16 total
    ]
    /// Paper key → list of biases it introduces or formalises.
    static let papersToBiases: [String: [String]] = [
        "pompian_2012":          [/* all 16, framework-level */],
        "kahneman_tversky_1979": ["Loss Aversion", "Sunk Cost Fallacy"],
        // ...
    ]
}
```

Most of this data is already inline in `BiasData.keyRef` and `BiasData.citation`. Refactor those into a structured lookup so the graph can render edges without duplicating the citation text.

### Effort estimate

- Static data extraction: ~2 hours (already in `BiasData`, just needs reshaping).
- Force-directed or layered layout via SwiftUI `Canvas` (similar pattern to `MindMapView`): ~6-8 hours.
- Tap-to-highlight + dim-others: ~2 hours (reuses `MindMapView.isInFocus` pattern).
- Edge tap → Nudge card: ~1 hour.
- **Total: 11-13 hours.** Solid v1.1 day or v1.2 polish week.

### My recommendation

Build after #30 Path A (concept-cluster Mind Map toggle) ships. They share the layout engine, so doing them in sequence amortises the SwiftUI Canvas work. Skip until users have proven they care about deeper research context; ship interactive-charts (#32) first since the demand is clearer.

---

## #36 — Programmatic bias illustrations (v1.1)

v1.0 shipped a Kahneman value-function S-curve inside the Loss Aversion bias detail sheet (see `Views/LossAversionChart.swift`). Bella's call: lean MVP, no paid integrations, render charts in SwiftUI Charts directly.

Extend the same pattern to the 4 other biases with clean math shapes:

- **Present Bias** — hyperbolic discounting curve. v(t) = 1 / (1 + kt) where k ≈ 0.5. Show how a $110 reward in 1 year discounts harder than a $110 reward in 1 week. ~30 min.
- **Anchoring** — bar chart pair: "no anchor" estimate vs "high anchor" estimate, illustrating how the anchor pulls answers upward. ~30 min.
- **Planning Fallacy** — actual cost / estimated cost ratio. Show the typical 30-50% overrun. ~30 min.
- **Mental Accounting** — split-jar visualisation showing how "tax refund" vs "salary" labels change spending freedom. Conceptual — could be a custom shape. ~45 min.
- **Overconfidence** — calibration curve (predicted vs actual). ~30 min.

Other biases (Social Proof, Status Quo, Moral Licensing) don't have clean mathematical shapes; would need illustrations (Path B from #35).

**Total v1.1 effort: ~3 hours for 5 charts.** Ship in the same v1.1 update as #35.

---

## #37 — End-of-week bias check-in (v2)

Bella's idea (2026-05-13): a Sunday-evening prompt asking "Which of these patterns showed up for you this week?" with yes/no per bias the user encountered most. Closes the loop between the algorithm's tagging and the user's lived experience.

### Flow

- Trigger: Sunday 7pm push (or first Home open after Saturday).
- Surface: full-screen sheet, similar to daily check-in.
- Content: top 3 most-frequent tagged biases from the week's events.
- Per bias: "Yes, that's me" / "No, different reason" / "Not sure".
- Outcome: feeds the +5/−2/0 weighted score (same as daily check-in answer scoring).
- Nudge close: short summary card on what changed in their awareness profile.

### Why v2 not v1.0

- New scheduled push surface (Sunday slot).
- New scoring path (batch confirmation instead of single).
- New review UI (similar to but distinct from BiasReviewView).
- Adds load to the algorithm path that's already shipped for v1.0.
- Bella explicitly scoped v1 as "enough value, lean MVP".

### Cost note

No external integrations needed. All UI + backend logic. First *paid* external integration the project takes on will be an AI advisory assistant — that's a future v2/v3 line item, not on tonight's roadmap.

---

## #35 — Concept graphs on Education tab (v1.1)

v1.0 shipped a lightweight `ResearchMapView` (chip layout, tap-to-highlight, no force-directed edges) on both Education and Research tabs. Bella greenlit the chip version for v1.0; the richer treatment is post-launch.

Three richer paths (escalating ambition):

**Path A — Canvas edges** *(~6h)*
Keep the chip layout but draw actual lines between paper chips and their underpinning bias chips using SwiftUI `Canvas` + a `PreferenceKey`-based position-capture pass. Lines fade dimmed nodes. No layout change.

**Path B — Force-directed cluster layout** *(~12-14h)*
Replace the static layered layout with a SwiftUI `Canvas`-driven force-directed graph. Biases pull together along `BiasRelationships` edges, repel based on `biasCategory` distance, drift toward their underpinning paper. Tap a node → it becomes the centre, others orbit. Visually striking but math-heavy.

**Path C — Concept-layer drill-down** *(~3-5 days)*
New top-level paradigm. Surface → Concept Cluster → Bias → Detail. User starts at 4-6 high-level concepts ("Why we spend the way we do") and drills in. Different mental model than the chip map.

### Recommendation

Path A first, ship in v1.1. The chip map already conveys the relationships; lines just make it look more graph-like. Defer Path B/C until usage data shows the chip version isn't enough.

---

## Status as of 2026-05-12

- v1.0 submission to Apple targeted for tomorrow.
- v1.1 plan above. Implementation lands post-launch.
- Open items still on tonight's list: bias-card accuracy audit (remaining 14 nudgeSays), Research tab card redesign, multi-bias UI layer (BiasReviewView + MoneyEventView display), AlgorithmExplainerSheet rewrite, paywall link verification.
