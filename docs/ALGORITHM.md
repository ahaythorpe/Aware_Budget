# GoldMind Algorithm — Methodology

> A 1-pager for advisors, co-founders, partners, or future agents.
> Last updated: 2026-04-17

This document explains how the GoldMind bias-tagging and learning
loop works under the hood. It cites the literature each design choice
is grounded in and flags known limitations so the system can be
audited rather than trusted blind.

---

## 1. The 60-second summary

GoldMind helps users notice the behavioural-finance biases driving
their spending. The loop:

```
1. User logs a spend (Quick log)
   → algorithm tags it with the primary bias (and optionally a
     secondary from a different bias category) for that
     (category × planned_status), drawn from a citation-grounded
     shortlist (BiasMappings.swift) via BiasRotation.nextBiasPair.
     Max two tags per event (Pompian 2012, Klontz 2011 on
     bias co-occurrence)
2. After a logging session, the user reviews each tagged event
   → "Yes, that's me" / "Not sure" / "No, different reason"
3. Active confirmation feeds three downstream systems:
   a) bias_progress score (5× weight vs passive observation)
   b) per-mapping confirmation rate (algorithm self-audit)
   c) decision_lessons (banked "next time" lesson — Layers B + C)
4. Next time the user enters a similar context (e.g. Coffee tile),
   the banked lesson surfaces as a contextual hint (Layer B) or
   opt-in pre-spend checklist (Layer C).
```

The framework is the **BFAS** (Behavioural Finance Assessment Scale) —
Pompian (2012). The 16 biases come from there. Everything else is
how we operationalise that framework into a daily-use app.

---

## 2. The 16 biases

Sourced from BFAS (Pompian 2012). Each bias has:
- A foundational paper (in `NudgeVoice.researchCueFor`)
- A plain-English meaning (in `BiasLessonsMock`)
- A counter-move ("how to interrupt it")

| Bias | Foundational paper |
|---|---|
| Loss Aversion | Kahneman & Tversky 1979 |
| Present Bias | O'Donoghue & Rabin 1999 |
| Status Quo Bias | Samuelson & Zeckhauser 1988 |
| Anchoring | Tversky & Kahneman 1974 |
| Social Proof | Cialdini 2001 + Berger & Heath 2007 |
| Moral Licensing | Merritt et al. 2010 |
| Scarcity Heuristic | Cialdini 2001 |
| Sunk Cost Fallacy | Thaler 1980 + Arkes & Blumer 1985 |
| Ego Depletion | Baumeister 1998 + Vohs 2008 |
| Mental Accounting | Thaler 1985 |
| Overconfidence Bias | Barber & Odean 2001 |
| Framing Effect | Tversky & Kahneman 1981 |
| Availability Heuristic | Tversky & Kahneman 1973 |
| Ostrich Effect | Galai & Sade 2006 |
| Planning Fallacy | Buehler, Griffin & Ross 1994 |
| Denomination Effect | Raghubir & Srivastava 2009 |

---

## 3. Mapping: which bias fits which spend?

`Services/BiasMappings.swift` is the authoritative source. Each row is
a `(category, status, bias, citation, confidence)` tuple.

**Confidence flags:**
- `high` — direct experimental evidence in this purchase domain
  (e.g. Vohs 2008 measured decision fatigue in midday food choices →
  `high` for Lunch + Impulse).
- `medium` — bias mechanism extends here but the literature didn't
  test the specific category.
- `low` — plausible by inference; flagged for review.

Mappings without citations live in `BiasRotation.statusFallback` only —
status-level priors grounded in the bias construct, not category claims.

---

## 4. Rotation: each log probes a different bias

Without rotation, every "Coffee + Impulse" log would always tag the
same bias. With rotation, successive logs probe the 4–6 plausible
biases for that pattern in turn:

```
Log 1 → Ego Depletion       (rotation index 0)
Log 2 → Present Bias         (index 1)
Log 3 → Status Quo Bias      (index 2)
Log 4 → Moral Licensing      (index 3)
Log 5 → Social Proof         (index 4)
Log 6 → Ego Depletion        (loops)
```

