-- Migration: clean up advisor follow-ups from this session's earlier migrations
--
-- WHY:
--   Running Supabase Advisor after the main batch of fixes surfaced three
--   issues directly tied to earlier migrations in this same session:
--
--   1. `set_profiles_updated_at` (introduced 20260509120000) is missing
--      `set search_path` — function_search_path_mutable WARN.
--   2. Four INSERT policies still use bare `auth.uid()` in their
--      `with_check` clause — task #9 missed them because my detection
--      query only scanned `qual`, not `with_check`. auth_rls_initplan
--      WARN on bias_mapping_stats, decision_lessons, user_monthly_income,
--      user_balance_snapshots.
--   3. `handle_new_user` (introduced 20260509120000) is exposed at
--      `/rest/v1/rpc/handle_new_user` for both anon and authenticated
--      roles. It should only run via the on_auth_user_created trigger.
--      anon_security_definer_function_executable WARN.
--
--   These are all minor but worth tidying up while the context is fresh.
--
-- NOT FIXED IN THIS MIGRATION (intentional, separate scope):
--   - `bias_mapping_stats_touch_updated` search_path (pre-existing, not
--     introduced by this session — defer to a dedicated audit pass).
--   - `rls_auto_enable` REST exposure (pre-existing, same reason).
--   - `delete_account` REST exposure — it IS supposed to be callable by
--     authenticated users; the warning is informational. Keeping it.
--   - Unindexed FKs / unused indexes — perf-only INFO, defer.
--   - Leaked password protection — auth dashboard setting, not SQL.
--
-- ROLLBACK:
--   Reverse each block independently. The four INSERT policies revert to
--   bare auth.uid(); the search_path setter reverts via ALTER FUNCTION
--   RESET search_path; handle_new_user EXECUTE can be re-granted to anon.

begin;

-- ─────── 1. set search_path on set_profiles_updated_at ───────
alter function public.set_profiles_updated_at()
    set search_path = public;

-- ─────── 2. fix INSERT policies still using bare auth.uid() ───────

drop policy if exists "users_insert_own_mapping_stats" on public.bias_mapping_stats;
create policy "users_insert_own_mapping_stats" on public.bias_mapping_stats
    for insert
    with check ((select auth.uid()) = user_id);

drop policy if exists "users_insert_own_lessons" on public.decision_lessons;
create policy "users_insert_own_lessons" on public.decision_lessons
    for insert
    with check ((select auth.uid()) = user_id);

drop policy if exists "users_upsert_own_income" on public.user_monthly_income;
create policy "users_upsert_own_income" on public.user_monthly_income
    for insert
    with check ((select auth.uid()) = user_id);

drop policy if exists "users_insert_own_snapshots" on public.user_balance_snapshots;
create policy "users_insert_own_snapshots" on public.user_balance_snapshots
    for insert
    with check ((select auth.uid()) = user_id);

-- ─────── 3. lock down handle_new_user — trigger-only, not REST ───────
revoke execute on function public.handle_new_user() from anon, authenticated, public;

commit;
