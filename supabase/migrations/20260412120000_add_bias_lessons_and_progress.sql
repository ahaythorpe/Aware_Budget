-- Migration: add bias_lessons + user_bias_progress, extend question_pool
-- PRD v1.1 — Education layer
-- No seed data in this migration; seeds go in follow-up migrations.

-- 1. Extend question_pool with bias_category + difficulty
alter table question_pool
  add column if not exists bias_category text;

alter table question_pool
  add column if not exists difficulty text
  check (difficulty in ('beginner', 'intermediate', 'advanced'))
  default 'beginner';

-- 2. Bias lessons (world-readable library)
create table if not exists bias_lessons (
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

-- 3. Per-user bias progress (private)
create table if not exists user_bias_progress (
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

-- 4. RLS
alter table bias_lessons enable row level security;
alter table user_bias_progress enable row level security;

drop policy if exists "read lessons" on bias_lessons;
create policy "read lessons" on bias_lessons
  for select using (true);

drop policy if exists "own data only" on user_bias_progress;
create policy "own data only" on user_bias_progress
  for all using (auth.uid() = user_id);