Rotation index per `(category, status)` persists in UserDefaults so
it survives app restart. Implementation: `BiasRotation.nextBias`.

---

## 5. Neglected-bias boost (adaptive threshold)

If a bias hasn't been touched in N days AND it's in the current
shortlist, override the rotation pick with the most-neglected bias.
Guarantees rare biases (Denomination Effect, etc.) keep getting
probed instead of withering.

**Threshold scales with user log frequency:**

```
threshold_days = clamp(median_log_gap_days × 5, 14, 60)

Daily logger (gap = 1d):   max(14, min(60,   5)) → 14 days
Weekly logger (gap = 7d):  max(14, min(60,  35)) → 35 days
Monthly logger (gap = 30d): max(14, min(60, 150)) → 60 days (capped)
```

A daily logger and a once-a-week logger have very different "what
counts as neglect" windows. The threshold adapts.

Implementation: `BiasRotation.boostedPick` + `adaptiveThreshold`.

---

## 6. Scoring: active vs passive

The `bias_progress` score formula is **deliberately weighted 5:1 in
favour of active confirmation over passive observation**:

```
score = (YES × 5)        // user identified it — gold standard
      − (DIFFERENT × 2)  // active denial — meaningful negative signal
      + (NOT_SURE × 0)   // explicit no signal
      + (event tag × 1)  // passive observation — weak signal
      + (BFAS baseline)  // 0–10 one-time seed at signup
```

**Why 5:1 (not 1:1 or 2:1):**

- **Stone et al. 1991** (foundational experience-sampling): contextual
  self-report ~70–85% accurate vs passive observation ~30–50%.
- **Robinson & Clore 2002**: real-time prompted self-report (which
  Quick log + check-in IS) climbs to **85–95%** because retrospection
  bias hasn't kicked in.
- **Schwarz 2007**: outside observers attribute the wrong cause ~60%
  of the time without internal motivation. Only the actor knows what
  drove the choice.
- **Beck 1976** (CBT foundation): the act of self-labelling is itself
  intervention — YES is both diagnostic AND therapeutic.

So a 5:1 ratio is well within what the literature supports. Anything
less inverts the diagnostic hierarchy.

Implementation: `Services/BiasScoreService.swift`.

---

## 7. Self-audit: confirmation rate per mapping

Every review answer feeds a per-`(category × status × bias)`
confirmation rate. The algorithm grades itself:

```
confirmation_rate = YES / (YES + NOT_SURE + DIFFERENT)
```

If a mapping (e.g. "Ego Depletion on Coffee+Impulse") drops below
**30% confirmation after 20+ samples**, it gets flagged in
`AlgorithmExplainerSheet` for retirement.

**Storage:**
- Local UserDefaults (`MappingConfirmationStats.swift`) for fast
  read + offline safety.
- Supabase `bias_mapping_stats` table (per-user, RLS owner-only)
  for durability + cross-device.
- Supabase `bias_mapping_aggregate` view (anonymised, k-anonymity
  floor of 50 reviews per mapping) for cross-user research output.

This is the "industry deliverable" surface — once enough users
generate data, the aggregate view shows which mappings the global
data validates and which it rejects.

---

## 8. Layers B + C — turning insight into action

After "Yes, that's me," the lesson is banked into `decision_lessons`
with the bias's `howToCounter` pre-filled. Two delivery layers
surface it later:

### Layer B — pre-spend hint banner (Gollwitzer 1999)

When the user opens a category they've banked lessons for, a banner
appears above the range picker:

> *"LAST TIME · EGO DEPLETION
> Notice when you're tired and pre-decide what you'll order before
> walking in.
> [Helpful] [Dismiss]"*

This is **implementation intentions** — the most well-evidenced
behaviour-change technique for everyday consumer decisions. The
planned cue ("when I'm about to log Coffee") triggers the planned
response ("I check whether I'm tired first").

Outcomes recorded: `surfaced` / `useful` / `dismissed`.

### Layer C — decision helper checklist (Gawande 2009)

Long-press a category tile to open `DecisionHelperSheet` — top 3
banked lessons as tickable rows + "I'm ready — log it" CTA. Opt-in,
because checklists at every spend would create friction for casual
loggers.

