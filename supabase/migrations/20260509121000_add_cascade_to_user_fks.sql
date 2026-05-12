-- Migration: add ON DELETE CASCADE to legacy user-scoped FK constraints
--
-- WHY:
--   The initial schema (20260412000000_initial_schema.sql) and the
--   bias-progress migration (20260412120000) declared user_id FKs without
--   ON DELETE CASCADE. This blocks `delete_account` from removing the
--   auth.users row because Postgres refuses to drop a parent that still
--   has dependent child rows.
--
--   Apple App Store Guideline 5.1.1(v) requires account deletion to fully
--   remove all user data. Without CASCADE on these 5 tables the delete
--   flow is silently broken — the call returns success but the auth row
--   stays and the data persists.
--
-- TABLES FIXED (5):
--   - public.budget_months
--   - public.daily_checkins
--   - public.money_events
--   - public.monthly_decisions
--   - public.user_bias_progress
--
-- TABLES ALREADY CORRECT (verified live before this migration):
--   - public.bias_mapping_stats
--   - public.decision_lessons
--   - public.user_monthly_income
--   - public.user_balance_snapshots
--   - public.profiles  (created in 20260509120000)
--
-- METHOD:
--   Drop + re-create each FK with CASCADE. No data is read or modified —
--   this is metadata-only. Wrapped in a single transaction so if any
--   ALTER fails, all five revert atomically.
--
-- ROLLBACK:
--   Re-run the same DROP statements, then re-create each FK without the
--   ON DELETE CASCADE clause. (Note: rolling back puts you back into the
--   broken state — Apple deletion will re-fail. Do not roll back unless
--   the cascade itself is causing a different problem.)

begin;

alter table public.budget_months
    drop constraint if exists budget_months_user_id_fkey,
    add constraint budget_months_user_id_fkey
        foreign key (user_id) references auth.users(id) on delete cascade;

alter table public.daily_checkins
    drop constraint if exists daily_checkins_user_id_fkey,
    add constraint daily_checkins_user_id_fkey
        foreign key (user_id) references auth.users(id) on delete cascade;

alter table public.money_events
    drop constraint if exists money_events_user_id_fkey,
    add constraint money_events_user_id_fkey
        foreign key (user_id) references auth.users(id) on delete cascade;

alter table public.monthly_decisions
    drop constraint if exists monthly_decisions_user_id_fkey,
    add constraint monthly_decisions_user_id_fkey
        foreign key (user_id) references auth.users(id) on delete cascade;

alter table public.user_bias_progress
    drop constraint if exists user_bias_progress_user_id_fkey,
    add constraint user_bias_progress_user_id_fkey
        foreign key (user_id) references auth.users(id) on delete cascade;

commit;
