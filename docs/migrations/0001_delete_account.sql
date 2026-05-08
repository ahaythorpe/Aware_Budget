-- Migration: 0001_delete_account
-- Date: 2026-05-03
-- Purpose: Apple App Store Guideline 5.1.1(v) — apps that allow account
-- creation must also let users permanently delete their account in-app.
--
-- Run instructions: Supabase Dashboard → SQL Editor → New query →
-- paste this entire file → Run. Idempotent (CREATE OR REPLACE).
--
-- Behaviour: Authenticated user calls supabase.rpc('delete_account').
-- Function wipes their rows from every per-user table, then deletes
-- their auth.users row. JWT becomes invalid immediately.

CREATE OR REPLACE FUNCTION public.delete_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    uid uuid := auth.uid();
BEGIN
    -- Refuse if not authenticated. Defensive: SECURITY DEFINER functions
    -- run as the function owner, so without this check an unauthenticated
    -- caller could in theory wipe other rows.
    IF uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
    END IF;

    -- Wipe every per-user table. Safe even if a table doesn't have
    -- user_id rows for this user (no-op delete). Add new tables here
    -- as the schema grows.
    DELETE FROM public.daily_checkins         WHERE user_id = uid;
    DELETE FROM public.money_events           WHERE user_id = uid;
    DELETE FROM public.user_bias_progress     WHERE user_id = uid;
    DELETE FROM public.user_monthly_income    WHERE user_id = uid;
    DELETE FROM public.user_balance_snapshots WHERE user_id = uid;
    DELETE FROM public.budget_months          WHERE user_id = uid;
    DELETE FROM public.question_pool          WHERE user_id = uid;
    DELETE FROM public.bias_mapping_stats     WHERE user_id = uid;
    DELETE FROM public.monthly_decisions      WHERE user_id = uid;
    DELETE FROM public.decision_lessons       WHERE user_id = uid;

    -- Finally, the auth row. Cascading FKs will catch anything missed
    -- above. Caller's JWT is now invalid; client must sign out locally.
    DELETE FROM auth.users WHERE id = uid;
END;
$$;

-- Lock down: only authenticated users can call. Revoke from anon and
-- the broad PUBLIC role; grant explicit EXECUTE to authenticated.
REVOKE ALL ON FUNCTION public.delete_account() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_account() FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_account() TO authenticated;

COMMENT ON FUNCTION public.delete_account() IS
'Apple-compliant account deletion. Authenticated user calls via supabase.rpc.
 Wipes all user-owned rows then deletes auth.users row. SECURITY DEFINER
 with explicit auth.uid() check ensures users can only delete themselves.';