This is **pre-decision checklists** — strong evidence in trained
domains (surgery, aviation per Gawande 2009). Behavioural finance is
arguably another such domain because the same biases repeat with
known cost.

Outcomes: ticked-then-confirmed = `useful`; surfaced-but-unticked =
`dismissed`. Lets us measure **whether the checklist actually changes
behaviour vs just feels good**.

---

## 9. The check-in loop (parallel to Quick log)

Two surfaces that feed `bias_progress`:

| Surface | Frequency | Active or passive? |
|---|---|---|
| Quick log | Voluntary, any time | Passive (event tag = +1) |
| Daily check-in | Once a day, ~30 sec | Active (YES = +5) |
| Sunday weekly review | Once per ISO week | Active |
| Monthly checkpoint | Once per month, **gated by 30-day install** | Active (re-asks YES'd biases) |

The 30-day install gate (`MonthlyReviewTracker`) prevents new users
from seeing "Monthly checkpoint" on day 1 — there's nothing to
checkpoint.

---

## 10. Known issues / watch items

### 10.1 Availability Heuristic over-assignment
Many `surprise`-status mappings default to Availability Heuristic
(it's the textbook bias for unexpected events — Tversky & Kahneman
1973). Result: users who log a lot of surprise-status events see
"Availability Heuristic" repeatedly and may feel the algorithm is
broken.

**Mitigation in place:**
- Sibling-bias hint surfaces when the same bias hits 3+ times in a
  session (`BiasReviewView.siblingBiasesHint`).
- Confirmation-rate self-audit will flag if real-world YES rate drops
  below 30% — at that point retire or refine the mapping.

**Watch:** monitor `bias_mapping_aggregate.confirmation_rate` for
Availability rows once 50+ users have generated data. If consistently
< 50%, broaden the surprise-status fallback to weight Planning
Fallacy / Loss Aversion / Ostrich Effect more.

### 10.2 Demo data vs real data ambiguity
Currently no flag separates real user logs from any seed data. If
seeded data ever ships with the app, add a `is_demo` boolean to
`money_events` so confirmation_rate isn't polluted.

### 10.3 Hand-curated shortlist
`BiasMappings.swift` is hand-curated, even with citations. Real
distribution of biases per (category × status) is an empirical
question — eventually replace prior probabilities with observed
posteriors from `bias_mapping_aggregate` once enough data accumulates.

### 10.4 Lesson decay
`decision_lessons` doesn't yet decay stale or low-usefulness lessons
in the surfacing rank. Without decay, old lessons crowd out new
realisations. Backlog: rank lessons by `(times_useful + 1) /
(times_surfaced + 1)` × recency, prune anything below threshold after
N surfacings.

### 10.5 Income/savings/investment — manual v1 shipped
The "behaviour change → financial outcome" loop needs the user to see
whether spending awareness translates to savings growth.

**v1 — shipped (manual entry, Privacy Act only):**
- `user_monthly_income` table — set-once monthly take-home
- `user_balance_snapshots` table — periodic savings + investment
  balance (one row per user per day, UPSERT on re-entry)
- Settings → "Net worth tracking" section to enter all three
- Insights → "Net worth trend" section showing the gold line
  (catmullRom interpolated, gradient area fill below) over the
  last 6 months

**v1.5 — shipped (this commit):**
- Awareness overlay on the trend chart — `decision_lessons.created_at`
  cumulative count plotted as a faint dashed green line on the same
  axis (normalised to net worth max so they read together).
- Trend insight Nudge above the chart — fires when there's enough
  data to compare last 30 days vs the prior 30. Three states:
  - Net worth up + awareness up → "The two move together"
  - Net worth up alone → "Keep noticing — the data is moving"
  - Awareness up alone → "Net worth hasn't moved yet — that's
    normal. Awareness comes first."

**Roadmap (still pending):**
- v2: aggregate via Basiq/Frollo (their CDR accreditation)
- v3: become CDR-accredited
- Per-bias trend overlay (currently aggregate awareness count)

---

## 11. References

- **Arkes, H. R., & Blumer, C.** (1985). The psychology of sunk cost. *Organizational Behavior and Human Decision Processes, 35(1), 124–140.*
- **Barber, B. M., & Odean, T.** (2001). Boys will be boys: Gender, overconfidence, and common stock investment. *Quarterly Journal of Economics, 116(1), 261–292.*
- **Baumeister, R. F., et al.** (1998). Ego depletion: Is the active self a limited resource? *Journal of Personality and Social Psychology, 74(5), 1252–1265.*
- **Beck, A. T.** (1976). *Cognitive Therapy and the Emotional Disorders*. International Universities Press.
- **Berger, J., & Heath, C.** (2007). Where consumers diverge from others: Identity signaling and product domains. *Journal of Consumer Research, 34(2), 121–134.*
- **Buehler, R., Griffin, D., & Ross, M.** (1994). Exploring the planning fallacy. *Journal of Personality and Social Psychology, 67(3), 366–381.*
- **Cialdini, R. B.** (2001). *Influence: Science and Practice* (4th ed.). Allyn & Bacon.
- **Galai, D., & Sade, O.** (2006). The "ostrich effect" and the relationship between the liquidity and the yields of financial assets. *Journal of Business, 79(5), 2741–2759.*
- **Gawande, A.** (2009). *The Checklist Manifesto: How to Get Things Right*. Metropolitan Books.
- **Gollwitzer, P. M.** (1999). Implementation intentions: Strong effects of simple plans. *American Psychologist, 54(7), 493–503.*
- **Hektner, J. M., Schmidt, J. A., & Csikszentmihalyi, M.** (2007). *Experience Sampling Method: Measuring the Quality of Everyday Life*. Sage.
- **Kahneman, D., & Tversky, A.** (1979). Prospect theory. *Econometrica, 47(2), 263–291.*
- **Merritt, A. C., Effron, D. A., & Monin, B.** (2010). Moral self-licensing. *Social and Personality Psychology Compass, 4(5), 344–357.*
- **O'Donoghue, T., & Rabin, M.** (1999). Doing it now or later. *American Economic Review, 89(1), 103–124.*
- **Pompian, M. M.** (2012). *Behavioral Finance and Wealth Management* (2nd ed.). Wiley.
- **Raghubir, P., & Srivastava, J.** (2009). The denomination effect. *Journal of Consumer Research, 36(4), 701–713.*
- **Robinson, M. D., & Clore, G. L.** (2002). Belief and feeling: Evidence for an accessibility model of emotional self-report. *Psychological Bulletin, 128(6), 934–960.*
- **Samuelson, W., & Zeckhauser, R.** (1988). Status quo bias in decision making. *Journal of Risk and Uncertainty, 1(1), 7–59.*
- **Schwarz, N.** (2007). Attitude construction: Evaluation in context. *Social Cognition, 25(5), 638–656.*
- **Stone, A. A., et al.** (1991). Self-report in real time. *Journal of Personality and Social Psychology, 60(4), 575–591.*
- **Thaler, R.** (1980). Toward a positive theory of consumer choice. *Journal of Economic Behavior and Organization, 1(1), 39–60.*
- **Thaler, R.** (1985). Mental accounting and consumer choice. *Marketing Science, 4(3), 199–214.*
- **Tversky, A., & Kahneman, D.** (1973). Availability: A heuristic for judging frequency and probability. *Cognitive Psychology, 5(2), 207–232.*
- **Tversky, A., & Kahneman, D.** (1974). Judgment under uncertainty: Heuristics and biases. *Science, 185(4157), 1124–1131.*
- **Tversky, A., & Kahneman, D.** (1981). The framing of decisions and the psychology of choice. *Science, 211(4481), 453–458.*
- **Della Vigna, S., & Malmendier, U.** (2006). Paying not to go to the gym. *American Economic Review, 96(3), 694–719.*
- **Vohs, K. D., et al.** (2008). Making choices impairs subsequent self-control. *Journal of Personality and Social Psychology, 94(5), 883–898.*
- **Wood, W., & Neal, D. T.** (2007). A new look at habits and the habit-goal interface. *Psychological Review, 114(4), 843–863.*
