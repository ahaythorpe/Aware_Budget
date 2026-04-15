# AwareBudget — Product Requirements Document
### For: Claude Code (iOS/SwiftUI Build)
### Version: 1.2 — Check-in architecture + bias ranking

---

## Check-in architecture (v1.2)

**Goal:** capture high-quality behavioural data without burning the user out. Split the work across the day.

### Flow by time of day

| Trigger | Content | Friction budget |
|---|---|---|
| **First open (onboarding)** | BFAS baseline — 16 questions (1 per bias) to seed initial bias weights | 3–4 min, one-time |
| **Throughout day (passive)** | Smart nudge pushes at 11am / 2pm / 7pm based on user's historical logging times. One-tap quick log. | 5 sec per log |
| **Evening check-in** | Today's event summary + 2 questions on today's top-ranked biases | 30 sec |
| **Morning check-in** | Yesterday's pattern recap + 2 deeper questions on yesterday's biases | 30 sec |
| **Sunday weekly review** | Week summary + 4 deeper questions on weekly top biases | 2 min |

**Daily total:** 4 behavioural questions across 2 moments (evening + next morning) — never one dreaded block.

### Ranking system (backend-only, invisible to user)

Lives in `BiasScoreService.computeScore`. User sees **outputs** (top biases, stage, trend) but never the maths.

```
final_score = current_score + BFAS_initial_weight

current_score = (YES answers × 2) + (tagged events × 3) − (NO answers × 1)
BFAS_initial_weight = 0–10 per bias, seeded from onboarding assessment
```

Trend: improving / worsening / stable (last 3 answers).
Stage: unseen → noticed → emerging → active → aware.

**Question selection:** for each daily check-in, pick top N ranked biases and fetch next unused question from `question_pool` where `bias_name = bias` ORDER BY `last_shown ASC`. After answer, append to `bias_progress.recentAnswers` and update `last_shown`.

### Motivation mechanisms (not gamification)

| Mechanism | Implementation |
|---|---|
| **Smart time nudges** | Push notifications at user's historical logging times, not fixed schedule. Body e.g. "Coffee run?" |
| **One-tap quick log** | 3-tap flow already implemented (`MoneyEventView` quick categories) |
| **Streak = pattern**, not punishment | Copy: "12-day logging streak — you're seeing more than most" (awareness frame) |
| **Evening preview** | Evening check-in shows "5 events today" — rewards daytime logging |
| **Loss aversion** | Nudge line: "Missing a log keeps you blind to the pattern" (behavioural-econ meta, not shamey) |
| **Pattern reveal** | After 3 same-category logs: "Your Wednesday coffees: 4× — Status Quo Bias" |

### Credibility cues strategy

**Design pattern:** evidence-based consumer design (NNg Group / Norman & Nielsen). Hide the math, surface authority at data-capture moments so seemingly-boring questions feel consequential.

**Canonical papers** (all verified, all already in `BiasData.swift`):
- Pompian (2012) *Behavioral Finance and Wealth Management* — BFAS framework
- Kahneman & Tversky (1979) *Prospect Theory*, Econometrica 47(2):263–291
- Thaler & Sunstein (2008) *Nudge*, Yale University Press
- Kahneman et al. (2004) *Day Reconstruction Method*, Science 306(5702):1776–1780

**Sprinkle points:**

| Surface | Cue |
|---|---|
| Onboarding screen 1 | "Based on 40+ years of behavioural research" tag under hero |
| Home · Top Biases card | `ⓘ` icon → `CredibilitySheet` (algorithm plain-English + stage legend + citation grid + "Read the full story" CTA to Why) |
| Check-in question screen | Footer "Q{n} of {total} · from BFAS assessment" |
| After answer submitted | Citation pill flashes briefly: "Kahneman & Tversky, 1979" |
| BiasDetail | Full citation card + "Why this matters" (audit existing) |
| Weekly review | "Reviewed by the BFAS framework" badge on summary |
| First-time BFAS assessment completion | "Your baseline is set. Based on Pompian, 2012." |

**Reference apps** confirming this pattern works for behavioural/health: Noom, Headspace, Apple Fitness+, Waking Up, Duolingo.

### Explicit anti-patterns

- No badges, confetti, XP, streak-freeze power-ups, level-ups
- No push notifications more than 3×/day
- No "great job" from Nudge — dry wit only
- No hardcoded bias suggestions — all from ranking + `question_pool`
- No user-facing score, points, or rank number

---

## Overview

AwareBudget is an awareness-based personal finance iOS app grounded in behavioural economics. It does NOT sync to banks. Users manually log their financial activity. Core philosophy: **Stay aware. Adjust early. No shame.**

The app addresses the "Ostrich Effect" — the tendency people have to avoid looking at their finances when things feel overwhelming. Success is measured by awareness streaks and alignment percentages, not perfect budget adherence.

**What makes AwareBudget different:**
Every competitor (YNAB, Copilot, Monarch) solves the tracking problem. Nobody solves the awareness and avoidance problem at the behavioural level. AwareBudget is built for the 70% of people who download budgeting apps and quit within 30 days.

