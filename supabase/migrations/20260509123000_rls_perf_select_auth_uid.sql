-- Migration: convert RLS policies to use (select auth.uid())
--
-- WHY:
--   Supabase Advisor flagged 15 policies across 9 user-scoped tables for
--   "Auth RLS Initialization Plan" warnings. The policies use bare
--   `auth.uid() = user_id`, which Postgres re-evaluates per row.
--   Wrapping in a subquery — `(select auth.uid()) = user_id` — moves
--   evaluation to once per query, which can be 10-100× faster on
--   large tables.
--
--   Policy semantics are identical. This is purely a performance fix
--   that closes the Advisor warnings. Apple doesn't read the Advisor
--   directly, but warning-free is a credibility signal we want.
--
-- TABLES + POLICY COUNTS (15 policies total):
--   bias_mapping_stats     × 2 (read, update)
--   budget_months          × 1 (ALL)
--   daily_checkins         × 1 (ALL)
--   decision_lessons       × 3 (read, update, delete)
--   money_events           × 1 (ALL)
--   monthly_decisions      × 1 (ALL)
--   user_balance_snapshots × 3 (read, update, delete)
--   user_bias_progress     × 1 (ALL)
--   user_monthly_income    × 2 (read, update)
--
-- METHOD:
--   Drop + re-create each policy inside a single transaction. If any
--   ALTER fails, the entire migration rolls back and the original
--   policies remain in place.
--
-- ROLLBACK:
--   Re-run with bare `auth.uid()` instead of `(select auth.uid())`.
--   You'd be reverting back to the perf warnings — only do this if
--   the subquery form turns out to behave differently somehow (it
--   shouldn't; this is a documented Supabase optimization pattern).

begin;

-- ─────────── budget_months ───────────
drop policy if exists "own data only" on public.budget_months;
create policy "own data only" on public.budget_months
    for all using ((select auth.uid()) = user_id);

-- ─────────── daily_checkins ───────────
drop policy if exists "own data only" on public.daily_checkins;
create policy "own data only" on public.daily_checkins
    for all using ((select auth.uid()) = user_id);

-- ─────────── money_events ───────────
drop policy if exists "own data only" on public.money_events;
create policy "own data only" on public.money_events
    for all using ((select auth.uid()) = user_id);

-- ─────────── monthly_decisions ───────────
drop policy if exists "own data only" on public.monthly_decisions;
create policy "own data only" on public.monthly_decisions
    for all using ((select auth.uid()) = user_id);

-- ─────────── user_bias_progress ───────────
drop policy if exists "own data only" on public.user_bias_progress;
create policy "own data only" on public.user_bias_progress
    for all using ((select auth.uid()) = user_id);

-- ─────────── bias_mapping_stats ───────────
drop policy if exists "users_read_own_mapping_stats"   on public.bias_mapping_stats;
drop policy if exists "users_update_own_mapping_stats" on public.bias_mapping_stats;

create policy "users_read_own_mapping_stats" on public.bias_mapping_stats
    for select using ((select auth.uid()) = user_id);

create policy "users_update_own_mapping_stats" on public.bias_mapping_stats
    for update
    using       ((select auth.uid()) = user_id)
    with check  ((select auth.uid()) = user_id);

-- ─────────── decision_lessons ───────────
drop policy if exists "users_read_own_lessons"   on public.decision_lessons;
drop policy if exists "users_update_own_lessons" on public.decision_lessons;
drop policy if exists "users_delete_own_lessons" on public.decision_lessons;

create policy "users_read_own_lessons" on public.decision_lessons
    for select using ((select auth.uid()) = user_id);

create policy "users_update_own_lessons" on public.decision_lessons
    for update
    using       ((select auth.uid()) = user_id)
    with check  ((select auth.uid()) = user_id);

create policy "users_delete_own_lessons" on public.decision_lessons
    for delete using ((select auth.uid()) = user_id);

-- ─────────── user_balance_snapshots ───────────
drop policy if exists "users_read_own_snapshots"   on public.user_balance_snapshots;
drop policy if exists "users_update_own_snapshots" on public.user_balance_snapshots;
drop policy if exists "users_delete_own_snapshots" on public.user_balance_snapshots;

create policy "users_read_own_snapshots" on public.user_balance_snapshots
    for select using ((select auth.uid()) = user_id);

create policy "users_update_own_snapshots" on public.user_balance_snapshots
    for update
    using       ((select auth.uid()) = user_id)
    with check  ((select auth.uid()) = user_id);

create policy "users_delete_own_snapshots" on public.user_balance_snapshots
    for delete using ((select auth.uid()) = user_id);

-- ─────────── user_monthly_income ───────────
drop policy if exists "users_read_own_income"   on public.user_monthly_income;
drop policy if exists "users_update_own_income" on public.user_monthly_income;

create policy "users_read_own_income" on public.user_monthly_income
    for select using ((select auth.uid()) = user_id);

create policy "users_update_own_income" on public.user_monthly_income
    for update
    using       ((select auth.uid()) = user_id)
    with check  ((select auth.uid()) = user_id);

commit;
