# Marketing site — Nudge peek animation

> Nudge mascot peeks in from the right edge of the viewport, holds, slides out, repeats.
> Pure CSS keyframes. No JS, no library, no paid integration.
> Drop into your marketing site (`mygoldmind.vercel.app`).

---

## Option A — Plain HTML + CSS (stack-agnostic)

Paste this anywhere in the page (the element is `position: fixed` so source order doesn't matter):

```html
<div class="nudge-peek" aria-hidden="true">
  <!-- Replace this with your Nudge mascot SVG/PNG/emoji -->
  <span class="nudge-peek__face">🤔</span>
</div>

<style>
  .nudge-peek {
    position: fixed;
    top: 50%;
    right: 0;
    transform: translate(100%, -50%);  /* hidden off-screen-right by default */
    z-index: 50;
    pointer-events: none;
    animation: nudge-peek 12s ease-in-out infinite;
  }

  /* The face itself — replace the emoji with an <img> for a real Nudge asset */
  .nudge-peek__face {
    display: inline-block;
    font-size: 4rem;       /* ~64px emoji */
    line-height: 1;
    animation: nudge-bob 2.4s ease-in-out infinite;
    filter: drop-shadow(0 6px 12px rgba(0,0,0,0.18));
  }

  /* Slide in from the right, hold, slide back out, pause */
  @keyframes nudge-peek {
    0%   { transform: translate(100%, -50%); }   /* hidden */
    8%   { transform: translate(20%, -50%); }    /* peeks in (only half-visible — playful) */
    35%  { transform: translate(20%, -50%); }    /* holds */
    45%  { transform: translate(100%, -50%); }   /* slides back out */
    100% { transform: translate(100%, -50%); }   /* hidden for the rest of the cycle */
  }

  /* Subtle bob while peeking */
  @keyframes nudge-bob {
    0%, 100% { transform: translateY(0); }
    50%      { transform: translateY(-6px); }
  }

  /* Pause animation if the user prefers reduced motion (a11y) */
  @media (prefers-reduced-motion: reduce) {
    .nudge-peek,
    .nudge-peek__face {
      animation: none;
      transform: translate(20%, -50%);
    }
  }

  /* Hide entirely on small screens to avoid covering content */
  @media (max-width: 640px) {
    .nudge-peek { display: none; }
  }
</style>
```

### Behaviour

- **0–1s:** Nudge slides in from the right (only half-visible — peeking, not fully on screen).
- **1–4s:** Holds, gently bobbing.
- **4–5s:** Slides back out.
- **5–12s:** Hidden, then loops.
- **Mobile (≤640px):** Hidden entirely so it doesn't cover hero copy.
- **Reduced-motion users:** Sits in the peek position with no animation.

### Swap the emoji for a real Nudge asset

Replace the `<span class="nudge-peek__face">🤔</span>` with whatever asset you have:

```html
<img class="nudge-peek__face" src="/nudge.png" alt="" width="80" height="80">
```

(Add to the CSS: `.nudge-peek__face { width: 80px; height: 80px; }` if you switch to `<img>`.)

---

## Option B — Tailwind / Next.js (if site uses Tailwind)

```tsx
export function NudgePeek() {
  return (
    <div
      aria-hidden="true"
      className="
        fixed right-0 top-1/2 z-50 pointer-events-none
        translate-x-full -translate-y-1/2
        motion-safe:animate-[nudge-peek_12s_ease-in-out_infinite]
        max-sm:hidden
      "
    >
      <span
        className="
          inline-block text-6xl leading-none
          drop-shadow-lg
          motion-safe:animate-[nudge-bob_2.4s_ease-in-out_infinite]
        "
      >
        🤔
      </span>
    </div>
  );
}
```

Then in `tailwind.config.js`:

```js
module.exports = {
  theme: {
    extend: {
      keyframes: {
        'nudge-peek': {
          '0%':   { transform: 'translate(100%, -50%)' },
          '8%':   { transform: 'translate(20%, -50%)' },
          '35%':  { transform: 'translate(20%, -50%)' },
          '45%':  { transform: 'translate(100%, -50%)' },
          '100%': { transform: 'translate(100%, -50%)' },
        },
        'nudge-bob': {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%':      { transform: 'translateY(-6px)' },
        },
      },
    },
  },
};
```

Drop `<NudgePeek />` into your root `layout.tsx` or `_app.tsx` so it's present on every page.

---

## Tuning knobs

| Want | Change |
|---|---|
| **Peek more often** | Drop `nudge-peek` duration: `12s` → `7s` |
| **Peek less often** | Bump duration: `12s` → `20s` |
| **More of the face visible** | `translate(20%, -50%)` → `translate(0%, -50%)` (fully visible) or `translate(40%, -50%)` (less visible) |
| **Different position on screen** | Change `top: 50%` to `top: 25%` (upper third) or `top: 70%` (lower third) |
| **Slower bob** | Bump `nudge-bob` duration: `2.4s` → `4s` |
| **Hide above tablet too** | Change breakpoint: `max-width: 1024px` |

---

## Where to paste

If the marketing site is plain HTML (Vercel static):
- Open the main page file (`index.html` or whichever route lands at `mygoldmind.vercel.app`)
- Paste Option A's snippet anywhere inside `<body>`, ideally just before the closing `</body>` tag

If it's Next.js / Tailwind:
- Drop Option B's `NudgePeek` component
- Add the keyframes to `tailwind.config.js`
- Render `<NudgePeek />` in `app/layout.tsx`

That's it — refresh the page and Nudge starts peeking.
