-- Migration: replace delete_account() RPC with tracked, correct version
--
-- WHY:
--   The delete_account() RPC exists in production but was never tracked
--   as a migration in this repo (Swift code at SupabaseService.swift:229
--   references the non-existent file 0001_delete_account.sql). The live
--   version also has a bug: it tries to DELETE FROM public.question_pool
--   WHERE user_id = uid — but question_pool is a shared content table
--   with NO user_id column, so that statement either errors or is a
--   no-op depending on Postgres version.
--
--   Apple Guideline 5.1.1(v) requires permanent, complete deletion of
--   the user's account + all derived data. With ON DELETE CASCADE now
--   in place on every user-scoped table (migration 20260509121000),
--   the RPC only needs to delete the auth.users row — cascades handle
--   the rest. Listing each table is defensive belt-and-braces.
--
-- DESIGN:
--   - SECURITY DEFINER so it can DELETE from auth.users (the caller
--     normally cannot).
--   - Uses auth.uid() server-side: users can only delete THEMSELVES,
--     never another user.
--   - Listed table deletions execute first; the auth.users delete at
--     the end is the cascade trigger. Either path produces the same
--     final state.
--   - public.profiles is NOT explicitly listed — its ON DELETE CASCADE
--     to auth.users handles it. Same for any table added later that
--     follows the standard FK pattern.
--
-- ROLLBACK:
--   The previous version of this function (with the question_pool bug)
--   is preserved in the comment block at the bottom of this file. To
--   restore, paste that block into the SQL editor.

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
    uid uuid := auth.uid();
begin
    if uid is null then
        raise exception 'Not authenticated' using errcode = '42501';
    end if;

    -- Explicit deletes first (defensive — even though CASCADE on
    -- auth.users handles all of these, listing them makes the intent
    -- self-documenting and survives accidental FK config drift).
    delete from public.daily_checkins         where user_id = uid;
    delete from public.money_events           where user_id = uid;
    delete from public.user_bias_progress     where user_id = uid;
    delete from public.user_monthly_income    where user_id = uid;
    delete from public.user_balance_snapshots where user_id = uid;
    delete from public.budget_months          where user_id = uid;
    delete from public.bias_mapping_stats     where user_id = uid;
    delete from public.monthly_decisions      where user_id = uid;
    delete from public.decision_lessons       where user_id = uid;
    delete from public.profiles               where id      = uid;

    -- Final delete — this cascades to anything we missed and removes
    -- the auth identity. After this returns, the user cannot sign in.
    delete from auth.users where id = uid;
end;
$$;

comment on function public.delete_account() is
    'Apple 5.1.1(v) account deletion. SECURITY DEFINER, uses auth.uid() so users can only delete themselves. Per migration 20260509121000 every user-scoped FK has ON DELETE CASCADE, so the final auth.users delete is the source of truth — explicit deletes above are defensive.';

-- Grant execute to authenticated users (so the Swift client can call it)
grant execute on function public.delete_account() to authenticated;

-- ─────────────────────────────────────────────────────────────────────
-- ROLLBACK COPY (do not run in normal flow):
-- The previous (buggy) version of this function for reference only.
-- Paste this into SQL editor if you need to revert.
-- ─────────────────────────────────────────────────────────────────────
-- CREATE OR REPLACE FUNCTION public.delete_account()
--  RETURNS void
--  LANGUAGE plpgsql
--  SECURITY DEFINER
--  SET search_path TO 'public', 'auth'
-- AS $function$
-- DECLARE
--     uid uuid := auth.uid();
-- BEGIN
--     IF uid IS NULL THEN
--         RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
--     END IF;
--
--     DELETE FROM public.daily_checkins         WHERE user_id = uid;
--     DELETE FROM public.money_events           WHERE user_id = uid;
--     DELETE FROM public.user_bias_progress     WHERE user_id = uid;
--     DELETE FROM public.user_monthly_income    WHERE user_id = uid;
--     DELETE FROM public.user_balance_snapshots WHERE user_id = uid;
--     DELETE FROM public.budget_months          WHERE user_id = uid;
--     DELETE FROM public.question_pool          WHERE user_id = uid;  -- ⚠ bug: no user_id column
--     DELETE FROM public.bias_mapping_stats     WHERE user_id = uid;
--     DELETE FROM public.monthly_decisions      WHERE user_id = uid;
--     DELETE FROM public.decision_lessons       WHERE user_id = uid;
--
--     DELETE FROM auth.users WHERE id = uid;
-- END;
-- $function$;
