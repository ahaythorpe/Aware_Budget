# App Store screenshot capture guide

> How to get past the paywall and capture the App Store screenshots without burning sandbox accounts.
> Last updated: 2026-05-13

---

## TL;DR

1. Set the Xcode scheme to pass `-ScreenshotMode YES` as a launch argument.
2. Pick the right simulator size for the screenshot tier you're capturing (6.9" / 6.5" / iPad).
3. Run from Xcode (Cmd-R). Paywall is auto-bypassed; you land on the Home tab logged in as the debug user.
4. Optionally run `xcrun simctl spawn booted touch /tmp/seed-demo` to seed demo data.
5. Navigate to each screen; capture with Cmd-S in the simulator or `xcrun simctl io booted screenshot`.
6. Drag PNGs from Desktop into App Store Connect.

---

## 1. Bypass the paywall (Screenshot Mode)

`GoldMindApp.init()` checks for one of:
- Launch argument `-ScreenshotMode` (preferred, scheme-scoped)
- UserDefaults key `screenshotMode` = `true` (persistent, useful on device)

When either is true (DEBUG builds only), `PaywallStore.shared.forceProForScreenshots()` runs, setting `isPro = true` and `hasLoaded = true`. The root navigator skips the paywall and lands on `RootTabView`.

### Set the launch argument in Xcode

1. Xcode → **Product → Scheme → Edit Scheme…** (Cmd-Shift-,)
2. Left sidebar: **Run** → **Arguments** tab
3. Under "Arguments Passed On Launch", click **+**
4. Add: `-ScreenshotMode YES`
5. Close.

Now every `Cmd-R` run skips the paywall. Untick the box to revert.

### Or persist via UserDefaults (no scheme edit)

For a build already running on a device or sim:

```bash
xcrun simctl spawn booted defaults write goldmind.app screenshotMode -bool YES
```

Then cold-launch the app. Disable with `-bool NO`.

---

## 2. Pick the right simulator size

Apple requires screenshots at one of these device sizes. Use the LARGEST you support; Apple auto-scales down.

| Tier | Required for v1.0? | Simulator name |
|---|---|---|
| **6.9" iPhone** (1320×2868) | ✅ yes — primary | `iPhone 17 Pro Max` |
| 6.5" iPhone (1284×2778) | optional | `iPhone 15 Plus` |
| iPad Pro 12.9" (2048×2732) | only if iPad supported | `iPad Pro 13-inch (M4)` |

Boot the right sim:

```bash
xcrun simctl boot "iPhone 17 Pro Max"
open -a Simulator
```

Check it's the booted device:

```bash
xcrun simctl list devices booted
```

---

## 3. Seed real-looking data

Cold paywall-bypassed launch lands you logged in but with no data. To make Home / Insights / charts populated:

### Option A — manual

Tap through: Log → log 4-5 spends across categories (Coffee, Lunch, Shopping, Subscriptions). Check-in twice. The Future-You chart needs ≥1 spend to render. Bias illustrations always render.

### Option B — DemoDataService

`Services/DemoDataService.swift` already exists and can seed a week of varied events. Wire it as another launch arg if you need repeated fresh seeded captures (not done by default to avoid polluting real test data).

---

## 4. Capture

In the simulator:

| Method | Shortcut | Output |
|---|---|---|
| Save screenshot to Desktop | **Cmd-S** | PNG named `Simulator Screenshot - <device> - <timestamp>.png` |
| Save to clipboard | Cmd-Ctrl-S | nothing on disk; paste into Preview |
| Programmatic | `xcrun simctl io booted screenshot ~/Desktop/home.png` | named file |

Tip: chain `simctl` for batch captures:

```bash
xcrun simctl io booted screenshot ~/Desktop/01-home.png
# tap into Insights manually, then:
xcrun simctl io booted screenshot ~/Desktop/02-insights.png
```

---

## 5. Recommended screenshot sequence (8 shots)

In order, showing the value prop top-to-bottom:

1. **Onboarding hero** — the "meet Nudge" intro slide
2. **Home** — greeting card + DAY STREAK + 25% patterns identified + check-in button
3. **Future-You chart on Home** — scrolled past the calendar, compound-growth chart populated
4. **Log tab** — picking a category + planned status (mid-flow)
5. **Insights** — Spending by Bias dropdowns expanded, showing one category
6. **Education** — awareness score bar at top, Money Mind Quiz CTA, mind map card
7. **Mind map node sheet** — Loss Aversion expanded, S-curve visible (the wow moment)
8. **Research** — bias-paper concept graph with a paper tapped, biases highlighted

Each PNG should be cropped to the simulator's exact pixel dimensions (Cmd-S preserves this). No status-bar editing — Apple accepts the default fake status bar from the simulator.

---

## 6. Upload to App Store Connect

1. App Store Connect → My Apps → GoldMind → **App Store** tab.
2. iOS 1.0 version → scroll to **Previews and Screenshots**.
3. Drag PNGs onto the **6.9" Display** slot.
4. Apple auto-derives 6.7" and 6.5" from the 6.9" upload if you tick "Use a single set of screenshots for all device sizes".
5. Save.

---

## 7. Cleanup before submission

- **Untick `-ScreenshotMode YES`** in the scheme before Archive (Release builds ignore it anyway, but cleanest to remove).
- **Don't ship Screenshot Mode in Release.** The `#if DEBUG` wrappers in `GoldMindApp.init` + `PaywallStore.forceProForScreenshots` ensure this; the `xcodebuild -configuration Release` archives won't include the bypass path. Verified by the existing TestFlight upload script using Release config.

---

## Quick reference

```
# Boot the right sim
xcrun simctl boot "iPhone 17 Pro Max"
open -a Simulator

# Run with screenshot mode (set in scheme first)
# Product → Run, or:
xcodebuild -project GoldMind.xcodeproj -scheme GoldMind \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  build && xcrun simctl install booted \
  ~/Library/Developer/Xcode/DerivedData/GoldMind-*/Build/Products/Debug-iphonesimulator/GoldMind.app && \
  xcrun simctl launch booted goldmind.app -ScreenshotMode YES

# Capture
xcrun simctl io booted screenshot ~/Desktop/goldmind-01-home.png
```
