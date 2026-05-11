-- Migration: Money Mind Quiz (Build 7)
--
-- WHY:
--   Adds the Money Mind Quiz feature — a 6-question multi-choice quiz that
--   scores users into one of 6 research-grounded archetypes (Drifter,
--   Reactor, Bookkeeper, Now, Bandwagon, Autopilot). The archetype is the
--   surface label; the deep data is the underlying biases from BiasData.swift.
--   The quiz is a fast personalisation entry, NOT a replacement for the
--   BFAS clinical assessment (which remains in `bfas_responses`).
--
-- DESIGN:
--   - Separate table `money_mind_quiz_responses` (not shoehorned into BFAS)
--     so the two can evolve independently.
--   - `profiles.archetype` + `profiles.top_biases[]` store the latest result
--     so the Home tile + Education tab "← You" card can render without
--     re-running the scorer on every render.
--   - RLS uses `(select auth.uid())` per the perf convention.
--   - FK ON DELETE CASCADE (delete_account RPC stays clean).
--   - Index on user_id (FK) per the FK-index convention from migration
--     20260509130000.
--
-- ROLLBACK:
--   ALTER TABLE public.profiles DROP COLUMN IF EXISTS top_biases;
--   ALTER TABLE public.profiles DROP COLUMN IF EXISTS archetype;
--   DROP TABLE  IF EXISTS public.money_mind_quiz_responses;

create table if not exists public.money_mind_quiz_responses (
    id              uuid        primary key default gen_random_uuid(),
    user_id         uuid        not null references auth.users(id) on delete cascade,
    answers         jsonb       not null,
    scores          jsonb       not null,
    archetype       text        not null,
    top_biases      text[]      not null default '{}',
    completed_at    timestamptz not null default now()
);

comment on table public.money_mind_quiz_responses is
    'One row per quiz completion. Users can retake — latest row by completed_at wins. Surface archetype is on profiles; this table is the audit log.';

create index if not exists money_mind_quiz_responses_user_id_idx
    on public.money_mind_quiz_responses(user_id);

create index if not exists money_mind_quiz_responses_user_completed_idx
    on public.money_mind_quiz_responses(user_id, completed_at desc);

alter table public.money_mind_quiz_responses enable row level security;

drop policy if exists "own quiz read"   on public.money_mind_quiz_responses;
drop policy if exists "own quiz insert" on public.money_mind_quiz_responses;

create policy "own quiz read"   on public.money_mind_quiz_responses
    for select using ((select auth.uid()) = user_id);

create policy "own quiz insert" on public.money_mind_quiz_responses
    for insert with check ((select auth.uid()) = user_id);

-- Profile columns: cache the latest archetype + top biases for fast reads
alter table public.profiles
    add column if not exists archetype  text,
    add column if not exists top_biases text[] not null default '{}';

comment on column public.profiles.archetype is
    'Latest Money Mind Quiz archetype (Drifter|Reactor|Bookkeeper|Now|Bandwagon|Autopilot). Null until first quiz completion.';
comment on column public.profiles.top_biases is
    'Top 3 bias names from the user''s archetype category. Cached from money_mind_quiz_responses.';
