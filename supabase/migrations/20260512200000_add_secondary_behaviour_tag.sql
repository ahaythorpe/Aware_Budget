-- Migration: add secondary_behaviour_tag to money_events
--
-- WHY:
--   Bella's algorithm constraint (2026-05-12): a spending event can be
--   driven by up to TWO co-occurring biases (e.g. an impulse coffee
--   purchase is often BOTH Ego Depletion AND Present Bias). The single
--   `behaviour_tag` column lost half the signal whenever two drivers
--   genuinely overlapped. Adding a nullable secondary column lets the
--   algorithm record the second-most-plausible bias when it comes from
--   a different bias category (avoiding redundant near-duplicates).
--
-- WHAT:
--   - Add `secondary_behaviour_tag TEXT NULL` to public.money_events.
--   - No data migration needed — existing rows keep secondary = NULL
--     and continue to work as single-bias events.
--
-- BACKWARD-COMPATIBLE:
--   The Swift model decodes the column as optional. Reads of historical
--   events continue to return nil for secondary_behaviour_tag.

ALTER TABLE public.money_events
    ADD COLUMN IF NOT EXISTS secondary_behaviour_tag TEXT NULL;

COMMENT ON COLUMN public.money_events.secondary_behaviour_tag IS
    'Optional second bias for events with overlapping drivers. Max two biases per event total. See BiasRotation.nextBiasPair.';
