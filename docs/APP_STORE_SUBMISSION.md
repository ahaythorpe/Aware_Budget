# App Store submission — step-by-step

> Last updated: 2026-05-12
> Target build: 23 (or whatever's latest on TestFlight when you submit)
> All answers prefilled where possible — anything in **[brackets]** needs your decision.

---

## Screenshots (captured 2026-05-13)

Four canonical screenshots live in `docs/screenshots/`:

| File | What | Notes |
|---|---|---|
| `01-insights.png` | Insights top — "$156 from future you" / END-OF-WEEK REVIEW card / FINANCIAL OVERVIEW grouped | Text-heavy; **skip in favour of #2** for the App Store listing |
| `02-insights-with-graph.png` | Insights scrolled — BIGGEST SPEND / MONTHLY TREND bar chart / Nudge card | **Use this for Insights** — Bella's call: more visually appealing |
| `03-education.png` | Education — "Your money mind" hero, AWARENESS SCORE bar (1/16), Take the Money Mind Quiz, Explore the bias map, 6 personalities | Note: previous "Awareness" tab is now "Education" |
| `04-research.png` | Research — hero, THE MAIN PAPERS (Pompian / Kahneman & Tversky / Thaler & Sunstein) | Final tab |

Still need to capture for a complete 8-shot set:
- Home (greeting card + DAY STREAK + 25% patterns identified)
- Home future-you compound-growth chart
- Log tab mid-flow (picking category + status)
- Mind map node sheet with Loss Aversion S-curve (the wow moment)

When captured, drop into `docs/screenshots/` named `00-home.png`, `01b-home-chart.png`, `02b-log-flow.png`, `04b-mindmap-s-curve.png` to keep the ordering.

---

## ⚠️ Pre-submit verification — RevenueCat pricing tiers

Bella's note 2026-05-13: the second and third RevenueCat tiers may only show the discounted price, RevCat may not have the updated prices. **Before submitting**, verify in the RevenueCat dashboard:

1. https://app.revenuecat.com → Project → Products
2. Confirm each product's **price** matches what you want shown in the App Store paywall:
   - Annual — should be the full price (with the 7-day trial as a separate metadata field, not part of the price)
   - Lifetime — full one-time price
   - Monthly — full subscription price
3. If RevenueCat is showing the discounted price as the headline price, fix in the RevenueCat product config OR in the App Store Connect Subscription pricing.

The local `GoldMind.storekit` file (used only for sim/test) currently has Annual $99.99 / Lifetime $149.99 / Monthly $9.99. Adjust those to match the live RevenueCat config so sim test purchases stay consistent.

---

## 0. Before you start

Make sure these are done first (off-app):

- [ ] **Marketing site privacy + terms updates pushed live** (see below for required text)
- [ ] **Build 23 has finished Apple processing** on TestFlight (check App Store Connect → TestFlight → iOS Builds)
- [ ] **You've personally tested Build 23 on your phone** against `docs/TESTING_BUILD_22.md` + the compound-growth chart on Home

---

## 1. Marketing site text updates (DO FIRST)

These are required for the App Privacy questionnaire (step 5) to match the live policies. Apple cross-checks.

### `mygoldmind.vercel.app/privacy`

Add this section (or merge into existing) listing third-party data processors:

```
GoldMind uses the following services to deliver the app:

- Supabase (Sydney, Australia) — stores your account, check-ins,
  money events, and bias progress on AWS infrastructure within
  Australia. We do not sell or share this data.

- RevenueCat — processes your subscription status. RevenueCat
  receives your in-app-purchase receipt and your anonymous user
  ID. No personally-identifying data is shared.

- Apple Sign In — your Apple ID stays private; we only receive
  the email you choose to share.

You can request deletion of your account and all associated data
at any time via Settings > Delete Account, which permanently
removes your data from Supabase.
```

### `mygoldmind.vercel.app/terms`

- [ ] Remove the line "Working draft, formal review pending" if it's still in the header
- [ ] Add this clause to the Refunds section:

```
In-app subscription refunds are processed by Apple via
reportaproblem.apple.com. GoldMind cannot directly issue refunds
for App Store purchases. For non-IAP issues, email ahaythorpe@gmail.com.
```

---

## 2. On-device paywall verification

Open Build 23 on your phone:

- [ ] Trigger paywall (Settings > Subscription, or new account flow)
- [ ] Tap **Terms** → opens `mygoldmind.vercel.app/terms` in Safari, no 404
- [ ] Tap **Privacy** → opens `mygoldmind.vercel.app/privacy` in Safari, no 404
- [ ] Tap **Restore** → either restores a purchase or shows an "nothing to restore" message (no crash)

If any of these 404, the App Store reviewer will reject. Fix marketing site URLs first.

---

## 3. App Store Connect — create the App Store version

Go to https://appstoreconnect.apple.com → My Apps → GoldMind → App Store tab.

- [ ] Click **+ Version or Platform** → iOS → **1.0** (or whatever marketing version you want, e.g. 1.0.0)
- [ ] In **Build** section, click + and select **Build 23** (or whatever's latest TF build)

---

## 4. Version Information

### What's New in This Version
First version, leave blank or write: `Initial release.`

### Promotional Text (optional, 170 chars)
**[Suggested]:**
> "Spot the biases behind your spending. Sixteen behavioural-finance patterns, one small daily check-in. No bank connection. Privacy-first."

### Description (4000 chars max)
**[Suggested — adjust voice]:**
> GoldMind is a behavioural-finance app that helps you notice the patterns driving your money decisions.
>
> No bank connection. No shame. No "great job" messages. Just a small daily check-in and a Nudge that helps you see what's actually happening.
>
> Sixteen behavioural-finance biases tracked from your tagged spending — the same framework professional planners use (BFAS, Pompian 2012).
>
> WHAT'S INSIDE
> • Quick log: tap a category, an amount, and whether it was planned, a surprise, or impulse
> • Nudge tags up to two co-occurring biases per spend (Pompian 2012, Klontz 2011)
> • Daily check-in: one question, sixty seconds
> • Money Mind quiz: discover your spending personality (Drifter, Reactor, Bookkeeper, Now, Bandwagon, Autopilot)
> • Bias mind map: see how patterns connect
> • Insights: weekly trends, bias spending breakdown, future-bank-account projection
>
> WHO IT'S FOR
> If you've abandoned budgeting apps because they made you feel watched, judged, or guilty — GoldMind starts from a different premise. Awareness drives change. The data is yours.
>
> WHAT IT'S NOT
> Not a budgeting app. Not a bank aggregator. Not financial advice.
>
> RESEARCH FOUNDATION
> Built on the Behavioural Finance Assessment Score (BFAS) framework, Klontz Money Scripts, and the underlying research (Kahneman & Tversky, Thaler, Laibson, Samuelson & Zeckhauser, Cialdini, Baumeister).

### Keywords (100 chars, comma-separated)
**[Suggested]:**
> `behaviour finance,money awareness,spending tracker,money mindset,nudge,bias,money habits`

### Support URL
> `https://mygoldmind.vercel.app/support` (or wherever your support page is)

### Marketing URL (optional)
> `https://mygoldmind.vercel.app`

---

## 5. App Privacy questionnaire (this is the big one)

Go to App Store Connect → GoldMind → App Privacy → Edit.

You'll be asked: "Do you or your third-party partners collect data from this app?" → **Yes**.

For each data type below, indicate the use case + whether linked to identity + whether tracked across apps.

### Contact Info → Email Address
- Collected: **Yes**
- Linked to identity: **Yes** (it's their Apple ID email)
- Used for tracking: **No**
- Purposes: **App Functionality** (auth)

### User Content → Other User Content
- This covers check-ins, money events, bias progress.
- Collected: **Yes**
- Linked to identity: **Yes**
- Used for tracking: **No**
- Purposes: **App Functionality**

### Identifiers → User ID
- Apple Sign In sub identifier + Supabase user UUID.
- Collected: **Yes**
- Linked to identity: **Yes**
- Used for tracking: **No**
- Purposes: **App Functionality, Analytics** (RevenueCat uses anonymous user ID for subscription analytics)

### Purchases → Purchase History
- RevenueCat receives IAP receipts.
- Collected: **Yes**
- Linked to identity: **Yes** (linked to anonymous user ID, not name/email)
- Used for tracking: **No**
- Purposes: **App Functionality, Analytics**

### NOT COLLECTED (uncheck these)
- Financial Info (we don't connect to banks)
- Health & Fitness
- Location
- Sensitive Info
- Contacts
- Search History
- Browsing History
- Diagnostics (unless you've added Crashlytics or similar — you haven't)

---

## 6. Age Rating
Click Edit on App Information → Age Rating.

All answers: **None**. Result: **4+**.

If you want **17+** (the original plan per memory) because of financial-decision content, you'd need to check one of the "infrequent/mild" boxes — but for a pure awareness tool with no financial advice, **4+** is honest.

**[Bella decision: 4+ or 17+?]**

---

## 7. App Review Information

This is the panel Apple uses to test the app.

### Sign-in credentials
- [ ] Provide a demo Apple ID + password for the reviewer (or note: "Uses Apple Sign In; reviewer can sign in with their own Apple ID")

### Notes
**[Suggested]:**
> GoldMind is a behavioural-finance awareness app, not a financial-advice tool. No bank connections, no transactions, no recommendations. The user manually logs spending events; the app surfaces the behavioural patterns ("biases") most likely driving each one based on a research-grounded mapping (BFAS / Pompian 2012).
>
> All data is stored in Supabase (Sydney, AU). Subscription management is via RevenueCat + StoreKit. The app requests no permissions on first launch; notification permission is gated behind an explicit user action.
>
> Delete-account flow: Settings → Delete Account (permanently removes all user data via tracked Supabase RPC, complying with 5.1.1(v)).

### Contact info
- First name: Arabella
- Last name: [your surname]
- Phone: [yours]
- Email: `ahaythorpe@gmail.com`

---

## 8. Pricing & Availability

- [ ] **Price tier:** [decide — free + paywall via RevenueCat is the current model, so app price = Free; subscription tiers managed in RevenueCat]
- [ ] **Availability:** Pick the regions you want. Start with Australia + USA at minimum.

---

## 9. Submit for Review

- [ ] Confirm Build 23 (or latest) is selected.
- [ ] Click **Save** on every section.
- [ ] Click **Add for Review** at the top of the version page.
- [ ] Answer Apple's two questions:
  - Export Compliance: **No** (you're not using non-standard encryption)
  - Content Rights: **Yes, contains, or accesses, third party content** → **No** (your bias content is your own)
  - Advertising Identifier: **No**
- [ ] Click **Submit to App Review**.

Review usually takes 24-48 hours. Apple will email when reviewed.

---

## Common rejection reasons (heads-up)

1. **Privacy policy URLs return 404.** Check `mygoldmind.vercel.app/privacy` and `/terms` are live before submitting.
2. **App Privacy questionnaire doesn't match the actual data collection.** If you say "no data collected" but Supabase clearly stores email, instant reject.
3. **Subscription terms not displayed before purchase.** Your paywall already does this — verify the Terms link works.
4. **Delete-account flow missing.** You have this (5.1.1(v) compliant) but the reviewer needs to test it works.
5. **Vague "behavioural finance" copy without disclaiming you're not giving advice.** The notes-to-reviewer in step 7 covers this. The in-app copy already does too (no "advice", just "awareness").

---

## Post-approval

Once Apple approves:

- [ ] Swap the marketing-site banner from "Coming soon" to "Available on App Store" with the badge (see `docs/LAUNCH_BANNER.md` bottom section)
- [ ] Get the App Store URL → update `mygoldmind.vercel.app` links
- [ ] Test purchase flow on a real Apple ID
- [ ] Celebrate
