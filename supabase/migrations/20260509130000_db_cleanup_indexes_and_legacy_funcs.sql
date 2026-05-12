-- Migration: cleanup pass on remaining advisor warnings + perf indexes
--
-- WHY:
--   After the main batch of fixes the advisor still flags 3 things that
--   pre-date this session, plus 4 missing indexes on user_id / question_id
--   foreign keys. Addressing them while context is fresh.
--
-- CONTENTS:
--   1. Set search_path on `bias_mapping_stats_touch_updated()`
--      (function_search_path_mutable WARN — pre-existing).
--   2. Revoke anon + authenticated EXECUTE on `rls_auto_enable()` —
--      it's an internal helper that should not be REST-callable
--      (anon_security_definer_function_executable WARN).
--   3. Add btree indexes on the four foreign keys flagged by the
--      performance advisor as "unindexed". user_id is the dominant
--      filter on every query in the app — these become 10–100× faster
--      at scale.
--
-- NOT FIXED (deliberately):
--   - delete_account REST exposure — that function IS supposed to be
--     callable by authenticated users. Warning is informational.
--   - Leaked password protection — toggled in the Supabase Auth
--     dashboard, not via SQL. Bella to enable manually.
--   - Unused indexes on bias_mapping_stats_user_idx and
--     decision_lessons_user_idx — they'll be used once user activity
--     resumes; dropping them now would just have to re-create them
--     in a future migration.
--
-- ROLLBACK:
--   Each block is independently reversible. Indexes can be dropped
--   with `DROP INDEX IF EXISTS …` and the search_path / EXECUTE
--   changes can be reset with the inverse statements.

begin;

-- ─────── 1. search_path on bias_mapping_stats_touch_updated ───────
alter function public.bias_mapping_stats_touch_updated()
    set search_path = public;

-- ─────── 2. lock down rls_auto_enable (internal-only) ───────
revoke execute on function public.rls_auto_enable() from anon, authenticated, public;

-- ─────── 3. indexes on FK columns flagged by perf advisor ───────
create index if not exists idx_budget_months_user_id
    on public.budget_months (user_id);

create index if not exists idx_daily_checkins_question_id
    on public.daily_checkins (question_id);

create index if not exists idx_money_events_user_id
    on public.money_events (user_id);

create index if not exists idx_monthly_decisions_user_id
    on public.monthly_decisions (user_id);

commit;