---

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Backend:** Supabase (PostgreSQL + Auth)
- **Notifications:** UserNotifications (native iOS)
- **Minimum iOS:** 17+
- **Architecture:** MVVM
- **Async:** async/await only — no Combine

---

## Project Structure

```
AwareBudget/
├── AwareBudgetApp.swift
├── ContentView.swift
├── Models/
│   ├── CheckIn.swift
│   ├── MoneyEvent.swift
│   ├── Question.swift
│   ├── BiasLesson.swift
│   ├── BudgetMonth.swift
│   └── MonthlyDecision.swift
├── Views/
│   ├── HomeView.swift
│   ├── CheckInView.swift
│   ├── MoneyEventView.swift
│   ├── MonthView.swift
│   ├── LearnView.swift
│   ├── BiasDetailView.swift
│   └── OnboardingView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── CheckInViewModel.swift
│   ├── MoneyEventViewModel.swift
│   └── LearnViewModel.swift
└── Services/
    ├── SupabaseService.swift
    └── NotificationService.swift
```

---

## Supabase Schema

```sql
create table budget_months (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  month date not null,
  income_target numeric default 0,
  created_at timestamptz default now()
);

create table daily_checkins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date date not null,
  question_id uuid references question_pool(id),
  response text,
  emotional_tone text check (emotional_tone in ('calm', 'anxious', 'neutral')),
  streak_count integer default 1,
  alignment_pct numeric default 0,
  created_at timestamptz default now(),
  unique(user_id, date)
);

create table money_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date date not null,
  amount numeric not null,
  category text,
  event_type text check (event_type in ('surprise', 'win', 'expected')),
  note text,
  created_at timestamptz default now()
);

create table monthly_decisions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  month date not null,
  decision text,
  insight text,
  created_at timestamptz default now()
);

create table question_pool (
  id uuid primary key default gen_random_uuid(),
  question text not null,
  why_explanation text not null,
  bias_name text not null,
  bias_category text not null,
  difficulty text check (difficulty in ('beginner', 'intermediate', 'advanced')) default 'beginner',
  last_shown date,
  created_at timestamptz default now()
);

create table bias_lessons (
  id uuid primary key default gen_random_uuid(),
  bias_name text not null unique,
  category text not null,
  short_description text not null,
  full_explanation text not null,
  real_world_example text not null,
  how_to_counter text not null,
  emoji text not null,
  sort_order integer default 0,
  created_at timestamptz default now()
);

create table user_bias_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  bias_name text not null,
  times_encountered integer default 0,
  times_reflected integer default 0,
  first_seen date,
  last_seen date,
  created_at timestamptz default now(),
  unique(user_id, bias_name)
);

-- RLS
alter table budget_months enable row level security;
alter table daily_checkins enable row level security;
alter table money_events enable row level security;
alter table monthly_decisions enable row level security;
alter table question_pool enable row level security;
alter table bias_lessons enable row level security;
alter table user_bias_progress enable row level security;

create policy "own data only" on budget_months for all using (auth.uid() = user_id);
create policy "own data only" on daily_checkins for all using (auth.uid() = user_id);
create policy "own data only" on money_events for all using (auth.uid() = user_id);
create policy "own data only" on monthly_decisions for all using (auth.uid() = user_id);
create policy "own data only" on user_bias_progress for all using (auth.uid() = user_id);
create policy "read questions" on question_pool for select using (true);
create policy "read lessons" on bias_lessons for select using (true);
```

---

## Seed Data — 30 Questions Across 16 Biases

