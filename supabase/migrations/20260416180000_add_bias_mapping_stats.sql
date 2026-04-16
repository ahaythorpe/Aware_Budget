-- MAPPING CONFIRMATION STATS
--
-- Tracks per-user, per-(category × status × bias) review outcomes
-- so the algorithm can audit itself across reinstalls AND aggregate
-- across users for industry/research deliverables.
--
-- v1 of this lived in UserDefaults (local-only, lost on reinstall).
-- Promoting it here.
--
-- Each row is one mapping the algorithm has proposed at least once.
-- The three outcome counters increment as the user reviews:
--   identified  → user said "Yes, that's me"
--   notSure     → user said "Not sure"
--   different   → user said "No, different reason"
--
-- A view derives confirmation_rate = identified / (identified + not_sure + different)
-- Mappings with rate < 0.30 after sample_size >= 20 are flagged in
-- AlgorithmExplainerSheet for review/retirement.

CREATE TABLE IF NOT EXISTS public.bias_mapping_stats (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category      TEXT NOT NULL,
    planned_status TEXT NOT NULL CHECK (planned_status IN ('planned','surprise','impulse')),
    bias_name     TEXT NOT NULL,
    identified_count   INTEGER NOT NULL DEFAULT 0,
    not_sure_count     INTEGER NOT NULL DEFAULT 0,
    different_count    INTEGER NOT NULL DEFAULT 0,
    last_review_at     TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- One row per (user, category, status, bias). Increments via UPSERT.
    UNIQUE (user_id, category, planned_status, bias_name)
);

CREATE INDEX IF NOT EXISTS bias_mapping_stats_user_idx
    ON public.bias_mapping_stats (user_id);

CREATE INDEX IF NOT EXISTS bias_mapping_stats_mapping_idx
    ON public.bias_mapping_stats (category, planned_status, bias_name);

-- RLS: a user can only read/write their own stats. Aggregation across
-- users for the research deliverable goes through a separate VIEW
-- (next migration) that strips user_id and only exposes counts.
ALTER TABLE public.bias_mapping_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_read_own_mapping_stats"
    ON public.bias_mapping_stats FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "users_insert_own_mapping_stats"
    ON public.bias_mapping_stats FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "users_update_own_mapping_stats"
    ON public.bias_mapping_stats FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- updated_at auto-touch on UPDATE.
CREATE OR REPLACE FUNCTION public.bias_mapping_stats_touch_updated()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS bias_mapping_stats_touch ON public.bias_mapping_stats;
CREATE TRIGGER bias_mapping_stats_touch
    BEFORE UPDATE ON public.bias_mapping_stats
    FOR EACH ROW EXECUTE FUNCTION public.bias_mapping_stats_touch_updated();

COMMENT ON TABLE public.bias_mapping_stats IS
    'Per-user (category x status x bias) review outcomes. Used by AlgorithmExplainerSheet to surface low-confirmation mappings flagged for retirement. v1 promoted from UserDefaults storage to enable cross-device persistence and aggregate research deliverables.';
