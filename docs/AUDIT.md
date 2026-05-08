# AUDIT — Bias Citation & Name Validation

> Generated 2026-04-20. No fixes applied — report only.

---

## CRITICAL: BiasData.swift out of sync with canonical 16

BiasData.swift has 14 biases with 2 wrong entries. BiasLessonsMock.swift has the correct 16.

| Issue | File | Detail |
|-------|------|--------|
| "Social Comparison" should be "Social Proof" | BiasData.swift | Uses Festinger 1954 — not BFAS |
| "Herding" should be "Scarcity Heuristic" | BiasData.swift | Uses Banerjee 1992 — not BFAS |
| Scarcity Heuristic missing entirely | BiasData.swift | Present in all other files |

---

## CITATION MISMATCHES

### 1. Planning Fallacy — WRONG PAPER in BiasData.swift

```
File: GoldMind/Services/BiasData.swift
Line: 163-165
Current: "Kahneman, D. & Tversky, A. (1979). Intuitive Prediction..."
Correct: "Buehler, R., Griffin, D. & Ross, M. (1994). Exploring the Planning Fallacy. JPSP, 67(3), 366-381."
Reason: K&T 1979 is Prospect Theory (Loss Aversion). Planning Fallacy foundational paper is Buehler et al. 1994. ALGORITHM.md already uses the correct one.
```

### 2. Moral Licensing — THREE DIFFERENT PAPERS across files

```
File: GoldMind/Services/BiasLessonsMock.swift:179
Current: Monin & Miller 2001
Status: CORRECT (seminal paper) — use this everywhere

File: GoldMind/Services/BiasData.swift:213
Current: Khan & Dhar 2006
Correct: Monin & Miller 2001
Reason: Khan & Dhar is consumer choice specific; Monin & Miller is the foundational work

File: GoldMind/Services/NudgeVoice.swift:156
Current: Merritt et al. 2010
Correct: Monin & Miller 2001
Reason: Merritt is a review article, not the original research
```

### 3. Overconfidence Bias — TWO DIFFERENT PAPERS

```
File: GoldMind/Services/NudgeVoice.swift:166
Current: Barber & Odean 2001
Status: Correct for financial context

File: GoldMind/Services/BiasData.swift:84
Current: Svenson 1981
Correct: Barber & Odean 2001
Reason: Svenson is about driving confidence, not finance. Barber & Odean is the financial overconfidence paper.
```

### 4. AwarenessView.swift — Cialdini edition year

```
File: GoldMind/Views/AwarenessView.swift
Line: 37
Current: "Cialdini 1984 · Influence"
Correct: "Cialdini 2001 · Influence" (preferred edition) OR keep 1984 (first edition — technically valid)
Reason: Minor — both editions exist. 2001 is the expanded 4th edition most commonly cited in academic work.
```

---

## ALL 16 BIASES — CROSS-FILE CONSISTENCY CHECK

| # | Bias | BiasLessonsMock | BiasData | BFASQuestion | QuestionPool | NudgeVoice | BiasMappings |
|---|------|-----------------|----------|--------------|--------------|------------|-------------|
| 1 | Ostrich Effect | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 2 | Loss Aversion | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3 | Anchoring | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 4 | Sunk Cost Fallacy | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 5 | Overconfidence Bias | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 6 | Ego Depletion | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 7 | Availability Heuristic | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 8 | Mental Accounting | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 9 | Denomination Effect | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 10 | Framing Effect | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 11 | Present Bias | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 12 | Planning Fallacy | ✅ | ❌ wrong cite | ✅ | ✅ | ✅ | ✅ |
| 13 | Social Proof | ✅ | ❌ "Social Comparison" | ✅ | ✅ | ✅ | ✅ |
| 14 | Scarcity Heuristic | ✅ | ❌ MISSING | ✅ | ✅ | ✅ | ✅ |
| 15 | Moral Licensing | ✅ | ✅ | ✅ | ✅ | ⚠️ diff paper | ✅ |
| 16 | Status Quo Bias | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## VERIFIED CORRECT CITATIONS (no action needed)

| Bias | Citation | Status |
|------|----------|--------|
| Loss Aversion | Kahneman & Tversky 1979, Prospect Theory | ✅ |
| Anchoring | Tversky & Kahneman 1974, Heuristics & Biases | ✅ |
| Availability Heuristic | Tversky & Kahneman 1973 | ✅ |
| Framing Effect | Tversky & Kahneman 1981 | ✅ |
| Mental Accounting | Thaler 1985 | ✅ |
| Sunk Cost Fallacy | Thaler 1980 | ✅ |
| Status Quo Bias | Samuelson & Zeckhauser 1988 | ✅ |
| Ego Depletion | Baumeister 1998 + Vohs 2008 | ✅ |
| Ostrich Effect | Galai & Sade 2006 | ✅ |
| Denomination Effect | Raghubir & Srivastava 2009 | ✅ |
| Present Bias | O'Donoghue & Rabin 1999 / Laibson 1997 | ✅ both valid |
| Scarcity Heuristic | Cialdini 2001 | ✅ |
| Social Proof | Cialdini 2001 + Berger & Heath 2007 | ✅ |

---

## ALGORITHM.MD REFERENCES — ALL CORRECT

The ~25 references in docs/ALGORITHM.md are properly formatted with authors, years, journals, volumes, and page numbers. No issues found.

---

## RECOMMENDED FIX ORDER

1. **BiasData.swift** — Replace Social Comparison/Herding with Social Proof/Scarcity Heuristic
2. **BiasData.swift** — Fix Planning Fallacy citation to Buehler et al. 1994
3. **NudgeVoice.swift** — Standardize Moral Licensing to Monin & Miller 2001
4. **BiasData.swift** — Standardize Overconfidence to Barber & Odean 2001
5. **AwarenessView.swift** — Optional: update Cialdini 1984 → 2001