```sql
insert into question_pool (question, why_explanation, bias_name, bias_category, difficulty) values
('Did you check your bank balance this week?', 'Avoiding financial information increases anxiety over time. Regular low-stakes exposure builds tolerance and reduces the avoidance response.', 'Ostrich Effect', 'Avoidance', 'beginner'),
('Was there a financial task you kept putting off this week?', 'Avoidance feels like relief short-term but compounds stress over time. Naming what you avoided is the first step to facing it.', 'Ostrich Effect', 'Avoidance', 'beginner'),
('Did you open a bill or financial email you had been ignoring?', 'The anticipation of bad news is nearly always worse than the news itself. Each time you open the envelope anyway, the fear response weakens.', 'Ostrich Effect', 'Avoidance', 'intermediate'),
('Did a financial loss feel more painful than an equal gain felt good?', 'We feel losses approximately twice as intensely as equivalent gains. Recognising this helps us make calmer, more symmetrical decisions.', 'Loss Aversion', 'Decision Making', 'beginner'),
('Did fear of losing money stop you from a decision that made sense?', 'Loss aversion can cause paralysis. Asking "what would I advise a friend?" bypasses the emotional charge.', 'Loss Aversion', 'Decision Making', 'intermediate'),
('Did you spend today what was meant for future you?', 'Our brains heavily discount future rewards. We treat our future self like a stranger. Naming this gap helps close it.', 'Present Bias', 'Time Perception', 'beginner'),
('Did you choose immediate comfort over a future financial goal?', 'Present bias is not laziness — it is how human brains are wired. The antidote is making future goals more vivid, not more disciplined.', 'Present Bias', 'Time Perception', 'intermediate'),
('Did you treat a refund or windfall differently to money you earned?', 'Money is fungible. Mental accounting tricks us into spending windfalls carelessly even though £100 from a refund buys the same things as earned money.', 'Mental Accounting', 'Money Psychology', 'beginner'),
('Did you have savings in one place while carrying a debt elsewhere?', 'Keeping savings while paying high-interest debt is often irrational. But mentally we keep accounts separate, which costs us.', 'Mental Accounting', 'Money Psychology', 'intermediate'),
('Did a sale price make you feel like you were saving money by spending?', 'The first number we see anchors all evaluations that follow. A £200 item marked down from £400 feels cheap — but you still spent £200.', 'Anchoring', 'Decision Making', 'beginner'),
('Did a number you encountered early in a decision influence the outcome more than it should?', 'Anchors are everywhere in financial life. Identifying the anchor gives you the power to set your own reference point.', 'Anchoring', 'Decision Making', 'intermediate'),
('Did you continue something mainly because you had already invested in it?', 'Past costs cannot be recovered. Only future value should drive current decisions. The question is not what have I spent but what would I choose fresh today.', 'Sunk Cost Fallacy', 'Decision Making', 'beginner'),
('Did you keep a subscription or membership going just because you had already paid?', 'Ask: if I had not paid anything, would I choose this today? If no — it is a sunk cost.', 'Sunk Cost Fallacy', 'Decision Making', 'intermediate'),
('Did social pressure or comparison influence a spending decision this week?', 'We overestimate how much others notice our possessions. Spending for status rarely delivers lasting satisfaction.', 'Social Proof', 'External Influence', 'beginner'),
('Did you spend to keep up with what people around you seemed to be spending?', 'Everyone is performing a version of financial health. Most people are doing the same thing simultaneously, creating a spiral that serves no one.', 'Social Proof', 'External Influence', 'intermediate'),
('Did you feel more certain about a financial outcome than the evidence supported?', 'Overconfidence in financial decisions is extremely common. We consistently overestimate our ability to predict and control financial outcomes.', 'Overconfidence Bias', 'Self Perception', 'intermediate'),
('Did you skip research because you felt you already knew enough?', 'The most expensive mistakes come not from ignorance but from confidence that outstrips knowledge. A second opinion costs little and can save much.', 'Overconfidence Bias', 'Self Perception', 'advanced'),
('Did you stick with a financial default without actively choosing it?', 'Default options are powerful nudges. Pension defaults, broadband providers, insurance renewals — inertia costs real money every year.', 'Status Quo Bias', 'Inertia', 'beginner'),
('Did you avoid switching something financial because changing felt like too much effort?', 'The effort of switching is almost always smaller than we imagine, and the cost of staying is often larger than we notice.', 'Status Quo Bias', 'Inertia', 'intermediate'),
('Did a limited time or only a few left message push you into a faster decision?', 'Artificial scarcity is one of the oldest sales techniques. Waiting 24 hours almost always dissolves false urgency.', 'Scarcity Heuristic', 'External Influence', 'beginner'),
('Did you feel more desire for something because it was scarce or hard to get?', 'Scarcity signals value — but only sometimes correctly. We want things more when we might lose access, regardless of whether they genuinely serve us.', 'Scarcity Heuristic', 'External Influence', 'intermediate'),
('Did small or digital payments feel less real than cash or large amounts?', 'Small amounts matter and accumulate. Contactless payments and subscriptions reduce psychological friction. Treating them as real money changes behaviour.', 'Denomination Effect', 'Money Psychology', 'beginner'),
('Did something cost more or take longer than you expected this week?', 'We consistently underestimate costs and timelines. Building a 30% buffer into every estimate corrects for this documented pattern.', 'Planning Fallacy', 'Time Perception', 'beginner'),
('Did an irregular expense arrive that you had not planned for?', 'Irregular expenses are predictably unpredictable. A buffer fund converts crises into inconveniences.', 'Planning Fallacy', 'Time Perception', 'intermediate'),
('Did you justify a spend because you had been good with money recently?', 'Good behaviour creates psychological credit that we spend on indulgence. Your past discipline does not obligate your future self.', 'Moral Licensing', 'Self Perception', 'intermediate'),
('Did a financial win make you feel licensed to splurge elsewhere?', 'Moral licensing is not about willpower — it is about how the brain tracks virtue and reward. Decoupling financial decisions from self-reward removes the trigger.', 'Moral Licensing', 'Self Perception', 'advanced'),
('Did you make a financial decision when you were stressed, tired, or emotionally drained?', 'Decision quality drops measurably under stress and fatigue. High-stakes financial decisions deserve a rested moment.', 'Ego Depletion', 'Decision Making', 'intermediate'),
('Did a recent news story change how you felt about your own financial security?', 'We judge likelihood by how easily examples come to mind. Recession news makes our own situation feel worse than data supports.', 'Availability Heuristic', 'Decision Making', 'intermediate'),
('Did a friend or family member''s money situation change how you evaluated your own?', 'Vivid nearby examples feel more representative than they are. Our sample of visible people is small and skewed.', 'Availability Heuristic', 'Decision Making', 'advanced'),
('Did a monthly price feel more affordable than the same thing expressed as an annual cost?', '£10 a month feels trivial. £120 a year feels significant. Same number, different frame. Annual framing reveals true cost more accurately.', 'Framing Effect', 'Money Psychology', 'beginner');
```

