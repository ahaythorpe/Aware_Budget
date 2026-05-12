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

## Status as of 2026-05-12

- v1.0 submission to Apple targeted for tomorrow.
- v1.1 plan above. Implementation lands post-launch.
- Open items still on tonight's list: bias-card accuracy audit (remaining 14 nudgeSays), Research tab card redesign, multi-bias UI layer (BiasReviewView + MoneyEventView display), AlgorithmExplainerSheet rewrite, paywall link verification.
