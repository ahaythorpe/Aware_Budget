# Plan — Bias illustrations + Headspace-style animations

> Captured 2026-05-13. Bella's vision: every bias has a visual that explains the concept, eventually animated.
> v1.0 shipped 6 programmatic SwiftUI Charts (`Views/BiasIllustrations.swift`). This doc plans v1.1 (all 16 illustrated) and v2 (animated).

---

## What "Headspace-style" actually means

Headspace's onboarding animations are made in **After Effects** (the industry standard for character + motion graphics), then exported via **Lottie** — Airbnb's open-source library that renders After Effects animations as lightweight JSON files in any framework, including SwiftUI.

Three-layer architecture:
1. **Designer** draws frames in Figma / Illustrator / Procreate.
2. **Animator** rigs the artwork in After Effects, adds keyframes, exports via the **Bodymovin** plugin to a `.json` file.
3. **Engineer** drops the .json into the app + plays it with the Lottie library.

The library itself is **free**. Cost is in the artwork + animation labour.

---

## v1.0 → v1.1 → v2 path

### v1.0 (shipped Build 28)

Six programmatic SwiftUI Charts inside `Views/BiasIllustrations.swift` for the biases with clean math shapes:

| Bias | Visualisation |
|---|---|
| Loss Aversion | Kahneman & Tversky value-function S-curve |
| Present Bias | Hyperbolic discount curve (1/(1+kt)) |
| Anchoring | No-anchor vs high-anchor bar pair |
| Planning Fallacy | Estimate vs actual cost bars |
| Mental Accounting | Refund-jar vs salary-jar bars |
| Overconfidence | Confidence-vs-accuracy calibration curve |

Zero external dependencies. Renders inline on the mind-map node sheet AND inside the Research overcome cards. **All free.**

### v1.1 — Static illustrations for the other 10 biases (cost: ~A$50-200/bias)

Biases that don't have a clean math shape and need an artist's hand:

| Bias | Suggested visualisation |
|---|---|
| Ostrich Effect | Person turned away from a glowing screen (bills); head-in-sand metaphor |
| Sunk Cost Fallacy | Money pouring into a leaking jar; the jar gets fuller despite the leak |
| Ego Depletion | A battery icon draining across morning → evening |
| Availability Heuristic | A scale tipping toward the brightest/loudest data point |
| Denomination Effect | A $100 note next to five $20 notes — the stack feels "lighter" |
| Framing Effect | The same glass labelled "half full" vs "half empty" |
| Social Proof | Crowd of identical figures, one looking sideways |
| Bandwagon Effect | Train pulling away, last-minute jumpers piling on |
| Status Quo Bias | A path worn through grass — the easier route, even when overgrown |
| Moral Licensing | A green tick on one decision unlocking a red cross on the next |

**Production options:**
1. **Bella designs in Procreate / Figma** — free if you have the time; ~30-60 min per illustration.
2. **Fiverr / Upwork illustrator** — typically A$30-80 per simple flat illustration. Find one designer with a consistent style; commission all 10 in one batch (~A$300-800 total).
3. **Stock illustrations** (unDraw, Freepik Pro) — fast + cheap but won't match the GoldMind aesthetic.

**Asset pipeline:** PNG @ 3x (or SVG/PDF) into `Assets.xcassets`. Render via `Image("ostrich_effect")` inside `BiasIllustrations.swift`, swapping the chart for the image on those 10 biases.

### v2 — Animate the illustrations via Lottie (cost: ~A$100-500/bias)

Once Bella has the static illustrations and they feel right, the same designer (or a separate motion designer) animates them.

**Pipeline:**
1. Designer hands After Effects file with the static illustration layered.
2. Motion designer rigs keyframes — e.g. the leaking jar drips, the head-in-sand pose lifts up, the battery drains.
3. Export to `.json` via **Bodymovin** (free After Effects plugin).
4. `.json` lives in `Assets.xcassets`.
5. App uses **lottie-ios** (Airbnb's SwiftUI-compatible package) to play the animation.

**Adding lottie-ios:**
- Swift Package Manager: `https://github.com/airbnb/lottie-spm` (no version pin needed; lottie-ios is mature).
- Free, MIT-licensed.

**Render call (after package added):**
```swift
import Lottie

struct AnimatedBiasIllustration: View {
    let asset: String  // "ostrich_effect"
    var body: some View {
        LottieView(animation: .named(asset))
            .playing(loopMode: .loop)
            .frame(height: 220)
    }
}
```

**Cost estimate:**
- Per-bias animation: A$100-500 depending on complexity (10-30 second loops).
- 10 biases × ~A$200 average = ~A$2000 total for the v2 animation upgrade.
- Bella's existing static illustrations are the input — animator doesn't re-design.

---

## Cost-conscious sequencing (Bella's "lean MVP" + "first paid integration is AI advisor" stance)

1. **Now (v1.0):** ship Build 28 with the 6 free SwiftUI charts. Done.
2. **v1.1 (post-launch, weeks 1-4):** Bella illustrates the remaining 10 herself (Procreate hours, no cash spend). Ships in v1.1 update.
3. **v2 (months 2-6):** when there's user signal that illustrations are loved and animations would unlock more time-on-app, commission animation work for the most-viewed biases first. Don't animate all 10 at once — start with the top 3 by usage.
4. **AI advisor (later):** the first PAID external integration is the AI advisor (Bella's roadmap). Lottie library + commissioned art are *one-off* spends, not ongoing integrations, so they don't conflict with the "no paid integrations" rule.

---

## Anti-pattern to avoid

**Don't pay a SaaS animation platform** (Rive Pro, LottieFiles team plans, etc.) until v2+ — the open-source Lottie reader is enough. Designer/animator labour is the real spend.

**Don't generate animations with AI image tools** for v1.0/v1.1 — quality is still patchy + Apple's review team has been flagging clearly AI-generated content. Hand-drawn or commissioned art only.

---

## Status

- v1.0 illustrations: **6 of 16 shipped** (Build 28)
- v1.1 plan: **10 more static illustrations**, to be designed by Bella or commissioned
- v2 plan: **animate via Lottie + lottie-ios SPM**, commission motion work
