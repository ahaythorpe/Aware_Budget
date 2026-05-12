-- Migration: fix SECURITY DEFINER warning on bias_mapping_aggregate view
--
-- WHY:
--   Supabase Advisor flagged this view as CRITICAL — Postgres views
--   default to security definer mode unless `WITH (security_invoker = true)`
--   is set. In definer mode, the view ignores RLS on its underlying
--   table (bias_mapping_stats), reading rows from ALL users.
--
--   Verified before this migration: the view is NOT consumed by any
--   Swift code (only the migration file references it). It was added
--   speculatively for a "research deliverable" that hasn't shipped.
--   So the fix can be minimal: flip to invoker mode, accept that the
--   view becomes per-user. If cross-user aggregation is needed later,
--   add a proper SECURITY DEFINER FUNCTION (not a view) that explicitly
--   enforces k-anonymity server-side.
--
-- ROLLBACK:
--   ALTER VIEW public.bias_mapping_aggregate RESET (security_invoker);
--   (Not recommended — rolling back re-introduces the cross-user leak
--   warning.)

alter view public.bias_mapping_aggregate set (security_invoker = true);

comment on view public.bias_mapping_aggregate is
    'Per-user aggregate of bias_mapping_stats with k-anonymity floor (sample_size >= 50). Set to security_invoker=true 2026-05-09 to close Supabase Advisor CRITICAL warning. The k-anonymity floor combined with invoker mode means a single user is unlikely to satisfy the floor — the view returns empty for typical clients. For cross-user research aggregation, build a SECURITY DEFINER function with explicit access control instead of widening this view.';