---

## Seed Data — 16 Bias Lessons

```sql
insert into bias_lessons (bias_name, category, short_description, full_explanation, real_world_example, how_to_counter, emoji, sort_order) values
('Ostrich Effect', 'Avoidance', 'We avoid information that might be bad news — even when knowing would help us.', 'The Ostrich Effect describes our tendency to ignore negative financial information. Research by Galai and Sade (2006) showed that investors check portfolios less frequently when markets fall. The same pattern appears in personal finance — people avoid opening bank statements, ignore bills, and delay checking balances when they suspect bad news. The irony is that avoidance increases anxiety over time while exposure reduces it.', 'You notice your balance is lower than expected so you stop checking your banking app altogether. The problem does not go away — it grows. Three weeks later you are hit with an overdraft fee you could have avoided.', 'Start with the smallest possible exposure: just open the app. You do not have to do anything — just look. Over time, regular low-stakes exposure reduces the stress response until checking feels normal.', '🙈', 1),
('Loss Aversion', 'Decision Making', 'Losses feel roughly twice as painful as equivalent gains feel good.', 'Discovered by Kahneman and Tversky in their landmark Prospect Theory research (1979), loss aversion is one of the most replicated findings in behavioural economics. The pain of losing £50 is psychologically equivalent to the pleasure of gaining approximately £100. This asymmetry distorts financial decisions in both directions — we hold losing investments too long, and avoid sensible risks because the downside feels disproportionately threatening.', 'You bought shares that have fallen 30%. Selling would lock in the loss — so you hold, telling yourself they will recover. Meanwhile a better opportunity sits in front of you that you cannot take because your capital is tied up.', 'Ask: if I did not already own this, would I buy it today? If no, loss aversion may be driving the decision. Reframing as choosing between options rather than accepting a loss reduces the emotional charge.', '😨', 2),
('Present Bias', 'Time Perception', 'We consistently overvalue the present at the expense of our future selves.', 'Present bias is the tendency to prefer smaller sooner rewards over larger later ones — even when we know waiting is better. Behavioural economists describe this as hyperbolic discounting: we discount the future steeply and non-linearly. We treat our future self not as ourselves but as a stranger whose interests matter less.', 'You know you should put £200 into savings this month. But a weekend away with friends feels urgent and vivid. Future-you''s retirement feels abstract. You go on the trip.', 'Make your future self more vivid and concrete — write a letter to them, name a savings pot after a goal, or use a photo of somewhere you want to go. The less abstract the future, the less steeply we discount it.', '⏱️', 3),
('Mental Accounting', 'Money Psychology', 'We treat money differently depending on where it came from or what it is for.', 'Coined by Richard Thaler (Nobel Prize, 2017), mental accounting describes how we create psychological buckets for different types of money. We spend from these buckets differently — windfall money gets spent more freely even though £100 from a refund buys exactly the same things as £100 from salary. This also manifests in keeping savings in low-interest accounts while carrying high-interest debt.', 'You receive a £300 tax refund and immediately spend it on something you would never have justified from salary. The refund felt like free money — but it was your money all along.', 'Before spending any windfall ask: would I spend this if it came from my salary? If no, that is mental accounting talking. Treat all money as interchangeable, because it is.', '🧮', 4),
('Anchoring', 'Decision Making', 'The first number we see disproportionately influences all evaluations that follow.', 'Anchoring was demonstrated by Kahneman and Tversky in an experiment where a random number from a spinning wheel influenced participants'' estimates of unrelated quantities. In financial contexts anchors are everywhere: the original price before a discount, the salary first quoted, the first property price seen. Once an anchor is set, we adjust from it — but rarely enough.', 'A jacket is displayed at £280 marked down from £560. It feels like a bargain — you are saving £280. But you only own a jacket you may not have bought otherwise. The anchor (£560) made £280 feel reasonable.', 'Before any significant purchase ask: what would I pay for this if I had seen no price yet? Set your own anchor before you encounter theirs.', '⚓', 5),
('Sunk Cost Fallacy', 'Decision Making', 'We factor in past costs that cannot be recovered when making future decisions.', 'The sunk cost fallacy is the tendency to continue investing in something because of what we have already put in — time, money, or effort — rather than because of future returns. Economically, sunk costs are irrelevant to forward-looking decisions. But psychologically, abandoning something we have invested in feels like admitting failure.', 'You bought an annual gym membership for £400. Three months in you realise you hate going. But you keep going — or feel guilty when you do not — because you already paid. The £400 is gone regardless.', 'The question to ask is never what have I spent but: if I had not already paid anything, would I choose this now? If the honest answer is no, you are in sunk cost territory.', '🕳️', 6),
('Social Proof', 'External Influence', 'We use what others do as a shortcut for what we should do.', 'Social proof is Robert Cialdini''s term for our tendency to look to others'' behaviour when uncertain. In finance this manifests as lifestyle inflation, investment herding, and consumption display. The problem is that everyone is performing a version of financial health — most people are more stretched than they appear.', 'Your peer group starts buying houses, going on expensive holidays, and driving newer cars. Even though your financial situation has not changed you start to feel behind and make spending decisions to close a gap that may not exist.', 'Remember that you see the outputs of others'' spending (the car, the holiday photos) but not the inputs (the debt, the stress, the trade-offs). The comparison is always incomplete.', '👥', 7),
('Overconfidence Bias', 'Self Perception', 'We systematically overestimate our knowledge, skill, and ability to predict outcomes.', 'Overconfidence is one of the most robust findings in psychology. In finance it leads to under-diversification, excessive trading, and skipping due diligence because we already know enough. Studies consistently show people rate themselves as above-average investors and more accurate predictors than they are.', 'You are convinced a particular investment will do well based on a trend you noticed. You put in more than you would normally risk. You are right 40% of the time — but your confidence is calibrated for 70%.', 'Keep a decision journal. Write down your predictions and confidence levels, then check back. Most people discover their confidence significantly outstrips their accuracy.', '🎯', 8),
('Status Quo Bias', 'Inertia', 'We prefer the current state of affairs and resist change even when change is beneficial.', 'Status quo bias, described by Samuelson and Zeckhauser (1988), is the tendency to prefer the existing situation. It is driven by loss aversion, regret aversion, and cognitive ease. In finance this costs money every year through insurance auto-renewals, forgotten subscriptions, and pension defaults that were never optimal.', 'Your home insurance renews automatically at a price that has increased 20% year-on-year. Switching would take 25 minutes and save £200. But switching feels like effort and risk. So you renew.', 'Schedule a quarterly financial MOT — a short session to review what you are paying and whether anything should change. Making inertia-breaking a habit removes the activation energy required.', '🛑', 9),
('Scarcity Heuristic', 'External Influence', 'We assign higher value to things that are scarce or might become unavailable.', 'Scarcity is a genuine signal of value in nature. But marketers have learned to manufacture artificial scarcity: countdown timers, only 3 left, limited edition, today only. Our brains cannot easily distinguish real scarcity from constructed urgency, so we respond to both.', 'A flight appears to have only 2 seats left at this price. You book immediately, anxious about missing out. In reality the airline updates this display dynamically to create urgency.', 'Introduce a 24-hour rule for any non-essential purchase triggered by scarcity language. The genuine opportunities will still be there. The artificial ones will reveal themselves.', '⏳', 10),
('Denomination Effect', 'Money Psychology', 'We spend large denominations and digital money more freely than small physical notes.', 'Research by Raghubir and Srivastava (2009) found people are less likely to spend a £50 note than five £10 notes. The same applies to digital payments — contactless, subscriptions, and in-app purchases all reduce psychological friction. Our spending behaviour is influenced by the format of money rather than its value.', 'You rarely notice the £9.99 Netflix, £7.99 Spotify, £4.99 app, and £12.99 news subscription you pay monthly. Individually trivial. Together: £430 a year on subscriptions you may barely use.', 'Periodically convert digital spending to annual figures. Seeing £430 instead of £9.99 engages a different part of your brain. A monthly subscription audit is one of the highest-return financial habits.', '💳', 11),
('Planning Fallacy', 'Time Perception', 'We consistently underestimate how long, how much, and how hard things will be.', 'The planning fallacy (Kahneman and Tversky, 1979) describes how we systematically underestimate costs, timelines, and obstacles for our own projects while estimating others'' more accurately. We imagine ideal scenarios rather than accounting for realistic friction.', 'You estimate a bathroom renovation will cost £4,000 and take 3 weeks. It costs £6,800 and takes 7 weeks. You have seen this before in other projects — but assumed yours would be different.', 'Use the outside view: look at what similar things actually cost and took rather than planning from scratch. Add a 30% buffer to any cost estimate. Build an irregular expenses fund for the costs you know are coming.', '📋', 12),
('Moral Licensing', 'Self Perception', 'Past good behaviour creates psychological permission to behave worse later.', 'Moral licensing describes how virtuous behaviour creates a sense of credit that we spend on indulgence. In finance, being disciplined all week can make a weekend splurge feel earned. The problem is that these transactions are psychological, not financial — your savings account does not care about your willpower.', 'You have stuck to your budget perfectly for six weeks. You feel you have earned a splurge. You spend £300 on things you would not normally justify. The six weeks of discipline is partially undone.', 'Decouple financial decisions from reward and self-image. Good financial decisions are not virtue — they are just decisions. They do not earn you permission for bad ones.', '🏅', 13),
('Ego Depletion', 'Decision Making', 'Willpower and decision quality are resources that deplete across a day.', 'Research by Baumeister (1998) proposed that self-control draws on a limited cognitive resource that depletes with use. Decision quality declines when we are tired, stressed, or have already made many decisions. This is why supermarkets place temptations at checkouts — and why financial decisions made under stress are systematically worse.', 'You have had an exhausting week. On Friday evening, emotionally drained, you make a financial commitment you later regret — a purchase, a contract, a promise — that you would not have made on a rested Tuesday morning.', 'Establish a rule: no significant financial decisions when tired, stressed, or emotional. Sleep is free and dramatically improves financial decision quality. If a decision feels urgent in a depleted state, that urgency is a signal to wait.', '🔋', 14),
('Availability Heuristic', 'Decision Making', 'We judge likelihood by how easily examples come to mind, not by actual data.', 'The availability heuristic (Kahneman and Tversky, 1973) is our tendency to assess the probability of events based on how readily examples come to mind. Vivid, recent, or emotionally charged events feel more common than they are. This distorts financial risk perception significantly.', 'After reading several articles about people losing their homes, you become convinced your own financial security is more precarious than it is. You make anxious over-cautious decisions that cost you in missed opportunity.', 'Before making a risk assessment ask: what does the data say, not what do I feel? Look for base rates — what percentage of people in my situation actually experience this outcome? Data corrects for the distortions of vivid anecdote.', '📰', 15),
('Framing Effect', 'Decision Making', 'Identical information presented differently produces systematically different decisions.', 'The framing effect (Kahneman and Tversky, 1981) demonstrates that we respond to the presentation of information, not just its content. A 90% survival rate and a 10% mortality rate are identical — but feel different. In finance, framing is used constantly: investment vs expense, save £50 a month vs £600 a year, affordable monthly payment vs total cost £18,000 over 5 years.', 'A car is advertised at £299 a month. You compare it to your monthly salary and it feels manageable. The total cost over the finance term is £21,528. Monthly framing made £21,528 feel like £299.', 'Always reframe financial decisions yourself before accepting the frame you were given. Convert monthly to annual. Convert saving X% to spending Y. Ask what the total cost is, not the monthly cost.', '🖼️', 16);
```

