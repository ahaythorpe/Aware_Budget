# GoldMind — Developer handover for v1.0 submission

> Bella is handing this list to the dev/engineer who'll handle anything requiring App Store Connect access, RevenueCat dashboard access, or backend verification. Bella herself is testing on TestFlight + updating the marketing site.
> Build to ship: **26** (next bump after Bella's TestFlight check on Build 25)
> Date: 2026-05-13

---

## 0. What's already done (FYI)

You can skip these — they're shipped and working:
- Multi-bias model + algorithm (`docs/ALGORITHM.md`)
- Notification scheduling + tap-routing fix (Build 25)
- Privacy-Act delete-account flow (Supabase RPC, applied to live DB)
- App Store-ready CHANGELOG, HANDOFF, STATUS docs in `docs/`

What's left is all your-side work: **verify, then submit**.

---

## 1. Notification routing — verification

Per Bella's product rule: every push lands on Quick Log OR the Home finance editor. Audit + verify on Build 25 (or 26 once shipped).

### Simulator test (60 seconds)

```bash
cat > /tmp/test-push-morning.apns <<'EOF'
{
  "Simulator Target Bundle": "goldmind.app",
  "aps": { "alert": { "title": "GoldMind", "body": "Coffee or breakfast spend today?" }, "sound": "default" },
  "slot": "morning"
}
EOF
xcrun simctl push booted goldmind.app /tmp/test-push-morning.apns
```

Tap the notification on the sim → should jump to **Log tab** with Coffee/Lunch tiles pre-highlighted.

Run the same with `"slot": "lunch"`, `"slot": "evening"`, `"slot": "chunky"` to verify each.

For the finance-editor route:
```json
{ "Simulator Target Bundle": "goldmind.app", "aps": {"alert": {...}}, "route": "finance_editor" }
```
→ should land on **Home** with the finance editor sheet auto-open.

### What good looks like

| Slot in payload | Lands on | Highlights |
|---|---|---|
| `morning` | Log tab | Coffee, Lunch |
| `lunch` | Log tab | Lunch, Coffee, Eating out |
| `evening` | Log tab | Eating out, Drinks, Lunch |
| `chunky` | Log tab | Shopping, Travel, Subscriptions, Big purchase |
| `route: finance_editor` | Home tab | Finance editor sheet auto-opens |

If any tap lands on the wrong tab → bug. Source: `Services/NotificationRouter.swift` + `Services/NotificationService.swift` + `Views/RootTabView.swift`.

---

## 2. Paywall — link + Restore verification

On a real device with Build 25+ installed:

1. Trigger the paywall (fresh account flow OR Settings → Subscription).
2. Tap **Terms** at the bottom of the paywall.
   - Expected: opens `https://mygoldmind.vercel.app/terms` in Safari.
   - **Reject case:** any 404, blank page, or different URL.
3. Tap **Privacy**.
   - Expected: opens `https://mygoldmind.vercel.app/privacy` in Safari.
4. Tap **Restore Purchases**.
   - Expected: either restores a previous IAP or shows "Nothing to restore" toast. No crash.

Source: paywall is RevenueCat-hosted (`RevenueCatUI.PaywallView`). The Terms/Privacy URLs are configured in the **RevenueCat dashboard**, not in code. If 404s appear, fix the URLs in the dashboard:
- RevenueCat dashboard → Project → Paywalls → GoldMind paywall → URLs section.

App Store reviewer **will tap these**. Apple rejects on 404.

---

## 3. RevenueCat dashboard verification

Confirm these in https://app.revenuecat.com:

- [ ] **App connected to App Store Connect.** Project → Settings → Apps → GoldMind iOS → App Store Connect credentials set.
- [ ] **Three products configured** matching `GoldMind/GoldMind.storekit`:
  - Annual ($99.99/year, 7-day free trial)
  - Lifetime ($149.99 one-time)
  - Monthly ($9.99/month)
- [ ] **Paywall Terms URL** = `https://mygoldmind.vercel.app/terms`
- [ ] **Paywall Privacy URL** = `https://mygoldmind.vercel.app/privacy`
- [ ] **Entitlement** ("pro" or similar) attached to each product.
- [ ] **Sandbox test:** sandbox-purchase one product on a real device; verify entitlement flips to active in the app.

If the dashboard's Terms/Privacy URLs are blank or wrong, the paywall renders empty links → Apple reject.

---

## 4. Supabase backend verification

Quick health check (sanity, none of this should fail since the app already ships against this DB):

```bash
# Replace with the anon key from .secrets/asc-api.env or AppConfig.swift
curl "https://vdnnoezyogbgtiubamze.supabase.co/rest/v1/profiles?limit=1" \
  -H "apikey: sb_publishable_lwuCqoY6jpKRwQRJoqZYFQ_CiavSWwH"
```

Expected: 200 OK + JSON (empty array is fine for an anon user, just confirms the API + key work).

- [ ] **Migrations applied.** Latest: `20260512200000_add_secondary_behaviour_tag.sql`. Check via Supabase dashboard → Database → Migrations.
- [ ] **RLS enabled** on every user-data table. Spot-check: `auth.users`, `public.profiles`, `public.money_events`, `public.check_ins`, `public.bias_progress`.
- [ ] **Delete-account RPC works.** Sign in to a test account in the iOS app → Settings → Delete Account → confirm. Verify in Supabase dashboard that the row in `auth.users` is gone (cascade-delete should wipe everything else).

---

## 5. App Store Connect submission

Follow `docs/APP_STORE_SUBMISSION.md` end-to-end. It's a step-by-step with prefilled answers for:
- Version Information (Description, Keywords, Promotional Text — all drafted, edit voice as needed)
- App Privacy questionnaire (per-data-type answers prefilled — Email, User Content, Identifiers, Purchases collected; everything else not collected)
- Age Rating (default 4+; flag if you want 17+ instead)
- App Review Information (reviewer notes drafted with framework context + delete-account location)
- Pricing & Availability (price tier free + RevenueCat subscriptions; regions = AU + USA minimum)
- Submit for Review

### Decision points for Bella before submit

The doc flags 2 things requiring her decision:
- **Age rating: 4+ or 17+?** (4+ is more honest for an awareness tool; 17+ was the original plan)
- **Phone number for reviewer contact** (yours or Bella's?)

---

## 6. Known v1.0 carry-overs (deliberate; don't submit fixes for these)

Documented in `CHANGELOG.md` Build 22 entry:
- BiasReviewView confirm flow only handles primary bias tag, not the secondary. Insights aggregation already credits both biases for co-driven spends; only the review-pass scoring is single-tag for now.
- Interactive trend charts (range chips + drag-to-zoom) not yet ported to bias/category/net-worth/financial trends. Plan in `docs/PLAN_V1_1.md` #32.
- Concept-graph layouts (#30, #34) for Education tab — plan only, deferred to v1.1.

Apple won't notice these — they're net-new feature work, not regressions.

---

## 7. Common rejection reasons to pre-empt

`docs/APP_STORE_SUBMISSION.md` section "Common rejection reasons" covers these in detail. TL;DR:

1. **Privacy/Terms URLs 404.** Verify on device before submitting. Section 2 above.
2. **App Privacy questionnaire doesn't match actual data collection.** Section 5 of submission doc has the per-data-type answers; cross-check against what Supabase actually stores.
3. **Delete-account flow missing or broken.** Section 4 above for verification.
4. **Subscription terms not displayed before purchase.** RevenueCat paywall handles this; verify the Terms link works (section 2 above).
5. **App promises financial advice without disclaimer.** In-app copy and the reviewer-notes blurb in submission doc both explicitly disclaim "no advice, only awareness". Keep it that way.

---

## 8. Bella's parallel checklist (FYI, she's doing this — don't duplicate)

- Test Build 25/26 on TestFlight (visual polish, copy, flow)
- Update `mygoldmind.vercel.app/privacy` and `/terms` with the disclosures listed in `docs/APP_STORE_SUBMISSION.md` section 1
- Paste the coming-soon banner from `docs/LAUNCH_BANNER.md` onto the marketing site
- Take App Store screenshots (Bella's design eye)

---

## Contact

- Bella (founder, designer): `ahaythorpe@gmail.com`
- Codebase docs: `docs/` directory (start with HANDOFF.md for architecture)
- Live DB: Supabase project `vdnnoezyogbgtiubamze` ("Aware Budget" org, FREE tier)
- TestFlight builds: App Store Connect → GoldMind → TestFlight
