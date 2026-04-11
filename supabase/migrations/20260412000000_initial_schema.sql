-- AwareBudget — Supabase schema
-- Run in Supabase SQL editor before launching the app.

-- 5. Question pool (defined first so daily_checkins can reference it)
create table if not exists question_pool (
  id uuid primary key default gen_random_uuid(),
  question text not null,
  why_explanation text not null,
  bias_name text not null,
  last_shown date,
  created_at timestamptz default now()
);

-- 1. Budget months
create table if not exists budget_months (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  month date not null,
  income_target numeric default 0,
  created_at timestamptz default now()
);

-- 2. Daily check-ins
create table if not exists daily_checkins (
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

-- 3. Money events
create table if not exists money_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date date not null,
  amount numeric not null,
  category text,
  event_type text check (event_type in ('surprise', 'win', 'expected')),
  note text,
  created_at timestamptz default now()
);

-- 4. Monthly decisions
create table if not exists monthly_decisions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  month date not null,
  decision text,
  insight text,
  created_at timestamptz default now()
);

-- Row Level Security
alter table budget_months      enable row level security;
alter table daily_checkins     enable row level security;
alter table money_events       enable row level security;
alter table monthly_decisions  enable row level security;
alter table question_pool      enable row level security;

create policy "own data only" on budget_months      for all using (auth.uid() = user_id);
create policy "own data only" on daily_checkins     for all using (auth.uid() = user_id);
create policy "own data only" on money_events       for all using (auth.uid() = user_id);
create policy "own data only" on monthly_decisions  for all using (auth.uid() = user_id);
create policy "read questions"  on question_pool     for select using (true);