---

## Swift Data Models

### CheckIn.swift
```swift
import Foundation

struct CheckIn: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var date: Date
    var questionId: UUID?
    var response: String?
    var emotionalTone: EmotionalTone
    var streakCount: Int
    var alignmentPct: Double
    var createdAt: Date

    enum EmotionalTone: String, Codable, CaseIterable {
        case calm, anxious, neutral
        var emoji: String {
            switch self {
            case .calm: return "😌"
            case .anxious: return "😟"
            case .neutral: return "😐"
            }
        }
        var label: String {
            switch self {
            case .calm: return "Calm"
            case .anxious: return "Anxious"
            case .neutral: return "Neutral"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, date, response
        case userId = "user_id"
        case questionId = "question_id"
        case emotionalTone = "emotional_tone"
        case streakCount = "streak_count"
        case alignmentPct = "alignment_pct"
        case createdAt = "created_at"
    }
}
```

### BiasLesson.swift
```swift
import Foundation

struct BiasLesson: Identifiable, Codable {
    let id: UUID
    var biasName: String
    var category: String
    var shortDescription: String
    var fullExplanation: String
    var realWorldExample: String
    var howToCounter: String
    var emoji: String
    var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, category, emoji
        case biasName = "bias_name"
        case shortDescription = "short_description"
        case fullExplanation = "full_explanation"
        case realWorldExample = "real_world_example"
        case howToCounter = "how_to_counter"
        case sortOrder = "sort_order"
    }
}
```

