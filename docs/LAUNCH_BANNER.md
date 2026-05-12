# Marketing site — coming-soon banner

> Goal: top-of-page banner announcing GoldMind is coming to the App Store, with a waitlist email capture. Paste the snippet that matches your marketing site's stack.
> Site: `mygoldmind.vercel.app`
> Last reviewed: 2026-05-12

---

## Option A — Plain HTML + CSS (stack-agnostic)

Drop into the top of the page above the existing hero, or wrap your existing hero in this banner section.

```html
<section class="gm-banner">
  <div class="gm-banner__inner">
    <span class="gm-banner__chip">COMING SOON · APP STORE</span>
    <h1 class="gm-banner__title">
      GoldMind. Awareness for the way you spend.
    </h1>
    <p class="gm-banner__subtitle">
      A behavioural-finance app that helps you notice the patterns driving your money decisions. Built on BFAS — the same framework professional planners use.
    </p>
    <form class="gm-banner__form" action="https://formspree.io/f/YOUR_FORM_ID" method="POST">
      <input type="email" name="email" required placeholder="your@email.com" class="gm-banner__input" />
      <button type="submit" class="gm-banner__cta">Get notified at launch</button>
    </form>
    <p class="gm-banner__legal">No spam. One email when GoldMind goes live.</p>
  </div>
</section>

<style>
  .gm-banner {
    background: linear-gradient(135deg, #1B5E20, #2E7D32, #388E3C);
    padding: 4rem 1.5rem;
    color: white;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  }
  .gm-banner__inner {
    max-width: 720px;
    margin: 0 auto;
    text-align: center;
  }
  .gm-banner__chip {
    display: inline-block;
    background: rgba(255, 255, 255, 0.14);
    border: 1px solid rgba(232, 184, 75, 0.5);
    color: #E8B84B;
    padding: 0.4rem 0.9rem;
    border-radius: 999px;
    font-size: 0.75rem;
    font-weight: 800;
    letter-spacing: 0.12em;
    margin-bottom: 1.5rem;
  }
  .gm-banner__title {
    font-size: 2.4rem;
    font-weight: 800;
    margin: 0 0 0.75rem;
    line-height: 1.15;
  }
  .gm-banner__subtitle {
    font-size: 1.05rem;
    opacity: 0.88;
    margin: 0 0 2rem;
    line-height: 1.5;
  }
  .gm-banner__form {
    display: flex;
    gap: 0.5rem;
    max-width: 460px;
    margin: 0 auto;
  }
  .gm-banner__input {
    flex: 1;
    padding: 0.85rem 1rem;
    border: 1px solid rgba(255, 255, 255, 0.25);
    background: rgba(255, 255, 255, 0.08);
    border-radius: 999px;
    color: white;
    font-size: 0.95rem;
  }
  .gm-banner__input::placeholder { color: rgba(255, 255, 255, 0.55); }
  .gm-banner__cta {
    padding: 0.85rem 1.4rem;
    border: none;
    background: linear-gradient(180deg, #C59430, #A87E2A);
    color: white;
    border-radius: 999px;
    font-weight: 700;
    font-size: 0.95rem;
    cursor: pointer;
    white-space: nowrap;
  }
  .gm-banner__cta:hover { filter: brightness(1.08); }
  .gm-banner__legal {
    font-size: 0.78rem;
    opacity: 0.6;
    margin-top: 1rem;
  }
  @media (max-width: 540px) {
    .gm-banner__title { font-size: 1.7rem; }
    .gm-banner__form { flex-direction: column; }
  }
</style>
```

Replace `YOUR_FORM_ID` with your Formspree form ID (the marketing site already uses Formspree per `HANDOFF.md` notes — find the form ID in your Formspree dashboard).

---

## Option B — Tailwind / Next.js (if marketing site uses Tailwind)

```tsx
export function ComingSoonBanner() {
  return (
    <section className="bg-gradient-to-br from-[#1B5E20] via-[#2E7D32] to-[#388E3C] px-6 py-16 text-white">
      <div className="mx-auto max-w-2xl text-center">
        <span className="inline-block rounded-full border border-[#E8B84B]/50 bg-white/[0.14] px-3.5 py-1.5 text-xs font-extrabold tracking-[0.12em] text-[#E8B84B] mb-6">
          COMING SOON · APP STORE
        </span>
        <h1 className="text-4xl md:text-5xl font-extrabold leading-tight mb-3">
          GoldMind. Awareness for the way you spend.
        </h1>
        <p className="text-lg opacity-90 leading-relaxed mb-8">
          A behavioural-finance app that helps you notice the patterns driving your money decisions. Built on BFAS — the same framework professional planners use.
        </p>
        <form
          action="https://formspree.io/f/YOUR_FORM_ID"
          method="POST"
          className="flex flex-col sm:flex-row gap-2 max-w-md mx-auto"
        >
          <input
            type="email"
            name="email"
            required
            placeholder="your@email.com"
            className="flex-1 rounded-full border border-white/25 bg-white/10 px-4 py-3 text-base placeholder:text-white/55 focus:outline-none focus:ring-2 focus:ring-[#E8B84B]"
          />
          <button
            type="submit"
            className="rounded-full bg-gradient-to-b from-[#C59430] to-[#A87E2A] px-6 py-3 font-bold hover:brightness-110 transition"
          >
            Get notified at launch
          </button>
        </form>
        <p className="text-xs opacity-60 mt-4">
          No spam. One email when GoldMind goes live.
        </p>
      </div>
    </section>
  );
}
```

---

## Copy variants (swap freely)

**Headline (pick one):**
- "GoldMind. Awareness for the way you spend." (current — neutral)
- "Money decisions aren't always rational. Now you can see why."
- "What if every spend told you something about you?"

**Subtitle (pick one):**
- "A behavioural-finance app that helps you notice the patterns driving your money decisions. Built on BFAS — the same framework professional planners use."
- "Track the biases behind your money decisions. Sixteen patterns. One small daily check-in. No bank connection."
- "Stay aware. Adjust early. No shame."

**CTA button:**
- "Get notified at launch" (current)
- "Join the waitlist"
- "Tell me when it's live"

**Legal line:**
- "No spam. One email when GoldMind goes live." (current)
- "We'll only email when the app is live on the App Store."

---

## After Apple approves the app

Swap `COMING SOON · APP STORE` chip for an actual Apple badge:

```html
<a href="https://apps.apple.com/au/app/goldmind/idYOUR_APP_ID">
  <img
    src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-au"
    alt="Download on the App Store"
    style="height: 48px;"
  />
</a>
```

(Replace `YOUR_APP_ID` with the App Store ID from App Store Connect once the app is approved.)

The waitlist form can stay or be removed — your call.