### Question.swift
```swift
import Foundation

struct Question: Identifiable, Codable {
    let id: UUID
    var question: String
    var whyExplanation: String
    var biasName: String
    var biasCategory: String
    var difficulty: String
    var lastShown: Date?

    enum CodingKeys: String, CodingKey {
        case id, question, difficulty
        case whyExplanation = "why_explanation"
        case biasName = "bias_name"
        case biasCategory = "bias_category"
        case lastShown = "last_shown"
    }
}
```

### MoneyEvent.swift
```swift
import Foundation

struct MoneyEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var date: Date
    var amount: Double
    var plannedStatus: PlannedStatus
    var behaviourTag: String?       // CheckIn.SpendingDriver rawValue
    var lifeEvent: String?          // LifeEvent rawValue
    var note: String?
    var createdAt: Date

    enum PlannedStatus: String, Codable, CaseIterable {
        case planned, surprise, impulse
        var isUnplanned: Bool { self != .planned }
    }

    enum LifeEvent: String, Codable, CaseIterable {
        case jobChange = "job_change"
        case unexpectedBill = "unexpected_bill"
        case medical, windfall
        case otherBig = "other_big"
    }

    // Derived, not stored
    enum SizeBucket { case small, medium, large }
    var sizeBucket: SizeBucket {
        switch amount {
        case ..<50: .small; case 50..<200: .medium; default: .large
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, date, amount, note
        case userId = "user_id"
        case plannedStatus = "planned_status"
        case behaviourTag = "behaviour_tag"
        case lifeEvent = "life_event"
        case createdAt = "created_at"
    }
}
```

---

## Screens & Features

### 1. Onboarding (OnboardingView)
First launch only. UserDefaults flag "hasOnboarded".
- 3 swipeable intro cards explaining awareness-based budgeting
- Email + password sign up
- Creates first budget_months row on sign up
- Navigates to HomeView

### 2. Home Dashboard (HomeView)
- Greeting with time of day + first name
- Check-in status card (checked in or not)
- Streak card + Alignment card side by side
- Bias of the week card (rotates weekly, tappable to LearnView)
- Log money event button
- Recent activity (last 3 events)
- This month link

Streak copy: 0="Start today" · 1-6="Keep showing up" · 7-13="One week strong" · 14-29="Building a habit" · 30+="Awareness mastery"
Alignment colour: ≥80% green · 50-79% orange · <50% red + reassurance copy

### 3. Daily Check-In (CheckInView)
Target: under 90 seconds.

Layout:
1. Bias pill (name + category)
2. Large question text
3. Optional text response field
4. "Why this matters" — collapsed toggle, never auto-expanded
5. Emotional tone picker: 😌 Calm · 😐 Neutral · 😟 Anxious (always optional)
6. Complete check-in button

Logic:
- Fetch least recently shown question (last_shown null or >14 days ago)
- Update last_shown and user_bias_progress on fetch
- Calculate streak: yesterday has check-in → streak+1, else streak=1
- Calculate alignment: max(0, (1 - surprise_total/income_target) * 100)
- Save to daily_checkins
- Show completion: green checkmark + streak count
- Return to HomeView

### 4. Money Event (MoneyEventView)
Sheet. No categories. Three taps:

1. **Amount** (required, numeric input)
2. **Was this planned?** — three full-width buttons:
   - [✓ Planned] "Expected, budgeted for"
   - [⚡ Surprise] "Didn't see this coming"
   - [🎯 Impulse] "Saw it, wanted it, bought it"
   Saved as `planned_status` column.
3. **What drove it?** — only shown for Surprise/Impulse.
   Same 6 behavioural tags as check-in SpendingDriver.
   Saved as `behaviour_tag` column.
4. **Life event** — only shown if amount > 200.
   [Job/income change] [Unexpected bill] [Medical]
   [Windfall] [Other big event]. Saved as `life_event` column.

Plus optional note and date picker.

Size bucket is derived (not stored): Small (<50), Medium (50-200), Large (200+).

**Philosophy:** Categories tell you nothing. "Shopping" is not insight.
Behaviour tags tell you WHY. Planned/surprise ratio tells you awareness.
Trends use planned_status + behaviour_tag + amount size, never categories.

### 5. Learn Screen (LearnView) ← NEW
Tab bar item. Browsable library of all 16 biases.
- Filter pills by category
- Bias cards: emoji + name + short description + "Encountered X times" if applicable
- "Your most encountered bias" section after 7+ check-ins
- Tappable → BiasDetailView

### 6. Bias Detail (BiasDetailView) ← NEW
Full bias education screen.
Sections: What it is · In real life (card treatment) · How to counter it · Your history with this bias
Shows related questions from question_pool for that bias.

### 7. Month View (MonthView)
- Alignment % + income target (editable)
- Streak calendar (dot per day, green/grey)
- Events grouped by type
- Category totals

---

## Swipe Card Architecture

### CheckInView — swipe card spec
Card stack of 3: front card (#2D1B69), middle (scaled 0.96, #3D2B85), back (scaled 0.92, #EEEDFE).

DragGesture thresholds:
- Swipe UP > 80pt = complete check-in
- Swipe RIGHT > 80pt = skip (no streak impact)
- Release < threshold = spring back to centre

Front card contains (top to bottom):
1. Bias pill: name · category in gold
2. Question text: .title3 bold white
3. Optional response TextField
4. Why toggle: collapsed by default, chevron rotates on expand
5. Tone picker: 3 equal buttons Calm/Neutral/Anxious
6. All optional except swipe gesture

Progress dots: one per question attempted today
Swipe hints: "skip →" left, "↑ complete" right

### LearnView — swipe card spec
Card stack of 3 visible.
Front card: white, 0.5px purple border.
Middle: #F0EEF8 scaled 0.96.
Back: #E8E5F5 scaled 0.92.

Front card contains:
1. Large emoji (48pt)
2. Category pill (coloured per category)
3. Seen X times badge (from user_bias_progress)
4. Bias name: .title2 bold #2D1B69
5. Short description: .body secondary
6. Divider
7. "In real life" label in teal
8. Example text in tinted card
9. "How to counter it →" button (#2D1B69)

Filter pills: All · Avoidance · Decision Making · Money Psychology · Time Perception · External Influence · Self Perception · Inertia

Navigation: swipe left/right OR dot indicator taps
Dot indicator: 5 dots showing position in filtered set

Category tile colours for filter pills:
- Avoidance: bg #E1F5EE text #085041
- Decision Making: bg #EEEDFE text #3C3489
- Money Psychology: bg #FAEEDA text #412402
- Time Perception: bg #F3E5F5 text #4A148C
- External Influence: bg #FAECE7 text #4A1B0C
- Self Perception: bg #E0F7FA text #006064
- Inertia: bg #FBE9E7 text #BF360C

---

## Navigation

```
Tab bar:
├── 🏠 Home
├── ✏️ Check In (fullScreenCover)
├── 📚 Learn
└── 📊 Month

Sheets: MoneyEventView (from Home + CheckIn)
Push: BiasDetailView (from Learn)
First launch: OnboardingView (fullScreenCover, permanent dismiss)
```

---

## Supabase Service Methods

```swift
// Auth
func signUp(email: String, password: String) async throws
func signIn(email: String, password: String) async throws
func signOut() async throws
func currentUser() -> User?

// Check-ins
func saveCheckIn(_ checkIn: CheckIn) async throws
func fetchTodaysCheckIn() async throws -> CheckIn?
func fetchCheckInsForMonth(_ date: Date) async throws -> [CheckIn]

// Money events
func saveMoneyEvent(_ event: MoneyEvent) async throws
func fetchMoneyEvents(forMonth: Date) async throws -> [MoneyEvent]

// Questions
func fetchNextQuestion() async throws -> Question

// Bias lessons
func fetchAllBiasLessons() async throws -> [BiasLesson]
func fetchBiasLesson(biasName: String) async throws -> BiasLesson?

// Bias progress
func updateBiasProgress(biasName: String, reflected: Bool) async throws
func fetchBiasProgress() async throws -> [UserBiasProgress]

// Budget
func fetchOrCreateBudgetMonth(for date: Date) async throws -> BudgetMonth
func updateIncomeTarget(_ amount: Double, for month: Date) async throws
```

---

## Push Notifications

Daily 8pm if not checked in. Rotate messages:
- "60 seconds. That's all it takes."
- "How's your awareness today?"
- "Your streak is waiting."
- "One question. That's today's check-in."

Request permission after first completed check-in, not on launch.

---

## Design

### Money Green + Nugget Gold colour system

Primary green (hero cards, nav): `#2E7D32`
Accent green (labels, ring, buttons): `#4CAF50`
Light green (card backs, tints): `#81C784`
Pale green (pills, tab active bg): `#E8F5E9`
App background: `#FAFAF8`
Card background: white
Text primary: `#1A2E1A`
Text secondary: `#6B7A6B`
Text tertiary: `#A0B0A0`
Positive: `#4CAF50`
Warning: `#FF7043`
Gold base: `#C59430`
Gold text: `#E8B84B`

Nugget gold gradient (5 stops, topLeading → bottomTrailing):
`#FFF0A0` → `#E8B84B` → `#C59430` → `#8B6010` → `#D4A843`

### Application

- **HomeView**: bg `#FAFAF8`, hero card `#2E7D32`, section labels
  `#4CAF50` 10pt 700 uppercase, streak ring `#4CAF50` stroke with
  gold gradient number, stat cards white with `#E8F5E9` border,
  gold bias pill on hero card, gold "Start check-in" button.
- **CheckInView**: front card `#2E7D32`, back cards `#81C784` /
  `#A5D6A7`, gold bias pill, `#E8F5E9` why section bg, gold
  complete button, `#4CAF50` progress dots.
- **LearnView**: filter pill active `#2E7D32` bg white text,
  inactive white with `#4CAF50` border, card backs `#C8E6C9` /
  `#A5D6A7`, "How to counter it" button `#2E7D32`, category
  colours keep their own tints.
- **BiasDetailView**: category pills keep category colours, "How
  to counter it" and "In real life" sections use `#E8F5E9` bg.
- **Tab bar**: active `#2E7D32` icon+label, inactive grey.

Typography: SF Pro system sizes only. Never hardcode font names.
Corner radius: 20pt cards · 14pt buttons · 999pt pills.
No purple. No violet. No blue accent.

---

## Behavioural UX Rules (Non-Negotiable)

1. Never show red without reassurance copy alongside it
2. Missed streak = encouragement only, never punishment
3. Why explanations always collapsed by default
4. Emotional tone always optional, never required
5. Alignment % clamped at 0%, never negative
6. Check-in completable in under 90 seconds
7. Education is always pull, never push
8. Bias names always shown with category context

---

## Build Order for Beta

1. OnboardingView + Supabase auth
2. HomeView (static → live data)
3. CheckInView with full behavioural layer
4. MoneyEventView
5. LearnView + BiasDetailView
6. NotificationService
7. MonthView

---

## Claude Code Session Rules

1. Read `.claude/CLAUDE.md` and all `/docs` before starting
2. Update `docs/STATUS.md` and `docs/CHANGELOG.md` after every task
3. Build order: Models → Services → ViewModels → Views
4. async/await only — no Combine
5. All Supabase calls in do/catch with user-facing error messages
6. Never hardcode credentials — ask Sanjay if missing

---

*PRD v1.1 — Updated: 2026-04-12*
*Added: Education layer, 16 bias lessons with full explanations, 30 questions, LearnView, BiasDetailView*
*Core philosophy: Stay aware. Adjust early. No shame.*
